#!/usr/bin/env bash
set -e

echo "🚀 Starting i3 setup installation..."

# 1️⃣ Update system
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install essential packages
sudo apt install -y i3 alacritty rofi picom compton feh amixer xorg xbacklight fonts-powerline python3-pip

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

# 9️⃣ Configure Custom Pywal Scripts (Toggle On/Off)
echo "🎨 Setting up Pywal toggle scripts..."
mkdir -p "$HOME/bin"

# Create the ENABLE script
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    wal -i "$img_path" -n
    rm -f "$HOME/.cache/wal/sequences"
    pywalfox update
    echo "✔ Pywal Enabled (Wallpaper & Firefox). Terminal colors blocked."
else
    echo "✘ Error: File not found!"
fi
EON

# Create the DISABLE script
cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
rm -rf "$HOME/.cache/wal/"*
# Set back to the default wallpaper from your .wallpapers folder
feh --bg-fill "$HOME/.wallpapers/wallpaper.jpg"
pywalfox update 2>/dev/null
reset
echo "✔ Pywal Disabled. Back to default."
EOD

# Make them executable
chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"

# Add aliases to .zshrc if they aren't there
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "alias py-on" "$HOME/.zshrc"; then
        echo -e "\n# Pywal Toggle Aliases\nalias py-on='~/bin/enable_pywal.sh'\nalias py-off='~/bin/disable_pywal.sh'" >> "$HOME/.zshrc"
    fi
fi

# Ensure ~/bin is in PATH for the current user session
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
fi

# 🔟 Install Python Tools for Pywal
# This is the part you just asked about!
echo "🐍 Installing Pywal and Pywalfox..."
sudo apt install -y python3-pip
python3 -m pip install --user pywal16 pywalfox --break-system-packages

echo "✅ i3 setup and Pywal toggle installation complete!"
echo "👉 Restart your terminal or run 'source ~/.zshrc' to use 'py-on' and 'py-off'."
