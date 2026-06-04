# Warp AI Enhancement Suite (macOS)

A focused macOS toolkit for Warp terminal that adds:

- lightweight startup context
- safe calculation and quick web lookup helpers
- optional local image analysis with Ollama
- Warp pane and screenshot automation
- install, uninstall, doctor, and permission helper workflows

This branch is intentionally narrower than the original Windows-heavy project. It is now a clean macOS-first Warp helper suite rather than a broad multi-platform automation experiment.

## Features

- `install.sh`
Installs the suite into `~/.warp-ai-enhancement` and wires it into `~/.zshrc`.

- `uninstall.sh`
Removes the managed loader block and installed suite files.

- `warpai-doctor`
Checks shell loading, binary availability, and likely GUI-permission readiness.

- `warpai-permissions`
Reopens the relevant macOS Privacy & Security panes for `Accessibility`, `Automation`, and `Screen Recording`.

- `warpai-search`
Uses Gemini CLI when available, with a DuckDuckGo fallback when it is not.

- `warpai-calc`
Evaluates numeric expressions with a restricted AST-based calculator.

- `warpai-image`
Runs a local Ollama multimodal model against an image prompt.

- `warpai-cmd`
Supports `split right`, `split down`, `close panel`, and `screenshot`.

## Requirements

- macOS
- `zsh`
- `bash`

Installed automatically if missing:

- `python3`

Optional companion tools:

- Gemini CLI
- Ollama

## Install

```bash
cd /path/to/warp-ai-enhancement-suite
chmod +x ./install.sh
./install.sh
```

The installer:

- installs the suite into `~/.warp-ai-enhancement`
- appends a managed loader block to `~/.zshrc`
- installs `python3` automatically if needed
- uses Homebrew for `python3`, and bootstraps Homebrew first if necessary
- can optionally install Gemini CLI and Ollama
- opens the relevant macOS Privacy & Security panes during interactive installs

Installer options:

```bash
./install.sh --no-shell-hook
./install.sh --no-permission-panes
./install.sh --install-gemini
./install.sh --install-ollama
./install.sh --install-gemini --install-ollama
./install.sh --help
```

## Usage

```bash
warpai-search "latest AI developments"
warpai-calc "1024 * 768 / 2"
warpai-image /absolute/path/to/image.png "Describe this image"
warpai-cmd split right
warpai-cmd split down
warpai-cmd close panel
warpai-cmd screenshot
warpai-cmd screenshot /tmp/warp-shot.png
warpai-doctor
warpai-permissions
```

## macOS permissions

For `warpai-cmd`, macOS may require:

- `Accessibility`
- `Automation`
- `Screen Recording`

The installer can open the correct panes, but macOS still requires user approval for those permissions.

## Behavior notes

- The startup welcome appears in Warp by default.
- Set `WARP_AI_ALWAYS_SHOW_WELCOME=1` to show it in other interactive shells too.
- The welcome is rate-limited so quick pane or tab creation should not flood the terminal.
- `warpai-cmd` assumes current default Warp macOS pane shortcuts.
- If you remap Warp shortcuts, pane automation may stop matching your setup.
- Warp-native Launch Configurations are still better for stable repeatable workspace layouts than simulated keystrokes.

## Limitations

- `zsh` is the supported startup shell path.
- Gemini-free search falls back to DuckDuckGo Instant Answer and may be sparse.
- Image analysis depends on a locally installed Ollama multimodal model.
- GUI automation depends on a live Warp window and granted macOS permissions.
- `--install-gemini` and `--install-ollama` make real system-wide dependency changes.

## Uninstall

```bash
./uninstall.sh
```

That removes:

- the managed loader block from `~/.zshrc`
- the installed suite in `~/.warp-ai-enhancement`

Logs are intentionally left in place at `~/Library/Logs/WarpAI` unless you remove them manually.

## Future improvements

- Improve first-run `warpai-cmd` diagnostics with more specific permission failure guidance.
- Add a small `warpai-layout` helper built around Warp-native Launch Configurations.
- Add optional model bootstrap helpers for recommended Ollama vision models.
- Add a small release checklist and GitHub Actions smoke job for public maintenance.
- Add a cleaner upgrade flow for existing installs when installer behavior changes.

## License

MIT. See [LICENSE](./LICENSE).
