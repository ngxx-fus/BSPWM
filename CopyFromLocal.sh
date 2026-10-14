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
    echo "[!] Sudo credential is required to access system paths (e.g., /etc/)."
    sudo -v
fi

# Validate PathLists.txt existence
if ! IsFileExisted "$LIST_PATHS"; then
    echo "[-] Error: File list '${LIST_PATHS}' not found or is not a valid file!"
    exit 1
fi

# Ensure backup destination root exists
mkdir -p "$DIR_ROOT"

# FUNC MAIN ###################################################

echo "=========================================================="
echo " Starting Copy Process into: ${DIR_ROOT}"
echo "=========================================================="

while IFS= read -r raw_path || [ -n "$raw_path" ]; do
    # Trim leading/trailing whitespace
    trimmed_path="$(echo "$raw_path" | xargs)"

    # Ignore empty lines or comments
    if [[ -z "$trimmed_path" || "$trimmed_path" == \#* ]]; then
        continue
    fi

    # Expand tilde (~) to full user HOME path
    expanded_path="${trimmed_path/#\~/$HOME}"

    # Determine mirror destination inside DIR_ROOT
    if [[ "$trimmed_path" == \~/* ]]; then
        relative_path="${trimmed_path#\~/}"
        dest_path="${DIR_ROOT}/home/${USER}/${relative_path}"
    else
        dest_path="${DIR_ROOT}${expanded_path}"
    fi

    dest_dir="$(dirname "$dest_path")"

    # Check existence via user or sudo
    is_dir=0
    target_type="file"

    if [ -d "$expanded_path" ] || sudo test -d "$expanded_path"; then
        is_dir=1
        target_type="folder"
    elif [ ! -e "$expanded_path" ] && ! sudo test -e "$expanded_path"; then
        echo "----------------------------------------------------------"
        echo "[!] Source does not exist: ${expanded_path}. Skipping."
        continue
    fi

    echo "----------------------------------------------------------"
    echo "Source [${target_type}] : ${expanded_path}"
    echo "Target [${target_type}] : ${dest_path}"

    do_copy=0

    if [ $CONFIRM_ALL -eq 1 ]; then
        do_copy=1
    else
        # Prompt user with [y/n/a]
        UserConfirmYNA "Do you want to copy this ${target_type}?" || ret_code=$?
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
        # Ensure parent destination directory exists
        if [ ! -d "$dest_dir" ]; then
            mkdir -p "$dest_dir"
        fi

        # Choose copy flags (-a preserves mode, ownership/symlinks and copies recursively)
        if [ $is_dir -eq 1 ]; then
            CP_CMD=(cp -avT)
        else
            CP_CMD=(cp -avf)
        fi

        # Use sudo if path cannot be read by current user
        if [ -r "$expanded_path" ]; then
            "${CP_CMD[@]}" "$expanded_path" "$dest_path"
        else
            sudo "${CP_CMD[@]}" "$expanded_path" "$dest_path"
            sudo chown -R "${USER}:${USER}" "$dest_path"
        fi
        echo "[+] Successfully copied: ${expanded_path}"
    else
        echo "[*] Action skipped by user."
    fi
done < "$LIST_PATHS"

echo "=========================================================="
echo " All tasks finished."
echo "=========================================================="