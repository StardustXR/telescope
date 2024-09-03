#!/bin/bash

set -e
set -x

# Function to clone and build a repository with musl
clone_and_build_musl() {
    local repo=$1
    local revision=$2
    local binary_name=${repo//-/_}  # Replace hyphens with underscores

    echo "Building $repo with musl..."
    git clone "https://github.com/StardustXR/$repo.git"
    cd "$repo"
    git checkout "$revision"
    cargo build --release --target x86_64-unknown-linux-musl
    cp "target/x86_64-unknown-linux-musl/release/$binary_name" "$BUILD_DIR/AppDir/usr/bin/"
    cd ..
}

# Function to clone and build the server with glibc
clone_and_build_server() {
    local revision=$1

    echo "Building server with glibc..."
    git clone "https://github.com/StardustXR/server.git"
    cd server
    git checkout "$revision"
    cargo build --release
    cp "target/release/server" "$BUILD_DIR/AppDir/usr/bin/stardust-xr-server"
    cd ..
}

# Create a temporary build directory
BUILD_DIR=$(mktemp -d)
cd "$BUILD_DIR"

# Create AppDir structure
mkdir -p AppDir/usr/bin AppDir/usr/lib

# Clone and build server with glibc
clone_and_build_server "499aa2be28be546287bf228e8edc3643b09e4016"

# Clone and build clients with musl
clone_and_build_musl "flatland" "d2b0b6c83f4a52cf4206a04df7c4aa941fb6ae8b"
clone_and_build_musl "protostar" "39499a061af74c3a2d5e1e46e4ad21aca5727219"
clone_and_build_musl "gravity" "96787ed3139717ea6061f6e259e9fed3e483274a"
clone_and_build_musl "black-hole" "875603d95bee7c4eb41a6aa7e16e3d5827e2098d"

# Create startup script
cat << EOF > AppDir/usr/bin/startup_script
#!/bin/bash
xwayland-satellite :10 &
export DISPLAY=:10
sleep 0.1

flatland &
gravity -- 0 0.0 -0.5 hexagon_launcher &
black_hole &
EOF
chmod +x AppDir/usr/bin/startup_script

# Create AppRun script
cat << EOF > AppDir/AppRun
#!/bin/bash
exec stardust-xr-server -o 1 -e "/usr/bin/startup_script" "\$@"
EOF
chmod +x AppDir/AppRun

# Create desktop file
cat << EOF > AppDir/stardust-xr.desktop
[Desktop Entry]
Name=Stardust XR
Exec=AppRun
Icon=stardust-xr
Type=Application
Categories=Utility;
EOF

# Create icon (you may want to replace this with an actual icon)
echo "P1 1 1 1" > AppDir/stardust-xr.pbm

# Build AppImage
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage

# Move AppImage to the original directory
mv Stardust_XR-x86_64.AppImage ..

# Clean up
cd ..
rm -rf "$BUILD_DIR"

echo "AppImage created: Stardust_XR-x86_64.AppImage"
