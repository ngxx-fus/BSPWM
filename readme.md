# 🚀 UbuntuBSPWM: Dotfiles & System Backup Suite

A sleek, modular, and high-performance **bspwm** (Binary Space Partitioning Window Manager) desktop environment for Ubuntu, paired with an automated backup and deployment system for user dotfiles and system configurations.

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Repository Structure](#-repository-structure)
- [Quick Start Guide](#-quick-start-guide)
  - [1. Install Dependencies & Packages](#1-install-dependencies--packages)
  - [2. Deploy Configurations (Restore to Local)](#2-deploy-configurations-restore-to-local)
  - [3. Start / Reload BSPWM](#3-start--reload-bspwm)
- [Synchronization Scripts](#-synchronization-scripts)
  - [CopyFromLocal (Backup Host -> Repo)](#copyfromlocal-backup-host---repo)
  - [CopyToLocal (Restore Repo -> Host)](#copytolocal-restore-repo---host)
  - [CLI Flags & Interactive Prompts](#cli-flags--interactive-prompts)
  - [Managing PathLists.txt](#managing-pathliststxt)
- [📂 Desktop Environment Layout](#-desktop-environment-layout)
- [⚡ Keybindings Cheat Sheet](#-keybindings-cheat-sheet)
  - [🖥️ Applications & Utilities](#-applications--utilities)
  - [🪟 Window Management](#-window-management)
  - [🧭 Workspaces & Multi-Monitor](#-workspaces--multi-monitor)
  - [🔊 Media & Hardware Controls](#-media--hardware-controls)
- [🛠️ Key Components & Integrations](#-key-components--integrations)
- [🔒 Security & Permissions Handling](#-security--permissions-handling)

---

## 🌟 Overview

**UbuntuBSPWM** provides:
- A fully customized X11 desktop environment built around **bspwm**, **sxhkd**, **polybar**, **rofi**, **dunst**, and **picom**.
- Ergonomic multi-monitor profiles, touchpad gestures, volume/brightness OSD notifications, and automatic lock/sleep handling.
- A zero-dependency, portable backup and restore engine (`CopyFromLocal.sh` and `CopyToLocal.sh`) allowing you to replicate your entire desktop and system configuration across Ubuntu machines in minutes.

---

## 🗂️ Repository Structure

```text
UbuntuBSPWM/
├── CopyFromLocal.sh       # Copies dotfiles and system configurations from local machine into root/
├── CopyToLocal.sh         # Restores dotfiles and system configurations from root/ to local machine
├── PathLists.txt          # Manifest listing all files and directories managed by the scripts
├── packages_manual.txt    # List of manually installed APT packages for rapid bootstrapping
├── readme.md              # Project documentation and keybindings guide
├── .gitignore             # Ignore rules for transient caches, runtime locks, and geometry files
└── root/                  # Mirrored root filesystem tree storing configuration backups
    ├── etc/               # System configurations (ACPI, logind, X11 touchpad)
    │   ├── acpi/
    │   ├── systemd/
    │   └── X11/xorg.conf.d/
    ├── home/
    │   └── fus/           # User configuration directory (bspwm, polybar, rofi, dunst, etc.)
    │       ├── .cargo/bin/
    │       ├── .config/
    │       └── .zshrc
    └── usr/local/bin/     # Custom helper binaries (betterlockscreen, skippy-xd, howdy)
```

---

## 🚀 Quick Start Guide

Setting up a fresh Ubuntu machine with this configuration:

### 1. Install Dependencies & Packages

Clone the repository and install all required packages listed in `packages_manual.txt`:

```bash
git clone https://github.com/ngxx-fus/UbuntuBSPWM.git
cd UbuntuBSPWM

# Update package lists
sudo apt update

# Install all APT packages from the manifest
xargs -a packages_manual.txt sudo apt install -y
```

### 2. Deploy Configurations (Restore to Local)

Deploy configurations from `root/` directly to your local user home and system directories:

```bash
# Preview what will be restored without writing files
./CopyToLocal.sh --dry-run

# Run interactive restore (prompts per item: y/n/a/q)
./CopyToLocal.sh

# Or restore everything automatically without confirmation prompts
./CopyToLocal.sh --yes
```

> [!NOTE]
> `CopyToLocal.sh` automatically adapts user home paths across different usernames (e.g. if the repo backup was taken by user `fus`, it will restore seamlessly into `/home/<your-user>/` with proper ownership).

### 3. Start / Reload BSPWM

Log out of your current desktop session, select **bspwm** from your display manager (GDM/LightDM/SDDM), and log in.

If already running bspwm, reload configurations instantly:
```bash
# Reload sxhkd hotkeys
pkill -USR1 -x sxhkd
# (or press Super + Escape)

# Restart bspwm window manager
bspc wm -r
# (or press Super + Alt + r)
```

---

## 🔄 Synchronization Scripts

The repository includes two scripts designed for daily workflow and machine synchronization. Both scripts support both `bash` and `zsh`.

### CopyFromLocal (Backup Host -> Repo)

Use `CopyFromLocal.sh` when you have customized your local configuration files and want to capture the changes into the Git repository:

```bash
# Preview changes before copying
./CopyFromLocal.sh --dry-run

# Interactive backup
./CopyFromLocal.sh

# Non-interactive backup (copies all items)
./CopyFromLocal.sh --yes
```

**Key Enhancements in `CopyFromLocal.sh`:**
- **Auto-pruning:** Automatically skips or prunes runtime lockfiles (`*.lock`, `.*.lock`), transient CopyQ clipboard databases (`copyq_tab_*.dat`), and window geometry states so runtime junk never enters version control.
- **Permission Normalization:** Automatically adjusts ownership of system files in `root/` to your current user so `git status`, `git diff`, and `git commit` run smoothly without requiring `sudo`.
- **Cross-directory execution:** Resolves its own path dynamically; can be invoked from any working directory.

### CopyToLocal (Restore Repo -> Host)

Use `CopyToLocal.sh` to apply repository configurations onto the local system:

```bash
# Interactive restore
./CopyToLocal.sh

# Auto-confirm all items
./CopyToLocal.sh --yes
```

**Key Enhancements in `CopyToLocal.sh`:**
- **Non-destructive Directory Sync:** Updates repository-managed configuration files while preserving any unmanaged local user files.
- **Cross-User Home Mapping:** Automatically detects user folders in `root/home/` and restores into the current user's `$HOME`.
- **System Integrity:** Sets `root:root` ownership on system files (`/etc/`, `/usr/`) and `$USER:$USER` on home files (`$HOME`).
- **Target State Indication:** Shows whether the target already exists or is new before prompting.

### CLI Flags & Interactive Prompts

Both scripts support the following command-line flags:

| Flag | Long Flag | Description |
| :--- | :--- | :--- |
| `-y` | `--yes`, `-a`, `--all` | Run non-interactively; automatically confirm all operations |
| `-n` | `--dry-run` | Preview operations without creating or modifying any files |
| `-h` | `--help` | Display usage instructions and options |

During interactive execution, each item prompts for confirmation:
- `y` (**Yes**): Copy / restore the current item.
- `n` (**No**): Skip the current item.
- `a` (**All**): Confirm the current item and all remaining items automatically.
- `q` (**Quit**): Immediately abort the process.

### Managing PathLists.txt

`PathLists.txt` defines what files and directories are synchronized. Lines can be paths relative to `~` or absolute paths:

```text
/home/fus/.config/bspwm/
/home/fus/.config/gtk-3.0/
/home/fus/.config/fcitx5/
/home/fus/.config/touchegg/
/home/fus/.config/Thunar/
/home/fus/.config/xfce4/
/home/fus/.config/flameshot/
/home/fus/.config/copyq/
/home/fus/.config/skippy-xd/
/home/fus/.config/polybar/
/home/fus/.config/dunst/
/home/fus/.zshrc
/etc/X11/xorg.conf.d/
/etc/systemd/logind.conf
/etc/acpi/
/usr/local/bin/skippy-xd
/usr/local/bin/betterlockscreen
/usr/local/bin/howdy
/home/fus/.cargo/bin/xidlehook
```

- Trailing slashes indicate directories (e.g., `~/.config/bspwm/`).
- Paths starting with `~` or `/home/<user>/` are mapped dynamically to the active user's home directory.
- Absolute paths outside `/home` (such as `/etc/` or `/usr/local/bin/`) are handled with elevated permissions when required.
- Blank lines and comments starting with `#` are ignored.

---

## 📂 Desktop Environment Layout

```text
~/.config/bspwm/
├── bspwmrc                      # Main initialization script and window management rules
├── readme.md                    # BSPWM specific guide
├── .gitignore                   # Ignore rules for cache / temporary files
│
├── alacritty/                   # Alacritty terminal emulator configuration
│   └── alacritty.yml
│
├── dunst/                       # Notification daemon configuration
│   └── dunstrc
│
├── obmenu/                      # Application menu generator schema
│   └── schema.pl
│
├── picom/                       # X11 compositor (opacity, shadows, fading)
│   └── picom.conf
│
├── polybar/                     # Modular status bar
│   ├── config.ini               # Module definitions and layout
│   ├── colors.ini               # Theme color palette
│   └── ibus-toggle.sh           # Input toggle script
│
├── rofi/                        # Application launcher & modal menus
│   ├── config.rasi              # Universe launcher configuration
│   ├── colors.rasi              # Palette definitions
│   ├── combi.rasi               # Unified launcher theme
│   ├── controlpanel.rasi        # System control panel theme
│   ├── keybinds.rasi            # Keybindings cheat sheet popup
│   ├── popup.rasi               # Shared popup modal theme
│   └── power.rasi               # Power session menu theme
│
├── scripts/                     # Helper & automation scripts
│   ├── Helper-ChangeBrightness  # Display brightness control with Dunst OSD
│   ├── Helper-ChangeKeyboardBrightness # Keyboard backlight control with Dunst OSD
│   ├── Helper-ChangeVolume      # PulseAudio/ALSA volume control with Dunst OSD
│   ├── Helper-DisplaySwitching  # Multi-monitor switcher (PC only, Clone, Extend, External)
│   ├── Helper-Help              # Displays keybinding cheat sheet via Rofi
│   ├── Helper-Power             # Session controls (Power off, Reboot, Suspend, Lock)
│   ├── Helper-ToggleTouchpad    # Enables / disables touchpad on demand
│   ├── Service-Background       # Desktop wallpaper manager
│   ├── Service-Polybar          # Polybar lifecycle launcher
│   └── data/display_config      # Persistent multi-monitor state
│
├── skippy-xd/                   # Exposé-style visual task switcher configuration
│   └── skippy-xd.rc
│
├── sxhkd/                       # Simple X Hotkey Daemon configuration
│   └── sxhkdrc
│
└── wallpaper/                   # Curated wallpapers for FHD and Ultrawide (3440x1440)
```

---

## ⚡ Keybindings Cheat Sheet

Modifier Key: **`Super`** (Windows key).

### 🖥️ Applications & Utilities
| Shortcut | Action | Command / Target |
| :--- | :--- | :--- |
| `Super + Enter` / `Super + r` | Open Terminal | `gnome-terminal` / `alacritty` |
| `Alt + Space` | Application Launcher (Universe) | `rofi -show combi` |
| `Super + e` | File Manager | `thunar` |
| `Super + v` | Clipboard History Manager | `copyq toggle` |
| `Super + l` | Lock Screen | `betterlockscreen -l blur` |
| `Super + Tab` | Visual Window Switcher (Exposé) | `skippy-xd` |
| `Alt + Tab` / `Alt + Shift + Tab` | Focus next / previous window | `bspc node -f next/prev.local.!hidden.window` |
| `Super + Space` | Toggle Input Method | `fcitx5` |
| `Super + p` | Display Switching Menu | Multi-monitor profile menu |
| `Super + x` | Power & Session Menu | Shutdown, Reboot, Suspend, Lock |
| `Super + /` | Hotkey Cheat Sheet | Visual keybindings help |
| `Super + Esc` | Reload Hotkeys | Reload `sxhkd` configuration |

### 🪟 Window Management
| Shortcut | Action |
| :--- | :--- |
| `Super + q` / `Super + w` | Close focused window (`bspc node -c`) |
| `Super + Shift + w` | Force kill window (`bspc node -k`) |
| `Super + f` | Toggle Fullscreen state |
| `Super + s` | Toggle between Floating and Tiled states |
| `Super + m` | Toggle between Tiled and Monocle (Maximized) layout |
| `Super + {Left, Down, Up, Right}` | Directional window focus (Arrow keys) |
| `Super + {h, j, k, l}` | Directional window focus (Vim keys) |
| `Super + Shift + {Arrows / hjkl}` | Swap focused window with neighbor |
| `Super + Ctrl + {Arrows}` | Move floating window coordinates |
| `Super + Alt + {h, j, k, l}` | Expand window size |
| `Super + Alt + Shift + {h, j, k, l}` | Contract window size |

### 🧭 Workspaces & Multi-Monitor
| Shortcut | Action |
| :--- | :--- |
| `Super + [1-9]` | Switch to Workspace 1–9 on focused monitor |
| `Super + Shift + [1-9]` | Send focused window to Workspace 1–9 |
| `Ctrl + Alt + Left / Right` | Cycle previous / next desktop |
| `Super + comma` / `Super + period` | Focus previous / next physical monitor |
| `Super + Ctrl + Shift + {Arrows}` | Send window to directional monitor |

### 🔊 Media & Hardware Controls
| Shortcut | Action |
| :--- | :--- |
| `XF86AudioRaiseVolume` / `Super + F12` | Volume Up (with Dunst OSD) |
| `XF86AudioLowerVolume` / `Super + F11` | Volume Down (with Dunst OSD) |
| `XF86AudioMute` / `Super + F10` | Mute / Unmute Audio |
| `XF86AudioMicMute` / `XF86Launch5` | Mute / Unmute Microphone |
| `XF86MonBrightnessUp / Down` | Screen Brightness Control |
| `XF86KbdBrightnessUp / Down` | Keyboard Backlight Control |
| `XF86TouchpadToggle` | Enable / Disable Touchpad |
| `Print` | Fullscreen Screenshot (`flameshot full`) |
| `Super + Shift + s` | Interactive Area Screenshot (`flameshot gui`) |

---

## 🛠️ Key Components & Integrations

- **Window Management**: `bspwm` organizes windows into a binary tree structure. `sxhkd` handles hotkey interception.
- **Notification Daemon**: `dunst` configured with custom themes and visual progress bars for brightness and volume changes.
- **Compositor**: `picom` provides dual-kawase blur, soft drop shadows, and subtle window transitions.
- **Power & Sleep Management**:
  - `/etc/systemd/logind.conf` handles lid switch behavior (ignoring lid close on external displays).
  - `/etc/acpi/` handles custom ACPI events.
  - `xidlehook` dims screen before auto-locking via `betterlockscreen`.
- **Touchpad Experience**:
  - `touchegg` enables multi-finger gestures (swipe up for window exposé, swipe left/right for workspaces).
  - `/etc/X11/xorg.conf.d/30-touchpad.conf` enables natural scrolling, tap-to-click, and palm detection.

---

## 🔒 Security & Permissions Handling

- **Exclusion of Sensitive Data**: The `.gitignore` and `CopyFromLocal.sh` scripts prevent CopyQ clipboard history (`copyq_tab_*.dat`), authentication keys, lockfiles, and application cache from being committed.
- **Root vs User Permissions**:
  - Configuration files copied to `$HOME` are set to `$USER:$USER`.
  - System files copied to `/etc/` or `/usr/` are restored as `root:root`.
  - When backing up to `root/`, all files are normalized to user ownership to enable normal Git operations.
