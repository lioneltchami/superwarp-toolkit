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

test_default_install() {
  local home_dir
  home_dir="$(mktemp -d)"
  HOME="$home_dir" "$ROOT_DIR/install.sh" >/dev/null

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

  HOME="$home_dir" WARP_AI_ENHANCEMENT_DIR="$custom_dir" "$ROOT_DIR/install.sh" >/dev/null
  [[ -f "$custom_dir/warp-ai-enhancement-profile.zsh" ]] || fail "custom install profile missing"

  output="$(HOME="$home_dir" TERM_PROGRAM=WarpTerminal zsh -ic 'source "$HOME/.zshrc" >/dev/null; echo ROOT=${WARP_AI_ROOT}; echo READY=${WARP_AI_READY:-0}' 2>&1)"
  assert_contains "$output" "ROOT=$custom_dir"
  assert_contains "$output" "READY=1"
}

test_unknown_flag_rejected() {
  local home_dir
  home_dir="$(mktemp -d)"
  if HOME="$home_dir" "$ROOT_DIR/install.sh" --bogus >/dev/null 2>&1; then
    fail "unknown install flag unexpectedly succeeded"
  fi
}

test_unrelated_zshrc_comment_does_not_block_install() {
  local home_dir
  home_dir="$(mktemp -d)"
  printf '# notes: WARP AI ENHANCEMENT SUITE\n' > "$home_dir/.zshrc"

  HOME="$home_dir" "$ROOT_DIR/install.sh" >/dev/null
  grep -Fq 'WARP AI ENHANCEMENT SUITE BEGIN' "$home_dir/.zshrc" || fail "managed block was not appended after unrelated comment"
}

test_help_includes_new_flags() {
  local output
  output="$("$ROOT_DIR/install.sh" --help 2>&1)"
  assert_contains "$output" "--install-gemini"
  assert_contains "$output" "--install-ollama"
  assert_contains "$output" "--no-permission-panes"
}

test_uninstall_removes_install_dir() {
  local home_dir
  home_dir="$(mktemp -d)"
  HOME="$home_dir" "$ROOT_DIR/install.sh" --no-permission-panes >/dev/null
  [[ -d "$home_dir/.warp-ai-enhancement" ]] || fail "install dir missing before uninstall"

  HOME="$home_dir" "$ROOT_DIR/uninstall.sh" >/dev/null
  [[ ! -d "$home_dir/.warp-ai-enhancement" ]] || fail "install dir still present after uninstall"
}

printf 'Running smoke tests...\n'
test_default_install
test_custom_install_dir
test_unknown_flag_rejected
test_unrelated_zshrc_comment_does_not_block_install
test_help_includes_new_flags
test_uninstall_removes_install_dir
printf 'Smoke tests passed.\n'
