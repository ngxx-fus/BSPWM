# 🚀 BSPWM: Multi-Distro Dotfiles & System Backup Suite

A modular, high-performance **bspwm** (Binary Space Partitioning Window Manager) desktop environment paired with an automated backup and restoration engine (`CopyFromLocal.sh` & `CopyToLocal.sh`) for user dotfiles, system configurations, and package manifests.

> [!IMPORTANT]
> **Branch Notice:** This `master` branch serves as the central landing page and project overview. Distribution-specific dotfiles, package lists, and detailed guides are maintained in dedicated branches:
> - 👉 **[`VoidLinux`](https://github.com/ngxx-fus/UbuntuBSPWM/tree/VoidLinux)**: Full desktop stack tailored for **Void Linux (`x86_64`)** with **`runit`**, **`elogind`**, and **`xbps`**.
> - 👉 **[`Ubuntu`](https://github.com/ngxx-fus/UbuntuBSPWM/tree/Ubuntu)**: Desktop stack tailored for **Ubuntu / Debian** with **`systemd`** and **`apt`**.
>
> Please switch to the target distribution branch for specific installation steps, package manifests, and configuration details.

---

## 📑 Table of Contents

- [Supported Distributions & Branches](#-supported-distributions--branches)
- [How to Choose & Switch Branches](#-how-to-choose--switch-branches)
- [Architecture & Common Philosophy](#-architecture--common-philosophy)
  - [Synchronization Scripts](#synchronization-scripts)
  - [Managed Components](#managed-components)
- [Detailed Distribution Guides](#-detailed-distribution-guides)

---

## 🌐 Supported Distributions & Branches

| Distribution | Target Branch | Init & Session Manager | Package Manager | Package Manifest | Documentation Link |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Void Linux** | [`VoidLinux`](https://github.com/ngxx-fus/UbuntuBSPWM/tree/VoidLinux) | `runit` + `elogind` | `xbps` (`xbps-install`, `xbps-query`) | `PackagesManual.txt` | [View VoidLinux README](https://github.com/ngxx-fus/UbuntuBSPWM/blob/VoidLinux/readme.md) |
| **Ubuntu / Debian** | [`Ubuntu`](https://github.com/ngxx-fus/UbuntuBSPWM/tree/Ubuntu) | `systemd` + `logind` | `apt` (`apt-get`, `apt-mark`) | `packages_manual.txt` | [View Ubuntu README](https://github.com/ngxx-fus/UbuntuBSPWM/blob/Ubuntu/readme.md) |

---

## 🚀 How to Choose & Switch Branches

### Option 1: Clone Directly into Target Branch

To clone only the desired distribution configuration:

```bash
# For Void Linux (x86_64):
git clone -b VoidLinux https://github.com/ngxx-fus/UbuntuBSPWM.git BSPWM

# For Ubuntu / Debian:
git clone -b Ubuntu https://github.com/ngxx-fus/UbuntuBSPWM.git BSPWM
```

### Option 2: Switch Branch in an Existing Clone

If you have already cloned the repository:

```bash
cd BSPWM

# Switch to Void Linux
git checkout VoidLinux

# Or switch to Ubuntu
git checkout Ubuntu
```

Once checked out, consult the branch-specific `readme.md` for full installation instructions, dependency management, and configuration guides.

---

## 🛠️ Architecture & Common Philosophy

Across all branches, this suite follows a clean, reproducible dotfiles management model:

### Synchronization Scripts

- **`CopyFromLocal.sh` (Backup Host -> Repo)**:
  - Scans `PathLists.txt` and copies local configurations into the repository's `root/` tree.
  - Automatically exports manual package selections (`xbps-query -m > PackagesManual.txt` on Void Linux, `apt-mark showmanual` on Ubuntu).
  - Automatically prunes transient runtime artifacts (`*.lock`, CopyQ clipboard caches, geometry files).
  - Normalizes file ownership to your local user for frictionless git versioning.

- **`CopyToLocal.sh` (Restore Repo -> Host)**:
  - Restores configurations from `root/` into the local host non-destructively.
  - Preserves untracked local files and sets appropriate ownership (`$USER:$USER` for home files, `root:root` for `/etc/` and `/usr/`).
  - Prompts to automatically install required packages from the distribution's package list.

- **`PathLists.txt`**:
  - The single source of truth defining which files and directories are tracked and synchronized.

### Managed Components

- **Window Management**: `bspwm` (tiling window manager) + `sxhkd` (hotkey daemon).
- **Status Bar**: `polybar` with modular status indicators (CPU temp, memory, backlight, battery, audio, input method).
- **Launcher & Menus**: `rofi` with customized themes (app launcher, display profile switcher, powermenu).
- **Compositor**: `picom` (fading, window rules, shadows, and GTK3 menu corner clipping).
- **Notifications**: `dunst` with OSD volume and brightness status feedback.
- **Clipboard**: `copyq` clipboard manager.
- **Input Method**: `fcitx5` (bamboo/unikey).
- **Touchpad**: `touchegg` gestures & libinput configurations.

---

## 📖 Detailed Distribution Guides

For complete setup guides, keybindings cheat sheets, multi-monitor configuration, and hardware setup, please switch to the branch matching your operating system:

- 📖 **[Read Void Linux Setup Guide (VoidLinux branch)](https://github.com/ngxx-fus/UbuntuBSPWM/blob/VoidLinux/readme.md)**
- 📖 **[Read Ubuntu Setup Guide (Ubuntu branch)](https://github.com/ngxx-fus/UbuntuBSPWM/blob/Ubuntu/readme.md)**
