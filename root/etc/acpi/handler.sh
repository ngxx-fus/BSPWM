#!/bin/sh

# @file handler.sh
# @brief ACPI event handler with notify-send integration.
# @details Captures WMI events and sends desktop notifications to user 'fus'.

###################################################################################################
# Configs & Utils
###################################################################################################
TARGET_USER="fus"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || echo 1000)

# @brief Dynamically extracts the DBUS_SESSION_BUS_ADDRESS from the active GUI session.
get_dbus_address() {
    local target_pid
    # Extract the PID of the window manager (bspwm) to read its environment.#
    target_pid=$(pgrep -u "$TARGET_UID" -x bspwm | head -n 1)
    
    # Fallback to dunst if bspwm is not found.#
    if [ -z "$target_pid" ]; then
        target_pid=$(pgrep -u "$TARGET_UID" -x dunst | head -n 1)
    fi

    # Validate if a GUI process was successfully found.#
    if [ -n "$target_pid" ]; then
        cat "/proc/$target_pid/environ" 2>/dev/null | tr '\0' '\n' | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-
    fi
}

# @brief Sends a desktop notification to the specified user.
# @param ... Variable number of arguments passed directly to notify-send.
send_notification() {
    # Verify if TARGET_UID is populated.#
    if [ -z "$TARGET_UID" ]; then
        # Abort execution due to missing user ID.#
        return 1
    fi

    local dbus_addr
    # Fetch dynamic DBus address.#
    dbus_addr=$(get_dbus_address)

    # Validate if the DBus address extraction was successful.#
    if [ -z "$dbus_addr" ]; then
        # Abort execution because the DBus session address could not be resolved.#
        return 1
    fi

    sudo -u "$TARGET_USER" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
        notify-send "$@"
}

#  * @brief Sends a desktop notification to the specified user (for debug).
#  * @param ... Variable number of arguments passed directly to notify-send.
send_debug_notification() {
    send_notification "ACPI Event (Debug)" "Args: \$1=\"$1\" / \$2=\"$2\" / \$3=\"$3\" / \$4=\"$4\" \$5=\"$5\" \$6=\"$6\""
}

###################################################################################################
# BAT event group
###################################################################################################

EventGroup_Battery() {
    # Args:
    #   $1 <---- handler.sh/$2
    #   $2 <---- handler.sh/$3
    case "$1" in
        PNP0C0A:00)
            case "$2" in
                00000080) # Update every capacity of battery changed
                    # Ignore for now
                    # send_notification "Battery" "State changed to 00000080."
                    ;;
                00000081) # Upadte every AC status changed
                    # Ignore for now
                    # send_notification "Battery" "State changed to 00000081."
                    ;;
                *)
                    ;;
            esac
            ;;
        *)
            ;;
    esac
}

###################################################################################################
# WMI event group
###################################################################################################

EventGroup_WMI() {
    # Args:
    #   $1 <---- handler.sh/$2
    #   $2 <---- handler.sh/$3
    case "$1" in
        PNP0C14:02)
            # Branch based on the specific WMI action code.
            case "$2" in
                000000ff)
                    local dbus_addr
                    # Fetch dynamic DBus address for the external script.#
                    dbus_addr=$(get_dbus_address)

                    sudo -u "$TARGET_USER" \
                        DISPLAY=:0 \
                        DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
                        /home/fus/.config/bspwm/scripts/Helper-ChangeKeyboardBrightness
                    
                    # Exit the 000000ff action case.
                    ;;
                *)
                    # Exit the unknown WMI action case.
                    ;;
            esac
            
            # Exit the PNP0C14:02 device case.
            ;;
        *)
            # Exit the unknown WMI device case.
            ;;
    esac
}

###################################################################################################
# Branch based on the main ACPI event group
###################################################################################################

# send_debug_notification "$1" "$2" "$3" "$4" "$5" "$6"

case "$1" in
    wmi)
        EventGroup_WMI "$2" "$3" "$4"
        ;;
    battery)
        # send_debug_notification "$1" "$2" "$3" "$4" "$5" "$6"
        EventGroup_Battery "$2" "$3" "$4"
        ;;
    *)
        # send_debug_notification "$1" "$2" "$3" "$4" "$5" "$6"
        # logger "ACPI Event/action undefined: $1 / $2"
        ;;
esac
