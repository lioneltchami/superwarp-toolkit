---
name: tab-config-installer
description: Install or open the bundled Superwarp Tab Configs for this repo. Use when the user wants a native Warp tab layout for toolkit, doctor, or recovery flows.
---

# Tab Config Installer

## When to use

Use this skill when the user asks to:

- install the repo's bundled Warp Tab Configs
- open the Superwarp toolkit tab
- open the Superwarp doctor tab
- create a more native Warp session layout from this repo

## Instructions

1. Resolve the repository root and use the repo copy of the toolkit:

```bash
ROOT="$(git rev-parse --show-toplevel)"
export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_install_tab_configs"
```

2. To open the installed tab configs from the terminal, use:

```bash
ROOT="$(git rev-parse --show-toplevel)"
export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_open toolkit"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_open doctor"
```

3. Explain the two bundled configs clearly:
   - `Superwarp Toolkit`: general toolkit + logs layout
   - `Superwarp Doctor`: doctor-first recovery layout
4. Be explicit that Warp discovers these Tab Configs from the user's tab config directory, not directly from the repository.

## Verification

Run:

```bash
zsh -n scripts/warp-ai-toolkit.sh
bash tests/smoke.sh
```

## Important notes

- Tab Configs are the current Warp-native path for reusable tab layouts.
- Install location on macOS stable is `~/.warp/tab_configs/`.
- `warpai-open permissions` reopens the macOS privacy panes instead of opening a Tab Config.
