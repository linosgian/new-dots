#!/usr/bin/env bash

# Get script name
SCRIPT_NAME="$(basename "$0")"

# Set dotfiles directory
DOTFILES_DIR="$PWD"

# Ensure the dotfiles directory exists
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Error: $DOTFILES_DIR does not exist."
    exit 1
fi

# Symlink entire .config subdirectories instead of individual files
find "$DOTFILES_DIR/.config" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    rel_path="${dir#$DOTFILES_DIR/}"
    target="$HOME/$rel_path"

    # Remove existing directory or symlink
    if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
    fi
    # Create symlink
    ln -s "$dir" "$target"
    echo "Symlinked: $target -> $dir"
done

# Symlink files in the root of dotfiles directory
find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type f | while read -r file; do
    rel_path="${file#$DOTFILES_DIR/}"
    target="$HOME/$rel_path"

    # Skip the script itself
    if [[ "$target" == "$HOME/$SCRIPT_NAME" ]]; then
        continue
    fi

    # Remove existing directory or symlink
    if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
    fi

    # Create symlink
    ln -s "$file" "$target"
    echo "Symlinked: $target -> $file"
done
