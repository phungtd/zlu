#!/usr/bin/env bash
# uninstall.sh — Removes Zalo AppImage and its desktop integration.
# Gear Lever and Flatpak are left in place (may be used by other apps).
#
# Usage:
#   wget -qO- https://raw.githubusercontent.com/phungtd/zlu/main/uninstall.sh | bash

set -euo pipefail

APPIMAGE_NAME="Zalo-26.6.11+ZaDark-26.2-0af5695.AppImage"
DEST_DIR="$HOME/Applications"
GEARLEVER_APP_ID="it.mijorus.gearlever"

log()  { echo -e "==> $*"; }
warn() { echo -e "!!  $*" >&2; }

log "Removing Gear Lever integration..."
if { yes || true; } 2>/dev/null | flatpak run "$GEARLEVER_APP_ID" --remove "$DEST_DIR/$APPIMAGE_NAME"; then
  log "Desktop integration removed."
else
  warn "Gear Lever removal failed or app was not integrated -- continuing."
fi

log "Removing AppImage..."
if [ -f "$DEST_DIR/$APPIMAGE_NAME" ]; then
  rm -f "$DEST_DIR/$APPIMAGE_NAME"
  log "Removed $DEST_DIR/$APPIMAGE_NAME."
else
  warn "AppImage not found at $DEST_DIR/$APPIMAGE_NAME -- skipping."
fi

log "Done! Zalo has been uninstalled."
