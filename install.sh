#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_INSTALL_DIR="$HOME/.superwarp-toolkit"
LEGACY_INSTALL_DIR="$HOME/.warp-ai-enhancement"
DEFAULTS_FILE="${WARP_AI_INSTALL_DEFAULTS_FILE:-$PROJECT_DIR/.superwarp-toolkit.env}"
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
if [[ -z "${WARP_AI_INSTALL_DIR:-}" && -z "${WARP_AI_ENHANCEMENT_DIR:-}" && -d "$LEGACY_INSTALL_DIR" && ! -d "$DEFAULT_INSTALL_DIR" ]]; then
  if command -v mv >/dev/null 2>&1; then
    mv "$LEGACY_INSTALL_DIR" "$DEFAULT_INSTALL_DIR"
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
  fi
fi
PROFILE_SOURCE="$PROJECT_DIR/warp-ai-enhancement-profile.zsh"
TOOLKIT_SOURCE="$PROJECT_DIR/scripts/warp-ai-toolkit.sh"

ZSHRC="$HOME/.zshrc"
LOADER_PATH="$INSTALL_DIR/warp-ai-enhancement-profile.zsh"
DO_PERMISSION_PANES=1
INSTALL_GEMINI=0
INSTALL_OLLAMA=0
INSTALL_CODEX=0
INSTALL_GROK=0
ASSUME_YES=0
EXPLICIT_INSTALL_FLAGS=0
if [[ -r "$DEFAULTS_FILE" ]]; then
  source_defaults() {
    local line key value
    while IFS= read -r line; do
      line="${line#"${line%%[!$'\t\r\n ']*}"}"
      line="${line%"${line##*[!$'\t\r\n ']}"}"
      [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
      [[ "$line" == *=* ]] || continue
      key="${line%%=*}"
      value="${line#*=}"
      key="${key#"${key%%[!$'\t\r\n ']*}"}"
      key="${key%"${key##*[!$'\t\r\n ']}"}"
      value="${value#"${value%%[!$'\t\r\n ']*}"}"
      value="${value%"${value##*[!$'\t\r\n ']}"}"
      case "$key" in
        [A-Za-z_][A-Za-z0-9_]*)
          ;;
        *)
          continue
          ;;
      esac
      if [[ -z "${!key+x}" ]]; then
        if [[ "$key" == WARP_AI_* ]]; then
          if [[ "${value}" == \"*\" && "${value}" == *\" ]]; then
            value="${value%\"}"
            value="${value#\"}"
          elif [[ "${value}" == \'*\' && "${value}" == *\' ]]; then
            value="${value%\'}"
            value="${value#\'}"
          fi
          export "${key}=${value}"
        fi
      fi
    done < "$DEFAULTS_FILE"
  }
  source_defaults
fi

if [[ -n "${WARP_AI_ACCEPT_DEFAULTS:-}" ]]; then
  local_accept_default="$(printf '%s' "$WARP_AI_ACCEPT_DEFAULTS" | tr '[:upper:]' '[:lower:]')"
  case "$local_accept_default" in
    1|true|yes|on|enabled)
      ASSUME_YES=1
      ;;
  esac
fi

ask_yes_no() {
  local prompt="$1"
  local answer

  while true; do
    if ! read -r -p "$prompt [Y/n]: " answer < /dev/tty; then
      log "Input unavailable; skipping prompt."
      return 1
    fi
    normalized_answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"

    case "$normalized_answer" in
      y|yes|"")
        return 0
        ;;
      n|no)
        return 1
        ;;
      *)
        log "Please answer y or n."
        ;;
    esac
  done
}

prompt_for_optional_components() {
  if [[ $ASSUME_YES -eq 1 ]]; then
    INSTALL_GEMINI=1
    INSTALL_OLLAMA=1
    INSTALL_CODEX=1
    INSTALL_GROK=1
    return 0
  fi

  log "Interactive install mode: choose optional components."
  log "Press Enter for yes, or type n to skip."
  if ask_yes_no "Install Gemini CLI"; then
    INSTALL_GEMINI=1
  fi
  if ask_yes_no "Install Ollama"; then
    INSTALL_OLLAMA=1
  fi
  if ask_yes_no "Install Codex CLI"; then
    INSTALL_CODEX=1
  fi
  if ask_yes_no "Install Grok CLI"; then
    INSTALL_GROK=1
  fi
}

log() {
  printf "[warp-ai] %s\n" "$*"
}

show_help() {
  log "Usage: ./install.sh [--no-shell-hook] [--no-permission-panes] [--accept-defaults] [--install-gemini] [--install-ollama] [--install-codex] [--install-grok]"
  log "  --install-gemini       Install Gemini CLI"
  log "  --install-ollama       Install Ollama"
  log "  --install-codex        Install Codex CLI (optional; requires codex package/source config)"
  log "  --install-codex uses WARP_AI_CODEX_INSTALL_COMMAND and/or WARP_AI_CODEX_NPM_PACKAGE."
  log "  --install-grok         Install Grok CLI via xAI installer or WARP_AI_GROK_INSTALL_COMMAND"
  log "  --install-grok can also use WARP_AI_GROK_BIN and/or WARP_AI_GROK_INSTALL_COMMAND."
  log "  --accept-defaults      Install all optional components without prompting"
  log "  WARP_AI_INSTALL_DEFAULTS_FILE  path to a per-repo defaults file (default: ./.superwarp-toolkit.env)"
  log "  WARP_AI_ACCEPT_DEFAULTS can also be set to 1/true/yes/on/enabled to auto-install defaults."
  log "  WARP_AI_OLLAMA_NO_START can be set to 1/true/yes/on/enabled to skip Ollama GUI startup."
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

install_grok_cli() {
  local grok_binary="${WARP_AI_GROK_BIN:-grok}"

  if command_exists "$grok_binary"; then
    log "Grok CLI already available."
    return 0
  fi

  if [[ -n "${WARP_AI_GROK_INSTALL_COMMAND:-}" ]]; then
    log "Installing Grok CLI via WARP_AI_GROK_INSTALL_COMMAND..."
    if ! sh -c "$WARP_AI_GROK_INSTALL_COMMAND"; then
      log "Grok CLI custom install command failed."
      exit 1
    fi
  else
    if ! command_exists curl; then
      log "curl is required to install Grok CLI."
      exit 1
    fi
    log "Installing Grok CLI from xAI official installer..."
    curl -fsSL https://x.ai/cli/install.sh | bash
  fi

  if ! command_exists "$grok_binary"; then
    log "Grok CLI installation did not complete successfully."
    exit 1
  fi

  log "Grok CLI installation completed."
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

install_codex_cli() {
  local codex_binary
  codex_binary="${WARP_AI_CODEX_BIN:-codex}"

  if command_exists "$codex_binary"; then
    log "Codex CLI already available."
    return 0
  fi

  if [[ -n "${WARP_AI_CODEX_INSTALL_COMMAND:-}" ]]; then
    log "Installing Codex CLI via WARP_AI_CODEX_INSTALL_COMMAND..."
    if ! sh -c "$WARP_AI_CODEX_INSTALL_COMMAND"; then
      log "Codex CLI custom install command failed."
      exit 1
    fi
  elif [[ -n "${WARP_AI_CODEX_NPM_PACKAGE:-}" ]]; then
    ensure_node
    log "Installing Codex CLI from npm package ${WARP_AI_CODEX_NPM_PACKAGE}..."
    if ! npm install -g "$WARP_AI_CODEX_NPM_PACKAGE"; then
      log "Codex CLI npm install failed."
      exit 1
    fi
  else
    log "Codex CLI is not installed, and no install command was configured."
    log "Use one of the following before running --install-codex:"
    log "  export WARP_AI_CODEX_INSTALL_COMMAND=\"<your command>\""
    log "  export WARP_AI_CODEX_NPM_PACKAGE=\"<npm package name>\""
    log "Examples:"
    log "  export WARP_AI_CODEX_NPM_PACKAGE=\"@openai/codex\""
    log "  # or export WARP_AI_CODEX_INSTALL_COMMAND=\"npm install -g @openai/codex\""
    return 1
  fi

  if ! command_exists "$codex_binary"; then
    log "Codex installation did not complete successfully."
    exit 1
  fi

  log "Codex CLI installation completed."
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
  if [[ -z "${WARP_AI_OLLAMA_NO_START:-}" ]]; then
    if [[ "${CI:-false}" == "true" || "${GITHUB_ACTIONS:-false}" == "true" ]]; then
      WARP_AI_OLLAMA_NO_START=1
    fi
  fi

  normalized_ollama_no_start="$(printf '%s' "${WARP_AI_OLLAMA_NO_START:-0}" | tr '[:upper:]' '[:lower:]')"
  case "$normalized_ollama_no_start" in
    1|true|yes|on|enabled)
      export OLLAMA_NO_START=1
      ;;
    *)
      unset OLLAMA_NO_START
      ;;
  esac
  curl -fsSL https://ollama.com/install.sh | sh
  if command_exists ollama; then
    return 0
  fi

  if [[ -x /Applications/Ollama.app/Contents/Resources/ollama ]]; then
    if [[ ! -x /usr/local/bin/ollama ]]; then
      local fallback_bin="$HOME/.local/bin/ollama"
      local fallback_bin_dir
      fallback_bin_dir="$(dirname "$fallback_bin")"
      mkdir -p "$fallback_bin_dir"
      ln -sf /Applications/Ollama.app/Contents/Resources/ollama "$fallback_bin"
      if [[ -x "$fallback_bin" ]]; then
        if [[ ":$PATH:" != *":$fallback_bin_dir:"* ]]; then
          PATH="$fallback_bin_dir:$PATH"
        fi
        log "Created fallback Ollama binary at $fallback_bin. PATH updates may require a new shell session."
        return 0
      fi
    fi
  fi

  log "Ollama installation did not complete successfully."
  exit 1
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
      EXPLICIT_INSTALL_FLAGS=$((EXPLICIT_INSTALL_FLAGS + 1))
      ;;
    --install-ollama)
      INSTALL_OLLAMA=1
      EXPLICIT_INSTALL_FLAGS=$((EXPLICIT_INSTALL_FLAGS + 1))
      ;;
    --install-codex)
      INSTALL_CODEX=1
      EXPLICIT_INSTALL_FLAGS=$((EXPLICIT_INSTALL_FLAGS + 1))
      ;;
    --install-grok)
      INSTALL_GROK=1
      EXPLICIT_INSTALL_FLAGS=$((EXPLICIT_INSTALL_FLAGS + 1))
      ;;
    --accept-defaults)
      ASSUME_YES=1
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

if [[ $EXPLICIT_INSTALL_FLAGS -eq 0 && $ASSUME_YES -eq 1 ]]; then
  prompt_for_optional_components
elif [[ $EXPLICIT_INSTALL_FLAGS -eq 0 && -t 0 && -t 1 ]]; then
  prompt_for_optional_components
elif [[ $EXPLICIT_INSTALL_FLAGS -eq 0 && ! -t 0 || ! -t 1 ]]; then
  log "Non-interactive run detected; defaulting to no optional component installation."
  log "Use --install-gemini/--install-ollama/--install-codex/--install-grok or --accept-defaults."
fi

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

if [[ $INSTALL_CODEX -eq 1 ]]; then
  install_codex_cli
fi

if [[ $INSTALL_GROK -eq 1 ]]; then
  install_grok_cli
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
