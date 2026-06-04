---
name: warp-permission-doctor
description: Diagnose Warp pane automation and screenshot failures on macOS. Use when split, close-panel, or screenshot behavior is blocked or inconsistent.
---

# Warp Permission Doctor

## When to use

Use this skill when any of these happen:

- `warpai-cmd split right` fails
- `warpai-cmd split down` fails
- `warpai-cmd close panel` fails
- `warpai-cmd screenshot` fails
- `warpai-doctor` reports manual permission checks remaining

## Instructions

1. Run a doctor pass first:

```bash
ROOT="$(git rev-parse --show-toplevel)"
export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_doctor"
```

2. Interpret failures in terms of actual macOS dependencies:
   - `osascript` and `System Events` for pane actions
   - `screencapture` and Screen Recording approval for screenshots
   - a live Warp window for pane automation
3. If the user wants help reopening settings panes, run:

```bash
ROOT="$(git rev-parse --show-toplevel)"
export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_open_permission_panes"
```

4. Explain exactly which manual approvals are still needed:
   - `Accessibility`
   - `Automation`
   - `Screen Recording`
5. If behavior still looks wrong after permissions are granted, use `tests/live-gui-validation.zsh` from a real Warp session.

## Verification

For repo changes, run:

```bash
zsh -n scripts/warp-ai-toolkit.sh
bash tests/smoke.sh
```

For live validation, run from inside Warp:

```bash
zsh tests/live-gui-validation.zsh
```

## Important notes

- Never claim the script can grant permissions automatically. It can only open the relevant System Settings panes.
- If Warp shortcuts were remapped, pane automation may fail even with correct permissions.
- Outside Warp, `warpai-doctor` should report that automation was not checked.

## Examples

- “Why is split-right failing on this Mac?”
- “Open the right permission panes and tell me what I still need to approve.”
- “Validate that screenshots work in a live Warp window.”
