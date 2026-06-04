#!/usr/bin/env zsh

if [[ -n "${WARP_AI_ENHANCEMENT_LOADED:-}" ]]; then
  return
fi
export WARP_AI_ENHANCEMENT_LOADED=1

if [[ -z "${WARP_AI_PROFILE_DIR:-}" ]]; then
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    WARP_AI_PROFILE_SOURCE="${(%):-%N}"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    WARP_AI_PROFILE_SOURCE="${BASH_SOURCE[0]}"
  else
    WARP_AI_PROFILE_SOURCE="$0"
  fi
  export WARP_AI_PROFILE_DIR="$(cd "$(dirname "$WARP_AI_PROFILE_SOURCE")" && pwd)"
fi

export WARP_AI_ROOT="${WARP_AI_ROOT:-$WARP_AI_PROFILE_DIR}"
export WARP_AI_LOG_DIR="${WARP_AI_LOG_DIR:-$HOME/Library/Logs/WarpAI}"
export WARP_AI_TOOLKIT="${WARP_AI_TOOLKIT:-$WARP_AI_ROOT/scripts/warp-ai-toolkit.sh}"

if [[ ! -f "$WARP_AI_TOOLKIT" ]]; then
  return
fi

source "$WARP_AI_TOOLKIT"

if [[ ! -o interactive ]]; then
  warp_ai_init_conversation_log
  return
fi

if [[ "${TERM_PROGRAM:-}" == "WarpTerminal" || "${WARP_AI_ALWAYS_SHOW_WELCOME:-0}" == "1" ]]; then
  if warp_ai_should_show_welcome; then
    warp_ai_startup
  else
    warp_ai_init_conversation_log
    warp_ai_log_system_event "Warp AI toolkit loaded during welcome cooldown"
  fi
else
  warp_ai_init_conversation_log
  warp_ai_log_system_event "Warp AI toolkit loaded without interactive welcome"
fi
