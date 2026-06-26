#!/usr/bin/env bash
# install.sh
# Installs Flatpak + Gear Lever, downloads the ZaDark Zalo AppImage,
# and integrates it into the system menu. Fully non-interactive.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/phungtd/zlu/main/install.sh | bash
#   wget -qO- https://raw.githubusercontent.com/phungtd/zlu/main/install.sh | bash

set -euo pipefail

APPIMAGE_URL="https://github.com/doandat943/zalo-for-linux/releases/download/26.6.11/Zalo-26.6.11+ZaDark-26.2-0af5695.AppImage"
APPIMAGE_NAME="Zalo-26.6.11+ZaDark-26.2-0af5695.AppImage"
DEST_DIR="$HOME/Applications"

log() { echo -e "==> $*"; }

# Re-exec under sudo if not root, so apt/flatpak system install works
# without prompting mid-script (still asks once for sudo password).
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

log "Updating package lists..."
$SUDO apt-get update -y

log "Installing Flatpak..."
if ! command -v flatpak >/dev/null 2>&1; then
  $SUDO apt-get install -y flatpak
else
  log "Flatpak already installed, skipping."
fi

log "Adding Flathub remote (if missing)..."
$SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Installing Gear Lever (it.mijorus.gearlever)..."
$SUDO flatpak install -y --noninteractive flathub it.mijorus.gearlever

log "Preparing download directory: $DEST_DIR"
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

log "Downloading Zalo AppImage..."
wget -q --show-progress -O "$APPIMAGE_NAME" "$APPIMAGE_URL"
chmod +x "$APPIMAGE_NAME"

log "Integrating with Gear Lever..."
flatpak run it.mijorus.gearlever --integrate "$DEST_DIR/$APPIMAGE_NAME"

log "Done! Zalo AppImage installed at: $DEST_DIR/$APPIMAGE_NAME"
log "You should now find it in your application menu."
