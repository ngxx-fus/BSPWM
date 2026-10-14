#!/usr/bin/env zsh

# /*
#  * @file polybar_bluetooth.sh
#  * @brief Bluetooth status and battery monitor for Polybar.
#  */

# Limit the display name of the connected devices (set 0 to disable truncation)
DEVICE_NAME_DISP_LIMIT=6

# Set 0 to disable connected device battery info
CONF_BATTERY_INFO_EN=1

# Check if Bluetooth adapter is powered on.
if [ "$(bluetoothctl show 2>/dev/null | grep -i "Powered: yes")" = "" ]; then
    echo "%{F#4e5b55}󰂲 OFF%{F-}"
    
    # /*
    #  * Exit execution if Bluetooth is off.
    #  */
    exit 0
fi

# Retrieve MAC address of the connected device.
DEVICE_MAC=$(bluetoothctl devices Connected 2>/dev/null | head -n 1 | cut -d ' ' -f 2)

# Check if any device is currently connected.
if [ -z "$DEVICE_MAC" ]; then
    echo "%{F#50a5f5}󰂯%{F-} ON"
    
    # /*
    #  * Exit execution if no device is connected.
    #  */
    exit 0
fi

# Retrieve the device alias.
DEVICE_NAME=$(bluetoothctl info "$DEVICE_MAC" 2>/dev/null | grep "Alias:" | cut -d ' ' -f 2-)

# Fallback to device name if alias is empty.
if [ -z "$DEVICE_NAME" ]; then
    DEVICE_NAME=$(bluetoothctl info "$DEVICE_MAC" 2>/dev/null | grep "Name:" | cut -d ' ' -f 2-)
fi

# /*
#  * Truncate the device name if it exceeds the configured limit.
#  */
if [ "$DEVICE_NAME_DISP_LIMIT" -gt 0 ] && [ "${#DEVICE_NAME}" -gt "$DEVICE_NAME_DISP_LIMIT" ]; then
    DEVICE_NAME="${DEVICE_NAME:0:$DEVICE_NAME_DISP_LIMIT}.."
fi

BATTERY_LEVEL=""

# /*
#  * Check if battery monitoring is enabled before querying.
#  */
if [ "$CONF_BATTERY_INFO_EN" -eq 1 ]; then
    # Retrieve battery percentage via bluetoothctl.
    BATTERY_LEVEL=$(bluetoothctl info "$DEVICE_MAC" 2>/dev/null | grep "Battery Percentage" | awk -F'[()]' '{print $2}')

    # Fallback to upower if bluetoothctl does not report battery level.
    if [ -z "$BATTERY_LEVEL" ]; then
        BATTERY_LEVEL=$(upower -e 2>/dev/null | grep -i "dev_${DEVICE_MAC//:/_}" | xargs -I {} upower -i {} 2>/dev/null | grep "percentage:" | awk '{print $2}')
    fi
fi

# Format and output the final string for Polybar.
if [ -n "$BATTERY_LEVEL" ]; then
    echo "%{F#52bdff}󰂱%{F-} $DEVICE_NAME %{F#ebf831}($BATTERY_LEVEL)%{F-}"
else
    echo "%{F#52bdff}󰂱%{F-} $DEVICE_NAME"
fi