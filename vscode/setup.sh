#!/bin/bash

CURRENT_DIR=$(pwd)

REPO_SETTINGS_FILE_NAME="settings.json"
REPO_SETTINGS_FILE_PATH="${CURRENT_DIR}/${REPO_SETTINGS_FILE_NAME}"

LOCAL_USER_SETTINGS_DIR="${HOME}/Library/Application\ Support/Code/User/"
LOCAL_USER_SETTINGS_FILE_NAME="settings.json"
LOCAL_USER_SETTINGS_FILE_PATH="${LOCAL_USER_SETTINGS_DIR}/${LOCAL_USER_SETTINGS_FILE_NAME}"

EXTENSIONS_SUB_DIR="extensions"
EXTENSIONS_FULL_DIR="${CURRENT_DIR}/${EXTENSIONS_SUB_DIR}"
EXTENSIONS_EXTERNAL_FILE_NAME="external.yaml"
EXTENSIONS_EXTERNAL_FILE_PATH="${EXTENSIONS_FULL_DIR}/${EXTENSIONS_EXTERNAL_FILE_NAME}"

if ! command -v code &> /dev/null; then
    echo "Error: VS Code is not installed. Please install it first." >&2
    exit 1
fi

echo "Installing local extensions"
for vsix_file in "$EXTENSIONS_FULL_DIR"/*/*.vsix; do
    if [[ -f "$vsix_file" ]]; then
        echo "..Installing extension: $vsix_file"
        code --install-extension "$vsix_file"
    fi
done

if ! command -v yq &> /dev/null; then
    echo "Error: yq not installed. Please install it first." >&2
    exit 1
fi

echo "Installing external extensions"
for extension in $(yq '.extensions[]' "$EXTENSIONS_EXTERNAL_FILE_PATH"); do
    echo "..Installing VS Code extension: $extension"
    code --install-extension "$extension"
done

echo "Setting up local user settings"
mkdir -p "$LOCAL_USER_SETTINGS_DIR"

if [[ -f "$LOCAL_USER_SETTINGS_FILE_PATH" ]]; then
    echo "..backing up existing settings file"
    mv "$LOCAL_USER_SETTINGS_FILE_PATH" "${LOCAL_USER_SETTINGS_FILE_PATH}.bak"
fi

echo "..Linking settings.json"
ln -sf "$REPO_SETTINGS_FILE_PATH" "$LOCAL_USER_SETTINGS_FILE_PATH"