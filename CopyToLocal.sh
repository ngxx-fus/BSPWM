#!/bin/zsh

set -e

# CONFIG ######################################################

LIST_PATHS="./PathLists.txt"
DIR_ROOT="./root"

# Flag to remember "Yes to All" choice
CONFIRM_ALL=0

# FUNC UTILS ##################################################

# IsDirExisted
# Input: 01 path
# Output:
#     0 : existed
#     1 : not existed
#     2 : not a dir
IsDirExisted() {
    local target_path="$1"

    if [ ! -e "$target_path" ]; then
        # Path does not exist
        return 1
    fi

    if [ ! -d "$target_path" ]; then
        # Exists but not a directory
        return 2
    fi

    # Path exists and is a directory
    return 0
}

# IsFileExisted
# Input: 01 path
# Output:
#     0 : existed
#     1 : not existed
#     2 : not a file
IsFileExisted() {
    local target_path="$1"

    if [ ! -e "$target_path" ]; then
        # Path does not exist
        return 1
    fi

    if [ ! -f "$target_path" ]; then
        # Exists but not a regular file
        return 2
    fi

    # Path exists and is a file
    return 0
}

# UserConfirmYNA
# Input: Message to print
# Output:
#     0 : YES (Confirmed)
#     1 : NO  (Declined)
#     2 : ALL (Confirmed for all subsequent actions)
UserConfirmYNA() {
    local prompt_msg="$1"
    local user_choice=""

    while true; do
        read -k 1 "user_choice?${prompt_msg} [y/n/a]: " </dev/tty
        echo ""
        case "$user_choice" in
            [yY])
                # User confirmed this item
                return 0
                ;;
            [nN])
                # User declined this item
                return 1
                ;;
            [aA])
                # User confirmed this and all subsequent items
                return 2
                ;;
            *)
                echo "Invalid input. Please choose 'y', 'n', or 'a'."
                ;;
        esac
    done
}

# CHECK ######################################################

# Check sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "[!] Sudo credential is required to restore files into system paths (e.g., /etc/)."
    sudo -v
fi

# Validate PathLists.txt existence
if ! IsFileExisted "$LIST_PATHS"; then
    echo "[-] Error: File list '${LIST_PATHS}' not found or is not a valid file!"
    exit 1
fi

# Check root backup folder existence
if ! IsDirExisted "$DIR_ROOT"; then
    echo "[-] Error: Source root folder '${DIR_ROOT}' does not exist!"
    exit 1
fi

# FUNC MAIN ###################################################

echo "=========================================================="
echo " Starting Restore Process from '${DIR_ROOT}' to Local"
echo "=========================================================="

while IFS= read -r raw_path || [ -n "$raw_path" ]; do
    # Trim leading/trailing whitespace
    trimmed_path="$(echo "$raw_path" | xargs)"

    # Ignore empty lines or comments
    if [[ -z "$trimmed_path" || "$trimmed_path" == \#* ]]; then
        continue
    fi

    # Expand tilde (~) to full user HOME path for local destination
    dest_local_path="${trimmed_path/#\~/$HOME}"

    # Determine mirror source inside DIR_ROOT
    if [[ "$trimmed_path" == \~/* ]]; then
        relative_path="${trimmed_path#\~/}"
        src_root_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    else
        src_root_path="${DIR_ROOT}${dest_local_path}"
    fi

    # Check existence of source inside DIR_ROOT
    is_dir=0
    target_type="file"

    if [ -d "$src_root_path" ] || sudo test -d "$src_root_path"; then
        is_dir=1
        target_type="folder"
    elif [ ! -e "$src_root_path" ] && ! sudo test -e "$src_root_path"; then
        echo "----------------------------------------------------------"
        echo "[!] No backup copy found in '${DIR_ROOT}': ${src_root_path}. Skipping."
        continue
    fi

    dest_dir="$(dirname "$dest_local_path")"

    echo "----------------------------------------------------------"
    echo "Source [${target_type} in root] : ${src_root_path}"
    echo "Target [local destination]      : ${dest_local_path}"

    do_copy=0

    if [ $CONFIRM_ALL -eq 1 ]; then
        do_copy=1
    else
        # Prompt user with [y/n/a]
        UserConfirmYNA "Do you want to restore this ${target_type} to local?" || ret_code=$?
        ret_code=${ret_code:-0}

        if [ $ret_code -eq 0 ]; then
            do_copy=1
        elif [ $ret_code -eq 2 ]; then
            CONFIRM_ALL=1
            do_copy=1
        else
            do_copy=0
        fi
    fi

    if [ $do_copy -eq 1 ]; then
        # Ensure parent destination directory exists on local
        if [ ! -d "$dest_dir" ] && ! sudo test -d "$dest_dir"; then
            if [ -w "$(dirname "$dest_dir")" ]; then
                mkdir -p "$dest_dir"
            else
                sudo mkdir -p "$dest_dir"
            fi
        fi

        # Choose copy flags (-a preserves mode, ownership/symlinks and copies recursively)
        if [ $is_dir -eq 1 ]; then
            CP_CMD=(cp -avT)
        else
            CP_CMD=(cp -avf)
        fi

        # Copy back to local path (use sudo if target is a root-owned system path)
        if [ -w "$dest_dir" ] && { [ ! -e "$dest_local_path" ] || [ -w "$dest_local_path" ]; }; then
            "${CP_CMD[@]}" "$src_root_path" "$dest_local_path"
        else
            sudo "${CP_CMD[@]}" "$src_root_path" "$dest_local_path"
        fi
        echo "[+] Successfully restored: ${dest_local_path}"
    else
        echo "[*] Action skipped by user."
    fi
done < "$LIST_PATHS"

echo "=========================================================="
echo " All tasks finished."
echo "=========================================================="