#!/usr/bin/env bash
# uninstall.sh — Removes Zalo AppImage and its desktop integration.
# Gear Lever and Flatpak are left in place (may be used by other apps).
#
# Usage:
#   wget -qO- https://raw.githubusercontent.com/phungtd/zlu/main/uninstall.sh | bash

set -euo pipefail

GEARLEVER_APP_ID="it.mijorus.gearlever"

log()  { echo -e "==> $*"; }
warn() { echo -e "!!  $*" >&2; }

log "Looking up Zalo in Gear Lever..."
ZALO_PATH=$(flatpak run "$GEARLEVER_APP_ID" --list-installed 2>/dev/null | grep -i "zalo" | awk '{print $NF}')

if [ -z "$ZALO_PATH" ]; then
  warn "Zalo not found in Gear Lever -- may already be removed."
else
  log "Found at: $ZALO_PATH"
  log "Removing Gear Lever integration..."
  if { yes || true; } 2>/dev/null | flatpak run "$GEARLEVER_APP_ID" --remove "$ZALO_PATH"; then
    log "Desktop integration and AppImage removed."
  else
    warn "Gear Lever removal failed -- removing AppImage manually..."
    rm -f "$ZALO_PATH"
    log "Removed $ZALO_PATH."
  fi
fi

log "Done! Zalo has been uninstalled."
