#!/usr/bin/env bash
set -e

echo "🚀 Starting i3 setup installation..."

# 1️⃣ Update system
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install essential packages
sudo apt install -y i3 alacritty rofi picom feh amixer xorg xbacklight fonts-powerline python3-pip

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
i3-msg reload || true
i3-msg restart || true

# 9️⃣ Configure Custom Pywal Scripts (Toggle On/Off)
echo "🎨 Setting up Pywal toggle scripts..."
mkdir -p "$HOME/bin"

# Create the ENABLE script
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    # 1. Force the wallpaper change immediately
    feh --bg-fill "$img_path"
    
    # 2. Generate colors but skip setting wallpaper again (-n)
    wal -i "$img_path" -n
    
    # 3. Update Firefox
    pywalfox update
    
    echo "✔ Pywal Enabled: Wallpaper, Firefox, and Terminal updated!"
else
    echo "✘ Error: File not found!"
fi
EON
# Create the DISABLE script
cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
rm -rf "$HOME/.cache/wal/"*
# Set back to default wallpaper
feh --bg-fill "$HOME/.wallpapers/wallpaper.jpg"
pywalfox update 2>/dev/null
reset
echo "✔ Pywal Disabled. Back to default."
EOD

# Make them executable
chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"

# Add aliases and PERSISTENCE to .zshrc
if [ -f "$HOME/.zshrc" ]; then
    # Add Aliases
    if ! grep -q "alias py-on" "$HOME/.zshrc"; then
        echo -e "\n# Pywal Toggle Aliases\nalias py-on='~/bin/enable_pywal.sh'\nalias py-off='~/bin/disable_pywal.sh'" >> "$HOME/.zshrc"
    fi
    
    # ADDED THIS: Color persistence logic for new terminal windows
    if ! grep -q "cache/wal/sequences" "$HOME/.zshrc"; then
        echo -e "\n# Import colors from pywal if they exist\nif [ -f ~/.cache/wal/sequences ]; then\n    (cat ~/.cache/wal/sequences &)\nfi" >> "$HOME/.zshrc"
    fi

    # Ensure ~/bin is in PATH
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    fi
fi

# 🔟 Install Python Tools for Pywal
echo "🐍 Installing Pywal and Pywalfox..."
python3 -m pip install --user pywal16 pywalfox --break-system-packages

echo "🔗 Linking Pywalfox to Firefox..."
# This is the exact command that worked!
python3 -m pywalfox install

echo "Installation completed!!!!!!!!!"
