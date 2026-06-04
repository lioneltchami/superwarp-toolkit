---
name: codex-command-assistant
description: Use Codex for repo-aware planning, risk checks, and implementation guidance. Add this when users ask for code-level decomposition, safer rollout plans, or command review.
---

# Codex Command Assistant

## When to use

Use this skill when the user asks for:

- repo-aware command planning before large edits
- risk-aware step breakdowns for complex local changes
- code-level guidance for installation/maintenance scripts
- concise triage of recent failed commands or unexpected behavior

## Instructions

1. Confirm the user’s working copy and branch context first if possible:

```bash
git status --short
git branch --show-current
```

2. Run the base checks before drafting recommendations:

```bash
zsh -n scripts/warp-ai-toolkit.sh
zsh -n warp-ai-enhancement-profile.zsh
```

3. Use Codex directly through the suite when you need deeper framing:

```bash
WARP_AI_CODEX_BIN=codex warpai-codex "Review the proposed change in this repo and provide a risk-aware rollout plan."
```

4. Be explicit in any advice:
   - what is safe to run now
   - what to defer
   - which step depends on user permissions (for example, GUI automation and Codex auth)

5. For repeated work cycles, pair this with:

- `suite-maintainer` for boundary-safe execution
- `usage-session-analyst` for local usage and telemetry state
- `warpai-doctor` for environment and permission checks

## Verification

```bash
zsh -n scripts/warp-ai-toolkit.sh
bash tests/smoke.sh
```

## Important notes

- This skill does not bypass any actual macOS permission gates; it only guides execution.
- `warpai-codex` requires a local Codex binary and valid user auth/session context.
- Keep advice bounded by what this toolkit actually controls locally.

## Example prompts

- “Can you review this repo-wide change and generate a low-risk rollout plan?”
- “Give me a quick checklist before I run the automation-heavy commands.”
- “What should I include in a post-change validation step?”
