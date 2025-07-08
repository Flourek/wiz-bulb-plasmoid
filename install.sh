#!/bin/bash

# WiZ Smart Bulb Control - KDE Plasma Widget Installer
# Installs the widget to the user's local Plasma widgets directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_ID="org.kde.plasma.wizcontrol"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"

echo "Installing WiZ Smart Bulb Control widget..."

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$INSTALL_DIR")"

# Remove existing installation if present
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_DIR"
fi

# Copy the plasmoid files
echo "Copying widget files..."
cp -r "$SCRIPT_DIR/plasmoid" "$INSTALL_DIR"

echo "Widget installed successfully to: $INSTALL_DIR"
echo ""
echo "To activate the widget:"
echo "1. Restart Plasma Shell: kquitapp6 plasmashell && kstart plasmashell"
echo "2. Right-click on panel/desktop → 'Add Widgets...'"
echo "3. Search for 'WiZ Smart Bulb Control'"
echo "4. Add to panel or desktop"
echo ""
echo "The widget will automatically discover WiZ bulbs on your network."
