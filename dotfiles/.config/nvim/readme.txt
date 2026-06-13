# create neovide desktop entry when build from sources
## Create / edit the desktop entry
vim ~/.local/share/applications/neovide.desktop
Replace YOUR_USERNAME with your actual username.

[Desktop Entry]
Type=Application
Name=Neovide
GenericName=Neovim GUI
Comment=Neovim client in Rust
Exec=/home/YOUR_USERNAME/.cargo/bin/neovide %F
TryExec=/home/YOUR_USERNAME/.cargo/bin/neovide
Icon=neovide
Terminal=false
Categories=Development;TextEditor;
StartupNotify=true
StartupWMClass=neovide

## Install the icon (user-local, no sudo)

From the Neovide source directory:

mkdir -p ~/.local/share/icons/hicolor/256x256/apps
cp assets/neovide-256x256.png ~/.local/share/icons/hicolor/256x256/apps/neovide.png

Then update caches:

update-desktop-database ~/.local/share/applications
gtk-update-icon-cache ~/.local/share/icons/hicolor

## Restart your desktop session

Log out and log back in (or restart GNOME Shell).
