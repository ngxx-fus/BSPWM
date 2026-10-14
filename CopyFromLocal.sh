#!/usr/bin/env bash

# ==============================================================================
# CopyFromLocal.sh
# Backup configured dotfiles and system files into the repository root folder.
# ==============================================================================

set -eo pipefail

# SCRIPT DIRECTORY & CONFIG ####################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LIST_PATHS="${SCRIPT_DIR}/PathLists.txt"
DIR_ROOT="${SCRIPT_DIR}/root"

CONFIRM_ALL=0
DRY_RUN=0

# CLI OPTIONS #################################################
PrintUsage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Backup dotfiles and system configurations defined in 'PathLists.txt' into '${DIR_ROOT}'.

Options:
  -y, --yes, -a, --all    Confirm all copy operations automatically (non-interactive)
  -n, --dry-run           Preview actions without copying or writing any files
  -h, --help              Display this help message and exit

Interactive Choices:
  [y] Yes  - Copy this item
  [n] No   - Skip this item
  [a] All  - Copy this and all subsequent items
  [q] Quit - Cancel and exit the backup script
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

# Clean unwanted runtime/lock artifacts from backed-up folder
PruneUnwantedArtifacts() {
    local target_dir="$1"
    if [ -d "$target_dir" ] && [ "$DRY_RUN" -eq 0 ]; then
        find "$target_dir" -type f \( \
            -name "*.lock" -o \
            -name ".*.lock" -o \
            -name "copyq_tab_*.dat" -o \
            -name "copyq_geometry.ini*" \
        \) -delete 2>/dev/null || true
    fi
}

# PRE-FLIGHT CHECKS ###########################################

if [ ! -f "$LIST_PATHS" ]; then
    echo "[-] Error: Manifest list '${LIST_PATHS}' not found or is not a valid file!"
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
        echo "[!] Sudo credential is required to access system paths (e.g., /etc/, /usr/)."
        sudo -v
    fi
fi

if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$DIR_ROOT"
fi

# MAIN PROCESS ################################################

echo "=========================================================="
if [ "$DRY_RUN" -eq 1 ]; then
    echo " Starting Backup Preview (DRY-RUN) into: ${DIR_ROOT}"
else
    echo " Starting Backup Process into: ${DIR_ROOT}"
fi
echo "=========================================================="

total_items=0
copied_items=0
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

    # Determine local source path and repository destination path
    if [[ "$trimmed_path" == \~/* ]]; then
        relative_path="${trimmed_path#\~/}"
        src_local_path="${HOME}/${relative_path}"
        dest_repo_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    elif [[ "$trimmed_path" == /home/*/* ]]; then
        sub_path="${trimmed_path#/home/}"
        relative_path="${sub_path#*/}"
        src_local_path="${HOME}/${relative_path}"
        dest_repo_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    else
        src_local_path="${trimmed_path}"
        dest_repo_path="${DIR_ROOT}${trimmed_path}"
    fi

    # Remove trailing slash for consistent handling
    src_local_path="${src_local_path%/}"
    dest_repo_path="${dest_repo_path%/}"
    dest_dir="$(dirname "$dest_repo_path")"

    # Inspect source existence and type
    is_dir=0
    target_type="file"

    if [ -d "$src_local_path" ] || sudo test -d "$src_local_path" 2>/dev/null; then
        is_dir=1
        target_type="folder"
    elif [ -e "$src_local_path" ] || [ -L "$src_local_path" ] || sudo test -e "$src_local_path" 2>/dev/null || sudo test -L "$src_local_path" 2>/dev/null; then
        is_dir=0
        target_type="file"
    else
        echo "----------------------------------------------------------"
        echo "[!] Source does not exist: ${src_local_path}. Skipping."
        skipped_items=$((skipped_items + 1))
        continue
    fi

    echo "----------------------------------------------------------"
    echo "Source [${target_type}] : ${src_local_path}"
    echo "Target [${target_type}] : ${dest_repo_path}"

    do_copy=0

    if [ $CONFIRM_ALL -eq 1 ]; then
        do_copy=1
    else
        ret_code=0
        if UserConfirmYNA "Do you want to copy this ${target_type}?"; then
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
                echo "[!] Backup process cancelled by user."
                break
                ;;
        esac
    fi

    if [ $do_copy -eq 1 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "[DRY-RUN] Would backup: ${src_local_path} -> ${dest_repo_path}"
            copied_items=$((copied_items + 1))
            continue
        fi

        # Ensure destination parent directory exists
        if [ ! -d "$dest_dir" ]; then
            mkdir -p "$dest_dir"
        fi

        copy_success=1
        if [ $is_dir -eq 1 ]; then
            mkdir -p "$dest_repo_path"
            if command -v rsync >/dev/null 2>&1; then
                RSYNC_EXCLUDES=(
                    --exclude="*.lock"
                    --exclude=".*.lock"
                    --exclude="copyq_tab_*.dat"
                    --exclude="copyq_geometry.ini*"
                    --exclude="*.tmp"
                    --exclude="*.log"
                )
                if [ -r "$src_local_path" ]; then
                    rsync -a --delete "${RSYNC_EXCLUDES[@]}" "${src_local_path}/" "${dest_repo_path}/" || copy_success=0
                else
                    sudo rsync -a --delete "${RSYNC_EXCLUDES[@]}" "${src_local_path}/" "${dest_repo_path}/" || copy_success=0
                    sudo chown -R "${USER}:${USER}" "$dest_repo_path" 2>/dev/null || true
                fi
            else
                if [ -r "$src_local_path" ]; then
                    cp -avT "$src_local_path" "$dest_repo_path" || copy_success=0
                else
                    sudo cp -avT "$src_local_path" "$dest_repo_path" || copy_success=0
                    sudo chown -R "${USER}:${USER}" "$dest_repo_path" 2>/dev/null || true
                fi
                PruneUnwantedArtifacts "$dest_repo_path"
            fi
        else
            if [ -r "$src_local_path" ]; then
                cp -avf "$src_local_path" "$dest_repo_path" || copy_success=0
            else
                sudo cp -avf "$src_local_path" "$dest_repo_path" || copy_success=0
                sudo chown -R "${USER}:${USER}" "$dest_repo_path" 2>/dev/null || true
            fi
        fi

        if [ $copy_success -eq 1 ]; then
            echo "[+] Successfully copied: ${src_local_path}"
            copied_items=$((copied_items + 1))
        else
            echo "[-] Failed to copy: ${src_local_path}"
            failed_items=$((failed_items + 1))
        fi
    else
        echo "[*] Action skipped by user."
        skipped_items=$((skipped_items + 1))
    fi
done < "$LIST_PATHS"

# Guarantee all backup files in DIR_ROOT remain user-owned for Git management
if [ "$DRY_RUN" -eq 0 ] && [ -d "$DIR_ROOT" ]; then
    sudo chown -R "${USER}:${USER}" "$DIR_ROOT" 2>/dev/null || chown -R "${USER}:${USER}" "$DIR_ROOT" 2>/dev/null || true
fi

echo "=========================================================="
echo " Backup Summary:"
echo "   Total processed : ${total_items}"
echo "   Copied          : ${copied_items}"
echo "   Skipped         : ${skipped_items}"
if [ $failed_items -gt 0 ]; then
    echo "   Failed          : ${failed_items}"
fi
echo "=========================================================="