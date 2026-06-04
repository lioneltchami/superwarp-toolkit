#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${WARP_AI_ENHANCEMENT_DIR:-$HOME/.warp-ai-enhancement}"
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

log "Removed install directory: $INSTALL_DIR"
log "Removed managed loader block from $ZSHRC"
log "Logs are left in place at ~/Library/Logs/WarpAI"
log "Remove them manually if you no longer want them."
