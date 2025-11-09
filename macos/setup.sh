#!/bin/bash

CURRENT_DIR=$(pwd)

REPO_BASH_PROFILE_FILE_NAME="bash_profile"
REPO_BASH_PROFILE_FILE_PATH="${CURRENT_DIR}/${REPO_BASH_PROFILE_FILE_NAME}"

LOCAL_USER_BASH_PROFILE_DIR="${HOME}"
LOCAL_USER_BASH_PROFILE_FILE_NAME=".bash_profile"
LOCAL_USER_BASH_PROFILE_FILE_PATH="${LOCAL_USER_BASH_PROFILE_DIR}/${LOCAL_USER_BASH_PROFILE_FILE_NAME}"

BREW_PACKAGES_FILE_NAME="brew_packages.yaml"
BREW_PACKAGES_FILE_PATH="${CURRENT_DIR}/${BREW_PACKAGES_FILE_NAME}"

echo "Changing shell to bash"
chsh -s /bin/bash

echo "Setting up local user bash profile"
if [ -f "$FILE_PATH" ] && [ ! -L "$FILE_PATH" ]; then
    echo "..backing up existing bash profile"
    mv "$LOCAL_USER_BASH_PROFILE_FILE_PATH" "${LOCAL_USER_BASH_PROFILE_FILE_PATH}.bak"
fi

echo "..Linking bash_profile"
ln -sf "$REPO_BASH_PROFILE_FILE_PATH" "$LOCAL_USER_BASH_PROFILE_FILE_PATH"

echo "Setting homebrew"
if ! command -v brew &> /dev/null; then
    echo "! Error: brew not installed. Please install it first." >&2
    exit 1
fi

echo "Installing homebrew packages"
for package in $(yq '.packages[]' "$BREW_PACKAGES_FILE_PATH"); do
    echo "..Installing brew package: $package"
    brew install "$package"
done