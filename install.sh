#!/bin/bash
set -e

echo "🚀 Starting Full i3-Gaps & Pywal Setup..."

# 1️⃣ Update & Install System Dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git thunar arandr flameshot arc-theme feh i3blocks \
    i3status i3 lxappearance python3-pip rofi unclutter cargo picom \
    papirus-icon-theme imagemagick unzip zsh

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

# 3️⃣ Install Alacritty (Debian package)
echo "🖥️ Installing Alacritty..."
wget -nc https://github.com/barnumbirr/alacritty-debian/releases/download/v0.10.0-rc4-1/alacritty_0.10.0-rc4-1_amd64_bullseye.deb
sudo dpkg -i alacritty_0.10.0-rc4-1_amd64_bullseye.deb || sudo apt install -f -y

# 4️⃣ Install Oh My Zsh (Unattended)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 5️⃣ Install Pywal & Pywalfox
echo "🐍 Installing Pywal and Pywalfox..."
python3 -m pip install --user pywal16 pywalfox --break-system-packages
python3 -m pywalfox install

# 6️⃣ Copy Configs & Setup Scripts
echo "⚙️ Syncing Config Files..."
mkdir -p ~/.config/i3 ~/.config/picom ~/.config/rofi ~/.config/alacritty ~/bin

# Copy from your repo to $HOME
cp -r .config/* ~/.config/
cp .zshrc ~/.zshrc
cp -r .wallpapers ~/.wallpapers

# 7️⃣ Create Pywal Toggle Scripts (Fixed Logic)
cat << 'EON' > "$HOME/bin/enable_pywal.sh"
#!/bin/bash
read -p "Enter wallpaper path: " img_path
if [ -f "$img_path" ]; then
    feh --bg-fill "$img_path"
    wal -i "$img_path" -n
    python3 -m pywalfox update
    echo "✔ Pywal Enabled!"
else
    echo "✘ Error: File not found!"
fi
EON

cat << 'EOD' > "$HOME/bin/disable_pywal.sh"
#!/bin/bash
rm -rf "$HOME/.cache/wal/"*
feh --bg-fill "$HOME/.wallpapers/wallpaper.jpg"
python3 -m pywalfox update 2>/dev/null
reset
echo "✔ Pywal Disabled."
EOD

chmod +x "$HOME/bin/enable_pywal.sh" "$HOME/bin/disable_pywal.sh"
chmod +x ~/.config/i3/clipboard_fix.sh

# 8️⃣ Final Touches
i3-msg reload || true

echo "✅ DONE! REBOOT and then:"
echo "1. Select i3 at login."
echo "2. Run lxappearance to set Arc-Dark icons/theme."
echo "3. Run 'py-on' to set your first dynamic theme!"
