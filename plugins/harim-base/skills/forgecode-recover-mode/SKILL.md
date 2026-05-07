---
name: forgecode-recover-mode
description: Apply ForgeCode's runtime recovery patterns when an agent hits errors, loops, or premature termination. USE WHEN a tool call fails, the agent shows repetition pattern (A,A,A or A,B,C,A,B,C), the agent tries to declare done with pending TODOs, or you need bounded retry with surfaced budget. Implements 6 of ForgeCode's 8 runtime recovery mechanisms (arxiv tailcallhq/forgecode 79.8% TB2 with Opus 4.6).
---

# ForgeCode recover-mode patterns

Lifted from `tailcallhq/forgecode` (Rust, 23 crates, hexagonal arch). ForgeCode's defense lives entirely in the running loop: 8 distinct recovery mechanisms. This skill packages 6 user-level patterns from that set.

## When to invoke

- A tool call returned an error
- Agent has tried similar action 3+ times without progress
- Agent attempts to signal completion but TODOs remain
- You're designing a retry policy

## When NOT to invoke

- Design-time governance work — use `ecc-prevent-mode` instead.
- Verifier is unsound — recovery loops will fire on noise (research-class tasks).

## The 6 patterns

### Pattern 1: doom-loop detection

Track last N action signatures (tool name + key args). If pattern matches `[A,A,A]` (3-rep) OR `[A,B,C][A,B,C]` (2-rep cycle), inject:

> Step back. Reconsider the approach. The last N actions are repeating without progress.

Implementation: PostToolUse hook reads JSONL action log, runs detection, injects via stdout to next turn.

### Pattern 2: pending-todos completion gate

BLOCKS the End signal until pending+in-progress todos are empty. Implementation: PreToolUse hook on `ExitPlanMode` or `Stop` event. Reads current todo state; rejects exit if any todo not `completed`.

```bash
# pseudocode
todos=$(get_todo_state)
if [[ "$(echo $todos | jq '.[] | select(.status != "completed")' | wc -l)" -gt 0 ]]; then
  echo "BLOCKED: pending todos exist. Complete or explicitly remove first." >&2
  exit 2
fi
```

### Pattern 3: 3-step error reflection

On any tool error, force a 3-phase response:
1. **Pinpoint** — identify the exact failing operation and error message verbatim
2. **Explain** — diagnose the root cause in one sentence (not "what error said" but "why it occurred")
3. **Correct** — propose a different approach (not just retry the same)

Inject as a system message after PostToolUseFailure event.

### Pattern 4: bounded retry with surfaced budget

When retrying, surface "Attempts remaining: N" in the prompt. Forces the policy to be aware of its budget. Default N=3.

```
Tool call failed: {error}
Attempts remaining: 2
```

After N exhausted, abort and escalate (not silent loop).

### Pattern 5: error-count abort

Track total tool errors in session. If > threshold (default 10), abort with a summary. Prevents indefinite degradation.

### Pattern 6: file-undo via snapshots

Before any destructive write/edit, snapshot the file. On error or user-requested undo, restore from snapshot. Implementation: PreToolUse on Edit|Write copies original to `.snaps/<sha>/<path>`.

## Procedure

1. Map current scenario to one of patterns 1-6.
2. Implement the trigger via PostToolUse / PreToolUse hook.
3. Test the trigger fires correctly (hook smoke test).
4. Set a budget (max retries, max errors, max snapshots).
5. Log every recovery action for post-session review.

## Reference

- Source: `research/foundations/02-forgecode-dssp.md` (1,117 lines deep audit)
- Condensed: `paper/sections/09-forgecode-condensed.md`
- Original repo: `tailcallhq/forgecode`
- The 12 prompt templates' verbatim text: paper Appendix B

## Theorem activations (DSSP)

- RL.3.6 (Sutton-Precup-Singh options) ★★ — patterns 1-6 are options
- RL.3.7 (Lightman PRM) ★ — error reflection + exit codes
- RL.3.5 partial (HER) — bounded retry with budget visibility
- OS.11 partial — pending-todos completion gate

## Anti-patterns

- Implementing all 6 patterns at once — start with pattern 1+3 (doom-loop + 3-step reflection).
- Aborting on first error without retry — patterns 4-5 give graceful degradation.
- Snapshot pattern on a 100-MB file — cap snapshot size (e.g., skip files >10MB).
- Retry without changing approach — that's the doom-loop pattern 1 detects.

## Companion skill

For pre-execution governance (the layer ForgeCode is light on), use `ecc-prevent-mode`.
