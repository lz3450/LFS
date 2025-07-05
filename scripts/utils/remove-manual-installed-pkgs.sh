#!/bin/bash

# Path to the file containing the list of necessary packages
PKG_LIST_FILE="desktop-installed-pkgs-noble.txt"

# Ensure the package list file exists
if [[ ! -f "$PKG_LIST_FILE" ]]; then
    echo "Error: Package list file not found!"
    exit 1
fi

# Get the list of necessary packages from the file
NECESSARY_PKGS=$(awk '{print $1}' "$PKG_LIST_FILE")

# Get the list of all installed packages
INSTALLED_PKGS=$(dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64$//g')

# Find packages that are installed but not in the necessary package list
PKGS_TO_REMOVE=()
for pkg in $INSTALLED_PKGS; do
    if ! grep -Fxq "$pkg" "$PKG_LIST_FILE"; then
        PKGS_TO_REMOVE+=("$pkg")
    fi
done

# If no packages need to be removed, exit
if [[ ${#PKGS_TO_REMOVE[@]} -eq 0 ]]; then
    echo "No unnecessary packages found. System is clean."
    exit 0
fi

# Print the packages to be removed
echo "The following unnecessary packages will be removed:"
printf '%s\n' "${PKGS_TO_REMOVE[@]}" | tee manual-installed-pkgs-to-remove.txt

# Confirm before proceeding
read -p "Do you want to proceed with uninstalling these packages? (y/N) " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 0
fi

# Uninstall unnecessary packages
sudo apt-get remove --purge -y "${PKGS_TO_REMOVE[@]}"
sudo apt-get autoremove -y
sudo apt-get clean

echo "Unnecessary packages removed successfully."
