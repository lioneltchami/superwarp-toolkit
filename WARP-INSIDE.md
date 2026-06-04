# Warp Usage Guide

This guide is for people running **Superwarp Toolkit inside Warp** and wanting clear, practical steps for daily use.

## 1) After install, load the toolkit in this Warp session

Start a new Warp window/tab (or source your shell profile again):

```bash
source ~/.zshrc
```

If loaded correctly, you should be able to run:

```bash
warpai-doctor
```

You should see:
- `WARP_AI_ROOT=...`
- `python3: ok` (or a clear install message)
- `toolkit file: ok`

## 2) Core command surface inside Warp

All commands are available as simple aliases after the loader is active:

- `warpai-doctor` → quick health check
- `warpai-permissions` → open required macOS permission panes
- `warpai-search "<query>"` → web search + Gemini fallback
- `warpai-calc "<expression>"` → safe local math evaluator
- `warpai-image <image-path> "<prompt>"` → run image prompt workflow
- `warpai-cmd split right` → split current Warp pane
- `warpai-cmd split down`
- `warpai-cmd close panel`
- `warpai-cmd screenshot [/tmp/file.png]`
- `warpai-grok "<query>"` → run a direct headless Grok prompt
- `warpai-usage` → reads Warp usage history + quota snapshot
- `warpai-quick` → concise quota/request summary
- `warpai-layout-install` → install Warp Tab Configs
- `warpai-open toolkit|doctor|permissions` → open configured views
- `warpai-codex "<prompt>"` → send prompt to local Codex CLI

## 3) Recommended Warp-first startup order

When entering a dev session:

1. Run health checks:

   ```bash
   warpai-doctor
   ```

2. Install tab configs once (safe to run repeatedly):

   ```bash
   warpai-layout-install
   ```

3. Open a toolkit tab if you want the split layout:

   ```bash
   warpai-open toolkit
   ```

4. If you want diagnostic view:

   ```bash
   warpai-open doctor
   ```

## 4) Warp-native repo features (this repo root)

When this repo is open locally, Warp can also use the repo-native assets:

- `.agents/skills/` for repo workflow guidance
- `.warp/workflows/` for structured workspace checks

These are discoverable in your repo context and help keep operations local-first (doctor + smoke + usage + permission checks).

## 5) Permissions flow (important)

`warpai-cmd` uses macOS GUI APIs and can show limited behavior if permissions are pending.

Run:

```bash
warpai-permissions
```

Then allow the relevant permissions in System Settings:
- Accessibility
- Automation
- Screen Recording

If a command still fails, re-run:

```bash
warpai-doctor
```

and check the permission notes (`permission_warnings` section).

## 6) Troubleshooting (from inside Warp)

- **I run a command and nothing happens**  
  Make sure the loader is actually active (`source ~/.zshrc`) and confirm `which warpai-doctor` resolves.

- **`warpai-open` opens nothing**  
  Confirm Warp tab configs were created:

  ```bash
  ls -la ~/.warp/tab_configs
  ```

  (or `~/.warp-preview/tab_configs` for preview installation).

- **`warpai-doctor` says permissions not verified**  
  Open permission panes and retry once manual approval is granted.

- **`warpai-codex` not found**  
  This is optional. Install Codex first (or set `WARP_AI_CODEX_BIN`) and re-run `./install.sh --install-codex` if needed.

- **`warpai-grok` not found**
  Install Grok with `./install.sh --install-grok`, or set `WARP_AI_GROK_BIN` for custom binary paths.

## 7) If you want the clean "this is what to do now" path

From a new Warp session:

```bash
source ~/.zshrc
warpai-doctor
warpai-layout-install
warpai-open toolkit
```

From there, use `warpai-open doctor` anytime for a fast status surface.
