#!/bin/bash
set -e

echo "🚀 Starting Full i3-Gaps & Pywal Setup..."

# 1️⃣ Update & Install System Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git thunar arandr flameshot arc-theme feh i3blocks \
    i3status i3 lxappearance python3-pip rofi unclutter cargo picom \
    papirus-icon-theme imagemagick unzip zsh lxpolkit ntfs-3g udisks2 jq

# Install Build Dependencies for i3-gaps (if needed)
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

# Copy everything from repo to .config
cp -r .config/* ~/.config/
cp .zshrc ~/.zshrc
cp -r .wallpapers ~/.wallpapers

# --- NEW: Symbolic Link Setup ---
# 1. Create the default color file from your current alacritty settings
# (Assumes your repo's alacritty.yml has your favorite colors)
cp ~/.config/alacritty/alacritty.yml ~/.config/alacritty/colors-default.yml

# 2. Create the symlink that Alacritty will actually 'import'
ln -sf ~/.config/alacritty/colors-default.yml ~/.config/alacritty/colors-wal.yml

# 3. Inject the import line into the MAIN config so it stays persistent
# We put it at the very top of the file
sed -i '1iimport:\n  - ~/.config/alacritty/colors-wal.yml' ~/.config/alacritty/alacritty.yml
# --------------------------------

sudo chown -R $USER:$USER ~/.config ~/.zshrc ~/bin
mkdir -p ~/.config/sublime-text/Packages/User/



# 7️⃣ Create Pywal Toggle Scripts
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    feh --bg-fill "$img_path"
    wal -i "$img_path" -n

    # 🔗 Update Alacritty link
    ln -sf ~/.cache/wal/colors-alacritty.yml ~/.config/alacritty/colors-wal.yml

    # 🎨 NEW: Build Sublime Text Color Scheme (Fixes broken link)
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
cat <<EOF > ~/.config/sublime-text/Packages/User/Adaptive.sublime-theme
[
    {
        "variables": {
            "--background": "$BG",
            "--bluish": "$C4",
            "--redish": "$C1"
        }
    }
]
EOF

    # 🔄 Reload i3 to apply transparency and bar colors
    i3-msg reload
    echo "✔ Pywal Enabled! Wallpaper, Alacritty, and Sublime synced."
else
    echo "✘ Error: File not found!"
fi
EON


cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
# Switch link back to Default Colors
ln -sf ~/.config/alacritty/colors-default.yml ~/.config/alacritty/colors-wal.yml

rm -rf "$HOME/.cache/wal/"*
feh --bg-fill "$HOME/.wallpapers/wallpaper.jpg"
python3 -m pywalfox update 2>/dev/null

# Force Alacritty to see the link change
touch ~/.config/alacritty/alacritty.yml
reset
echo "✔ Pywal Disabled. (Colors linked to Default)"
EOD

chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"

# Create Virtual Screen Toggle Script
cat << 'EOT' > "$HOME/bin/monitor_toggle.sh"
#!/bin/bash
# Check if HDMI-1-1 is currently active (has a resolution assigned)
if xrandr | grep "HDMI-1-1 connected" | grep -q "[0-9]x[0-9]"; then
    xrandr --output HDMI-1-1 --off
    notify-send "Virtual Monitor" "HDMI-1-1 Disabled"
else
    # Re-run the setup commands
    xrandr --newmode "1360x768_60.00" 84.75 1360 1432 1568 1776 768 771 781 798 -HSync +VSync 2>/dev/null || true
    xrandr --addmode HDMI-1-1 "1360x768_60.00" 2>/dev/null || true
    xrandr --output HDMI-1-1 --mode "1360x768_60.00" --left-of eDP-1
    notify-send "Virtual Monitor" "HDMI-1-1 Enabled (1360x768)"
fi
EOT

chmod +x "$HOME/bin/monitor_toggle.sh"

# 8️⃣ System Permissions (Thunar/Mounting Fix)
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

# 9️⃣ Finalize Zsh (History & Plugins)
echo "📝 Finalizing Zsh Configuration..."
touch ~/.zsh_history
sudo chown $USER:$USER ~/.zshrc ~/.zsh_history
chmod +w ~/.zshrc

# Update .zshrc plugins
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# --- NEW: Add Monitor Toggle Alias ---
if ! grep -q "alias vmon" ~/.zshrc; then
    echo "alias vmon='~/bin/monitor_toggle.sh'" >> ~/.zshrc
fi

# Append history settings if they don't exist
if ! grep -q "HISTFILE" ~/.zshrc; then
cat << 'EOF' >> ~/.zshrc

# --- Added by Install Script ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history
setopt append_history
# -------------------------------
EOF
fi

# 🔟 Final Touches
# 🔟 Final Touches
echo "🖼️ Setting default wallpaper..."
# Ensure the directory exists and has the file
if [ -f "$HOME/.wallpapers/23.jpg" ]; then
    feh --bg-fill "$HOME/.wallpapers/23.jpg"
    # Create the .fehbg file so it persists on next login
    echo "feh --bg-fill '$HOME/.wallpapers/23.jpg'" > "$HOME/.fehbg"
    chmod +x "$HOME/.fehbg"
else
    echo "⚠️ Warning: .wallpapers/wallpaper.jpg not found. Skipping wallpaper set."
fi

echo "🔄 Reloading i3..."
i3-msg reload || true

# 9.1️⃣ Setup Virtual Monitor for Deskreen (1360x768)
echo "🖥️ Configuring Virtual HDMI Monitor..."

# A. Force HDMI-A-1 to 'Enabled' in GRUB if not already there
if ! grep -q "video=HDMI-A-1:e" /etc/default/grub; then
    echo "Adding video=HDMI-A-1:e to /etc/default/grub..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="video=HDMI-A-1:e /g' /etc/default/grub
    sudo update-grub
    echo "⚠️ GRUB updated. You MUST reboot for the virtual port to appear."
fi

# B. Add the xrandr commands to i3 config to set resolution and position
# We use a heredoc to ensure the commands are clean
cat << 'EOF' >> ~/.config/i3/config

# --- Virtual Monitor Setup (Deskreen) ---
exec_always --no-startup-id xrandr --newmode "1360x768_60.00" 84.75 1360 1432 1568 1776 768 771 781 798 -HSync +VSync
exec_always --no-startup-id xrandr --addmode HDMI-1-1 "1360x768_60.00"
exec_always --no-startup-id xrandr --output HDMI-1-1 --mode "1360x768_60.00" --left-of eDP-1
# ----------------------------------------
EOF

echo "✅ DONE! REBOOT and then:"
echo "1. Select i3 at login."
echo "2. Run lxappearance to set Arc-Dark icons/theme."
echo "3. Run 'py-on' to set your first dynamic theme!"
source ~/.zshrc || true
