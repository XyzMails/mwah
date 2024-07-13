#!/bin/bash

# mwah - an AUR package manager

# Function to show usage
usage() {
    echo "[mwah]: usage: $0 -S <package> | -R <package> | -C"
    exit 1
}

# Function to install package from AUR
install_package() {
    local pkgname=$1

    # Print installation message
    echo "[mwah]: installing package: $pkgname"

    # Install dependencies
    echo "[mwah]: installing dependencies: base-devel, git, pv"
    sudo pacman -S --needed base-devel git pv --noconfirm

    # Check if package exists on AUR
    aur_url="https://aur.archlinux.org/${pkgname}.git"
    echo "[mwah]: checking if package exists at $aur_url"
    package_info=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=${pkgname}")
    if [[ $(echo "$package_info" | jq -r '.resultcount') -eq 0 ]]; then
        echo "[mwah]: package ${pkgname} not found in AUR."
        exit 1
    fi

    # Confirm installation
    read -p "[mwah]: package ${pkgname} found in AUR. Do you want to install it? [y/n]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "[mwah]: installation aborted."
        exit 0
    fi

    # Check if directory already exists
    if [ -d "$pkgname" ]; then
        read -p "[mwah]: The directory '${pkgname}' already exists. Do you want to overwrite it? This will delete all existing files. [y/n]: " overwrite_confirm
        if [[ $overwrite_confirm =~ ^[Yy]$ ]]; then
            echo "[mwah]: Removing existing directory '${pkgname}'..."
            rm -rf "$pkgname"
        else
            echo "[mwah]: installation aborted."
            exit 0
        fi
    fi

    # Download and prepare to install
    echo "[mwah]: downloading and preparing to install ${pkgname}..."

    # Clone the repository
    echo "[mwah]: cloning repository from $aur_url"
    git clone ${aur_url}
    if [ $? -ne 0 ]; then
        echo "[mwah]: failed to clone AUR package repository."
        exit 1
    fi
    
    cd ${pkgname} || exit

    # Check if PKGBUILD exists
    if [ ! -f PKGBUILD ]; then
        echo "[mwah]: PKGBUILD does not exist in the cloned repository."
        cd ..
        rm -rf ${pkgname}
        exit 1
    fi

    # Build and install the package
    echo "[mwah]: building the package..."
    makepkg -si --noconfirm
    if [ $? -ne 0 ]; then
        echo "[mwah]: failed to build and install the package."
        cd ..
        rm -rf ${pkgname}
        exit 1
    fi
    
    # Clean up
    cd ..
    rm -rf ${pkgname}
    
    echo "[mwah]: package ${pkgname} installed successfully!"
}

# Function to remove a package
remove_package() {
    local pkgname=$1

    # Print removal message
    echo "[mwah]: removing package: $pkgname"

    # Confirm removal
    read -p "[mwah]: are you sure you want to remove ${pkgname}? [y/n]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "[mwah]: removal aborted."
        exit 0
    fi

    # Perform removal using pacman
    sudo pacman -R ${pkgname} --noconfirm
    if [ $? -ne 0 ]; then
        echo "[mwah]: failed to remove the package ${pkgname}."
        exit 1
    fi
    
    echo "[mwah]: package ${pkgname} removed successfully!"
}

# Function to clear cloned repositories
clear_repositories() {
    echo "[mwah]: clearing cloned repositories..."
    for dir in [a-zA-Z]*; do
        if [ -d "$dir" ]; then
            echo "[mwah]: removing directory '$dir'..."
            rm -rf "$dir"
        fi
    done
    echo "[mwah]: cloned repositories cleared."
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# Parse options
while getopts ":S:R:C" opt; do
    case ${opt} in
        S)
            package=${OPTARG}
            install_package ${package}
            ;;
        R)
            package=${OPTARG}
            remove_package ${package}
            ;;
        C)
            clear_repositories
            ;;
        *)
            usage
            ;;
    esac
done


