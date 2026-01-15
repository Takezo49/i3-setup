#!/usr/bin/env bash
set -e

echo "🚀 Starting i3 setup installation..."

# 1️⃣ Update system
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install essential packages
sudo apt install -y i3 alacritty rofi picom compton feh amixer xorg xbacklight fonts-powerline

# 3️⃣ Backup existing configs
for d in .config .wallpapers; do
    if [ -d "$HOME/$d" ]; then
        echo "Backing up existing $d to $d-backup"
        mv "$HOME/$d" "$HOME/$d-backup-$(date +%s)"
    fi
done

# 4️⃣ Copy your configs
cp -r .config "$HOME/"
cp -r .wallpapers "$HOME/"

# 5️⃣ Set wallpapers
if [ -f "$HOME/.wallpapers/wallpaper.jpg" ]; then
    feh --bg-scale "$HOME/.wallpapers/wallpaper.jpg"
fi

# 6️⃣ Kill any existing compositor
killall picom compton || true

# 7️⃣ Start picom
picom --config "$HOME/.config/picom/picom.conf" &

# 8️⃣ Reload i3
i3-msg reload
i3-msg restart

echo "✅ i3 setup installation complete!"
