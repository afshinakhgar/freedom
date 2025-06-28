#!/bin/bash

# Create directory for .deb files
DEBS_DIR="/Users/afshinakhgar/Projects/iranazad/debs"
mkdir -p "$DEBS_DIR"
cd "$DEBS_DIR"

# Base URLs for Ubuntu 22.04 (Jammy) repositories
BASE_URL="http://security.ubuntu.com/ubuntu/pool"
ARCHIVE_URL="http://archive.ubuntu.com/ubuntu/pool"
OLD_RELEASES_URL="http://old-releases.ubuntu.com/ubuntu/pool"

# List of corrupted packages with updated URLs
packages=(
    "libatomic1 main/g/gcc-11/libatomic1_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libc6-dev main/g/glibc/libc6-dev_2.35-0ubuntu3.8_amd64.deb $ARCHIVE_URL"
    "libcc1-0 main/g/gcc-11/libcc1-0_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libc-dev-bin main/g/glibc/libc-dev-bin_2.35-0ubuntu3.8_amd64.deb $ARCHIVE_URL"
    "libc-devtools main/g/glibc/libc-devtools_2.35-0ubuntu3.8_amd64.deb $ARCHIVE_URL"
    "libgd3 main/libg/libgd3/libgd3_2.3.0-2ubuntu2_amd64.deb $ARCHIVE_URL"
    "libgomp1 main/g/gcc-11/libgomp1_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libisl23 main/libi/libisl/libisl23_0.24-2build1_amd64.deb $ARCHIVE_URL"
    "libitm1 main/g/gcc-11/libitm1_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libjbig0 main/libj/libjbig/libjbig0_2.1-3.1ubuntu0.22.04.1_amd64.deb $ARCHIVE_URL"
    "liblsan0 main/g/gcc-11/liblsan0_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libmpc3 main/m/mpc/libmpc3_1.2.1-2build1_amd64.deb $ARCHIVE_URL"
    "libquadmath0 main/g/gcc-11/libquadmath0_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "libtiff5 main/libt/libtiff/libtiff5_4.3.0-6ubuntu0.10_amd64.deb $ARCHIVE_URL"
    "libubsan1 main/g/gcc-11/libubsan1_11.4.0-1ubuntu1~22.04_amd64.deb $BASE_URL"
    "linux-headers-5.15.0-116-generic main/l/linux/linux-headers-5.15.0-116-generic_5.15.0-116.136_amd64.deb $ARCHIVE_URL"
    "linux-libc-dev main/l/linux/linux-libc-dev_5.15.0-116.136_amd64.deb $ARCHIVE_URL"
    "lto-disabled-list main/g/gcc-defaults/lto-disabled-list_0.56ubuntu1_all.deb $ARCHIVE_URL"
    "resolvconf universe/r/resolvconf/resolvconf_1.91ubuntu1_all.deb $ARCHIVE_URL"
    "wireguard-dkms universe/w/wireguard/wireguard-dkms_1.0.20210606-1_all.deb $ARCHIVE_URL"
    "wireguard-tools universe/w/wireguard/wireguard-tools_1.0.20210914-1ubuntu2_amd64.deb $ARCHIVE_URL"
)

# Function to download .deb file
download_deb() {
    local pkg="$1"
    local url_path="$2"
    local base_url="$3"
    local full_url="${base_url}/${url_path}"
    echo "Downloading $pkg from $full_url..."
    wget "$full_url" -O "${pkg}.deb" || {
        echo "Failed to download $pkg from $full_url"
        # Try old-releases if main archive fails
        local old_url="${OLD_RELEASES_URL}/${url_path}"
        echo "Trying $old_url..."
        wget "$old_url" -O "${pkg}.deb" || {
            echo "Failed to download $pkg from $old_url"
            return 1
        }
    }
    echo "$pkg downloaded successfully."
    return 0
}

# Download all packages
for pkg_entry in "${packages[@]}"; do
    pkg_name=$(echo "$pkg_entry" | awk '{print $1}')
    url_path=$(echo "$pkg_entry" | awk '{print $2}')
    base_url=$(echo "$pkg_entry" | awk '{print $3}')
    download_deb "$pkg_name" "$url_path" "$base_url"
done

echo "Download complete. Files are in $DEBS_DIR"
echo "Please transfer these files to /opt/iranazad/debs/ on the Iran server."
