#!/bin/bash

# shellcheck source=../_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh" "$@"

echo ""
echo "Setting up Homebrew"
BREW_PACKAGES_FILE_PATH="$REPO_DIR/homebrew/brew_packages.yaml"

if ! command -v brew &> /dev/null; then
    echo "! Error: brew not installed. Please install it first." >&2
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo "..yq not found, installing via brew"
    brew install yq
fi

if [[ ! -f "$BREW_PACKAGES_FILE_PATH" ]]; then
    echo "..No brew_packages.yaml found, skipping"
    exit 0
fi

echo "Installing homebrew packages"
for package in $(yq '.packages[]' "$BREW_PACKAGES_FILE_PATH"); do
    echo "..Installing brew package: $package"
    brew install "$package"
done

echo "Installing homebrew casks"
for cask in $(yq '.casks[]' "$BREW_PACKAGES_FILE_PATH"); do
    echo "..Installing brew cask: $cask"
    brew install --cask "$cask"
done
