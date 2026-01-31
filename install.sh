#!/bin/bash
# =================================================================
# 🚀 Full i3-Gaps & Pywal Setup Script (Corrected Sync & Transparency)
# =================================================================
set -e

echo "🚀 Starting Full i3-Gaps & Pywal Setup..."

# 1️⃣ Update & Install System Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git thunar arandr flameshot arc-theme feh i3blocks \
    i3status i3 lxappearance python3-pip rofi unclutter cargo picom \
    papirus-icon-theme imagemagick unzip zsh lxpolkit ntfs-3g udisks2 jq

# Install Build Dependencies for i3 (standard for Kali/Debian)
sudo apt install -y libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev \
    libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev \
    libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev \
    libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev \
    libxcb-xrm0 libxcb-xrm-dev autoconf meson libxcb-render-util0-dev \
    libxcb-shape0-dev libxcb-xfixes0-dev

# 2️⃣ Install Nerd Fonts
echo "📂 Installing Fonts..."
mkdir -p ~/.local/share/fonts/
wget -nc https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget -nc https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
unzip -o Iosevka.zip -d ~/.local/share/fonts/
unzip -o RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# 3️⃣ Install Alacritty
echo "🖥️ Installing Alacritty..."
wget -nc https://github.com/barnumbirr/alacritty-debian/releases/download/v0.10.0-rc4-1/alacritty_0.10.0-rc4-1_amd64_bullseye.deb
sudo dpkg -i alacritty_0.10.0-rc4-1_amd64_bullseye.deb || sudo apt install -f -y

# 4️⃣ Install Oh My Zsh (Unattended)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 4.1️⃣ Install Zsh Plugins
echo "🔌 Installing Zsh Plugins..."
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_CUSTOM_PLUGINS"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" || true

# 5️⃣ Install Pywal & Pywalfox
echo "🐍 Installing Pywal and Pywalfox..."
python3 -m pip install --user pywal16 pywalfox --break-system-packages
python3 -m pywalfox install

# 6️⃣ Sync Configs & Fix Permissions
echo "⚙️ Syncing Config Files..."
mkdir -p ~/.config/i3 ~/.config/picom ~/.config/rofi ~/.config/alacritty ~/bin
mkdir -p ~/.config/sublime-text/Packages/User/

# Copy everything from repo to .config
cp -r .config/* ~/.config/
cp .zshrc ~/.zshrc
cp -r .wallpapers ~/.wallpapers

# --- Alacritty Symbolic Link Setup ---
cp ~/.config/alacritty/alacritty.yml ~/.config/alacritty/colors-default.yml
ln -sf ~/.config/alacritty/colors-default.yml ~/.config/alacritty/colors-wal.yml
if ! grep -q "colors-wal.yml" ~/.config/alacritty/alacritty.yml; then
    sed -i '1iimport:\n  - ~/.config/alacritty/colors-wal.yml' ~/.config/alacritty/alacritty.yml
fi

sudo chown -R $USER:$USER ~/.config ~/.zshrc ~/bin

# 7️⃣ Create Pywal Toggle Scripts (CORRECTED SYNC)
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    feh --bg-fill "$img_path"
    wal -i "$img_path" -n

    # 🔗 Update Alacritty link
    ln -sf ~/.cache/wal/colors-alacritty.yml ~/.config/alacritty/colors-wal.yml

    # 🎨 Sync Sublime Text
    BG=$(jq -r '.special.background' ~/.cache/wal/colors.json)
    FG=$(jq -r '.special.foreground' ~/.cache/wal/colors.json)
    C1=$(jq -r '.colors.color1' ~/.cache/wal/colors.json)
    C2=$(jq -r '.colors.color2' ~/.cache/wal/colors.json)
    C3=$(jq -r '.colors.color3' ~/.cache/wal/colors.json)
    C4=$(jq -r '.colors.color4' ~/.cache/wal/colors.json)

    cat <<EOF > ~/.config/sublime-text/Packages/User/pywal.sublime-color-scheme
{
    "variables": { "background": "$BG", "foreground": "$FG", "color1": "$C1", "color2": "$C2", "color3": "$C3", "color4": "$C4" },
    "globals": {
        "background": "var(background)", "foreground": "var(foreground)", "caret": "var(foreground)",
        "line_highlight": "var(background)", "selection": "var(color1)44"
    },
    "rules": [
        { "scope": "keyword", "foreground": "var(color1)" },
        { "scope": "string", "foreground": "var(color2)" },
        { "scope": "constant.numeric", "foreground": "var(color3)" },
        { "scope": "entity.name.function", "foreground": "var(color4)" }
    ]
}
EOF

    # 🔗 Update Firefox
    python3 -m pywalfox update

    # 🔄 REFRESH i3BAR (This fixes the transparency/sync issue)
    xrdb -merge ~/.cache/wal/colors.Xresources
    i3-msg restart

    echo "✔ Pywal Enabled! Wallpaper, Alacritty, i3Bar (Transparent), and Sublime synced."
else
    echo "✘ Error: File not found!"
fi
EON

cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
ln -sf ~/.config/alacritty/colors-default.yml ~/.config/alacritty/colors-wal.yml
rm -rf "$HOME/.cache/wal/"*
feh --bg-fill "$HOME/.wallpapers/23.jpg"
xrdb -remove
i3-msg restart
echo "✔ Pywal Disabled."
EOD

chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"

# 8️⃣ System Permissions & Virtual Monitor Fix
echo "🛡️ Setting up system permissions..."
sudo mkdir -p /etc/polkit-1/rules.d/
cat <<EOF | sudo tee /etc/polkit-1/rules.d/10-udisks2.rules
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount") &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOF

# Ensure lxpolkit starts with i3
if ! grep -q "lxpolkit" ~/.config/i3/config; then
    echo "exec --no-startup-id lxpolkit" >> ~/.config/i3/config
fi

# 9️⃣ Finalize Zsh
echo "📝 Finalizing Zsh Configuration..."
touch ~/.zsh_history
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
if ! grep -q "alias vmon" ~/.zshrc; then
    echo "alias vmon='~/bin/monitor_toggle.sh'" >> ~/.zshrc
    echo "alias py-on='~/bin/enable_pywal.sh'" >> ~/.zshrc
    echo "alias py-off='~/bin/disable_pywal.sh'" >> ~/.zshrc
fi

# 🔟 Final Touches & Wallpaper
echo "🖼️ Setting default wallpaper..."
if [ -f "$HOME/.wallpapers/23.jpg" ]; then
    feh --bg-fill "$HOME/.wallpapers/23.jpg"
    echo "feh --bg-fill '$HOME/.wallpapers/23.jpg'" > "$HOME/.fehbg"
    chmod +x "$HOME/.fehbg"
fi

# Apply Xresources mapping to config if not present
if ! grep -q "set_from_resource" ~/.config/i3/config; then
cat << 'EOF' >> ~/.config/i3/config
# Set colors from Xresources (generated by pywal)
set_from_resource $term_background background #1C1D2B
set_from_resource $term_foreground foreground #EEEEEE
set_from_resource $color1 color1 #82c8ff
set_from_resource $color0 color0 #1C1D2B
EOF
fi

echo "🔄 Restarting i3..."
i3-msg restart || true

echo "✅ DONE! Reboot and run 'py-on' to test your dynamic theme!"
