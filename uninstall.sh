#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INSTALL_DIR="$HOME/.superwarp-toolkit"
LEGACY_INSTALL_DIR="$HOME/.warp-ai-enhancement"
if [[ -n "${WARP_AI_INSTALL_DIR:-}" ]]; then
  INSTALL_DIR="$WARP_AI_INSTALL_DIR"
elif [[ -n "${WARP_AI_ENHANCEMENT_DIR:-}" ]]; then
  INSTALL_DIR="$WARP_AI_ENHANCEMENT_DIR"
elif [[ -L "$LEGACY_INSTALL_DIR" ]]; then
  INSTALL_DIR="$LEGACY_INSTALL_DIR"
elif [[ -d "$LEGACY_INSTALL_DIR" && ! -d "$DEFAULT_INSTALL_DIR" ]]; then
  INSTALL_DIR="$LEGACY_INSTALL_DIR"
else
  INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi
ZSHRC="$HOME/.zshrc"
BEGIN_MARKER="# >>> WARP AI ENHANCEMENT SUITE BEGIN >>>"
END_MARKER="# <<< WARP AI ENHANCEMENT SUITE END <<<"

log() {
  printf "[warp-ai] %s\n" "$*"
}

remove_managed_block() {
  [[ -f "$ZSHRC" ]] || return 0

  local tmp_file
  tmp_file="$(mktemp)"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { skip=1; next }
    $0 == end { skip=0; next }
    skip != 1 { print }
  ' "$ZSHRC" > "$tmp_file"
  mv "$tmp_file" "$ZSHRC"
}

remove_managed_block
rm -rf "$INSTALL_DIR"
rm -rf "$HOME/.superwarp-toolkit"
rm -rf "$HOME/.warp-ai-enhancement"

log "Removed install directory: $INSTALL_DIR"
log "Also removed legacy/new toolkit folders if present."
log "Removed managed loader block from $ZSHRC"
log "Logs are left in place at ~/Library/Logs/WarpAI"
log "Remove them manually if you no longer want them."
