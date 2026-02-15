#!/bin/bash
# =================================================================
# Full i3-Gaps & Pywal Setup Script (Corrected Sync & Transparency)
# =================================================================
set -e

echo "Starting Full i3-Gaps & Pywal Setup..."

# 1. Update & Install System Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git thunar arandr flameshot arc-theme feh i3blocks \
    i3status i3 lxappearance python3-pip rofi unclutter cargo picom \
    papirus-icon-theme imagemagick unzip zsh lxpolkit ntfs-3g udisks2 jq \
    pulseaudio-utils brightnessctl xinput xserver-xorg-input-libinput

# Install Build Dependencies for i3 (standard for Kali/Debian)
sudo apt install -y libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev \
    libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev \
    libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev \
    libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev \
    libxcb-xrm0 libxcb-xrm-dev autoconf meson libxcb-render-util0-dev \
    libxcb-shape0-dev libxcb-xfixes0-dev

# 2. Install Nerd Fonts
echo "Installing Fonts..."
mkdir -p ~/.local/share/fonts/
wget -nc https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip || true
wget -nc https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip || true
unzip -o Iosevka.zip -d ~/.local/share/fonts/
unzip -o RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# 3. Install Alacritty
echo "Installing Alacritty..."
wget -nc https://github.com/barnumbirr/alacritty-debian/releases/download/v0.10.0-rc4-1/alacritty_0.10.0-rc4-1_amd64_bullseye.deb || true
sudo dpkg -i alacritty_0.10.0-rc4-1_amd64_bullseye.deb || sudo apt install -f -y

# 4. Install Oh My Zsh (Unattended)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 4.1. Install Zsh Plugins
echo "Installing Zsh Plugins..."
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_CUSTOM_PLUGINS"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" || true

# 5. Install Pywal & Pywalfox
echo "Installing Pywal and Pywalfox..."
python3 -m pip install --user pywal16 pywalfox --break-system-packages
python3 -m pywalfox install

# 6. Sync Configs & Fix Permissions
echo "Syncing Config Files..."
mkdir -p ~/.config/i3 ~/.config/picom ~/.config/rofi ~/.config/alacritty ~/bin
mkdir -p ~/.config/sublime-text/Packages/User/
mkdir -p ~/.config/wal/templates

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

# 6.1. Clone i3blocks-contrib scripts
# i3blocks does NOT expand $HOME or custom shell variables in its config.
# Scripts must be referenced with absolute paths.
echo "Installing i3blocks-contrib scripts..."
if [ ! -d "$HOME/.config/i3blocks-scripts/.git" ]; then
    git clone https://github.com/vivien/i3blocks-contrib "$HOME/.config/i3blocks-scripts"
else
    git -C "$HOME/.config/i3blocks-scripts" pull || true
fi
# Ensure all scripts are executable
find "$HOME/.config/i3blocks-scripts" -name "*.sh" -exec chmod +x {} \;
find "$HOME/.config/i3blocks-scripts" -maxdepth 2 -type f ! -name "*.*" -exec chmod +x {} \;

# 6.2. Fix pywal i3blocks template with absolute paths
# The repo template uses __HOME__ as a placeholder since i3blocks
# does NOT expand $HOME or custom shell variables.
# Replace __HOME__ with the actual home directory path.
sed -i "s|__HOME__|$HOME|g" "$HOME/.config/wal/templates/i3blocks.conf"

# 7. Create Pywal Toggle Scripts (CORRECTED SYNC)
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    feh --bg-fill "$img_path"
    wal -i "$img_path" -n

    # Update Alacritty link
    ln -sf ~/.cache/wal/colors-alacritty.yml ~/.config/alacritty/colors-wal.yml

    # Sync Sublime Text
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

    # Update Firefox
    python3 -m pywalfox update

    # Merge Xresources and restart i3
    # wal already generated ~/.cache/wal/i3blocks.conf from the template
    # i3-msg restart will reload i3bar which re-reads the i3blocks config
    xrdb -merge ~/.cache/wal/colors.Xresources
    i3-msg restart

    echo "Pywal Enabled! Wallpaper, Alacritty, i3blocks, i3Bar, and Sublime synced."
else
    echo "Error: File not found!"
fi
EON

cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
ln -sf ~/.config/alacritty/colors-default.yml ~/.config/alacritty/colors-wal.yml
feh --bg-fill "$HOME/.wallpapers/23.jpg"
# Re-generate wal cache with the default wallpaper so i3blocks config still exists
wal -i "$HOME/.wallpapers/23.jpg" -n
xrdb -merge ~/.cache/wal/colors.Xresources
i3-msg restart
echo "Pywal Disabled (reset to default wallpaper)."
EOD

chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"

# 7.1. Create Wallpaper Picker Script (rofi-based)
cat << 'EOWP' > "$HOME/bin/wallpicker.sh"
#!/bin/bash
WALLDIR="$HOME/.wallpapers/Wallpaper-Bank/wallpapers"

# Pick a random wallpaper
img_path=$(find "$WALLDIR" -type f | shuf -n 1)

wal -i "$img_path"
ln -sf ~/.cache/wal/colors-alacritty.yml ~/.config/alacritty/colors-wal.yml
python3 -m pywalfox update 2>/dev/null
xrdb -merge ~/.cache/wal/colors.Xresources
i3-msg restart
EOWP
chmod +x "$HOME/bin/wallpicker.sh"

# 8. System Permissions (udisks2 auto-mount for Thunar / NTFS drives)
echo "Setting up system permissions..."
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

# 8.1. Touchpad - Enable tap-to-click, natural scrolling, disable-while-typing
echo "Configuring touchpad..."
sudo mkdir -p /etc/X11/xorg.conf.d/
cat <<EOF | sudo tee /etc/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
    Option "DisableWhileTyping" "on"
EndSection
EOF

# Ensure wal -R runs on every i3 start/reload to regenerate all configs
if ! grep -q "wal -R" ~/.config/i3/config; then
    echo "exec_always --no-startup-id wal -R" >> ~/.config/i3/config
fi

# 9. Finalize Zsh
echo "Finalizing Zsh Configuration..."
touch ~/.zsh_history
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
if ! grep -q "alias vmon" ~/.zshrc; then
    echo "alias vmon='~/bin/monitor_toggle.sh'" >> ~/.zshrc
    echo "alias py-on='~/bin/enable_pywal.sh'" >> ~/.zshrc
    echo "alias py-off='~/bin/disable_pywal.sh'" >> ~/.zshrc
    echo "alias wallpick='~/bin/wallpicker.sh'" >> ~/.zshrc
fi

# 10. Final Touches & Wallpaper
echo "Setting default wallpaper..."
if [ -f "$HOME/.wallpapers/23.jpg" ]; then
    feh --bg-fill "$HOME/.wallpapers/23.jpg"
    echo "feh --bg-fill '$HOME/.wallpapers/23.jpg'" > "$HOME/.fehbg"
    chmod +x "$HOME/.fehbg"
fi

# Apply Xresources mapping to i3 config if not present
if ! grep -q "set_from_resource" ~/.config/i3/config; then
cat << 'EOF' >> ~/.config/i3/config
# Set colors from Xresources (generated by pywal)
set_from_resource $term_background background #1C1D2B
set_from_resource $term_foreground foreground #EEEEEE
set_from_resource $color0 color0 #1C1D2B
set_from_resource $color1 color1 #82c8ff
set_from_resource $color2 color2 #82c8ff
set_from_resource $color3 color3 #82c8ff
set_from_resource $color4 color4 #82c8ff
set_from_resource $color5 color5 #82c8ff
set_from_resource $color6 color6 #82c8ff
set_from_resource $color7 color7 #dddddd
set_from_resource $color8 color8 #333333
EOF
fi

# Run wal once to generate all cached configs (including i3blocks.conf)
# before restarting i3, so i3bar has a valid config to read on first boot
if [ -f "$HOME/.wallpapers/23.jpg" ]; then
    wal -i "$HOME/.wallpapers/23.jpg" -n || true
fi

echo "Restarting i3..."
i3-msg restart || true

echo "DONE! Reboot and run 'py-on' to test your dynamic theme!"
echo ""
echo "How it works:"
echo "  - wal -R runs on every i3 start (exec_always in i3 config)"
echo "  - wal regenerates ~/.cache/wal/i3blocks.conf from the pywal template"
echo "  - i3bar reads i3blocks config from ~/.cache/wal/i3blocks.conf"
echo "  - All colors (i3bar, i3blocks, alacritty, sublime) auto-sync with your wallpaper"
