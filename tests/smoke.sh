#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

run_smoke_install() {
  local home_dir="$1"
  shift
  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" "$@"
}

test_default_install() {
  local home_dir
  home_dir="$(mktemp -d)"
  run_smoke_install "$home_dir" >/dev/null

  [[ -f "$home_dir/.zshrc" ]] || fail "default install did not create ~/.zshrc"
  grep -Fq 'WARP AI ENHANCEMENT SUITE BEGIN' "$home_dir/.zshrc" || fail "managed zshrc block missing"

  local output
  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; echo READY=${WARP_AI_READY:-0}; warp_ai_calculate "2+2"' 2>&1)"
  assert_contains "$output" "READY=1"
  assert_contains "$output" "Result: 4"
}

test_custom_install_dir() {
  local home_dir custom_dir output
  home_dir="$(mktemp -d)"
  custom_dir="$home_dir/custom-suite"

  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 WARP_AI_ENHANCEMENT_DIR="$custom_dir" "$ROOT_DIR/install.sh" >/dev/null
  [[ -f "$custom_dir/warp-ai-enhancement-profile.zsh" ]] || fail "custom install profile missing"

  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; echo ROOT=${WARP_AI_ROOT}; echo READY=${WARP_AI_READY:-0}' 2>&1)"
  assert_contains "$output" "ROOT=$custom_dir"
  assert_contains "$output" "READY=1"
}

test_unknown_flag_rejected() {
  local home_dir
  home_dir="$(mktemp -d)"
  if HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --bogus >/dev/null 2>&1; then
    fail "unknown install flag unexpectedly succeeded"
  fi
}

test_unrelated_zshrc_comment_does_not_block_install() {
  local home_dir
  home_dir="$(mktemp -d)"
  printf '# notes: WARP AI ENHANCEMENT SUITE\n' > "$home_dir/.zshrc"

  run_smoke_install "$home_dir" >/dev/null
  grep -Fq 'WARP AI ENHANCEMENT SUITE BEGIN' "$home_dir/.zshrc" || fail "managed block was not appended after unrelated comment"
}

test_help_includes_new_flags() {
  local output
  output="$("$ROOT_DIR/install.sh" --help 2>&1)"
  assert_contains "$output" "--install-gemini"
  assert_contains "$output" "--install-ollama"
  assert_contains "$output" "--install-grok"
  assert_contains "$output" "--accept-defaults"
  assert_contains "$output" "WARP_AI_INSTALL_DEFAULTS_FILE"
  assert_contains "$output" "WARP_AI_ACCEPT_DEFAULTS"
  assert_contains "$output" "WARP_AI_GROK_INSTALL_COMMAND"
  assert_contains "$output" "WARP_AI_GROK_BIN"
  assert_contains "$output" "--no-permission-panes"
  assert_contains "$output" "WARP_AI_CODEX_INSTALL_COMMAND"
  assert_contains "$output" "--install-codex"
}


test_install_codex_with_command() {
  local home_dir codex_path custom_install_cmd
  home_dir="$(mktemp -d)"
  codex_path="$home_dir/.local/bin/codex"
  custom_install_cmd="$(
cat <<EOF
mkdir -p '$home_dir/.local/bin'
cat > '$codex_path' <<'EOF_SCRIPT'
#!/usr/bin/env sh
printf 'codex-installed'
EOF_SCRIPT
chmod +x '$codex_path'
EOF
  )"

  HOME="$home_dir" \
    WARP_AI_CODEX_INSTALL_COMMAND="$custom_install_cmd" \
    WARP_AI_CODEX_BIN="$codex_path" \
    WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 \
    "$ROOT_DIR/install.sh" --install-codex --no-permission-panes >/dev/null

  [[ -x "$codex_path" ]] || fail "custom codex install command did not create executable"
  [[ "$($codex_path)" == "codex-installed" ]] || fail "custom codex install command produced unexpected output"
}

test_install_codex_missing_config_fails() {
  local home_dir custom_codex_path output exit_code
  home_dir="$(mktemp -d)"
  custom_codex_path="$home_dir/.local/bin/missing-codex"

  set +e
  output="$(HOME="$home_dir" WARP_AI_CODEX_BIN="$custom_codex_path" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --install-codex --no-permission-panes 2>&1)"
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    fail "--install-codex without configuration unexpectedly succeeded"
  fi

  assert_contains "$output" "Codex CLI is not installed, and no install command was configured."
  assert_contains "$output" "WARP_AI_CODEX_INSTALL_COMMAND"
  assert_contains "$output" "WARP_AI_CODEX_NPM_PACKAGE"
}

test_install_grok_with_command() {
  local home_dir grok_path custom_install_cmd
  home_dir="$(mktemp -d)"
  grok_path="$home_dir/.local/bin/grok"
  custom_install_cmd="$(
cat <<EOF
mkdir -p '$home_dir/.local/bin'
cat > '$grok_path' <<'EOF_SCRIPT'
#!/usr/bin/env sh
printf 'grok-installed'
EOF_SCRIPT
chmod +x '$grok_path'
EOF
  )"

  HOME="$home_dir" \
    WARP_AI_GROK_INSTALL_COMMAND="$custom_install_cmd" \
    WARP_AI_GROK_BIN="$grok_path" \
    WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 \
    "$ROOT_DIR/install.sh" --install-grok --no-permission-panes >/dev/null

  [[ -x "$grok_path" ]] || fail "custom grok install command did not create executable"
  [[ "$("$grok_path")" == "grok-installed" ]] || fail "custom grok command output mismatch"
}

test_uninstall_removes_install_dir() {
  local home_dir
  home_dir="$(mktemp -d)"
  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null
  [[ -d "$home_dir/.superwarp-toolkit" ]] || fail "install dir missing before uninstall"

  HOME="$home_dir" "$ROOT_DIR/uninstall.sh" >/dev/null
  [[ ! -d "$home_dir/.superwarp-toolkit" ]] || fail "install dir still present after uninstall"
}

test_repo_native_assets_exist() {
  local required_files=(
    "$ROOT_DIR/AGENTS.md"
    "$ROOT_DIR/WARP.md"
    "$ROOT_DIR/.agents/skills/suite-maintainer/SKILL.md"
    "$ROOT_DIR/.agents/skills/tab-config-installer/SKILL.md"
    "$ROOT_DIR/.agents/skills/warp-permission-doctor/SKILL.md"
    "$ROOT_DIR/.agents/skills/usage-session-analyst/SKILL.md"
    "$ROOT_DIR/.agents/skills/codex-command-assistant/SKILL.md"
    "$ROOT_DIR/.warp/workflows/bootstrap-superwarp.yaml"
    "$ROOT_DIR/.warp/workflows/install-tab-configs.yaml"
    "$ROOT_DIR/.warp/workflows/suite-health-check.yaml"
    "$ROOT_DIR/.warp/workflows/permission-readiness-check.yaml"
    "$ROOT_DIR/.warp/workflows/usage-snapshot.yaml"
    "$ROOT_DIR/.warp/workflows/install-suite-safely.yaml"
    "$ROOT_DIR/.warp/workflows/install-uninstall-validation.yaml"
    "$ROOT_DIR/.warp/workflows/codex-assistant.yaml"
  )

  local path
  for path in "${required_files[@]}"; do
    [[ -f "$path" ]] || fail "expected repo-native asset missing: $path"
  done

  grep -Fq "Warp-Native Superwarp Layer" "$ROOT_DIR/README.md" || fail "README missing Warp-native section"
  grep -Fq ".agents/skills/" "$ROOT_DIR/WARP.md" || fail "WARP.md missing skill guidance"
  grep -Fq "warpai-open" "$ROOT_DIR/AGENTS.md" || fail "AGENTS.md missing warpai-open command"
}

test_warp_asset_contracts() {
  ruby - "$ROOT_DIR" <<'RUBY' || exit 1
require "yaml"

root = ARGV.fetch(0)
workflow_paths = Dir[File.join(root, ".warp/workflows/*.yaml")]
abort("FAIL: no workflow files found") if workflow_paths.empty?

workflow_paths.each do |path|
  doc = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
  abort("FAIL: workflow #{path} is empty") unless doc.is_a?(Hash)
  %w[name command].each do |field|
    abort("FAIL: workflow #{path} missing #{field}") if doc[field].to_s.strip.empty?
  end
  shells = doc["shells"]
  if shells
    allowed = %w[zsh bash fish]
    abort("FAIL: workflow #{path} has invalid shells") unless shells.is_a?(Array) && shells.all? { |s| allowed.include?(s) }
  end

  placeholders = doc["command"].scan(/\{\{([^}]+)\}\}/).flatten.uniq.sort
  arg_names = Array(doc["arguments"]).map { |arg| arg["name"] }.compact.sort
  abort("FAIL: workflow #{path} placeholders #{placeholders.inspect} do not match arguments #{arg_names.inspect}") unless placeholders == arg_names
end
RUBY

  local skill
  for skill in "$ROOT_DIR"/.agents/skills/*/SKILL.md; do
    grep -Fq -- "---" "$skill" || fail "skill missing frontmatter fence: $skill"
    grep -Eq '^name: ' "$skill" || fail "skill missing name frontmatter: $skill"
    grep -Eq '^description: ' "$skill" || fail "skill missing description frontmatter: $skill"
  done
}

test_repo_doctor_uses_repo_toolkit_path() {
  local output
  output="$(HOME="$(mktemp -d)" TERM_PROGRAM=WarpTerminal zsh -ic 'ROOT="'"$ROOT_DIR"'"; export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"; source "$WARP_AI_TOOLKIT" >/dev/null; warp_ai_doctor' 2>&1)"
  assert_contains "$output" "toolkit file: ok"
}

test_tab_config_install() {
  local home_dir output
  home_dir="$(mktemp -d)"
  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null

  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-layout-install' 2>&1)"
  assert_contains "$output" "Installed Warp Tab Configs:"
  [[ -f "$home_dir/.warp/tab_configs/superwarp_toolkit.toml" ]] || fail "toolkit tab config missing"
  [[ -f "$home_dir/.warp/tab_configs/superwarp_doctor.toml" ]] || fail "doctor tab config missing"
  grep -Fq 'name = "Superwarp Toolkit"' "$home_dir/.warp/tab_configs/superwarp_toolkit.toml" || fail "toolkit tab config name missing"
  grep -Fq 'warp_ai_doctor' "$home_dir/.warp/tab_configs/superwarp_doctor.toml" || fail "doctor tab config command missing"

  output="$(HOME="$home_dir" WARP_AI_OPEN_URL_ONLY=1 TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-open toolkit; warpai-open doctor' 2>&1)"
  assert_contains "$output" "warp://tab_config/superwarp_toolkit"
  assert_contains "$output" "warp://tab_config/superwarp_doctor"
}

test_tab_config_preview_detection() {
  local home_dir output
  home_dir="$(mktemp -d)"
  mkdir -p "$home_dir/.warp-preview"

  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null
  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-layout-install' 2>&1)"
  [[ -f "$home_dir/.warp-preview/tab_configs/superwarp_toolkit.toml" ]] || fail "preview toolkit tab config missing"
  [[ -f "$home_dir/.warp-preview/tab_configs/superwarp_doctor.toml" ]] || fail "preview doctor tab config missing"

  output="$(HOME="$home_dir" WARP_AI_OPEN_URL_ONLY=1 TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-open toolkit; warpai-open doctor' 2>&1)"
  assert_contains "$output" "warppreview://tab_config/superwarp_toolkit"
  assert_contains "$output" "warppreview://tab_config/superwarp_doctor"
}

test_codex_command_integration() {
  local home_dir fake_bin missing_bin
  local working_output missing_output
  local cmd_script

  home_dir="$(mktemp -d)"
  fake_bin="$home_dir/bin/codex"
  cmd_script="$home_dir/run-codex-command.zsh"
  mkdir -p "$home_dir/bin"

  cat > "$fake_bin" <<'EOF'
#!/usr/bin/env sh
printf 'codex-hit: %s\n' "$*"
EOF
  chmod +x "$fake_bin"

  cat > "$cmd_script" <<EOF
source "$ROOT_DIR/scripts/warp-ai-toolkit.sh"
warp_ai_invoke_codex ask 'please draft a safe rollout'
EOF

  working_output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal WARP_AI_CODEX_BIN="$fake_bin" zsh "$cmd_script" 2>&1)"
  assert_contains "$working_output" "⚙️ Running Codex with: please draft a safe rollout"
  assert_contains "$working_output" "codex-hit: please draft a safe rollout"

  missing_bin="$home_dir/missing-codex"
  cat > "$cmd_script" <<EOF
source "$ROOT_DIR/scripts/warp-ai-toolkit.sh"
warp_ai_invoke_codex ask 'this should fail'
EOF

  missing_output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal WARP_AI_CODEX_BIN="$missing_bin" zsh "$cmd_script" 2>&1 || true)"
  assert_contains "$missing_output" "Codex CLI not found"
  assert_contains "$missing_output" "Install and authenticate Codex first"
}

test_grok_command_integration() {
  local home_dir fake_grok cmd_script
  local working_output missing_output

  home_dir="$(mktemp -d)"
  fake_grok="$home_dir/bin/grok"
  mkdir -p "$home_dir/bin"
  cmd_script="$home_dir/run-grok-command.zsh"

  cat > "$fake_grok" <<'EOF'
#!/usr/bin/env sh
printf 'grok-hit: %s\n' "$*"
EOF
  chmod +x "$fake_grok"

  cat > "$cmd_script" <<EOF
source "$ROOT_DIR/scripts/warp-ai-toolkit.sh"
WARP_AI_GROK_BIN="$fake_grok"
warp_ai_invoke_grok 'explain this repo in 3 points'
EOF

  working_output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh "$cmd_script" 2>&1)"
  assert_contains "$working_output" "grok-hit:"
  assert_contains "$working_output" "-p explain this repo in 3 points"

  cat > "$cmd_script" <<EOF
source "$ROOT_DIR/scripts/warp-ai-toolkit.sh"
WARP_AI_GROK_BIN="$home_dir/bin/missing-grok"
warp_ai_invoke_grok 'explain this'
EOF

  missing_output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh "$cmd_script" 2>&1 || true)"
  assert_contains "$missing_output" "⚠️ Grok CLI not installed"
  assert_contains "$missing_output" "./install.sh --install-grok"
}

create_usage_fixtures() {
  local fixture_dir="$1"
  local db_path="$fixture_dir/warp.sqlite"
  local plist_path="$fixture_dir/dev.warp.Warp-Stable.plist"
  local today two_days_ago ten_days_ago next_refresh_time
  local fixture_values

  fixture_values="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone

now = datetime.now()
print((now.replace(hour=9, minute=0, second=0, microsecond=0)).strftime("%Y-%m-%d %H:%M:%S"))
print((now - timedelta(days=2)).replace(hour=9, minute=0, second=0, microsecond=0).strftime("%Y-%m-%d %H:%M:%S"))
print((now - timedelta(days=10)).replace(hour=9, minute=0, second=0, microsecond=0).strftime("%Y-%m-%d %H:%M:%S"))
print((now + timedelta(days=1)).astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"

  today="$(printf '%s\n' "$fixture_values" | sed -n '1p')"
  two_days_ago="$(printf '%s\n' "$fixture_values" | sed -n '2p')"
  ten_days_ago="$(printf '%s\n' "$fixture_values" | sed -n '3p')"
  next_refresh_time="$(printf '%s\n' "$fixture_values" | sed -n '4p')"

  sqlite3 "$db_path" <<SQL
CREATE TABLE ai_queries (start_ts TEXT NOT NULL, model_id TEXT NOT NULL);
INSERT INTO ai_queries (start_ts, model_id) VALUES
  ('$today', 'gpt-5'),
  ('$two_days_ago', 'claude-3.7-sonnet'),
  ('$ten_days_ago', 'gemini-2.5-pro');
SQL

  python3 - "$plist_path" "$next_refresh_time" <<'PY'
import json
import plistlib
import sys

path = sys.argv[1]
next_refresh_time = sys.argv[2]

payload = {
    "AIRequestLimitInfo": json.dumps(
        {
            "num_requests_used_since_refresh": 224,
            "limit": 2500,
            "is_unlimited": False,
            "next_refresh_time": next_refresh_time,
            "voice_request_limit": 999999,
            "max_codebase_indices": 40,
        }
    )
}

with open(path, "wb") as handle:
    plistlib.dump(payload, handle)
PY
}

test_usage_helpers_with_fixtures() {
  local home_dir fixture_dir db_path plist_path output
  home_dir="$(mktemp -d)"
  fixture_dir="$(mktemp -d)"
  db_path="$fixture_dir/warp.sqlite"
  plist_path="$fixture_dir/dev.warp.Warp-Stable.plist"

  create_usage_fixtures "$fixture_dir"
  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null

  output="$(HOME="$home_dir" WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-usage; warpai-quick' 2>&1)"
  assert_contains "$output" "Warp AI Usage Report"
  assert_contains "$output" "plan: Pro"
  assert_contains "$output" "usage: 224/2500"
  assert_contains "$output" "total requests: 3"
  assert_contains "$output" "today: 1"
  assert_contains "$output" "last 7 days: 2"
  assert_contains "$output" "model breakdown"
  assert_contains "$output" "Warp AI: plan Pro 224/2500"
}

test_usage_helpers_handle_missing_data() {
  local home_dir output
  home_dir="$(mktemp -d)"
  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null

  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-usage; warpai-quick' 2>&1)"
  assert_contains "$output" "Plist snapshot: not found"
  assert_contains "$output" "SQLite history: not found"
  assert_contains "$output" "Warp AI: no usage data found"
}

test_usage_helpers_handle_unsupported_sqlite_schema() {
  local home_dir fixture_dir db_path plist_path output
  home_dir="$(mktemp -d)"
  fixture_dir="$(mktemp -d)"
  db_path="$fixture_dir/warp.sqlite"
  plist_path="$fixture_dir/dev.warp.Warp-Stable.plist"

  sqlite3 "$db_path" <<SQL
CREATE TABLE ai_queries (created_at TEXT NOT NULL, model TEXT NOT NULL);
INSERT INTO ai_queries (created_at, model) VALUES ('2026-06-04 09:00:00', 'gpt-5');
SQL

  python3 - "$plist_path" <<'PY'
import json
import plistlib
import sys

path = sys.argv[1]
payload = {
    "AIRequestLimitInfo": json.dumps(
        {
            "num_requests_used_since_refresh": 5,
            "limit": 100,
            "is_unlimited": False,
            "next_refresh_time": "2026-06-05T18:40:59Z",
        }
    )
}

with open(path, "wb") as handle:
    plistlib.dump(payload, handle)
PY

  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null
  output="$(HOME="$home_dir" WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-usage; warpai-quick' 2>&1)"
  assert_contains "$output" "SQLite history: ai_queries schema unsupported"
  assert_contains "$output" "history unsupported"
}

test_usage_helpers_handle_malformed_plist_values() {
  local home_dir fixture_dir db_path plist_path output
  home_dir="$(mktemp -d)"
  fixture_dir="$(mktemp -d)"
  db_path="$fixture_dir/warp.sqlite"
  plist_path="$fixture_dir/dev.warp.Warp-Stable.plist"

  sqlite3 "$db_path" <<SQL
CREATE TABLE ai_queries (start_ts TEXT NOT NULL, model_id TEXT NOT NULL);
INSERT INTO ai_queries (start_ts, model_id) VALUES ('2026-06-04 09:00:00', 'gpt-5');
SQL

  python3 - "$plist_path" <<'PY'
import json
import plistlib
import sys

path = sys.argv[1]
payload = {
    "AIRequestLimitInfo": json.dumps(
        {
            "num_requests_used_since_refresh": "not-a-number",
            "limit": 100,
            "is_unlimited": False,
            "next_refresh_time": "2026-06-05T18:40:59Z",
        }
    )
}

with open(path, "wb") as handle:
    plistlib.dump(payload, handle)
PY

  HOME="$home_dir" WARP_AI_ACCEPT_DEFAULTS=0 WARP_AI_OLLAMA_NO_START=1 WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null
  output="$(HOME="$home_dir" WARP_AI_USAGE_DB="$db_path" WARP_AI_USAGE_PLIST="$plist_path" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; warpai-usage; warpai-quick' 2>&1)"
  assert_contains "$output" "Plist snapshot: unavailable"
  assert_contains "$output" "Warp AI: today 1 7d 1"
}

printf 'Running smoke tests...\n'
test_default_install
test_custom_install_dir
test_unknown_flag_rejected
test_unrelated_zshrc_comment_does_not_block_install
test_help_includes_new_flags
test_install_codex_with_command
test_install_codex_missing_config_fails
test_uninstall_removes_install_dir
test_repo_native_assets_exist
test_warp_asset_contracts
test_repo_doctor_uses_repo_toolkit_path
test_install_grok_with_command
test_tab_config_install
test_tab_config_preview_detection
test_codex_command_integration
test_grok_command_integration
test_usage_helpers_with_fixtures
test_usage_helpers_handle_missing_data
test_usage_helpers_handle_unsupported_sqlite_schema
test_usage_helpers_handle_malformed_plist_values
printf 'Smoke tests passed.\n'
