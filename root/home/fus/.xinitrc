#!/bin/sh
# ==============================================================================
# ~/.xinitrc
# Void Linux X11 session initialization for BSPWM
# ==============================================================================

# Ensure XDG_RUNTIME_DIR exists with correct permissions on runit systems
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        mkdir -p "$XDG_RUNTIME_DIR"
        chmod 0700 "$XDG_RUNTIME_DIR"
    fi
fi

# Merge Xresources and keymaps if present
[ -f "$HOME/.Xresources" ] && /usr/bin/xrdb -merge "$HOME/.Xresources"
[ -f "$HOME/.Xmodmap" ] && /usr/bin/xmodmap "$HOME/.Xmodmap"

# Source system Xinit scripts if present
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Set default cursor shape so X11 does not show legacy 'X' cursor
xsetroot -cursor_name left_ptr &

# Input method and UI theming environment variables
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORMTHEME=qt5ct

# Launch BSPWM inside a DBus session if not already active
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] && command -v dbus-run-session >/dev/null 2>&1; then
    exec /usr/bin/dbus-run-session bspwm
else
    exec /usr/bin/xsetroot
fi