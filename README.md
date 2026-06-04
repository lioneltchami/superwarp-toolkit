# 🚀 Superwarp Toolkit
**A polished Warp terminal toolkit for macOS with install, uninstall, doctor, permissions, search, automation, and local AI helpers.**

![Status](https://img.shields.io/badge/Status-macOS%20Ready-brightgreen)
![AI Collaboration](https://img.shields.io/badge/AI%20Collaboration-Claude%20%2B%20Gemini%20%2B%20Ollama-blue)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)
![Shell](https://img.shields.io/badge/Shell-zsh-black)
![License](https://img.shields.io/badge/License-MIT-success)

> **macOS-first refresh:** this repo keeps the best parts of the original Warp AI idea, but reshapes them into a tighter, cleaner, more honest toolkit for real macOS Warp workflows.

## 🎯 What This Is

Superwarp Toolkit is a **macOS-first helper layer for Warp terminal**.

It gives you:

- **⚡ Faster setup** with an installer, uninstall script, and permission helper
- **🩺 Better trust** with `warpai-doctor` for runtime checks
- **🧠 Useful terminal helpers** for calculation, search, image prompting, and Warp pane control
- **📝 Lightweight session logging** and startup context
- **🎛️ Optional AI integrations** through Gemini CLI and Ollama

This branch is intentionally **smaller and cleaner** than the old Windows-heavy version. It is not trying to be an everything-platform. It is trying to be a solid macOS Warp toolkit that you can actually install, validate, and use.

## ✨ Highlights

- **`install.sh`**  
  Installs the suite into `~/.warp-ai-enhancement` and wires it into `~/.zshrc`.

- **`uninstall.sh`**  
  Cleanly removes the managed loader block and installed toolkit files.

- **`warpai-doctor`**  
  Checks shell loading, key binaries, and likely GUI permission readiness.

- **`warpai-permissions`**  
  Reopens the relevant macOS Privacy & Security panes for:
  - `Accessibility`
  - `Automation`
  - `Screen Recording`

- **`warpai-search`**  
  Uses Gemini CLI when available, with a DuckDuckGo fallback when it is not.

- **`warpai-calc`**  
  Uses a restricted AST-based numeric evaluator rather than unsafe `eval`.

- **`warpai-image`**  
  Runs a local Ollama multimodal model against an image path and prompt.

- **`warpai-cmd`**  
  Supports:
  - `split right`
  - `split down`
  - `close panel`
  - `screenshot`

- **`warpai-usage` / `warpai-quick`**
  Read-only Warp usage helpers that summarize local SQLite history and the current quota snapshot from Warp's preference plist.

- **`warpai-layout-install`**
  Installs bundled Warp Tab Configs into the active Warp tab config directory for a more native session bring-up flow.

- **`warpai-open`**
  Opens the bundled Superwarp Tab Configs or the macOS permission panes.

## 🛠️ What’s Included

Core files:

- `install.sh`
- `uninstall.sh`
- `warp-ai-enhancement-profile.zsh`
- `scripts/warp-ai-toolkit.sh`
- `tests/smoke.sh`
- `WARP.md`
- `.agents/skills/`
- `.warp/workflows/`

Core commands:

- `warpai-search`
- `warpai-calc`
- `warpai-image`
- `warpai-cmd`
- `warpai-doctor`
- `warpai-permissions`
- `warpai-usage`
- `warpai-quick`
- `warpai-layout-install`
- `warpai-open`

Warp-native repo assets:

- `.agents/skills/suite-maintainer`
- `.agents/skills/tab-config-installer`
- `.agents/skills/warp-permission-doctor`
- `.agents/skills/usage-session-analyst`
- `.warp/workflows/suite-health-check.yaml`
- `.warp/workflows/permission-readiness-check.yaml`
- `.warp/workflows/usage-snapshot.yaml`
- `.warp/workflows/install-suite-safely.yaml`
- `.warp/workflows/install-uninstall-validation.yaml`
- `.warp/workflows/install-tab-configs.yaml`
- `.warp/workflows/bootstrap-superwarp.yaml`

## 🍏 Requirements

Required:

- macOS
- `zsh`
- `bash`

Installed automatically if missing:

- `python3`

Optional companion tools:

- **Gemini CLI** for better search and web-grounded responses
- **Ollama** for local image analysis and multimodal workflows

## 🚀 Installation

```bash
git clone https://github.com/lioneltchami/superwarp-toolkit.git
cd superwarp-toolkit
chmod +x ./install.sh
./install.sh
```

### What the installer does

- installs the suite into `~/.warp-ai-enhancement`
- appends a managed loader block to `~/.zshrc`
- installs `python3` automatically if needed
- uses Homebrew for `python3`, and bootstraps Homebrew first if necessary
- can optionally install Gemini CLI and Ollama
- opens the relevant macOS Privacy & Security panes during interactive installs

### Installer options

```bash
./install.sh --no-shell-hook
./install.sh --no-permission-panes
./install.sh --install-gemini
./install.sh --install-ollama
./install.sh --install-gemini --install-ollama
./install.sh --help
```

## 🧪 Quick Start

```bash
warpai-doctor
warpai-search "latest AI developments"
warpai-calc "1024 * 768 / 2"
warpai-image /absolute/path/to/image.png "Describe this image"
warpai-cmd split right
warpai-cmd split down
warpai-cmd close panel
warpai-cmd screenshot
warpai-cmd screenshot /tmp/warp-shot.png
warpai-permissions
warpai-layout-install
warpai-open toolkit
warpai-open doctor
```

## 🧠 Startup Experience

When loaded in Warp, the toolkit can show a lightweight startup banner with recent session context.

That startup behavior is intentionally tuned to be friendlier now:

- **Warp-first** by default
- **rate-limited** so quick pane and tab creation does not keep replaying the full banner
- **quieter outside Warp**, unless you explicitly opt in with:

```bash
export WARP_AI_ALWAYS_SHOW_WELCOME=1
```

## 🔐 macOS Permissions

For `warpai-cmd`, macOS may require:

- `Accessibility`
- `Automation`
- `Screen Recording`

The suite can **open the correct System Settings panes**, but macOS still requires **manual user approval** for those permissions.

Use:

```bash
warpai-permissions
```

if you want to reopen those panes later.

## 📋 Behavior Notes

- `warpai-cmd` assumes the current default Warp macOS pane shortcuts.
- If you remap Warp shortcuts, pane automation may stop matching your setup.
- Warp Tab Configs are a better fit for repeatable workspace layouts than simulated keystrokes.
- Gemini-free search falls back to DuckDuckGo Instant Answer and may return sparse summaries.
- Image analysis depends on a locally installed Ollama multimodal model.

## 🚀 Tab Configs

The suite now includes a native bridge into Warp Tab Configs.

Run:

```bash
warpai-layout-install
```

This installs two Tab Config files into:

```text
~/.warp/tab_configs
```

or, on Warp Preview:

```text
~/.warp-preview/tab_configs
```

- **Superwarp Toolkit**
  Opens a practical toolkit workspace with the install directory and log directory ready to go.

- **Superwarp Doctor**
  Opens a doctor-oriented workspace with a pane that runs `warpai-doctor` on startup.

You can then open them from Warp's `+` menu or from the terminal:

```bash
warpai-open toolkit
warpai-open doctor
```

This is the cleanest way to make repeatable Warp sessions feel native on macOS without relying on brittle pane-keystroke simulation alone.

The helper auto-detects Warp Preview when `~/.warp-preview` exists and `~/.warp` does not, and it switches the URI scheme to `warppreview://...` in that case.

## 🦾 Warp-Native Superwarp Layer

This repo now includes a real **Warp-native layer** on top of the shell toolkit.

When you open the repo root in Warp, it can discover:

- **repo-local skills** under `.agents/skills/`
- **repo-local workflows** under `.warp/workflows/`

That means this project is not only a set of commands you install into your shell. It is also becoming a **Warp-aware workspace toolkit** that teaches the agent how to maintain, validate, and troubleshoot the suite from inside Warp itself.

### Included skills

- **`suite-maintainer`**
  Keeps changes aligned with the repo boundary, docs, tests, and macOS-only scope.

- **`warp-permission-doctor`**
  Helps diagnose pane split, close-panel, and screenshot issues tied to macOS permissions.

- **`usage-session-analyst`**
  Interprets local usage state from Warp's plist snapshot, SQLite history, and toolkit logs.

- **`tab-config-installer`**
  Installs or opens the bundled Superwarp Tab Configs for a native Warp session layout.

### Included workflows

- **`Suite Health Check`**
  Runs `warpai-doctor` plus the smoke suite.

- **`Permission Readiness Check`**
  Checks automation and screenshot readiness, with an option to reopen the relevant permission panes.

- **`Usage Snapshot`**
  Shows both the quick quota summary and the deeper local usage report.

- **`Install Suite Safely`**
  Runs the installer with optional extra flags.

- **`Install Uninstall Validation`**
  Proves the installer and uninstall path in a temporary `HOME`.

- **`Install Tab Configs`**
  Copies the bundled Tab Config files into Warp's user-level tab configuration directory.

- **`Bootstrap Superwarp`**
  Installs Tab Configs, runs the doctor, and prints the current quick usage snapshot in one shot.

In practice, this is the beginning of the "superwarp" idea: Warp-native skills for agent behavior, Warp-native workflows for repeatable actions, and shell helpers for the actual local execution surface.

## ⚠️ Limitations

- `zsh` is the supported startup shell path.
- GUI automation depends on a live Warp window and granted macOS permissions.
- `--install-gemini` and `--install-ollama` make real system-wide dependency changes.
- This repo does **not** directly hook into Warp’s internal agent runtime or automatically capture Warp AI prompts and responses.

## 🧭 Rename Notes (2026-06-04)

This repository is now branded as **Superwarp Toolkit** and the local folder is now:

- `superwarp-toolkit`

For users from older local checkouts:

- The rename is intentionally lightweight: existing install paths like `~/.warp-ai-enhancement` and existing managed loader behavior are unchanged for compatibility.
- Existing installations continue to work.
- If you want the local checkout to reflect the new name, clone or `cd` from the new folder path shown in the instructions below.
- Remote is now: `https://github.com/lioneltchami/superwarp-toolkit`

If you want, we can do one optional cleanup pass to migrate remaining shell/config references from older local paths.

## ✅ Validation Status

This macOS branch has been checked across:

- installer behavior
- uninstall behavior
- doctor command behavior
- smoke tests
- real Warp startup loading
- live pane splitting
- live screenshot capture

That does not make every machine identical, but it does mean the branch is in much better shape than a raw concept repo.

## 🧼 Uninstall

```bash
./uninstall.sh
```

That removes:

- the managed loader block from `~/.zshrc`
- the installed suite in `~/.warp-ai-enhancement`

Logs are intentionally left behind at `~/Library/Logs/WarpAI` unless you remove them manually.

## 🔮 Future Improvements

- **Better `warpai-cmd` diagnostics** with more specific permission failure guidance
- **More Tab Config variants** tuned for different kinds of setups
- **Optional model bootstrap helpers** for recommended Ollama vision models
- **Public maintenance workflow** with a release checklist and GitHub Actions smoke job
- **Cleaner upgrade flow** for existing installs when installer behavior changes
- **More first-run guidance** for people setting up Gemini CLI and Ollama on a fresh Mac

For repo-local agent guidance, see [WARP.md](./WARP.md).

## 🤝 Contributing

If you want to extend it, the most natural areas are:

- better Warp-native workflow support
- richer doctor diagnostics
- cleaner optional dependency installation
- sharper local AI ergonomics
- better release automation

## 📜 License

MIT. See [LICENSE](./LICENSE).
