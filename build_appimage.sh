#!/bin/bash

set -e
set -x

# Function to install a repository with musl
install_musl() {
    local repo=$1
    local revision=$2
    local binary_name=${repo//-/_}  # Replace hyphens with underscores

    echo "Installing $repo with musl..."
    cargo install --git "https://github.com/StardustXR/$repo.git" --rev "$revision" --target x86_64-unknown-linux-musl --root "$BUILD_DIR/Telescope.AppDir/usr"
}

# Function to install the server with glibc
install_server() {
    local revision=$1

    echo "Installing server with glibc..."
    cargo install --git "https://github.com/StardustXR/server.git" --rev "$revision" --root "$BUILD_DIR/Telescope.AppDir/usr"
}

# Create a temporary build directory
BUILD_DIR=$(mktemp -d)

# Create AppDir structure
mkdir -p "$BUILD_DIR/Telescope.AppDir/usr/bin" "$BUILD_DIR/Telescope.AppDir/usr/lib"

# Install server with glibc
install_server "499aa2be28be546287bf228e8edc3643b09e4016"

# Install clients with musl
install_musl "flatland" "d2b0b6c83f4a52cf4206a04df7c4aa941fb6ae8b"
cargo install --git "https://github.com/StardustXR/protostar.git" --rev "39499a061af74c3a2d5e1e46e4ad21aca5727219" --target x86_64-unknown-linux-musl --root "$BUILD_DIR/Telescope.AppDir/usr" hexagon_launcher
install_musl "gravity" "96787ed3139717ea6061f6e259e9fed3e483274a"
install_musl "black-hole" "875603d95bee7c4eb41a6aa7e16e3d5827e2098d"

# Create startup script
cat << EOF > "$BUILD_DIR/Telescope.AppDir/usr/bin/startup_script"
#!/bin/bash
xwayland-satellite :10 &
export DISPLAY=:10
sleep 0.1

flatland &
gravity -- 0 0.0 -0.5 hexagon_launcher &
black_hole &
EOF
chmod +x "$BUILD_DIR/Telescope.AppDir/usr/bin/startup_script"

# Create AppRun script
cat << EOF > "$BUILD_DIR/Telescope.AppDir/AppRun"
#!/bin/bash
exec stardust-xr-server -o 1 -e "/usr/bin/startup_script" "\$@"
EOF
chmod +x "$BUILD_DIR/Telescope.AppDir/AppRun"

# Create desktop file
cat << EOF > "$BUILD_DIR/Telescope.AppDir/telescope.desktop"
[Desktop Entry]
Name=Telescope
Exec=AppRun
Icon=stardust
Type=Application
Categories=Utility;
EOF

# Download icon
wget https://raw.githubusercontent.com/StardustXR/assets/main/icon.png -O "$BUILD_DIR/Telescope.AppDir/stardust.png"

# Remove hard-coded paths
cd "$BUILD_DIR/Telescope.AppDir/usr/"
find . -type f -exec sed -i -e 's#/usr#././#g' {} \;
cd -

# Validate desktop file
desktop-file-validate "$BUILD_DIR/Telescope.AppDir/telescope.desktop"

# Create AppImage
./appimagetool "$BUILD_DIR/Telescope.AppDir" Telescope-x86_64.AppImage

# Clean up
rm -rf "$BUILD_DIR"

echo "AppImage created: Telescope-x86_64.AppImage"
