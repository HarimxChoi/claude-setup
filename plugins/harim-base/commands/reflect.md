---
description: Apply GEPA verbatim reflection to improve a prompt or instruction
---

Apply the `gepa-reflection` skill workflow to optimize a prompt the user provides.

## Prerequisites (ask if missing)
- Current instruction text (the prompt to improve)
- ≥3 failed examples with feedback (Actionable Side Information — the WHY of failure, not just score)

## Procedure
1. Render `<curr_param>` and `<side_info>` blocks
2. Apply the verbatim GEPA reflection prompt (dual-extraction: niche facts + generalizable strategy)
3. Extract candidate from triple-backtick block
4. Two-tier acceptance: minibatch eval first; full valset only on improvement

## Anti-patterns
- Score-only feedback (no diagnosis) → reflection has no signal
- Single failure example → use ad-hoc rewrite instead
- Skipping minibatch gate → wastes full-val budget
