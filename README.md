<div align="center">

# LostBoi's i3-Gaps + Pywal Rice

**A fully automated, dynamically themed i3 setup for Kali/Debian**

Every color across your entire desktop adapts to your wallpaper — automatically.

---

`i3-gaps` | `pywal` | `i3blocks` | `picom` | `rofi` | `alacritty`

</div>

---

## Preview

![Clean Desktop](screenshots/example-full-screen.png)

---

## What's Inside

| Component | Purpose |
|---|---|
| **i3-gaps** | Tiling window manager with gaps and pixel borders |
| **Pywal** | Generates color schemes from your wallpaper |
| **i3blocks** | Status bar with CPU, RAM, Disk, Battery, Network — colors synced to wallpaper |
| **Picom** | Compositor for transparency and shadows |
| **Alacritty** | GPU-accelerated terminal — colors synced to wallpaper |
| **Rofi** | Application launcher |
| **Pywalfox** | Firefox colors synced to wallpaper |
| **Sublime Text** | Editor with pywal-synced color scheme |
| **Oh My Zsh** | Zsh with autosuggestions and syntax highlighting |

![Sublime Text + Terminal — Colors Synced to Wallpaper](screenshots/subl-sync-colours.png)

---

## Features

- **One-command install** — everything configured automatically
- **Dynamic theming** — change wallpaper, everything follows (bar, terminal, browser, borders, blocks)
- **Random wallpaper picker** — press a key and get a new look instantly
- **Transparent i3bar** — with pywal-synced workspace colors
- **i3blocks with pywal colors** — each block gets its own accent color from your wallpaper

![Tiled Layout with Transparent Firefox](screenshots/transperent%20-firefox-layout.png)
- **Tap-to-click touchpad** — configured out of the box
- **Volume/Brightness keys** — Fn keys just work
- **NTFS auto-mount** — access Windows drives from Thunar without issues

---

## Installation

> **Note:** Do **not** run as root. The script uses `sudo` where needed.

### Step 1 — Install i3

```bash
sudo apt update
sudo apt install i3
```

### Step 2 — Switch to i3

1. Log out of your current session
2. On the login screen, click the **session/gear icon** (bottom-right or top-right depending on your display manager)
3. Select **i3** from the list
4. Log back in

> You'll see a default i3 setup — that's expected. The install script will configure everything.

### Step 3 — Run the Install Script

Open a terminal (`Super + Return`) and run:

```bash
git clone https://github.com/Takezo49/i3-setup.git
cd i3-setup
chmod +x install.sh
./install.sh
```

### Step 4 — Reboot

```bash
sudo reboot
```

After rebooting, your fully themed i3 desktop will be ready.

---

## Keybindings

### General

| Key | Action |
|---|---|
| `Super + Return` | Open Alacritty terminal |
| `Super + D` | Open Rofi launcher |
| `Super + B` | Open Firefox |
| `Super + Shift + Q` | Kill focused window |
| `Super + Shift + C` | Reload i3 config |
| `Super + Shift + R` | Restart i3 in-place |
| `Super + Shift + E` | Exit i3 |

### Workspaces

| Key | Action |
|---|---|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace 1-10 |

### Layout

| Key | Action |
|---|---|
| `Super + H` | Split horizontal |
| `Super + V` | Split vertical |
| `Super + S` | Stacking layout |
| `Super + W` | Tabbed layout |
| `Super + E` | Toggle split |
| `Super + F` | Fullscreen |
| `Super + Shift + Space` | Toggle floating |
| `Super + Space` | Toggle focus (tiling/floating) |

### Navigation

| Key | Action |
|---|---|
| `Super + Arrow Keys` | Move focus |
| `Super + Shift + Arrow Keys` | Move window |
| `Super + R` | Enter resize mode (use arrows, then Enter/Esc) |

### Tools

| Key | Action |
|---|---|
| `Super + P` | Screenshot (Flameshot) |
| `Super + C` | Clipboard manager |
| `Super + Shift + W` | Random wallpaper + apply pywal theme |

### Media

| Key | Action |
|---|---|
| `F2 / Volume Down` | Volume -5% |
| `F3 / Volume Up` | Volume +5% |
| `Mute Key` | Toggle mute |
| `Mic Mute Key` | Toggle mic mute |
| `Brightness Up` | Brightness +5% |
| `Brightness Down` | Brightness -5% |

---

## Commands

Run these in your terminal:

| Command | What it does |
|---|---|
| `py-on` | Set a specific wallpaper + apply pywal theme everywhere |
| `py-off` | Reset to default wallpaper |
| `wallpick` | Apply a random wallpaper from your collection |

---

## Terminal + System Info

![Fastfetch](screenshots/fastfetch.png)

---

## How Theming Works

```
Wallpaper changed (py-on / wallpick / Super+Shift+W)
        |
        v
   pywal generates colors
        |
        +---> ~/.cache/wal/colors.Xresources  ---> i3 bar + window borders
        +---> ~/.cache/wal/i3blocks.conf       ---> i3blocks (CPU, RAM, etc.)
        +---> ~/.cache/wal/colors-alacritty.yml --> Alacritty terminal
        +---> pywalfox                          ---> Firefox
        +---> sublime color scheme              ---> Sublime Text
        |
        v
   i3-msg restart (applies everything)
```

On every **reboot**, `wal -R` runs automatically via `exec_always` in the i3 config, restoring your last theme and regenerating all configs.

---

## Directory Structure

```
i3-setup/
├── .config/
│   ├── i3/
│   │   ├── config              # i3 config (pywal colors, keybindings, bar)
│   │   └── clipboard_fix.sh    # VM clipboard workaround
│   ├── wal/
│   │   └── templates/
│   │       └── i3blocks.conf   # Pywal template for i3blocks
│   ├── alacritty/
│   │   └── alacritty.yml       # Terminal config
│   ├── picom/
│   │   └── picom.conf          # Compositor config
│   └── rofi/
│       ├── config              # Rofi config
│       └── config.rasi         # Rofi theme
├── .wallpapers/
│   └── 23.jpg                  # Default wallpaper
├── screenshots/
│   ├── example-full-screen.png # Clean desktop preview
│   ├── fastfetch.png           # Terminal with system info
│   └── transperent -firefox-layout.png # Tiled layout with Firefox
├── .zshrc                      # Zsh config with plugins
├── install.sh                  # One-command setup script
└── README.md
```

---

## What the Install Script Does

1. Installs all system dependencies (i3, picom, rofi, alacritty, pywal, fonts, etc.)
2. Copies all config files to `~/.config/`
3. Clones [i3blocks-contrib](https://github.com/vivien/i3blocks-contrib) for status bar scripts
4. Sets up pywal template so i3blocks colors auto-sync with wallpaper
5. Creates `py-on`, `py-off`, and `wallpick` helper scripts
6. Configures polkit rules for auto-mounting NTFS/USB drives in Thunar
7. Configures touchpad (tap-to-click, natural scrolling)
8. Sets up Zsh with Oh My Zsh, autosuggestions, and syntax highlighting
9. Runs pywal once to generate initial theme
10. Restarts i3

---

## Adding Wallpapers

Drop images into `~/.wallpapers/Wallpaper-Bank/wallpapers/` and they'll automatically be available to the random wallpaper picker (`Super+Shift+W` or `wallpick`).

---

<div align="center">

**Made by [LostBoi](https://github.com/Takezo49)**

</div>
