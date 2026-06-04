#!/usr/bin/env zsh
set -euo pipefail

output_file="/tmp/warp-live-validation.txt"
screenshot_file="/tmp/warp-live-shot.png"

{
  echo "TERM_PROGRAM=${TERM_PROGRAM:-}"
  echo "WARP_AI_READY=${WARP_AI_READY:-0}"
  whence -w warp_ai_calculate
  whence -w warp_ai_command
  warp_ai_calculate "2+2"

  set +e
  warp_ai_command split right
  split_right_status=$?
  echo "split_right_status=${split_right_status}"

  sleep 1

  warp_ai_command split down
  split_down_status=$?
  echo "split_down_status=${split_down_status}"

  sleep 1

  warp_ai_command screenshot "$screenshot_file"
  screenshot_status=$?
  echo "screenshot_status=${screenshot_status}"
  set -e
} >"$output_file" 2>&1
