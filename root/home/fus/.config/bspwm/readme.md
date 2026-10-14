# 🚀 BSPWM Dotfiles Configuration

A sleek, high-performance **bspwm** (Binary Space Partitioning Window Manager) desktop configuration for Linux, featuring flexible multi-monitor support, custom utilities, and ergonomic keybindings.

---

## 📂 Directory Structure

```text
~/.config/bspwm/
├── bspwmrc                      # Main startup script and window management rules
├── readme.md                    # Documentation and reference guide
├── .gitignore                   # Git ignore rules for temporary/cache files
│
├── dunst/                       # System notification daemon configuration
│   └── dunstrc
│
├── obmenu/                      # Menu generator schema (migrated from Openbox)
│   └── schema.pl
│
├── picom/                       # Compositor configuration (transparency, shadows, blur)
│   └── picom.conf
│
├── polybar/                     # Status bar configuration
│   ├── config.ini               # Bar modules and layout configuration
│   ├── colors.ini               # Color palette for Polybar
│   └── ibus-toggle.sh           # Input method toggle script
│
├── rofi/                        # Application launcher, power menu, and popup themes
│   ├── config.rasi              # Main Rofi configuration (App Finder / Universe)
│   ├── colors.rasi              # Theme color definitions
│   ├── combi.rasi               # Combi mode theme
│   ├── controlpanel.rasi        # Control Panel theme
│   ├── keybinds.rasi            # Keybindings cheat sheet theme
│   ├── popup.rasi               # Shared popup menu theme
│   └── power.rasi               # Power Menu theme
│
├── scripts/                     # Automation & system utility scripts
│   ├── Helper-ChangeBrightness  # Display brightness control with Dunst OSD
│   ├── Helper-ChangeKeyboardBrightness # Keyboard backlight control with Dunst OSD
│   ├── Helper-ChangeVolume      # Volume up/down/mute control with Dunst OSD
│   ├── Helper-DisplaySwitching  # Multi-monitor profile switcher (PC only, Duplicate, Extend, Second only)
│   ├── Helper-Help              # Display system keybindings cheat sheet
│   ├── Helper-Power             # Quick Menu / Power Menu (Shutdown, Reboot, Lock, etc.)
│   ├── Helper-ToggleTouchpad    # Enable / disable touchpad
│   ├── Service-Background       # Set random or designated desktop wallpaper
│   ├── Service-Polybar          # Polybar launch service script
│   ├── data/display_config      # Persistent display configuration file
│   └── archived/                # Archived / legacy scripts
│
├── skippy-xd/                   # Visual window switcher (Exposé) configuration
│   └── skippy-xd.rc
│
├── sxhkd/                       # Simple X Hotkey Daemon configuration
│   └── sxhkdrc
│
└── wallpaper/                   # High-resolution wallpapers (Ultrawide 3440x1440 & FHD)
```

---

## ⚡ Keybindings

Primary modifier key: `Super` (Windows key).

### 🖥️ Applications & Utilities
| Shortcut | Action |
| :--- | :--- |
| `Super + Enter` / `Super + r` | Launch Terminal (`gnome-terminal`) |
| `Alt + Space` | Open Rofi Application Launcher (Universe) |
| `Super + e` | Launch File Manager (`thunar`) |
| `Super + v` | Toggle Clipboard Manager (`copyq`) |
| `Super + l` | Lock Screen (`betterlockscreen`) |
| `Super + Tab` | Visual Window Switcher (`skippy-xd`) |
| `Alt + Tab` / `Alt + Shift + Tab` | Cycle through windows forward / backward |
| `Super + Space` | Toggle input method (`fcitx5`) |
| `Super + p` | Open Display Profile Switcher |
| `Super + x` | Open Quick / Power Menu (Shutdown, Reboot, Suspend, Lock, etc.) |
| `Super + /` | Show Keybindings Help Menu |
| `Super + Esc` | Reload `sxhkd` configuration |

### 🪟 Window Management
| Shortcut | Action |
| :--- | :--- |
| `Super + q` / `Super + w` | Close focused window |
| `Super + Shift + w` | Force kill focused window |
| `Super + f` | Toggle Fullscreen mode |
| `Super + s` | Toggle between Tiled and Floating states |
| `Super + m` | Alternate between Tiled and Monocle layouts |
| `Super + {Left, Down, Up, Right}` | Focus window directionally (Arrow keys) |
| `Super + {h, j, k, l}` | Focus window directionally (Vim keys) |
| `Super + Shift + {Arrows / hjkl}` | Swap focused window with directional neighbor |
| `Super + Ctrl + {Left, Down, Up, Right}` | Move floating window by coordinates |
| `Super + Alt + {h, j, k, l}` | Expand window size |
| `Super + Alt + Shift + {h, j, k, l}` | Contract window size |

### 🧭 Workspaces & Multi-Monitor
| Shortcut | Action |
| :--- | :--- |
| `Super + [1-9]` | Switch to Workspace 1–9 on the focused monitor |
| `Super + Shift + [1-9]` | Move active window to Workspace 1–9 |
| `Ctrl + Alt + Left / Right` | Switch to previous / next local desktop |
| `Super + comma` / `Super + period` | Focus previous / next monitor |
| `Super + Ctrl + Shift + {Arrows}` | Send focused window to directional monitor |

### 🔊 Media & Hardware Keys
| Shortcut | Action |
| :--- | :--- |
| `XF86AudioRaiseVolume` / `Super + F12` | Increase volume |
| `XF86AudioLowerVolume` / `Super + F11` | Decrease volume |
| `XF86AudioMute` / `Super + F10` | Mute / unmute audio |
| `XF86AudioMicMute` / `XF86Launch5` | Mute / unmute microphone |
| `XF86MonBrightnessUp / Down` | Increase / decrease screen brightness |
| `XF86KbdBrightnessUp / Down` | Increase / decrease keyboard backlight |
| `XF86TouchpadToggle` | Toggle touchpad |
| `Print` | Capture fullscreen screenshot (`flameshot full`) |
| `Super + Shift + s` | Interactive screenshot selection (`flameshot gui`) |

---

## 🛠️ Dependencies

Make sure the following packages are installed for full functionality:

- **Window Manager & Hotkeys**: `bspwm`, `sxhkd`
- **Status Bar & Menus**: `polybar`, `rofi`
- **Compositor**: `picom`
- **Notifications & Screen Locking**: `dunst`, `libnotify`, `betterlockscreen`, `xidlehook`
- **Wallpaper & Theming**: `feh`, `pywal` (optional for `wallpaper-theme`)
- **Utilities & Daemons**: `copyq`, `skippy-xd`, `flameshot`, `thunar`, `fcitx5`, `brightnessctl`, `pamixer` / `pulseaudio-utils` / `pactl`, `power-profiles-daemon`

---

## 🚀 Usage & Reloading

1. **Restart bspwm**:
   ```bash
   bspc wm -r
   # or press: Super + Alt + r
   ```

2. **Reload sxhkd keybindings**:
   ```bash
   pkill -USR1 -x sxhkd
   # or press: Super + Escape
   ```
