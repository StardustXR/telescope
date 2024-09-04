#!/bin/bash

set -e
set -x
# Function to install a repository with musl and custom binary name
install_client_multi() {
    local repo=$1
    local revision=$2
    local package_name=$3

    echo "Installing $repo with musl..."
    git clone "https://github.com/StardustXR/$repo.git" "$BUILD_DIR/$repo"
    local repo_dir="$BUILD_DIR/$repo"
    git -C "$repo_dir" checkout "$revision"

    # Check if it's a workspace or a single package
    if [ -f "$repo_dir/Cargo.toml" ] && grep -q '^\[workspace\]' "$repo_dir/Cargo.toml"; then
        # It's a workspace, assume the package is there
        repo_dir="$repo_dir/$package_name"
    fi

    cargo install --path "$repo_dir" --target x86_64-unknown-linux-musl --root "$BUILD_DIR/Telescope.AppDir/usr"

    # install resources
    if [ -d "$repo_dir/res" ]; then
        mkdir -p "$BUILD_DIR/Telescope.AppDir/usr/share"
        cp -r "$repo_dir/res"/* "$BUILD_DIR/Telescope.AppDir/usr/share/"
    fi

    rm -rf "$BUILD_DIR/$repo"
}

# Function to install a repository with musl
install_client() {
    local repo=$1
    local revision=$2
    install_client_multi "$repo" "$revision" "${repo//-/_}"
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
install_client "flatland" "d2b0b6c83f4a52cf4206a04df7c4aa941fb6ae8b"
install_client_multi "protostar" "39499a061af74c3a2d5e1e46e4ad21aca5727219" "hexagon_launcher"
install_client "gravity" "96787ed3139717ea6061f6e259e9fed3e483274a"
install_client "black-hole" "875603d95bee7c4eb41a6aa7e16e3d5827e2098d"

# Create startup script
cat << EOF > "$BUILD_DIR/Telescope.AppDir/usr/bin/startup_script"
#!/bin/bash
# xwayland-satellite :10 &
# export DISPLAY=:10
# sleep 0.1

flatland &
gravity -- 0 0.0 -0.5 hexagon_launcher &
black_hole &
EOF
chmod +x "$BUILD_DIR/Telescope.AppDir/usr/bin/startup_script"

# Create AppRun script
cat << EOF > "$BUILD_DIR/Telescope.AppDir/AppRun"
#!/bin/bash
# Set up environment variables
export PATH="\$APPDIR/usr/bin:\$PATH"
export XDG_DATA_DIRS="\$APPDIR/usr/share:\$XDG_DATA_DIRS"
export STARDUST_THEMES="\$APPDIR/usr/share"
stardust-xr-server -o 1 -e "\$APPDIR/usr/bin/startup_script" "\$@"
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

# Create AppImage
./appimagetool "$BUILD_DIR/Telescope.AppDir" Telescope-x86_64.AppImage

# Clean up
rm -rf "$BUILD_DIR"

echo "AppImage created: Telescope-x86_64.AppImage"
