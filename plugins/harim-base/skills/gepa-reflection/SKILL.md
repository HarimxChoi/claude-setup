---
name: gepa-reflection
description: Apply GEPA's verbatim reflection prompt to iteratively improve a prompt, scaffold, or agent configuration based on observed failures. USE WHEN refining a prompt template, optimizing instructions after a failed run, processing reflective dataset of (input, trace, score, feedback) tuples, or extending an agent's prompt vocabulary. Implements the dual-extraction pattern (niche domain facts + generalizable strategy) and two-tier acceptance gating from gepa-ai/gepa.
---

# GEPA reflection

Lifted verbatim from `gepa-ai/gepa` `src/gepa/strategies/instruction_proposal.py:13-29`. Uses dual-extraction (niche facts + generalizable strategy) with triple-backtick output funneling for trivial parsing.

## When to invoke

- A prompt or instruction set produced wrong outputs on multiple inputs
- You have ≥3 failed examples with feedback (Actionable Side Information)
- You want a structured propose-evaluate-accept loop (not free-form rewriting)
- The failures share a common diagnosis (otherwise: per-failure rewrite, not GEPA)

## The verbatim reflection prompt

```
I provided an assistant with the following instructions:

<curr_param>
{current_instruction_text}
</curr_param>

The assistant performed the task with this instruction. Below are several
example inputs, the assistant's reasoning trace, and feedback on the output:

<side_info>
{rendered_failures_with_feedback}
</side_info>

Your task is to write a NEW instruction that, if used, would produce
better outputs on these examples.

Two extractions to capture:
1. Niche domain-specific facts the assistant lacked
2. Generalizable strategy that improves performance across this task family

Output the new instruction inside ```...``` so it can be parsed.
```

## Procedure

1. **Collect failures.** ≥3 (input, trace, score, feedback) tuples. Each `feedback` is a short string explaining why it failed.
2. **Render side_info.** Concatenate failures into `<side_info>` block. Keep each example ≤500 tokens.
3. **Send the reflection prompt** to a strong model (Opus 4.x or Claude 4.5 Sonnet recommended).
4. **Extract** content from triple-backtick block. This is the candidate instruction.
5. **Two-tier acceptance gate**:
   - Run candidate on a minibatch (≤10 examples). If score does not improve, REJECT (no full eval).
   - Only on minibatch improvement: run full validation set. Accept if full score improves.
6. **On accept**: replace current instruction. Archive old instruction with score for Pareto frontier.

## Notes

- `feedback` field is critical (the "ASI" — Actionable Side Information). Without it, GEPA falls back to score-only and is much weaker.
- If `feedback` is just "got X% accuracy", the reflection has no signal. Augment with a one-line diagnosis.
- The triple-backtick output funnel matters. Don't try to parse free-form prose.
- For multi-instruction systems, GEPA can optimize each instruction separately or jointly. Single-instruction default is simpler.

## Data sources for in-session reflection

When invoked via `/reflect` with no explicit failure set, derive the trace from the doom-loop log:

- `${CLAUDE_PROJECT_DIR}/.harim/action-log.jsonl` (project scope) or `~/.claude/harim-base/.harim/action-log.jsonl` (global fallback)
- Each line: `{ts, tool, sig, ses}`. Filter by current `ses` (session_id) for in-session trace; group by `tool` to spot loop-prone tools; diff `sig` against task to identify drift.
- Use this trajectory as `<side_info>` when the user asks "why did this session take so long" or "what's wrong with my recent approach".

## Anti-patterns

- Sending only score (no feedback) → degenerates to random search.
- Skipping the minibatch gate → wastes full-val budget on regressions.
- Reflecting on a single failure → use ad-hoc rewriting instead.
- Prepending rules to existing prompt without removing contradictions.
