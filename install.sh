#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${WARP_AI_ENHANCEMENT_DIR:-$HOME/.warp-ai-enhancement}"
PROFILE_SOURCE="$PROJECT_DIR/warp-ai-enhancement-profile.zsh"
TOOLKIT_SOURCE="$PROJECT_DIR/scripts/warp-ai-toolkit.sh"

ZSHRC="$HOME/.zshrc"
LOADER_PATH="$INSTALL_DIR/warp-ai-enhancement-profile.zsh"
DO_PERMISSION_PANES=1
INSTALL_GEMINI=0
INSTALL_OLLAMA=0

log() {
  printf "[warp-ai] %s\n" "$*"
}

show_help() {
  log "Usage: ./install.sh [--no-shell-hook] [--no-permission-panes] [--install-gemini] [--install-ollama]"
  log "  --install-gemini       Install Gemini CLI"
  log "  --install-ollama       Install Ollama"
  log "  --no-permission-panes   Do not open macOS Privacy & Security panes"
  log "  --no-shell-hook   Install files only, do not modify ~/.zshrc"
  log "  --help            Show this help"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_brew_bin() {
  if command_exists brew; then
    command -v brew
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
    return 0
  fi
  if [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
    return 0
  fi
  return 1
}

load_brew_env() {
  local brew_bin
  brew_bin="$(detect_brew_bin)" || return 1
  eval "$("$brew_bin" shellenv)"
}

ensure_homebrew() {
  if detect_brew_bin >/dev/null 2>&1; then
    load_brew_env
    return 0
  fi

  if ! command_exists curl; then
    log "curl is required to bootstrap Homebrew."
    exit 1
  fi

  log "Homebrew not found. Installing Homebrew so python3 can be installed."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env || {
    log "Homebrew installed, but brew was not added to PATH in this shell."
    exit 1
  }
}

ensure_python3() {
  if command_exists python3; then
    log "python3 already available."
    return 0
  fi

  ensure_homebrew
  log "Installing python3 with Homebrew..."
  brew install python
  command_exists python3 || {
    log "python3 installation did not complete successfully."
    exit 1
  }
}

ensure_node() {
  if command_exists node && command_exists npm; then
    log "node and npm already available."
    return 0
  fi

  ensure_homebrew
  log "Installing node with Homebrew for Gemini CLI..."
  brew install node
  if ! command_exists node || ! command_exists npm; then
    log "node/npm installation did not complete successfully."
    exit 1
  fi
}

install_gemini_cli() {
  if command_exists gemini; then
    log "Gemini CLI already available."
    return 0
  fi

  ensure_node
  log "Installing Gemini CLI..."
  npm install -g @google/gemini-cli
  if ! command_exists gemini; then
    log "Gemini CLI installation did not complete successfully."
    exit 1
  fi
}

install_ollama() {
  if command_exists ollama && [[ -d /Applications/Ollama.app ]]; then
    log "Ollama already available."
    return 0
  fi

  if ! command_exists curl; then
    log "curl is required to install Ollama."
    exit 1
  fi

  log "Installing Ollama with the official installer..."
  curl -fsSL https://ollama.com/install.sh | sh
  if ! command_exists ollama; then
    log "Ollama installation did not complete successfully."
    exit 1
  fi
}

open_permission_panes() {
  log "macOS Privacy & Security approval is still manual."
  log "Opening Accessibility, Automation, and Screen Recording panes."
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' || true
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Automation' || true
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture' || true
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

DO_SHELL_HOOK=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-shell-hook)
      DO_SHELL_HOOK=0
      ;;
    --no-permission-panes)
      DO_PERMISSION_PANES=0
      ;;
    --install-gemini)
      INSTALL_GEMINI=1
      ;;
    --install-ollama)
      INSTALL_OLLAMA=1
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      log "Unknown option: ${1}"
      log "Use --help to see supported options."
      exit 1
      ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  log "This project is now macOS-only. Install on macOS with this script."
  exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
  log "zsh is required on macOS and is not available on PATH."
  exit 1
fi

ensure_python3

if [[ $INSTALL_GEMINI -eq 1 ]]; then
  install_gemini_cli
fi

if [[ $INSTALL_OLLAMA -eq 1 ]]; then
  install_ollama
fi

mkdir -p "$INSTALL_DIR/scripts"

cp "$PROFILE_SOURCE" "$LOADER_PATH"
cp "$TOOLKIT_SOURCE" "$INSTALL_DIR/scripts/warp-ai-toolkit.sh"

chmod 755 "$LOADER_PATH" "$INSTALL_DIR/scripts/warp-ai-toolkit.sh"

if [[ $DO_SHELL_HOOK -eq 1 ]]; then
  BEGIN_MARKER="# >>> WARP AI ENHANCEMENT SUITE BEGIN >>>"
  END_MARKER="# <<< WARP AI ENHANCEMENT SUITE END <<<"
  if [[ -f "$ZSHRC" ]] && grep -Fq "$BEGIN_MARKER" "$ZSHRC"; then
    log "zsh hook already exists in $ZSHRC"
  else
    cat >> "$ZSHRC" <<EOF

$BEGIN_MARKER
export WARP_AI_ROOT="$INSTALL_DIR"
export WARP_AI_TOOLKIT="$INSTALL_DIR/scripts/warp-ai-toolkit.sh"
if [[ -f "$LOADER_PATH" ]]; then
  source "$LOADER_PATH"
fi
$END_MARKER

EOF
    log "Added loader hook to $ZSHRC"
  fi
fi

log "Installed to: $INSTALL_DIR"
log "If you want to enable manually later, add this line to ~/.zshrc:"
log "  source \"$LOADER_PATH\""
if [[ $DO_PERMISSION_PANES -eq 1 && -t 1 ]]; then
  open_permission_panes
fi
log "Restart Warp to load the profile."
