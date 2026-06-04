#!/usr/bin/env zsh

# -----------------------------------------------------------------------------
# macOS-friendly Warp AI enhancement toolkit
# -----------------------------------------------------------------------------

if [[ -z "${WARP_AI_ROOT:-}" ]]; then
  export WARP_AI_ROOT="$HOME/.warp-ai-enhancement"
fi

export WARP_AI_LOG_DIR="${WARP_AI_LOG_DIR:-$HOME/Library/Logs/WarpAI}"
export WARP_AI_MAIN_LOG="$WARP_AI_LOG_DIR/Claude_Conversation_Log.txt"
export WARP_AI_BACKUP_LOG="$WARP_AI_LOG_DIR/Claude_Conversation_Backup_$(date +%Y%m%d).txt"
export WARP_AI_WELCOME_STAMP_FILE="${WARP_AI_WELCOME_STAMP_FILE:-${TMPDIR:-/tmp}/warp-ai-last-welcome}"
export WARP_AI_WELCOME_COOLDOWN="${WARP_AI_WELCOME_COOLDOWN:-90}"

mkdir -p "$WARP_AI_LOG_DIR"

_warpai_ts() {
  date "+%Y-%m-%d %H:%M:%S"
}

_warpai_log_raw() {
  local line="$1"
  printf '[%s] %s\n' "$(_warpai_ts)" "$line" >> "$WARP_AI_MAIN_LOG"
  printf '[%s] %s\n' "$(_warpai_ts)" "$line" >> "$WARP_AI_BACKUP_LOG"
}

warp_ai_init_conversation_log() {
  mkdir -p "$WARP_AI_LOG_DIR"
  local header="=========================================================================="
  local ts="$(_warpai_ts)"
  {
    echo ""
    echo "$header"
    echo "NEW WARP SESSION STARTED: $ts"
    echo "Session path: $PWD"
    echo "$header"
  } >> "$WARP_AI_MAIN_LOG"
  {
    echo ""
    echo "$header"
    echo "NEW WARP SESSION STARTED: $ts"
    echo "Session path: $PWD"
    echo "$header"
  } >> "$WARP_AI_BACKUP_LOG"
}

warp_ai_log() {
  local kind="$1"
  shift
  local msg="$*"
  _warpai_log_raw "[$kind] $msg"
}

warp_ai_write_user_prompt() {
  local prompt="$1"
  warp_ai_log "USER PROMPT" "Prompt: $prompt"
}

warp_ai_write_response() {
  local response="${1:-}"
  local status="${2:-COMPLETE}"
  warp_ai_log "CLAUDE RESPONSE ($status)" "Response: $response"
}

warp_ai_log_system_event() {
  local event="$1"
  warp_ai_log "SYSTEM" "$event"
}

warp_ai_open_permission_panes() {
  if command -v open >/dev/null 2>&1; then
    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' || true
    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Automation' || true
    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture' || true
    echo "Opened macOS Privacy & Security panes for Accessibility, Automation, and Screen Recording."
  else
    echo "⚠️ Unable to open System Settings panes automatically on this machine."
    return 1
  fi
}

warp_ai_doctor() {
  local issues=0
  local permission_warnings=0
  local permission_probe

  echo "Warp AI doctor"
  echo "=============="
  echo "WARP_AI_ROOT=${WARP_AI_ROOT:-unset}"
  echo "WARP_AI_TOOLKIT=${WARP_AI_TOOLKIT:-unset}"
  echo "TERM_PROGRAM=${TERM_PROGRAM:-unset}"
  echo

  if command -v python3 >/dev/null 2>&1; then
    echo "python3: ok ($(python3 --version 2>/dev/null))"
  else
    echo "python3: missing"
    issues=1
  fi

  if command -v gemini >/dev/null 2>&1; then
    echo "gemini: ok"
  else
    echo "gemini: optional, not installed"
  fi

  if command -v ollama >/dev/null 2>&1; then
    echo "ollama: ok"
  else
    echo "ollama: optional, not installed"
  fi

  if [[ -f "${WARP_AI_TOOLKIT:-}" ]]; then
    echo "toolkit file: ok"
  else
    echo "toolkit file: missing"
    issues=1
  fi

  if [[ -w "$WARP_AI_LOG_DIR" || ! -e "$WARP_AI_LOG_DIR" ]]; then
    echo "log dir: ok ($WARP_AI_LOG_DIR)"
  else
    echo "log dir: not writable ($WARP_AI_LOG_DIR)"
    issues=1
  fi

  echo
  echo "macOS GUI capability checks:"

  if command -v osascript >/dev/null 2>&1; then
    if osascript -e 'tell application "System Events" to count processes' >/dev/null 2>&1; then
      echo "Accessibility / System Events: likely available"
    else
      echo "Accessibility / System Events: not verified"
      permission_warnings=1
    fi
  else
    echo "Accessibility / System Events: osascript missing"
    issues=1
  fi

  if [[ "${TERM_PROGRAM:-}" == "WarpTerminal" ]]; then
    permission_probe="$(warp_ai_command split right 2>&1 >/dev/null || true)"
    if [[ "$permission_probe" == *"Attempted split-right"* ]]; then
      echo "Warp automation: likely available"
    else
      echo "Warp automation: not verified"
      permission_warnings=1
    fi
  else
    echo "Warp automation: not checked outside Warp"
    permission_warnings=1
  fi

  if command -v screencapture >/dev/null 2>&1; then
    local probe_file
    probe_file="$(mktemp /tmp/warpai-doctor-screen-XXXXXX.png)"
    if screencapture -x "$probe_file" >/dev/null 2>&1; then
      echo "Screen Recording / screenshot capture: likely available"
      rm -f "$probe_file"
    else
      echo "Screen Recording / screenshot capture: not verified"
      rm -f "$probe_file"
      permission_warnings=1
    fi
  else
    echo "Screen Recording / screenshot capture: screencapture missing"
    issues=1
  fi

  if (( issues == 0 )); then
    echo
    if (( permission_warnings == 0 )); then
      echo "Doctor status: healthy"
    else
      echo "Doctor status: mostly healthy, with manual permission checks remaining"
    fi
    return 0
  fi

  echo
  echo "Doctor status: needs attention"
  return 1
}

warp_ai_should_show_welcome() {
  local now last_shown
  now="$(date +%s)"

  if [[ ! -f "$WARP_AI_WELCOME_STAMP_FILE" ]]; then
    printf '%s\n' "$now" > "$WARP_AI_WELCOME_STAMP_FILE"
    return 0
  fi

  last_shown="$(head -n 1 "$WARP_AI_WELCOME_STAMP_FILE" 2>/dev/null || echo 0)"
  if [[ ! "$last_shown" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$now" > "$WARP_AI_WELCOME_STAMP_FILE"
    return 0
  fi

  if (( now - last_shown >= WARP_AI_WELCOME_COOLDOWN )); then
    printf '%s\n' "$now" > "$WARP_AI_WELCOME_STAMP_FILE"
    return 0
  fi

  return 1
}

warp_ai_calculate() {
  local expression="$*"
  if [[ -z "$expression" ]]; then
    echo "❌ Usage: warp_ai_calculate '<expression>'"
    return 1
  fi

  warp_ai_log "TOOL" "Calculation requested: $expression"
  if command -v python3 >/dev/null 2>&1; then
    WARP_AI_EXPRESSION="$expression" python3 - <<'PY'
import ast
import os
expr = os.environ.get("WARP_AI_EXPRESSION", "")
ALLOWED_BINARY = {
    ast.Add: lambda a, b: a + b,
    ast.Sub: lambda a, b: a - b,
    ast.Mult: lambda a, b: a * b,
    ast.Div: lambda a, b: a / b,
    ast.FloorDiv: lambda a, b: a // b,
    ast.Mod: lambda a, b: a % b,
    ast.Pow: lambda a, b: a ** b,
}
ALLOWED_UNARY = {
    ast.UAdd: lambda a: +a,
    ast.USub: lambda a: -a,
}

def evaluate(node):
  if isinstance(node, ast.Expression):
    return evaluate(node.body)
  if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
    return node.value
  if isinstance(node, ast.BinOp) and type(node.op) in ALLOWED_BINARY:
    return ALLOWED_BINARY[type(node.op)](evaluate(node.left), evaluate(node.right))
  if isinstance(node, ast.UnaryOp) and type(node.op) in ALLOWED_UNARY:
    return ALLOWED_UNARY[type(node.op)](evaluate(node.operand))
  raise ValueError(f"Unsupported expression: {type(node).__name__}")

try:
  tree = ast.parse(expr, mode='eval')
  value = evaluate(tree)
  print("Result:", value)
except Exception as e:
  print(f"Calculation error: {e}")
PY
  else
    echo "⚠️ Python3 is required for safe calculation. Please install or use a basic shell calc."
  fi
}

warp_ai_invoke_web_search() {
  local query="$*"
  if [[ -z "$query" ]]; then
    echo "❌ Usage: warp_ai_web_search '<query>'"
    return 1
  fi

  warp_ai_log "TOOL" "Web search requested: $query"
  if command -v gemini >/dev/null 2>&1; then
    gemini -p "Use google_web_search to research this query and return a concise summary with source citations: ${query}"
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    WARP_AI_QUERY="$query" python3 - <<'PY'
import urllib.request, urllib.parse, json
query = urllib.parse.quote(__import__('os').environ.get("WARP_AI_QUERY", ""))
url = f"https://api.duckduckgo.com/?q={query}&format=json&no_html=1"
try:
  with urllib.request.urlopen(url, timeout=10) as response:
    payload = json.loads(response.read().decode("utf-8"))
  print(payload.get("AbstractText") or "No summary from DuckDuckGo. Try the gemini tool if installed.")
except Exception as e:
  print(f"Web search unavailable: {e}")
PY
  else
    echo "⚠️ Gemini CLI not found, and python3 missing for fallback web lookup."
  fi
}

warp_ai_invoke_image_analysis() {
  local image_path="$1"
  local prompt="${2:-Describe this image in detail}"
  if [[ -z "$image_path" ]]; then
    echo "❌ Usage: warp_ai_image_analysis <image-path> [prompt]"
    return 1
  fi

  warp_ai_log "TOOL" "Image analysis requested: $image_path"
  if ! command -v ollama >/dev/null 2>&1; then
    echo "⚠️ Ollama is not installed. Install from https://ollama.com"
    return 1
  fi

  local model="${WARP_AI_VISION_MODEL:-llama3.2-vision:11b}"
  if [[ ! -f "$image_path" ]]; then
    echo "❌ Image file not found: $image_path"
    return 1
  fi

  echo "Running Ollama model: $model"
  ollama run "$model" "${prompt} ${image_path}"
}

warp_ai_exec_apple_events() {
  local keystroke="$1"
  local modifiers="$2"
  osascript \
    -e 'tell application "Warp" to activate' \
    -e "tell application \"System Events\" to keystroke \"$keystroke\" using {$modifiers}"
}

warp_ai_command() {
  local action="${1:-}"
  shift || true
  local command_text="${action}${*:+ }$*"
  local lowered="$(printf "%s" "$command_text" | tr '[:upper:]' '[:lower:]')"

  warp_ai_log "AUTOMATION" "Warp command requested: $command_text"

  if [[ -z "$command_text" ]]; then
    echo "Available commands: split right | split down | close panel | screenshot"
    return 1
  fi

  case "$lowered" in
    *split*right*|*right*split*)
      if command -v osascript >/dev/null 2>&1; then
        if warp_ai_exec_apple_events "d" "command down"; then
          echo "✅ Attempted split-right via AppleScript (Cmd+D)"
        else
          echo "⚠️ AppleScript automation failed. Check macOS Privacy & Security > Automation and Accessibility permissions for Warp and your shell."
          return 1
        fi
      else
        echo "⚠️ osascript not available on this machine."
      fi
      ;;
    *split*down*|*down*split*)
      if command -v osascript >/dev/null 2>&1; then
        if warp_ai_exec_apple_events "d" "command down, shift down"; then
          echo "✅ Attempted split-down via AppleScript (Shift+Cmd+D)"
        else
          echo "⚠️ AppleScript automation failed. Check macOS Privacy & Security > Automation and Accessibility permissions for Warp and your shell."
          return 1
        fi
      else
        echo "⚠️ osascript not available on this machine."
      fi
      ;;
    *close*panel*|*panel*close*)
      if command -v osascript >/dev/null 2>&1; then
        if warp_ai_exec_apple_events "w" "command down"; then
          echo "✅ Attempted close panel via AppleScript (Cmd+W)"
        else
          echo "⚠️ AppleScript automation failed. Check macOS Privacy & Security > Automation and Accessibility permissions for Warp and your shell."
          return 1
        fi
      else
        echo "⚠️ osascript not available on this machine."
      fi
      ;;
    screenshot*)
      if command -v screencapture >/dev/null 2>&1; then
        local output="${1:-$HOME/Desktop/warp-ai-screenshot-$(date +%Y%m%d-%H%M%S).png}"
        if screencapture "$output"; then
          echo "✅ Saved screenshot: $output"
        else
          echo "⚠️ Screenshot failed. macOS may need Screen Recording permission for your terminal."
          return 1
        fi
      else
        echo "⚠️ screencapture not available."
      fi
      ;;
    *)
      echo "⚠️ Unknown command: $command_text"
      echo "Try: split right | split down | close panel | screenshot"
      return 1
      ;;
  esac
}

warp_ai_context_snapshot() {
  local project_count=0
  local recent_file
  recent_file="$(tail -n 200 "$WARP_AI_BACKUP_LOG" 2>/dev/null | head -n 200)"

  local last_activity
  last_activity="$(stat -f "%Sm" "$WARP_AI_MAIN_LOG" 2>/dev/null || echo "unknown")"

  local projects=()
  if [[ -n "$recent_file" ]]; then
    if [[ "$recent_file" == *"Ollama"* ]]; then
      projects+=("🦙 Ollama vision/tooling activity detected")
      (( project_count += 1 ))
    fi
    if [[ "$recent_file" == *"Gemini"* || "$recent_file" == *"gemini"* ]]; then
      projects+=("💎 Gemini CLI usage detected")
      (( project_count += 1 ))
    fi
    if [[ "$recent_file" == *"Shell command"* || "$recent_file" == *"tool requested"* ]]; then
      projects+=("🧰 Automation/tooling activity detected")
      (( project_count += 1 ))
    fi
  fi

  if (( project_count == 0 )); then
    projects=("📦 New session context not detected yet")
  fi

  printf '%s\n' "$projects"
  echo "LAST_ACTIVITY=${last_activity}"
}

warp_ai_show_welcome() {
  local hour now
  hour="$(date +%H)"
  if (( hour < 12 )); then
    now="morning"
  elif (( hour < 17 )); then
    now="afternoon"
  else
    now="evening"
  fi

  local snapshot
  snapshot="$(warp_ai_context_snapshot)"
  local last_activity
  last_activity="$(printf "%s\n" "$snapshot" | grep -E "^LAST_ACTIVITY=" | tail -n 1 | sed 's/^LAST_ACTIVITY=//')"

  echo "👋 Welcome back! How's it going this $now?"
  echo "════════════════════════════════════════════════════════════"
  echo "🎯 Based on recent activity, we were working on:"
  echo "$snapshot" | grep -Ev "^LAST_ACTIVITY="

  if [[ -n "$last_activity" ]]; then
    echo "📊 Recent session marker: $last_activity"
  fi
  echo "💡 Ready to continue where we left off?"
  echo "🛡️ All systems active - your work is protected."
  echo "==============================================================="
}

warp_ai_startup() {
  warp_ai_init_conversation_log
  warp_ai_log_system_event "Warp AI toolkit loaded"
  warp_ai_show_welcome
  warp_ai_log_system_event "Startup complete"
}

alias warpai-search='warp_ai_invoke_web_search'
alias warpai-image='warp_ai_invoke_image_analysis'
alias warpai-calc='warp_ai_calculate'
alias warpai-cmd='warp_ai_command'
alias warpai-doctor='warp_ai_doctor'
alias warpai-permissions='warp_ai_open_permission_panes'

export WARP_AI_READY=1
