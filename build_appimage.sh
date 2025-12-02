#!/bin/bash

set -e
set -x
# Function to install a repository with musl and custom binary name
install_client_multi() {
    local repo=$1
    local package_name=$2
    local revision=$3

    echo "Installing $repo with musl..."
    git clone "https://github.com/StardustXR/$repo.git" "$repo"
    local repo_dir="$repo"
		if [ "$revision" ]; then
			git -C "$repo_dir" checkout "$revision"
		fi

    # install resources
    if [ -d "$repo_dir/res" ]; then
        cp -r "$repo_dir/res"/* "Telescope.AppDir/usr/share/"
    fi

    # Check if it's a workspace or a single package
    if [ -f "$repo_dir/Cargo.toml" ] && grep -q '^\[workspace\]' "$repo_dir/Cargo.toml"; then
        # It's a workspace, assume the package is there
        repo_dir="$repo_dir/$package_name"
    fi

    cargo install --locked --path "$repo_dir" --root "Telescope.AppDir/usr"

    rm -rf "$repo"
}
# Function to install a repository with musl
install_client() {
    local repo=$1
    local revision=$2
		if [ -n "$revision" ]; then
			install_client_multi "$repo" "${repo//-/_}" "$revision"
		else
			install_client_multi "$repo" "${repo//-/_}"
		fi
}

# Function to install the server with glibc
install_server() {
    local revision=$1

    echo "Installing server with glibc..."
		if [ -z "$revision" ]; then
			cargo install --locked --git "https://github.com/StardustXR/server.git" --root "Telescope.AppDir/usr"
		else
			cargo install --locked --git "https://github.com/StardustXR/server.git" --rev "$revision" --root "Telescope.AppDir/usr"
		fi
}

# Function to include system libraries in the AppImage
include_system_library() {
    local library=$1
    echo "Including system library: $library"
    cp -L $(ldconfig -p | grep "$library" | awk '{print $NF}' | head -n 1) "Telescope.AppDir/usr/lib/"
}

# Create AppDir structure
# takes less code to just have the thing there
cp -rf AppDir Telescope.AppDir

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
install_server

# Install clients with musl
install_client "flatland" 
install_client_multi "protostar" "hexagon_launcher"
install_client "gravity"
install_client "black-hole"
install_client "solar-sailer"

install_client_multi "non-spatial-input" "manifold"
install_client_multi "non-spatial-input" "simular"

cargo install --locked --git "https://github.com/Supreeeme/xwayland-satellite" --rev "v0.7" --root "Telescope.AppDir/usr"


# Create tarball of AppDir
tar -czvf Telescope-x86_64.tar.gz Telescope.AppDir

# Create AppImage
if [ ! -e "./appimagetool" ]; then
	wget https://github.com/AppImage/appimagetool/releases/download/1.9.0/appimagetool-x86_64.AppImage -O appimagetool
	chmod u+x appimagetool
fi

./appimagetool "Telescope.AppDir" Telescope-x86_64.AppImage

echo "AppImage created: Telescope-x86_64.AppImage"
