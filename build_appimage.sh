#!/bin/bash

set -e
set -x
# Function to install a repository with musl and custom binary name
install_client_multi() {
    local repo=$1
    local revision=$2
    local package_name=$3

    echo "Installing $repo with musl..."
    git clone "https://github.com/StardustXR/$repo.git" "$repo"
    local repo_dir="$repo"
    git -C "$repo_dir" checkout "$revision"

    # install resources
    if [ -d "$repo_dir/res" ]; then
        cp -r "$repo_dir/res"/* "Telescope.AppDir/usr/share/"
    fi

    # Check if it's a workspace or a single package
    if [ -f "$repo_dir/Cargo.toml" ] && grep -q '^\[workspace\]' "$repo_dir/Cargo.toml"; then
        # It's a workspace, assume the package is there
        repo_dir="$repo_dir/$package_name"
    fi

    cargo install --locked --path "$repo_dir" --target x86_64-unknown-linux-musl --root "Telescope.AppDir/usr"


    rm -rf "$repo"
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
    cargo install --locked --target x86_64-unknown-linux-gnu --git "https://github.com/StardustXR/server.git" --rev "$revision" --root "Telescope.AppDir/usr"
}

# Function to include system libraries in the AppImage
include_system_library() {
    local library=$1
    echo "Including system library: $library"
    cp -L $(ldconfig -p | grep "$library" | awk '{print $NF}' | head -n 1) "Telescope.AppDir/usr/lib/"
}

# Create AppDir structure
mkdir -p "Telescope.AppDir/usr/bin" "Telescope.AppDir/usr/lib" "Telescope.AppDir/usr/share"

# Include system libraries
# include_system_library "libxkbcommon.so.0"
# include_system_library "libstdc++.so.6"
# include_system_library "libopenxr_loader.so.1"
# include_system_library "libX11.so.6"
# include_system_library "libXfixes.so.3"
# include_system_library "libgbm.so.1"
# include_system_library "libfontconfig.so.1"
# include_system_library "libgcc_s.so.1"
# include_system_library "libjsoncpp.so.25"
# include_system_library "libxcb.so.1"
# include_system_library "libGLdispatch.so.0"
# include_system_library "libdrm.so.2"
# include_system_library "libwayland-server.so.0"
# include_system_library "libexpat.so.1"
# include_system_library "libxcb-randr.so.0"
# include_system_library "libfreetype.so.6"
# include_system_library "libxml2.so.2"
# include_system_library "libXau.so.6"
# include_system_library "libffi.so.8"
# include_system_library "libz.so.1"
# include_system_library "libbz2.so.1"
# include_system_library "libpng16.so.16"
# include_system_library "libharfbuzz.so.0"
# include_system_library "libbrotlidec.so.1"
# include_system_library "liblzma.so.5"
# include_system_library "libglib-2.0.so.0"
# include_system_library "libgraphite2.so.3"
# include_system_library "libbrotlicommon.so.1"
# include_system_library "libpcre2-8.so.0"

# Install server with glibc
install_server "71c30a05b87a8f23929ad380b3fa195b693bb4fa"

# Install clients with musl
install_client "flatland" "0914dd3df54a5e6258dfc0a02d65af1c0fc0fc90"
install_client_multi "protostar" "39499a061af74c3a2d5e1e46e4ad21aca5727219" "hexagon_launcher"
install_client "gravity" "96787ed3139717ea6061f6e259e9fed3e483274a"
install_client "black-hole" "0b847b6ddc383bfcc1e133a2238a37ce8202fe95"

# Create startup script
cat << EOF > "Telescope.AppDir/usr/bin/startup_script"
#!/bin/bash
export LD_LIBRARY_PATH="\$OLD_LD_LIBRARY_PATH"
# xwayland-satellite :10 &
# export DISPLAY=:10

\$TELESCOPE_PATH/flatland &
\$TELESCOPE_PATH/gravity -- 0 0.0 -0.5 \$TELESCOPE_PATH/hexagon_launcher &
\$TELESCOPE_PATH/black-hole &
EOF
chmod +x "Telescope.AppDir/usr/bin/startup_script"

# Create AppRun script
cat << EOF > "Telescope.AppDir/AppRun"
#!/bin/bash
export TELESCOPE_PATH="\$APPDIR/usr/bin"
export OLD_LD_LIBRARY_PATH="\$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="\$APPDIR/usr/lib:\$OLD_LD_LIBRARY_PATH"
export STARDUST_THEMES="\$APPDIR/usr/share"

\$TELESCOPE_PATH/stardust-xr-server -o 1 -e "\$TELESCOPE_PATH/startup_script" \$@
EOF
chmod +x "Telescope.AppDir/AppRun"

# Create desktop file
cat << EOF > "Telescope.AppDir/telescope.desktop"
[Desktop Entry]
Name=Telescope
Exec=AppRun
Icon=stardust
Type=Application
Categories=Utility;
EOF

# Download icon
wget https://raw.githubusercontent.com/StardustXR/assets/main/icon.png -O "Telescope.AppDir/stardust.png"

# Create tarball of AppDir
tar -czvf Telescope-x86_64.tar.gz Telescope.AppDir

# Create AppImage
./appimagetool "Telescope.AppDir" Telescope-x86_64.AppImage

echo "AppImage created: Telescope-x86_64.AppImage"
