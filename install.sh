#!/usr/bin/env bash
# install.sh — Installs Flatpak + Gear Lever, downloads the ZaDark Zalo AppImage,
# and integrates it into the system menu. Fully non-interactive.
#
# Usage (recommended — exports XDG_DATA_DIRS into your current shell):
#   . <(wget -qO- https://raw.githubusercontent.com/phungtd/zlu/main/install.sh)
#
# Alternative (XDG_DATA_DIRS won't persist in current shell):
#   wget -qO- https://raw.githubusercontent.com/phungtd/zlu/main/install.sh | bash

set -euo pipefail

# When sourced, 'exit' would kill the terminal; use 'return' instead.
# Also restore shell options on exit so sourcing doesn't pollute the parent shell.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  SOURCED=1
  _saved_opts=$(set +o)
  trap 'eval "$_saved_opts"; unset _saved_opts SOURCED' RETURN
else
  SOURCED=0
fi
die() { warn "$*"; [[ $SOURCED -eq 1 ]] && return 1 || exit 1; }

APPIMAGE_URL="https://github.com/doandat943/zalo-for-linux/releases/download/26.6.11/Zalo-26.6.11+ZaDark-26.2-0af5695.AppImage"
APPIMAGE_NAME="Zalo-26.6.11+ZaDark-26.2-0af5695.AppImage"
DEST_DIR="$HOME/Applications"
GEARLEVER_APP_ID="it.mijorus.gearlever"

log()  { echo -e "==> $*"; }
warn() { echo -e "!!  $*" >&2; }

# Use sudo only when not already root (keeps $HOME pointing at the invoking user).
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

log "Configuring XDG_DATA_DIRS for Flatpak desktop exports..."
FLATPAK_EXPORT_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:$FLATPAK_EXPORT_DIRS"

# Persist for future login sessions (fallback in case profile.d isn't sourced).
PROFILE_LINE="export XDG_DATA_DIRS=\"\$XDG_DATA_DIRS:$FLATPAK_EXPORT_DIRS\""
for rc in "$HOME/.profile" "$HOME/.bashrc"; do
  if [ -f "$rc" ] && ! grep -qF "flatpak/exports/share" "$rc"; then
    { echo ''; echo '# Added by zlu/install.sh'; echo "$PROFILE_LINE"; } >> "$rc"
    log "Added Flatpak export path to $rc (takes effect on next login)."
  fi
done

log "Refreshing desktop database..."
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
$SUDO update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

log "Checking for FUSE (libfuse2)..."
# Ubuntu 24.04+ renamed libfuse2 → libfuse2t64; AppImages still need it.
FUSE_PKG=""
if apt-cache show libfuse2t64 >/dev/null 2>&1; then
  FUSE_PKG="libfuse2t64"
elif apt-cache show libfuse2 >/dev/null 2>&1; then
  FUSE_PKG="libfuse2"
fi

if [ -n "$FUSE_PKG" ]; then
  if dpkg -s "$FUSE_PKG" >/dev/null 2>&1; then
    log "$FUSE_PKG already installed, skipping."
  else
    log "Installing $FUSE_PKG..."
    $SUDO apt-get install -y "$FUSE_PKG" || warn "$FUSE_PKG install failed -- AppImage may not launch."
  fi
else
  warn "libfuse2/libfuse2t64 not found. Install FUSE manually if the AppImage fails to launch."
fi

log "Adding Flathub remote (if missing)..."
$SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Installing/updating Gear Lever ($GEARLEVER_APP_ID)..."
$SUDO flatpak install -y --noninteractive --or-update flathub "$GEARLEVER_APP_ID"

log "Preparing download directory: $DEST_DIR"
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

log "Downloading Zalo AppImage..."
wget -q --show-progress -O "$APPIMAGE_NAME" "$APPIMAGE_URL"
chmod +x "$APPIMAGE_NAME"

log "Integrating with Gear Lever..."
if ! flatpak run "$GEARLEVER_APP_ID" --integrate "$DEST_DIR/$APPIMAGE_NAME"; then
  warn "Gear Lever integration failed."
  warn "If FUSE-related: dpkg -s ${FUSE_PKG:-libfuse2t64} and re-run."
  warn "Workaround: $DEST_DIR/$APPIMAGE_NAME --appimage-extract-and-run"
  die "Integration failed."
fi

log "Done! Zalo installed at: $DEST_DIR/$APPIMAGE_NAME"
log "Find it in your application menu."
