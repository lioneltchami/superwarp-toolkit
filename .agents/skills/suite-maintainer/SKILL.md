---
name: suite-maintainer
description: Maintain the Warp AI Enhancement Suite safely as a macOS-only Warp toolkit. Use when editing install, runtime, docs, or tests in this repo.
---

# Suite Maintainer

## When to use

Use this skill when the task touches the toolkit itself:

- `install.sh`
- `uninstall.sh`
- `warp-ai-enhancement-profile.zsh`
- `scripts/warp-ai-toolkit.sh`
- `tests/smoke.sh`
- `tests/live-gui-validation.zsh`
- `README.md`
- `WARP.md`
- `.agents/skills/`
- `.warp/workflows/`

## Instructions

1. Treat this repository as a macOS-only zsh helper layer for Warp Terminal.
2. Keep changes local-first and honest. Do not imply deep Warp internals integration that the repo does not actually have.
3. Prefer extending existing commands such as `warpai-doctor`, `warpai-permissions`, `warpai-usage`, and `warpai-quick` before adding new surface area.
4. Do not reintroduce Windows, PowerShell, Linux, Docker, or hosted terminal behavior unless the task explicitly changes scope.
5. If you add a new `warpai-*` command:
   - document it in `README.md`
   - wire its alias in `scripts/warp-ai-toolkit.sh`
   - add smoke coverage in `tests/smoke.sh`
   - document any real limitations
6. Keep user-facing guidance short and accurate. The README is user-facing; `WARP.md` and skills are agent-facing.

## Verification

Run the repo’s real gates after meaningful changes:

```bash
zsh -n warp-ai-enhancement-profile.zsh
zsh -n scripts/warp-ai-toolkit.sh
bash -n install.sh
bash -n uninstall.sh
bash -n tests/smoke.sh
bash tests/smoke.sh
git diff --check
```

If the task touches GUI automation, note that `tests/live-gui-validation.zsh` still requires a real Warp session with approved macOS permissions.

## Important notes

- Missing Warp plist or SQLite files are normal and should be handled clearly, not treated as crashes.
- GUI automation is best-effort and depends on `Accessibility`, `Automation`, and `Screen Recording`.
- Keep edits focused. This repo should feel like “superwarp”, not a random terminal toolbox.

## Examples

- “Add a new read-only Warp helper and cover it with smoke tests.”
- “Tighten install behavior for a second Mac.”
- “Update repo-native Warp workflows to match the current commands.”
