#!/usr/bin/env zsh

# -----------------------------------------------------------------------------
# macOS-friendly Warp AI enhancement toolkit
# -----------------------------------------------------------------------------

if [[ -z "${WARP_AI_ROOT:-}" ]]; then
  if [[ -d "$HOME/.superwarp-toolkit" ]]; then
    export WARP_AI_ROOT="$HOME/.superwarp-toolkit"
  elif [[ -L "$HOME/.warp-ai-enhancement" ]]; then
    export WARP_AI_ROOT="$HOME/.warp-ai-enhancement"
  elif [[ -d "$HOME/.warp-ai-enhancement" ]]; then
    export WARP_AI_ROOT="$HOME/.superwarp-toolkit"
    if command -v mv >/dev/null 2>&1; then
      mv "$HOME/.warp-ai-enhancement" "$HOME/.superwarp-toolkit"
    fi
  else
    export WARP_AI_ROOT="$HOME/.superwarp-toolkit"
  fi
fi

export WARP_AI_LOG_DIR="${WARP_AI_LOG_DIR:-$HOME/Library/Logs/WarpAI}"
export WARP_AI_MAIN_LOG="$WARP_AI_LOG_DIR/Claude_Conversation_Log.txt"
export WARP_AI_BACKUP_LOG="$WARP_AI_LOG_DIR/Claude_Conversation_Backup_$(date +%Y%m%d).txt"
export WARP_AI_CODEX_BIN="${WARP_AI_CODEX_BIN:-codex}"
export WARP_AI_GROK_BIN="${WARP_AI_GROK_BIN:-grok}"
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
  if [[ -n "$(command -v open 2>/dev/null)" ]]; then
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

  if [[ -n "$(command -v python3 2>/dev/null)" ]]; then
    echo "python3: ok ($(python3 --version 2>/dev/null))"
  else
    echo "python3: missing"
    issues=1
  fi

  if [[ -n "$(command -v gemini 2>/dev/null)" ]]; then
    echo "gemini: ok"
  else
    echo "gemini: optional, not installed"
  fi

  if [[ -n "$(command -v ollama 2>/dev/null)" ]]; then
    echo "ollama: ok"
  else
    echo "ollama: optional, not installed"
  fi

  if [[ -n "$(command -v "$WARP_AI_CODEX_BIN" 2>/dev/null)" ]]; then
    echo "codex: ok"
  else
    echo "codex: optional, not installed"
  fi

  if [[ -n "$(command -v "$WARP_AI_GROK_BIN" 2>/dev/null)" ]]; then
    echo "grok: ok"
  else
    echo "grok: optional, not installed"
  fi

  if [[ -n "$(command -v sqlite3 2>/dev/null)" ]]; then
    echo "sqlite3: ok"
  else
    echo "sqlite3: optional, not installed"
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

  if [[ -n "$(command -v osascript 2>/dev/null)" ]]; then
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

  if [[ -n "$(command -v screencapture 2>/dev/null)" ]]; then
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

warp_ai_find_usage_db() {
  local candidate

  if [[ -n "${WARP_AI_USAGE_DB:-}" ]]; then
    if [[ -f "$WARP_AI_USAGE_DB" ]]; then
      printf '%s\n' "$WARP_AI_USAGE_DB"
      return 0
    fi
    return 1
  fi

  for candidate in \
    "$HOME/Library/Application Support/dev.warp.Warp-Stable/warp.sqlite" \
    "$HOME/Library/Application Support/dev.warp.Warp-Beta/warp.sqlite" \
    "$HOME/Library/Application Support/dev.warp.Warp-Nightly/warp.sqlite" \
    "$HOME/Library/Application Support/dev.warp.Warp/warp.sqlite"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

warp_ai_find_usage_plist() {
  local candidate

  if [[ -n "${WARP_AI_USAGE_PLIST:-}" ]]; then
    if [[ -f "$WARP_AI_USAGE_PLIST" ]]; then
      printf '%s\n' "$WARP_AI_USAGE_PLIST"
      return 0
    fi
    return 1
  fi

  for candidate in \
    "$HOME/Library/Preferences/dev.warp.Warp-Stable.plist" \
    "$HOME/Library/Preferences/dev.warp.Warp-Beta.plist" \
    "$HOME/Library/Preferences/dev.warp.Warp-Nightly.plist" \
    "$HOME/Library/Preferences/dev.warp.Warp.plist"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

warp_ai_usage_plist_summary() {
  local plist_path="$1"

  if [[ -z "$plist_path" || ! -f "$plist_path" ]]; then
    echo "plist_error=Warp preferences file not found"
    return 0
  fi

  if [[ -z "$(command -v python3 2>/dev/null)" ]]; then
    echo "plist_error=python3 is required to parse the Warp preferences plist"
    return 0
  fi

  python3 - "$plist_path" <<'PY'
import json
import plistlib
import sys
from datetime import datetime, timezone

path = sys.argv[1]

try:
    with open(path, "rb") as handle:
        plist = plistlib.load(handle)
except Exception as exc:
    print(f"plist_error={exc}")
    raise SystemExit(0)

limit_key = next((key for key in ("AIRequestLimitInfo", "AIAssistantRequestLimitInfo") if key in plist), None)
if not limit_key:
    print("plist_error=missing AIRequestLimitInfo")
    raise SystemExit(0)

raw_limit_info = plist.get(limit_key)
if isinstance(raw_limit_info, bytes):
    raw_limit_info = raw_limit_info.decode("utf-8", "replace")

if not isinstance(raw_limit_info, str):
    print("plist_error=invalid AIRequestLimitInfo value")
    raise SystemExit(0)

try:
    limit_info = json.loads(raw_limit_info)
except Exception as exc:
    print(f"plist_error={exc}")
    raise SystemExit(0)

try:
    requests_used = int(limit_info.get("num_requests_used_since_refresh") or 0)
    requests_limit = int(limit_info.get("limit") or 0)
    is_unlimited = bool(limit_info.get("is_unlimited"))
    voice_request_limit = int(limit_info.get("voice_request_limit") or 0)
    max_codebase_indices = int(limit_info.get("max_codebase_indices") or 0)
    next_refresh_time = str(limit_info.get("next_refresh_time") or "")
except Exception as exc:
    print(f"plist_error={exc}")
    raise SystemExit(0)

if is_unlimited:
    subscription_type = "Pro"
elif requests_limit >= 2500 and voice_request_limit >= 999999 and max_codebase_indices >= 40:
    subscription_type = "Pro"
elif requests_limit >= 2500:
    subscription_type = "Standard"
elif requests_limit >= 150:
    subscription_type = "Basic"
else:
    subscription_type = "Free"

print(f"plist_path={path}")
print(f"limit_key={limit_key}")
print(f"requests_used={requests_used}")
print(f"requests_limit={requests_limit}")
print(f"is_unlimited={str(is_unlimited).lower()}")
print(f"subscription_type={subscription_type}")
print(f"next_refresh_time={next_refresh_time}")
print(f"voice_request_limit={voice_request_limit}")
print(f"max_codebase_indices={max_codebase_indices}")
PY
}

warp_ai_usage() {
  local db_path plist_path plist_output
  local requests_used=0
  local requests_limit=0
  local is_unlimited=false
  local subscription_type="Unknown"
  local next_refresh_time="unknown"
  local voice_request_limit=0
  local max_codebase_indices=0

  db_path="$(warp_ai_find_usage_db 2>/dev/null || true)"
  plist_path="$(warp_ai_find_usage_plist 2>/dev/null || true)"

  echo "Warp AI Usage Report"
  echo "===================="
  echo

  if [[ -n "$plist_path" ]]; then
    plist_output="$(warp_ai_usage_plist_summary "$plist_path" 2>/dev/null || true)"
    if [[ "$plist_output" == plist_error=* ]]; then
      echo "Plist snapshot: unavailable (${plist_output#plist_error=})"
    else
      while IFS='=' read -r key value; do
        case "$key" in
          requests_used) requests_used="$value" ;;
          requests_limit) requests_limit="$value" ;;
          is_unlimited) is_unlimited="$value" ;;
          subscription_type) subscription_type="$value" ;;
          next_refresh_time) next_refresh_time="$value" ;;
          voice_request_limit) voice_request_limit="$value" ;;
          max_codebase_indices) max_codebase_indices="$value" ;;
        esac
      done <<< "$plist_output"

      echo "Plist snapshot: $plist_path"
      echo "  plan: $subscription_type"
      if [[ "$is_unlimited" == "true" ]]; then
        echo "  usage: unlimited"
      else
        local percent
        percent="$(awk -v used="$requests_used" -v limit="$requests_limit" 'BEGIN { if (limit > 0) printf "%.1f", (used / limit) * 100; else printf "0.0" }')"
        echo "  usage: ${requests_used}/${requests_limit} (${percent}%)"
      fi
      echo "  next refresh: $next_refresh_time"
      echo "  voice request limit: $voice_request_limit"
      echo "  max codebase indices: $max_codebase_indices"
    fi
  else
    echo "Plist snapshot: not found"
  fi

  echo

  if [[ -n "$db_path" ]]; then
    if [[ -z "$(command -v sqlite3 2>/dev/null)" ]]; then
      echo "SQLite history: sqlite3 not available"
      return 0
    fi

    local ai_table schema_columns
    ai_table="$(sqlite3 "$db_path" "SELECT name FROM sqlite_master WHERE type='table' AND name='ai_queries';" 2>/dev/null || true)"
    if [[ "$ai_table" != "ai_queries" ]]; then
      echo "SQLite history: ai_queries table not found in $db_path"
      return 0
    fi

    schema_columns="$(sqlite3 "$db_path" "PRAGMA table_info(ai_queries);" 2>/dev/null || true)"
    if [[ "$schema_columns" != *"|start_ts|"* || "$schema_columns" != *"|model_id|"* ]]; then
      echo "SQLite history: ai_queries schema unsupported in $db_path"
      return 0
    fi

    local total_requests today_requests weekly_requests first_use last_use active_days avg_per_day
    total_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries;" 2>/dev/null || true)"
    if [[ -z "$total_requests" || "$total_requests" == "0" ]]; then
      echo "SQLite history: no AI query rows found"
      return 0
    fi

    today_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries WHERE DATE(start_ts) = DATE('now');" 2>/dev/null || true)"
    weekly_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries WHERE start_ts >= datetime('now', '-7 days');" 2>/dev/null || true)"
    first_use="$(sqlite3 "$db_path" "SELECT DATE(MIN(start_ts)) FROM ai_queries;" 2>/dev/null || true)"
    last_use="$(sqlite3 "$db_path" "SELECT DATE(MAX(start_ts)) FROM ai_queries;" 2>/dev/null || true)"
    active_days="$(sqlite3 "$db_path" "SELECT CAST(julianday(DATE(MAX(start_ts))) - julianday(DATE(MIN(start_ts))) + 1 AS INTEGER) FROM ai_queries;" 2>/dev/null || true)"
    if [[ -z "$active_days" || "$active_days" == "0" ]]; then
      active_days=1
    fi
    avg_per_day="$(awk -v total="$total_requests" -v days="$active_days" 'BEGIN { if (days > 0) printf "%.1f", total / days; else printf "0.0" }')"

    echo "SQLite history: $db_path"
    echo "  total requests: $total_requests"
    echo "  today: $today_requests"
    echo "  last 7 days: $weekly_requests"
    echo "  first use: $first_use"
    echo "  last use: $last_use"
    echo "  active days: $active_days"
    echo "  avg/day: $avg_per_day"
    echo "  top usage days:"
    while IFS='|' read -r date requests; do
      [[ -n "$date" ]] || continue
      echo "    $date: $requests"
    done < <(sqlite3 "$db_path" "SELECT DATE(start_ts), COUNT(*) FROM ai_queries GROUP BY DATE(start_ts) ORDER BY COUNT(*) DESC, DATE(start_ts) DESC LIMIT 5;" 2>/dev/null || true)
    echo "  model breakdown:"
    while IFS='|' read -r model requests; do
      [[ -n "$model" ]] || continue
      echo "    $model: $requests"
    done < <(sqlite3 "$db_path" "SELECT COALESCE(NULLIF(model_id, ''), 'unknown'), COUNT(*) FROM ai_queries GROUP BY COALESCE(NULLIF(model_id, ''), 'unknown') ORDER BY COUNT(*) DESC, 1 ASC;" 2>/dev/null || true)
  else
    echo "SQLite history: not found"
  fi
}

warp_ai_quick_usage() {
  local db_path plist_path plist_output
  local summary_parts=()
  local requests_used=0
  local requests_limit=0
  local is_unlimited=false
  local subscription_type="Unknown"
  local next_refresh_time="unknown"

  db_path="$(warp_ai_find_usage_db 2>/dev/null || true)"
  plist_path="$(warp_ai_find_usage_plist 2>/dev/null || true)"

  if [[ -n "$plist_path" ]]; then
    plist_output="$(warp_ai_usage_plist_summary "$plist_path" 2>/dev/null || true)"
    if [[ "$plist_output" != plist_error=* ]]; then
      while IFS='=' read -r key value; do
        case "$key" in
          requests_used) requests_used="$value" ;;
          requests_limit) requests_limit="$value" ;;
          is_unlimited) is_unlimited="$value" ;;
          subscription_type) subscription_type="$value" ;;
          next_refresh_time) next_refresh_time="$value" ;;
        esac
      done <<< "$plist_output"

      if [[ "$is_unlimited" == "true" ]]; then
        summary_parts+=("plan ${subscription_type} (unlimited)")
      else
        local percent
        percent="$(awk -v used="$requests_used" -v limit="$requests_limit" 'BEGIN { if (limit > 0) printf "%.1f", (used / limit) * 100; else printf "0.0" }')"
        summary_parts+=("plan ${subscription_type} ${requests_used}/${requests_limit} (${percent}%)")
      fi
      summary_parts+=("refresh ${next_refresh_time}")
    fi
  fi

  if [[ -n "$db_path" && -n "$(command -v sqlite3 2>/dev/null)" ]]; then
    local total_requests today_requests weekly_requests
    local ai_table schema_columns
    ai_table="$(sqlite3 "$db_path" "SELECT name FROM sqlite_master WHERE type='table' AND name='ai_queries';" 2>/dev/null || true)"
    if [[ "$ai_table" == "ai_queries" ]]; then
      schema_columns="$(sqlite3 "$db_path" "PRAGMA table_info(ai_queries);" 2>/dev/null || true)"
      if [[ "$schema_columns" != *"|start_ts|"* || "$schema_columns" != *"|model_id|"* ]]; then
        summary_parts+=("history unsupported")
      else
        total_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries;" 2>/dev/null || true)"
        if [[ -n "$total_requests" && "$total_requests" != "0" ]]; then
          today_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries WHERE DATE(start_ts) = DATE('now');" 2>/dev/null || true)"
          weekly_requests="$(sqlite3 "$db_path" "SELECT COUNT(*) FROM ai_queries WHERE start_ts >= datetime('now', '-7 days');" 2>/dev/null || true)"
          summary_parts+=("today ${today_requests}")
          summary_parts+=("7d ${weekly_requests}")
        fi
      fi
    fi
  fi

  if [[ ${#summary_parts[@]} -eq 0 ]]; then
    echo "Warp AI: no usage data found"
    return 0
  fi

  local summary
  summary="$(IFS=' | '; print -r -- "${summary_parts[*]}")"
  echo "Warp AI: $summary"
}

warp_ai_tab_config_dir() {
  if [[ -n "${WARP_AI_TAB_CONFIG_DIR:-}" ]]; then
    printf '%s\n' "$WARP_AI_TAB_CONFIG_DIR"
    return 0
  fi

  if [[ -d "$HOME/.warp-preview" && ! -d "$HOME/.warp" ]]; then
    printf '%s\n' "$HOME/.warp-preview/tab_configs"
    return 0
  fi

  printf '%s\n' "$HOME/.warp/tab_configs"
}

warp_ai_uri_scheme() {
  if [[ -n "${WARP_AI_URI_SCHEME:-}" ]]; then
    printf '%s\n' "$WARP_AI_URI_SCHEME"
    return 0
  fi

  if [[ -d "$HOME/.warp-preview" && ! -d "$HOME/.warp" ]]; then
    printf '%s\n' "warppreview"
    return 0
  fi

  printf '%s\n' "warp"
}

warp_ai_install_tab_configs() {
  local tab_dir install_dir logs_dir profile_path toolkit_config doctor_config
  tab_dir="$(warp_ai_tab_config_dir)"
  install_dir="${WARP_AI_ROOT:-$HOME/.superwarp-toolkit}"
  logs_dir="${WARP_AI_LOG_DIR:-$HOME/Library/Logs/WarpAI}"
  profile_path="${install_dir}/warp-ai-enhancement-profile.zsh"
  toolkit_config="${tab_dir}/superwarp_toolkit.toml"
  doctor_config="${tab_dir}/superwarp_doctor.toml"

  mkdir -p "$tab_dir" "$logs_dir"

  cat > "$toolkit_config" <<EOF
name = "Superwarp Toolkit"
title = "Superwarp Toolkit"
color = "blue"

[[panes]]
id = "root"
split = "horizontal"
children = ["toolkit", "logs"]

[[panes]]
id = "toolkit"
type = "terminal"
directory = "$install_dir"
commands = [
  "printf 'Superwarp toolkit ready in %s\\n' \"$install_dir\"",
]
is_focused = true

[[panes]]
id = "logs"
type = "terminal"
directory = "$logs_dir"
commands = [
  "ls -lah",
]
EOF

  cat > "$doctor_config" <<EOF
name = "Superwarp Doctor"
title = "Superwarp Doctor"
color = "yellow"

[[panes]]
id = "root"
split = "vertical"
children = ["doctor", "logs"]

[[panes]]
id = "doctor"
type = "terminal"
shell = "zsh"
directory = "$install_dir"
commands = [
  "source \"$profile_path\" >/dev/null 2>&1; warp_ai_doctor",
]
is_focused = true

[[panes]]
id = "logs"
type = "terminal"
directory = "$logs_dir"
commands = [
  "ls -lah",
]
EOF

  echo "Installed Warp Tab Configs:"
  echo "  - $toolkit_config"
  echo "  - $doctor_config"
  echo "Open them in Warp from the + menu or via warp://tab_config/<name>."
}

warp_ai_open() {
  local target="${1:-}"
  local opener="${WARP_AI_OPEN_BIN:-open}"
  local uri=""
  local scheme
  scheme="$(warp_ai_uri_scheme)"

  case "$target" in
    toolkit)
      uri="${scheme}://tab_config/superwarp_toolkit"
      ;;
    doctor)
      uri="${scheme}://tab_config/superwarp_doctor"
      ;;
    permissions)
      warp_ai_open_permission_panes
      return $?
      ;;
    *)
      echo "Usage: warpai-open toolkit | doctor | permissions"
      return 1
      ;;
  esac

  if [[ "${WARP_AI_OPEN_URL_ONLY:-0}" == "1" ]]; then
    echo "$uri"
    return 0
  fi

  "$opener" "$uri"
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
  if [[ -n "$(command -v python3 2>/dev/null)" ]]; then
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
  if [[ -n "$(command -v gemini 2>/dev/null)" ]]; then
    gemini -p "Use google_web_search to research this query and return a concise summary with source citations: ${query}"
    return $?
  fi

  if [[ -n "$(command -v "$WARP_AI_GROK_BIN" 2>/dev/null)" ]]; then
    if [[ -n "${WARP_AI_GROK_MODEL:-}" ]]; then
      "$WARP_AI_GROK_BIN" -p "Please summarize this query with sources for research: ${query}" --model "${WARP_AI_GROK_MODEL}" --output-format plain --no-auto-update
    else
      "$WARP_AI_GROK_BIN" -p "Please summarize this query with sources for research: ${query}" --output-format plain --no-auto-update
    fi
    return $?
  fi

  if [[ -n "$(command -v python3 2>/dev/null)" ]]; then
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
    echo "⚠️ Gemini/Grok CLI not found, and python3 missing for fallback web lookup."
  fi
}

warp_ai_invoke_grok() {
  local query="$*"
  if [[ -z "$query" ]]; then
    echo "❌ Usage: warp_ai_invoke_grok '<query>'"
    return 1
  fi

  if [[ -z "$(command -v "$WARP_AI_GROK_BIN" 2>/dev/null)" ]]; then
    echo "⚠️ Grok CLI not installed."
    echo "   Install with: ./install.sh --install-grok"
    echo "   Or set WARP_AI_GROK_BIN if installed as a custom path."
    return 1
  fi

  warp_ai_log "TOOL" "Direct Grok request: $query"
  if [[ -n "${WARP_AI_GROK_MODEL:-}" ]]; then
    "$WARP_AI_GROK_BIN" -p "$query" --model "$WARP_AI_GROK_MODEL" --output-format plain --no-auto-update
  else
    "$WARP_AI_GROK_BIN" -p "$query" --output-format plain --no-auto-update
  fi
}

warp_ai_invoke_codex() {
  local mode="${1:-ask}"
  shift || true

  if [[ "$mode" == "--help" || "$mode" == "-h" || "$mode" == "help" || "$mode" == "" ]]; then
    cat <<'EOF'
Usage: warp_ai_invoke_codex <prompt>
Usage: warp_ai_invoke_codex ask "<prompt>"
Usage: warp_ai_invoke_codex raw <codex-args...>

Examples:
  warpai-codex explain why this command keeps failing
  warpai-codex raw --help
EOF
    return 0
  fi

  if [[ -z "$(command -v "$WARP_AI_CODEX_BIN" 2>/dev/null)" ]]; then
    echo "⚠️ Codex CLI not found. Install and authenticate Codex first."
    echo "   Set WARP_AI_CODEX_BIN if your executable is not on PATH and set up auth in your Codex CLI profile."
    return 1
  fi

  local -a payload
  if [[ "$mode" == "raw" ]]; then
    if [[ $# -eq 0 ]]; then
      echo "❌ Usage: warp_ai_invoke_codex raw <codex-args...>"
      return 1
    fi
    payload=("$@")
  elif [[ "$mode" == "ask" ]]; then
    if [[ $# -eq 0 ]]; then
      echo "❌ Usage: warp_ai_invoke_codex ask \"<prompt>\""
      return 1
    fi
    payload=("$*")
  else
    payload=("$mode" "$@")
  fi

  warp_ai_log "TOOL" "Codex requested"
  echo "⚙️ Running Codex with: ${payload[*]}"

  if [[ "$mode" == "raw" || "$mode" == "ask" ]]; then
    "$WARP_AI_CODEX_BIN" "${payload[@]}"
  else
    "$WARP_AI_CODEX_BIN" "$mode" "$@"
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
  if [[ -z "$(command -v ollama 2>/dev/null)" ]]; then
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
      if [[ -n "$(command -v osascript 2>/dev/null)" ]]; then
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
      if [[ -n "$(command -v osascript 2>/dev/null)" ]]; then
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
      if [[ -n "$(command -v osascript 2>/dev/null)" ]]; then
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
      if [[ -n "$(command -v screencapture 2>/dev/null)" ]]; then
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
    if [[ "$recent_file" == *"Grok"* || "$recent_file" == *"grok"* ]]; then
      projects+=("🤖 Grok workflow activity detected")
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
alias warpai-grok='warp_ai_invoke_grok'
alias warpai-image='warp_ai_invoke_image_analysis'
alias warpai-calc='warp_ai_calculate'
alias warpai-cmd='warp_ai_command'
alias warpai-doctor='warp_ai_doctor'
alias warpai-permissions='warp_ai_open_permission_panes'
alias warpai-usage='warp_ai_usage'
alias warpai-quick='warp_ai_quick_usage'
alias warpai-codex='warp_ai_invoke_codex'
alias warpai-layout-install='warp_ai_install_tab_configs'
alias warpai-open='warp_ai_open'

export WARP_AI_READY=1
