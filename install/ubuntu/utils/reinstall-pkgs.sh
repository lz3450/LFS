#!/bin/bash

# Path to the file containing the list of necessary packages
PKG_LIST_FILE="desktop-installed-pkgs-noble.txt"

# Ensure the package list file exists
if [[ ! -f "$PKG_LIST_FILE" ]]; then
    echo "Error: Package list file not found!"
    exit 1
fi

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Read necessary packages from file
NECESSARY_PKGS=($(awk '{print $1}' "$PKG_LIST_FILE"))

# Arrays to store packages by installation state
MANUAL_PKGS=()
AUTO_PKGS=()

# Check installation states and store them in respective arrays
for pkg in "${NECESSARY_PKGS[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2> /dev/null | grep -q "install ok installed"; then
        if apt-mark showmanual | grep -q "^$pkg$"; then
            MANUAL_PKGS+=("$pkg")
        else
            AUTO_PKGS+=("$pkg")
        fi
    fi
done

# Reinstall necessary packages
echo "Reinstalling necessary packages..."
sudo apt-get install --reinstall -y "${NECESSARY_PKGS[@]}"

# Restore package installation states
if [[ ${#MANUAL_PKGS[@]} -gt 0 ]]; then
    echo "Restoring manual package states..."
    sudo apt-mark manual "${MANUAL_PKGS[@]}"
fi

if [[ ${#AUTO_PKGS[@]} -gt 0 ]]; then
    echo "Restoring auto package states..."
    sudo apt-mark auto "${AUTO_PKGS[@]}"
fi

echo "Reinstallation complete with preserved installation states."
