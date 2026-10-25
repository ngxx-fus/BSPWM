#!/usr/bin/env bash

# ==============================================================================
# CopyToLocal.sh
# Restore dotfiles and system configurations from the repository to local system.
# ==============================================================================

set -eo pipefail

# SCRIPT DIRECTORY & CONFIG ####################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "${SCRIPT_DIR}/PathLists.txt" ]; then
    LIST_PATHS="${SCRIPT_DIR}/PathLists.txt"
elif [ -f "${SCRIPT_DIR}/PathList.txt" ]; then
    LIST_PATHS="${SCRIPT_DIR}/PathList.txt"
else
    LIST_PATHS="${SCRIPT_DIR}/PathLists.txt"
fi
DIR_ROOT="${SCRIPT_DIR}/root"

CONFIRM_ALL=0
DRY_RUN=0
SKIP_PACKAGES=0

# CLI OPTIONS #################################################
PrintUsage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Restore dotfiles and system configurations from '${DIR_ROOT}' to the local system based on 'PathLists.txt'.

Options:
  -y, --yes, -a, --all    Confirm all restore operations automatically (non-interactive)
  -n, --dry-run           Preview actions without copying or writing any files
  --skip-packages         Skip installing packages from PackagesManual.txt
  -h, --help              Display this help message and exit

Interactive Choices:
  [y] Yes  - Restore this item
  [n] No   - Skip this item
  [a] All  - Restore this and all subsequent items
  [q] Quit - Cancel and exit the restore script
EOF
}

for arg in "$@"; do
    case "$arg" in
        -y|--yes|-a|--all)
            CONFIRM_ALL=1
            ;;
        -n|--dry-run)
            DRY_RUN=1
            ;;
        --skip-packages)
            SKIP_PACKAGES=1
            ;;
        -h|--help)
            PrintUsage
            exit 0
            ;;
        *)
            echo "[-] Error: Unknown option '$arg'"
            echo "Run '$(basename "$0") --help' for usage."
            exit 1
            ;;
    esac
done

# FUNC UTILS ##################################################

UserConfirmYNA() {
    local prompt_msg="$1"
    local user_choice=""

    while true; do
        if [ -n "$ZSH_VERSION" ]; then
            read -k 1 "user_choice?${prompt_msg} [y/n/a/q]: " </dev/tty
            echo ""
        else
            read -n 1 -r -p "${prompt_msg} [y/n/a/q]: " user_choice </dev/tty
            echo ""
        fi

        case "$user_choice" in
            [yY])
                return 0
                ;;
            [nN])
                return 1
                ;;
            [aA])
                return 2
                ;;
            [qQ])
                return 3
                ;;
            *)
                echo "Invalid input. Please choose 'y' (yes), 'n' (no), 'a' (all), or 'q' (quit)."
                ;;
        esac
    done
}

# PRE-FLIGHT CHECKS ###########################################

if [ ! -f "$LIST_PATHS" ]; then
    echo "[-] Error: Manifest list '${LIST_PATHS}' not found or is not a valid file!"
    exit 1
fi

if [ ! -d "$DIR_ROOT" ]; then
    echo "[-] Error: Source root folder '${DIR_ROOT}' does not exist!"
    exit 1
fi

# Check if any system paths (outside /home or ~) are present in PathLists.txt
has_system_paths=0
while IFS= read -r line || [ -n "$line" ]; do
    line="$(echo "$line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi
    if [[ "$line" != \~* && "$line" != /home/* ]]; then
        has_system_paths=1
        break
    fi
done < "$LIST_PATHS"

# Prompt for sudo only if required by system paths
if [ $has_system_paths -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        echo "[!] Sudo credential is required to restore files into system paths (e.g., /etc/, /usr/)."
        sudo -v
    fi
fi

# MAIN PROCESS ################################################

echo "=========================================================="
if [ "$DRY_RUN" -eq 1 ]; then
    echo " Starting Restore Preview (DRY-RUN) from '${DIR_ROOT}' to Local"
else
    echo " Starting Restore Process from '${DIR_ROOT}' to Local"
fi
echo "=========================================================="

total_items=0
restored_items=0
skipped_items=0
failed_items=0

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # Strip carriage return and trim leading/trailing whitespace
    trimmed_path="$(echo "$raw_line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignore empty lines or comments
    if [[ -z "$trimmed_path" || "$trimmed_path" == \#* ]]; then
        continue
    fi

    total_items=$((total_items + 1))
    is_home_target=0

    # Determine local destination path and repository source path
    if [[ "$trimmed_path" == \~/* ]]; then
        is_home_target=1
        relative_path="${trimmed_path#\~/}"
        dest_local_path="${HOME}/${relative_path}"
        src_root_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    elif [[ "$trimmed_path" == /home/*/* ]]; then
        is_home_target=1
        sub_path="${trimmed_path#/home/}"
        relative_path="${sub_path#*/}"
        dest_local_path="${HOME}/${relative_path}"
        src_root_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    else
        is_home_target=0
        dest_local_path="${trimmed_path}"
        src_root_path="${DIR_ROOT}${trimmed_path}"
    fi

    # Remove trailing slash for consistent handling
    dest_local_path="${dest_local_path%/}"
    src_root_path="${src_root_path%/}"

    # If home source path is not found under current $USER, search for any user backup folder in DIR_ROOT/home/
    if [ $is_home_target -eq 1 ] && [ ! -e "$src_root_path" ] && [ ! -L "$src_root_path" ]; then
        for alt_user_dir in "${DIR_ROOT}/home/"*; do
            if [ -d "$alt_user_dir" ]; then
                candidate_path="${alt_user_dir}/${relative_path}"
                candidate_path="${candidate_path%/}"
                if [ -e "$candidate_path" ] || [ -L "$candidate_path" ]; then
                    src_root_path="$candidate_path"
                    break
                fi
            fi
        done
    fi

    # Inspect source in root backup
    is_dir=0
    target_type="file"

    if [ -d "$src_root_path" ] || { [ "$DRY_RUN" -eq 0 ] && sudo -n test -d "$src_root_path" 2>/dev/null; }; then
        is_dir=1
        target_type="folder"
    elif [ -e "$src_root_path" ] || [ -L "$src_root_path" ] || { [ "$DRY_RUN" -eq 0 ] && sudo -n test -e "$src_root_path" 2>/dev/null; }; then
        is_dir=0
        target_type="file"
    else
        echo "----------------------------------------------------------"
        echo "[!] No backup copy found in '${DIR_ROOT}': ${src_root_path}. Skipping."
        skipped_items=$((skipped_items + 1))
        continue
    fi

    dest_dir="$(dirname "$dest_local_path")"
    status_suffix="(new)"
    if [ -e "$dest_local_path" ] || [ -L "$dest_local_path" ]; then
        status_suffix="(exists, will overwrite)"
    fi

    echo "----------------------------------------------------------"
    echo "Source [${target_type} in repo] : ${src_root_path}"
    echo "Target [local destination]  : ${dest_local_path} ${status_suffix}"

    do_copy=0

    if [ $CONFIRM_ALL -eq 1 ]; then
        do_copy=1
    else
        ret_code=0
        if UserConfirmYNA "Do you want to restore this ${target_type} to local?"; then
            ret_code=0
        else
            ret_code=$?
        fi

        case $ret_code in
            0)
                do_copy=1
                ;;
            1)
                do_copy=0
                ;;
            2)
                CONFIRM_ALL=1
                do_copy=1
                ;;
            3)
                echo ""
                echo "[!] Restore process cancelled by user."
                break
                ;;
        esac
    fi

    if [ $do_copy -eq 1 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "[DRY-RUN] Would restore: ${src_root_path} -> ${dest_local_path}"
            restored_items=$((restored_items + 1))
            continue
        fi

        # Ensure parent destination directory exists on local system
        if [ ! -d "$dest_dir" ] && ! sudo test -d "$dest_dir" 2>/dev/null; then
            if [ -w "$(dirname "$dest_dir")" 2>/dev/null ]; then
                mkdir -p "$dest_dir"
            else
                sudo mkdir -p "$dest_dir"
            fi
        fi

        restore_success=1

        # Use non-destructive copy/rsync to preserve untracked local user files
        if [ $is_dir -eq 1 ]; then
            if command -v rsync >/dev/null 2>&1; then
                # rsync without --delete so local custom files are preserved
                if [ -w "$dest_dir" ] && { [ ! -e "$dest_local_path" ] || [ -w "$dest_local_path" ]; }; then
                    mkdir -p "$dest_local_path"
                    rsync -a "${src_root_path}/" "${dest_local_path}/" || restore_success=0
                else
                    sudo mkdir -p "$dest_local_path"
                    sudo rsync -a "${src_root_path}/" "${dest_local_path}/" || restore_success=0
                fi
            else
                if [ -w "$dest_dir" ] && { [ ! -e "$dest_local_path" ] || [ -w "$dest_local_path" ]; }; then
                    cp -avT "$src_root_path" "$dest_local_path" || restore_success=0
                else
                    sudo cp -avT "$src_root_path" "$dest_local_path" || restore_success=0
                fi
            fi
        else
            if [ -w "$dest_dir" ] && { [ ! -e "$dest_local_path" ] || [ -w "$dest_local_path" ]; }; then
                cp -avf "$src_root_path" "$dest_local_path" || restore_success=0
            else
                sudo cp -avf "$src_root_path" "$dest_local_path" || restore_success=0
            fi
        fi

        # Apply correct ownership
        if [ $restore_success -eq 1 ]; then
            if [ $is_home_target -eq 1 ]; then
                chown -R "${USER}:${USER}" "$dest_local_path" 2>/dev/null || sudo chown -R "${USER}:${USER}" "$dest_local_path" 2>/dev/null || true
            else
                sudo chown -R root:root "$dest_local_path" 2>/dev/null || true
            fi
            echo "[+] Successfully restored: ${dest_local_path}"
            restored_items=$((restored_items + 1))
        else
            echo "[-] Failed to restore: ${dest_local_path}"
            failed_items=$((failed_items + 1))
        fi
    else
        echo "[*] Action skipped by user."
        skipped_items=$((skipped_items + 1))
    fi
done < "$LIST_PATHS"

echo "=========================================================="
echo " Restore Summary:"
echo "   Total processed : ${total_items}"
echo "   Restored        : ${restored_items}"
echo "   Skipped         : ${skipped_items}"
if [ $failed_items -gt 0 ]; then
    echo "   Failed          : ${failed_items}"
fi
echo "=========================================================="

# PACKAGE INSTALLATION PROMPT #################################
PKG_LIST_FILE="${SCRIPT_DIR}/PackagesManual.txt"
if [ "$SKIP_PACKAGES" -eq 0 ] && [ -f "$PKG_LIST_FILE" ] && command -v xbps-install >/dev/null 2>&1; then
    echo ""
    echo "=========================================================="
    echo " Package Installation Check ($(basename "$PKG_LIST_FILE"))"
    echo "=========================================================="
    install_pkgs=0

    if [ $CONFIRM_ALL -eq 1 ]; then
        install_pkgs=1
    else
        ret_pkg=0
        if UserConfirmYNA "Do you want to install packages from $(basename "$PKG_LIST_FILE")?"; then
            ret_pkg=0
        else
            ret_pkg=$?
        fi

        if [ $ret_pkg -eq 0 ] || [ $ret_pkg -eq 2 ]; then
            install_pkgs=1
        fi
    fi

    if [ $install_pkgs -eq 1 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "[DRY-RUN] Would run: xargs -a \"$PKG_LIST_FILE\" sudo xbps-install -Sy"
        else
            echo "[*] Synchronizing XBPS database and installing packages..."
            xargs -a "$PKG_LIST_FILE" sudo xbps-install -Sy || {
                echo "[-] Warning: Some packages might have encountered errors during installation."
            }
        fi
    else
        echo "[*] Package installation skipped by user."
    fi
fi
