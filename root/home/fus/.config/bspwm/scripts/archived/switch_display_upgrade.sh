#!/usr/bin/env zsh

###################################################################################################
# CONFIG
###################################################################################################

# Set where to save the project mode index (0-indexed for rofi)
PROJECT_MODE="/home/fus/.config/bspwm/.tmp/projectmode"
TIMEOUT_SEC=15

# Manual monitor assignments and resolution config
# MON0 is always treated as the primary display
MON0_OUT="eDP-1"
MON0_W=1920
MON0_H=1200

# Secondary monitor config (leave MON1_OUT="" if not used)
MON1_OUT="HDMI-1"
MON1_W=1920
MON1_H=1080

# Tertiary monitor config (leave MON2_OUT="" if not used)
MON2_OUT=""
MON2_W=1920
MON2_H=1080

# Menu options matching Windows + P
OPTIONS_ARR=(
    "1. PC screen only"
    "2. Duplicate"
    "3. Extend 0"
    "4. Extend 1"
    "5. Second screen only"
)
OPTIONS=$(printf "%s\n" "${OPTIONS_ARR[@]}")

# Read previously selected index, defaulting to 0
CURRENT_INDEX=0
if [ -f "$PROJECT_MODE" ]; then
    CURRENT_INDEX=$(cat "$PROJECT_MODE")
fi

# Calculate next index in cycle (0 -> 1 -> 2 -> 3 -> 4 -> 0)
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % 5 ))

# Extend position
#   Desc:
#
#       .pos(row=0, col=0)
#       ################ W0 ####################
#       ########################################
#       H0 #####################################
#       ########################################
#       ########################################
#                                               .pos(row=H0, col=W0)
#                                               ################ W1 ####################
#                                               ########################################
#                                               H1 #####################################
#                                               ########################################
#                                               ########################################
#                                                                                       .pos(row=H0+H1,col=W0+W1)
#
#   3 Monitors Extension Desc:
#
#   [Profile 0: Horizontal chain (MON0 | MON1 | MON2)]
#   .pos(0,0)               .pos(0, W0)             .pos(0, W0+W1)
#   +----------+            +----------+            +----------+
#   |   MON0   |            |   MON1   |            |   MON2   |
#   | (Primary)|            |          |            |          |
#   +----------+            +----------+            +----------+
#
#   [Profile 1: Stacked / Mixed arrangement (MON1 below MON0, MON2 to the right)]
#   .pos(0,0)                                       .pos(0, W0)
#   +----------+                                    +----------+
#   |   MON0   |                                    |   MON2   |
#   | (Primary)|                                    |          |
#   +----------+                                    +----------+
#   .pos(H0,0)
#   +----------+
#   |   MON1   |
#   |          |
#   +----------+

# Call back to handle the extend mode
extend_apply() {
    # profile select
    MONITOR_PROFILE=$1

    # profile 0: (default) MON0 | MON1 | MON2
    MONITOR_0_POX_ROW=0
    MONITOR_0_POX_COL=$(( MON1_W ))

    MONITOR_1_POX_ROW=0
    MONITOR_1_POX_COL=0

    MONITOR_2_POX_ROW=0
    MONITOR_2_POX_COL=$(( MON0_W + MON1_W ))

    case $MONITOR_PROFILE in
        1)
            # Mixed layout: MON1 below MON0, MON2 placed to the right
            MONITOR_0_POX_ROW=0
            MONITOR_0_POX_COL=$(( MON1_W ))

            MONITOR_1_POX_ROW=0
            MONITOR_1_POX_COL=0
            
            MONITOR_2_POX_ROW=$MON1_H
            MONITOR_2_POX_COL=0
            ;;
        *)
            : # NOP
            ;;
    esac

    # Initialize xrandr execution command with MON0 as primary
    XRANDR_CMD="xrandr --output $MON0_OUT --mode ${MON0_W}x${MON0_H} --pos ${MONITOR_0_POX_COL}x${MONITOR_0_POX_ROW} --primary"

    # Append MON1 if defined
    if [ -n "$MON1_OUT" ]; then
        XRANDR_CMD="$XRANDR_CMD --output $MON1_OUT --mode ${MON1_W}x${MON1_H} --pos ${MONITOR_1_POX_COL}x${MONITOR_1_POX_ROW}"
    fi

    # Append MON2 if defined
    if [ -n "$MON2_OUT" ]; then
        XRANDR_CMD="$XRANDR_CMD --output $MON2_OUT --mode ${MON2_W}x${MON2_H} --pos ${MONITOR_2_POX_COL}x${MONITOR_2_POX_ROW}"
    fi

    # Execute constructed xrandr configuration
    eval "$XRANDR_CMD"
}

###################################################################################################
# ACTION
###################################################################################################

# Fallback check if no secondary monitor is configured
if [ -z "$MON1_OUT" ] && [ -z "$MON2_OUT" ]; then
    xrandr --output "$MON0_OUT" --mode "${MON0_W}x${MON0_H}" --pos 0x0 --primary
    exit 0
fi

# Prompt via rofi with timeout
CHOICE=$(echo -e "$OPTIONS" | timeout "$TIMEOUT_SEC" rofi -dmenu -i -selected-row "$NEXT_INDEX" -p "Project (${TIMEOUT_SEC}s)" -theme /home/fus/.config/bspwm/rofi/popup.rasi)
EXIT_CODE=$?

# If timed out (exit code 124), auto-select the highlighted mode
if [ "$EXIT_CODE" -eq 124 ]; then
    CHOICE="${OPTIONS_ARR[$(( NEXT_INDEX + 1 ))]}"
# If cancelled by user pressing Esc (exit code 1), abort cleanly
elif [ "$EXIT_CODE" -ne 0 ] || [ -z "$CHOICE" ]; then
    exit 0
fi

case "$CHOICE" in
    "1. PC screen only")
        XRANDR_CMD="xrandr --output $MON0_OUT --mode ${MON0_W}x${MON0_H} --pos 0x0 --primary"
        [ -n "$MON1_OUT" ] && XRANDR_CMD="$XRANDR_CMD --output $MON1_OUT --off"
        [ -n "$MON2_OUT" ] && XRANDR_CMD="$XRANDR_CMD --output $MON2_OUT --off"
        eval "$XRANDR_CMD"
        echo 0 > "$PROJECT_MODE"
        ;;
    "2. Duplicate")
        XRANDR_CMD="xrandr --output $MON0_OUT --auto --primary"
        [ -n "$MON1_OUT" ] && XRANDR_CMD="$XRANDR_CMD --output $MON1_OUT --auto --same-as $MON0_OUT"
        [ -n "$MON2_OUT" ] && XRANDR_CMD="$XRANDR_CMD --output $MON2_OUT --auto --same-as $MON0_OUT"
        eval "$XRANDR_CMD"
        echo 1 > "$PROJECT_MODE"
        ;;
    "3. Extend 0")
        extend_apply 0 # profile: 0
        echo 2 > "$PROJECT_MODE"
        ;;
    "4. Extend 1")
        extend_apply 1 # profile: 1
        echo 3 > "$PROJECT_MODE"
        ;;
    "5. Second screen only")
        # Target MON1 as standalone display if defined, else fallback to MON2
        STANDALONE_EXT="${MON1_OUT:-$MON2_OUT}"
        XRANDR_CMD="xrandr --output $MON0_OUT --off --output $STANDALONE_EXT --auto --primary"
        [ -n "$MON2_OUT" ] && [ "$STANDALONE_EXT" != "$MON2_OUT" ] && XRANDR_CMD="$XRANDR_CMD --output $MON2_OUT --off"
        eval "$XRANDR_CMD"
        echo 4 > "$PROJECT_MODE"
        ;;
esac

# Wait for X server to finalize display modes
sleep 1

# Restart polybar to match the updated display state
/usr/bin/notify-send "Display" "Restart polybar..."
/usr/bin/bspc wm -r
# /home/fus/.config/bspwm/polybar/polybar-ob >/dev/null 2>&1 &
# /usr/bin/notify-send "Display" "Restart background..."
# /home/fus/.config/bspwm/scripts/background.sh >/dev/null 2>&1 &
