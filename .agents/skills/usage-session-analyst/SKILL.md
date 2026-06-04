---
name: usage-session-analyst
description: Analyze Warp quota state, local AI usage history, and toolkit session logs. Use when the user asks about usage, limits, refresh timing, or session context.
---

# Usage Session Analyst

## When to use

Use this skill when the user asks:

- how much Warp AI usage is left
- what plan/quota state Warp shows locally
- whether usage data came from plist, SQLite, both, or neither
- what recent toolkit session activity was captured

## Instructions

1. Run both quick and full usage views:

```bash
ROOT="$(git rev-parse --show-toplevel)"
export WARP_AI_ROOT="$ROOT" WARP_AI_TOOLKIT="$ROOT/scripts/warp-ai-toolkit.sh"
zsh -ic "source \"$WARP_AI_TOOLKIT\" >/dev/null; warp_ai_quick_usage; echo; warp_ai_usage"
```

2. Distinguish the two sources clearly:
   - plist snapshot: current local quota state
   - SQLite history: local historical request activity
3. If the output says `unsupported` or `unavailable`, report that honestly rather than inferring missing values.
4. If the user asks about recent toolkit activity, inspect the logs under:

```text
~/Library/Logs/WarpAI
```

5. Keep the explanation grounded in what the local files actually contain.

## Verification

For repo changes touching usage logic, run:

```bash
zsh -n scripts/warp-ai-toolkit.sh
bash tests/smoke.sh
git diff --check
```

## Important notes

- Warp’s plist and SQLite formats are private implementation details and may drift between versions or channels.
- Missing files are normal on machines that have not used a given Warp feature yet.
- Do not merge plist state and SQLite history into a single invented metric.

## Examples

- “Show me whether Warp usage came from plist or SQLite.”
- “Why does `warpai-quick` say no usage data found?”
- “What does the toolkit log say about recent sessions?”
