---
name: dssp-audit
description: Apply DSSP (Decision Science Stratified Profiling) 6-step methodology to audit an agent system. USE WHEN evaluating an agent's activation conditions, scoring its 12-branch theorem coverage, mapping mechanisms to RL spine layers (RL.3.1-3.7), or estimating its predicted ceiling and top-3 bottlenecks. Outputs a quantitative activation footprint (0-12 score) plus per-branch mechanism tables.
---

# DSSP audit

Six-step procedure to audit any agentic system against the 12-branch decision-science taxonomy.

## When to invoke

- A new agent / scaffold appears (paper, repo, blog post) and you need to place it
- You're evaluating whether a candidate scaffold is worth deeper integration
- You need to compute predicted ceiling + top-3 bottleneck for a system
- A paper makes claims you want to verify against the framework

## Procedure

**1. POMDP 5-tuple extraction.** Identify the agent's `(S, A, π, ρ, τ, V)`:
- `S` — state (what's tracked across steps)
- `A` — action space (tools, sub-agent spawns, options)
- `π` — policy (base LLM + prompts + governance docs)
- `ρ` — recovery / failure-handling mechanisms (count them: prevent-mode vs recover-mode)
- `τ` — termination signal (LLM-unilateral vs goal-observability gate)
- `V` — verifier (sound vs unsound; layered or single)

**2. Task-class profile.** Classify into: SWE-bench-class / TerminalBench-class / research-browse / agentic-IO / etc. Note verifier soundness for THIS class.

**3. 12-branch coverage table.** Score each branch:
- ★★ core leverage (theorem fully exploited)
- ★ explicit use
- △ implicit / partial
- — unused

Branches: `RL.3.1` AlphaZero | `RL.3.2` PSRL | `RL.3.3` QD | `RL.3.4` OPE | `RL.3.5` HER | `RL.3.6` Options | `RL.3.7` PRM | `Game.2` | `UQ.3` | `IT.4` | `OL.5` | `Causal.6` | `DT.7` | `DRO.8` | `OR.9` | `Submodular.10` | `OS.11` | `AL.12`.

**4. Net activation score.** Sum: ★★ = 1.0, ★ = 0.5, △ = 0.25. Range 0-12.

**5. Predicted ceiling + bottleneck.** Decompose the score into expected lift (pp) over baseline. Identify top-3 unactivated branches with highest marginal lift if added.

**6. Latent advantages.** Note what infrastructure is already present but unused (e.g., ForgeCode's SQLite persistence enables RL.3.4 OPE with no new infra).

## Output template

```
## Agent: <name>
- POMDP: S=..., A=..., ρ=N recovery mechanisms, τ=..., V=...
- Task class: <class>, verifier <soundness>
- 12-branch table: (markdown table)
- Net activation: X.X / 12
- Predicted ceiling: baseline + ~Y pp
- Top-3 bottlenecks:
  1. <branch>: +A-B pp
  2. <branch>: +A-B pp
  3. <branch>: +A-B pp
- Latent advantages: <list>
```

## Reference data

- 14-agent corpus master table: `paper/sections/10-cross-agent-pattern.md` §9.1
- 12-branch quick reference: `paper/sections/05-12branch-taxonomy.md`
- RL 7-spine details: `research/foundations/05-rl-foundational-hierarchy.md`
- Worked examples: ECC condensed (`paper/sections/08-`), ForgeCode condensed (`paper/sections/09-`)

## Anti-patterns

- Don't aggregate across task classes when verifier soundness differs (security ≠ research).
- Don't claim ★★ without identifying the specific theorem instantiation.
- Don't skip latent-advantage check; it's where the highest-ROI extensions live.
