# Superwarp Toolkit

This repository is a macOS-only zsh helper layer for Warp Terminal.

## Project Boundary

- Maintain the installer, uninstall path, profile loader, toolkit script, README, and tests.
- Keep the suite local-first and macOS-specific.
- Do not reintroduce Windows, PowerShell, Docker, or container-terminal guidance unless the codebase explicitly grows that support.

## Supported Runtime

- macOS only
- `zsh` for startup loading
- `bash` for installer scripts
- `python3` for calculator and plist parsing
- `sqlite3` for read-only Warp usage history
- Gemini CLI, Codex, and Ollama are optional

For explicit Codex installation, you can set:
- `WARP_AI_CODEX_INSTALL_COMMAND` (full shell command) or
- `WARP_AI_CODEX_NPM_PACKAGE` (default npm package name)
- `WARP_AI_CODEX_BIN` (explicit binary path when not on PATH)

## Core Commands

- `warpai-doctor`
- `warpai-permissions`
- `warpai-search`
- `warpai-calc`
- `warpai-image`
- `warpai-cmd split right`
- `warpai-cmd split down`
- `warpai-cmd close panel`
- `warpai-cmd screenshot`
- `warpai-usage`
- `warpai-quick`
- `warpai-layout-install`
- `warpai-open`
- `warpai-codex`

## Safety Rules

- Classify whether a user message is a question or a task before acting.
- Prefer concise terminal-native commands.
- Read files before editing them.
- Follow local conventions over generic advice.
- Never echo secrets.
- Do not claim access to Warp internals that this repo does not actually use.
- Treat GUI automation as best-effort and permission-bound.

## Install And Recovery

- Install with `./install.sh`
- Use `./install.sh --no-permission-panes` for quieter test runs
- Uninstall with `./uninstall.sh`
- Logs remain in `~/Library/Logs/WarpAI`

## Validation

- Run `./tests/smoke.sh`
- Keep new features covered with fixture-based tests when possible
- Treat missing Warp databases or plist files as normal failure modes and report them clearly

## Warp-Native Repo Assets

- Skills live under `.agents/skills/`
- Workflows live under `.warp/workflows/`
- Keep those assets aligned with the real command surface in `scripts/warp-ai-toolkit.sh`
- If a new workflow or skill is added, document it in `README.md` and add smoke coverage where reasonable
