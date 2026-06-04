# 🚀 Warp AI Enhancement Suite (macOS)
**A polished Warp terminal toolkit for macOS with install, uninstall, doctor, permissions, search, automation, and local AI helpers.**

![Status](https://img.shields.io/badge/Status-macOS%20Ready-brightgreen)
![AI Collaboration](https://img.shields.io/badge/AI%20Collaboration-Claude%20%2B%20Gemini%20%2B%20Ollama-blue)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)
![Shell](https://img.shields.io/badge/Shell-zsh-black)
![License](https://img.shields.io/badge/License-MIT-success)

> **macOS-first refresh:** this repo keeps the best parts of the original Warp AI idea, but reshapes them into a tighter, cleaner, more honest toolkit for real macOS Warp workflows.

## 🎯 What This Is

Warp AI Enhancement Suite is a **macOS-first helper layer for Warp terminal**.

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

## 🛠️ What’s Included

Core files:

- `install.sh`
- `uninstall.sh`
- `warp-ai-enhancement-profile.zsh`
- `scripts/warp-ai-toolkit.sh`
- `tests/smoke.sh`

Core commands:

- `warpai-search`
- `warpai-calc`
- `warpai-image`
- `warpai-cmd`
- `warpai-doctor`
- `warpai-permissions`

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
cd /path/to/warp-ai-enhancement-suite
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
- Warp-native Launch Configurations are still a better fit for repeatable workspace layouts than simulated keystrokes.
- Gemini-free search falls back to DuckDuckGo Instant Answer and may return sparse summaries.
- Image analysis depends on a locally installed Ollama multimodal model.

## ⚠️ Limitations

- `zsh` is the supported startup shell path.
- GUI automation depends on a live Warp window and granted macOS permissions.
- `--install-gemini` and `--install-ollama` make real system-wide dependency changes.
- This repo does **not** directly hook into Warp’s internal agent runtime or automatically capture Warp AI prompts and responses.

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
- **`warpai-layout` helper** built around Warp-native Launch Configurations
- **Optional model bootstrap helpers** for recommended Ollama vision models
- **Public maintenance workflow** with a release checklist and GitHub Actions smoke job
- **Cleaner upgrade flow** for existing installs when installer behavior changes
- **More first-run guidance** for people setting up Gemini CLI and Ollama on a fresh Mac

## 🤝 Contributing

If you want to extend it, the most natural areas are:

- better Warp-native workflow support
- richer doctor diagnostics
- cleaner optional dependency installation
- sharper local AI ergonomics
- better release automation

## 📜 License

MIT. See [LICENSE](./LICENSE).
