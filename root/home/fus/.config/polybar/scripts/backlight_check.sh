#!/bin/sh

# Set 1 to show icon, 0 to display percentage only
SHOW_ICON_EN=0

# Check display connector status via sysfs DRM interfaces
BUILTIN_CONNECTED=0
# Iterate over candidate eDP and LVDS DRM status files
for status_file in /sys/class/drm/card*-eDP-*/status /sys/class/drm/card*-LVDS-*/status; do
    # Verify if interface status is connected
    if [ -f "$status_file" ] && [ "$(cat "$status_file" 2>/dev/null)" = "connected" ]; then
        BUILTIN_CONNECTED=1
        # Stop checking once a connected display is found
        break
    fi
done

# Exit silently if built-in display is disconnected or absent
if [ "$BUILTIN_CONNECTED" -eq 0 ]; then
    # Invalidate output and ignore action
    exit 0
fi

# Locate backlight device
CARD=$(ls -1 /sys/class/backlight/ 2>/dev/null | head -n 1)

# Verify existence of valid backlight interface
if [ -z "$CARD" ] || [ ! -f "/sys/class/backlight/$CARD/brightness" ]; then
    # Return empty to hide Polybar module
    exit 0
fi

# Handle scroll actions when built-in display is present
case "$1" in
    up)
        # Increase brightness by 5 percent
        brightnessctl -d "$CARD" set +5% >/dev/null 2>&1
        # Action completed
        exit 0
        ;;
    down)
        # Decrease brightness by 5 percent
        brightnessctl -d "$CARD" set 5%- >/dev/null 2>&1
        # Action completed
        exit 0
        ;;
esac

ACTUAL=$(cat "/sys/class/backlight/$CARD/brightness" 2>/dev/null)
MAX=$(cat "/sys/class/backlight/$CARD/max_brightness" 2>/dev/null)

# Verify valid brightness data before calculation
if [ -n "$ACTUAL" ] && [ -n "$MAX" ] && [ "$MAX" -gt 0 ] 2>/dev/null; then
    PERCENT=$(( ACTUAL * 100 / MAX ))

    # Evaluate whether icon rendering is enabled
    if [ "$SHOW_ICON_EN" -eq 1 ]; then
        # Map brightness percentage to corresponding ramp icon
        if [ "$PERCENT" -ge 80 ]; then
            ICON="󰃠"
        elif [ "$PERCENT" -ge 50 ]; then
            ICON="󰃟"
        elif [ "$PERCENT" -ge 20 ]; then
            ICON="󰃝"
        else
            ICON="󰃞"
        fi

        # Print icon with percentage output
        echo "%{F#24a8b4}$ICON%{F-} $PERCENT%"
    else
        # Print percentage output only
        echo "$PERCENT%"
    fi
else
    # Exit silently on read error to hide Polybar module
    exit 0
fi