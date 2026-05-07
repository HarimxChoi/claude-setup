# wshobson/agents — DSSP audit

**Repo**: https://github.com/wshobson/agents
**Owner**: Seth Hobson (`seth@major7apps.com` / sethhobson.com)
**Marketplace name**: `claude-code-workflows`
**Marketplace version**: 1.6.0
**Stars / Forks**: 34.9K / 3.8K (audit time: 2026-05-07)
**Pushed**: 2026-05-02 (active)
**License**: MIT (most plugins); Apache-2.0 (`conductor`)

**DSSP score**: **~3.5/12** (UQ.3★★ + RL.3.4★ + RL.3.6★ + RL.3.7★ + DT.7★ + Game.2/OL.5 partials)

> Lower than ruflo (4.5/12) because there is no federation, no witness chain, no swarm orchestration. The novelty is concentrated in **one sub-plugin (`plugin-eval`)** that lifts UQ.3 to a level no other surveyed agent system reaches.

---

## 1. Repo overview

A marketplace of **80 granular Claude Code plugins** packaging **185 specialized agents**, **153 progressive-disclosure skills**, and **100 commands**. Every plugin is single-responsibility (avg 3.6 components per plugin, matching Anthropic's 2-8 spec range) and installable in isolation via `/plugin marketplace add wshobson/agents` + `/plugin install <name>`.

Numerical drift across docs (README: 80/185/153/100 ; marketplace.json: 79/184/150 ; architecture.md: 79/99/107) — README is freshest. This drift itself is a DSSP signal (no automated catalog generator).

The repo's claim-to-fame is **PluginEval** — a self-contained Python CLI + Claude-Code-native plugin that scores skills/plugins on 10 quality dimensions via three-layer evaluation (static → LLM judge → Monte Carlo). It is the first surveyed agent system that operationalizes **statistical UQ on agentic scaffolds**.

## 2. POMDP 5-tuple

| Element | Realization |
|---|---|
| **State `s`** | `(skill_or_plugin_under_eval, corpus_state, prior_elo)` |
| **Action `a`** | `score(path, depth)` ∈ {quick, standard, deep, thorough}; `certify`; `compare(a, b)`; `init(corpus_dir)` |
| **Observation `o`** | `(static_subscores, judge_scores, mc_activation_rate ± Wilson CI, mc_quality ± bootstrap CI, mc_failure ± Clopper-Pearson CI, token_efficiency, anti_pattern_set)` |
| **Reward `r`** | composite ∈ [0, 100], badge ∈ {Bronze, Silver, Gold, Platinum, none}, Elo update post-matchup |
| **Discount `γ`** | implicit; Elo K-factor = 32 (per-matchup learning rate) |

User-facing reward signal is **multi-tiered**: numeric score + letter grade (A+ to F) + badge + Elo + confidence label (Estimated/Assessed/Certified/Certified+). This is one of the few audited systems where the reward channel itself encodes uncertainty.

## 3. Task-class profile

- **Primary task class**: meta-evaluation of agentic scaffolds (skills/plugins). Marketplace owners and CI gates are the user persona.
- **Secondary task class**: agent specialization across 80 domain plugins (web dev, ML ops, security, deployment, etc.). Plugin-eval is the meta-layer; the rest is a specialist library.
- **Verifier-soundness master variable**: explicitly addressed via Layer 1 (deterministic) and Layer 2 (anchored rubrics). Layer 3 is partially heuristic (see §11.1).

## 4. 12-branch theorem coverage

| Branch | Mechanism in wshobson/agents | Score |
|---|---|---|
| RL.3.1 AlphaZero (planning + value net) | — | — |
| RL.3.2 PSRL (posterior sampling) | — | — |
| RL.3.3 Q-learning / DQN | — | — |
| **RL.3.4 OPE (off-policy eval)** | **PluginEval Layer 3 Monte Carlo** — N=50/100 synthetic prompts, runs the skill *without ground-truth tasks*, estimates activation rate / output consistency / failure rate via MC sampling. This is OPE in the agent-eval sense: estimating skill-policy quality from off-policy synthetic rollouts. | **★** |
| RL.3.5 HER (hindsight) | — | — |
| **RL.3.6 Options (temporally extended actions)** | 80 plugins × 185 specialty agents = explicit option library. Three-tier model strategy (Opus/Sonnet/Haiku) is option-cost stratification. | **★** |
| **RL.3.7 PRM (process reward models)** | Layer 2 LLM judge with anchored 5-point rubrics for orchestration_fitness + scope_calibration + output_quality + triggering_accuracy → emits per-dimension reward signal at the *step* (per-skill) level, not just end-of-trajectory. | **★** |
| **Game.2 (multi-agent / minimax)** | `agent-teams` plugin uses Claude Code experimental `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` for parallel hypothesis-driven debugging (competing hypothesis investigation) + multi-reviewer code review (parallel security/perf/architecture/testing/accessibility). Sequential, not BNE. | partial |
| **UQ.3 (uncertainty quantification)** | **Wilson score CI** for activation rate; **Bootstrap CI (1000 resamples)** for quality consistency; **Clopper-Pearson exact CI** for failure rate; **Elo with bootstrap CI** for skill ranking; **Cohen's kappa** for inter-rater agreement; **CV (coefficient of variation)** for output stability. All pure-Python, zero scipy/numpy. **Confidence labels (Estimated / Assessed / Certified / Certified+) honestly disclose depth-dependent uncertainty.** | **★★** |
| IT.4 (information-theoretic) | — | — |
| **OL.5 (online learning)** | Elo rating updates per matchup (K=32, init 1500); corpus persists in `~/.plugineval/corpus/index.json` and accumulates ratings across runs. | partial |
| Causal.6 | — | — |
| **DT.7 (decision transparency)** | Composite formula `Σ(weight × blended_score) × 100 × penalty` is publicly documented; per-dimension blend tables are verbatim in `engine.py`; rubrics are verbatim in `judge.py`; output formats {json, markdown, html}; CI gate via `--threshold N` flag (exit 1 if below). | **★** |
| DRO.8 (distributionally robust) | — (tangentially: `signed-audit-trails`, `protect-mcp` plugins for cryptographic governance, but not the eval framework itself) | — |
| OR.9 (operations research) | — | — |
| Submodular.10 | — | — |
| OS.11 (online scheduling) | — | — |
| AL.12 (active learning) | — | — |

**Activation count**: 5 strong (RL.3.4, RL.3.6, RL.3.7, UQ.3★★, DT.7) + 2 partial (Game.2, OL.5) = **~3.5/12**.

## 5. Theorem activation + predicted ceiling

**Activation footprint**: deep on UQ/OPE/PRM axis (the eval meta-layer); broad-but-shallow on Options axis (the 80-plugin catalog); thin on everything else.

**Predicted ceiling** (using verifier-soundness master variable):
- For **plugin-quality measurement** task class: high ceiling. The Wilson/bootstrap/Clopper-Pearson stack gives statistically calibrated answers within depth budget. Bottleneck is Layer 3's heuristic quality_score (`min(1, len/500)`) which biases toward verbose-but-wrong outputs.
- For **end-user code generation** task class: ceiling identical to vanilla Claude Code + skill activation; no novel mechanism beyond progressive disclosure.

**Top-3 predicted bottlenecks**:
1. Heuristic MC quality score conflates length with correctness (§11.1)
2. Hardcoded thresholds (15 MUST/NEVER directives, 800 lines, 8000 token cap) unvalidated against external benchmark
3. Plugin-level `evaluate_plugin()` only runs Layer 1 — confidence label hardcoded `Estimated` regardless of `--depth`

## 6. PluginEval deep-dive (the lift target)

### 6.1 Three layers

| Layer | Latency | LLM cost | What it does |
|---|---|---|---|
| **Static (L1)** | < 2 s | $0 | 6 sub-checks: frontmatter quality (35%), orchestration wiring (25%), progressive disclosure (15%), structural completeness (10%), token efficiency (10%), ecosystem coherence (5%). 6 anti-pattern detectors. |
| **LLM Judge (L2)** | ~30 s | 4 calls (Haiku + Sonnet) | 4 dimensions: triggering accuracy (10 synthetic prompts → F1), orchestration fitness (anchored 5-pt rubric), output quality (3 simulated tasks), scope calibration (anchored 5-pt rubric). Concurrent via semaphore. Skill body truncated to 3000 chars. |
| **Monte Carlo (L3)** | 2–5 min | 50–100 calls | 15 varied prompts generated by Haiku → repeated to fill N runs → quality_score (heuristic length proxy) + activation_rate (Wilson CI) + cv_quality (bootstrap CI 1000 resamples) + failure_rate (Clopper-Pearson CI) + token efficiency (median, IQR, Tukey 1.5×IQR outliers; cap = 8000). |

Depth → layers → confidence label:
- `quick` → L1 only → "Estimated"
- `standard` → L1+L2 → "Assessed"
- `deep` → L1+L2+L3 (50 MC runs) → "Certified"
- `thorough` → L1+L2+L3 (100 MC runs) → "Certified+"

### 6.2 Composite formula

```
Final = Σ(dimension_weight × blended_score) × 100 × anti_pattern_penalty
where penalty = max(0.5, 1 − 0.05 × n_anti_patterns)
```

**Dimension weights** (sum to 1.0, verbatim from `engine.py`):

| Dimension | Weight |
|---|---|
| triggering_accuracy | 0.25 |
| orchestration_fitness | 0.20 |
| output_quality | 0.15 |
| scope_calibration | 0.12 |
| progressive_disclosure | 0.10 |
| token_efficiency | 0.06 |
| robustness | 0.05 |
| structural_completeness | 0.03 |
| code_template_quality | 0.02 |
| ecosystem_coherence | 0.02 |

**Per-dimension layer blend** (verbatim, renormalized when layers absent):

| Dimension | static | judge | mc |
|---|---|---|---|
| triggering_accuracy | 0.15 | 0.25 | 0.60 |
| orchestration_fitness | 0.10 | 0.70 | 0.20 |
| output_quality | 0.00 | 0.40 | 0.60 |
| scope_calibration | 0.30 | 0.55 | 0.15 |
| progressive_disclosure | 0.80 | 0.20 | 0.00 |
| token_efficiency | 0.40 | 0.10 | 0.50 |
| robustness | 0.00 | 0.20 | 0.80 |
| structural_completeness | 0.90 | 0.10 | 0.00 |
| code_template_quality | 0.30 | 0.70 | 0.00 |
| ecosystem_coherence | 0.85 | 0.15 | 0.00 |

> Insight: the table itself is the design contract. `output_quality` has 0% static weight on purpose — it requires LLM evaluation. `progressive_disclosure` has 80% static weight — line-count and `references/` directory existence are deterministic. `robustness` is 80% MC because failure rate is only meaningful with N≥30 trials.

### 6.3 Score → grade → badge

Letter grade (verbatim cutoffs):

```
A+ ≥97   A ≥93   A− ≥90   B+ ≥87   B ≥83   B− ≥80
C+ ≥77   C ≥73   C− ≥70   D+ ≥67   D ≥63   D− ≥60   F <60
```

Badge thresholds (composite + Elo gate; Elo skipped at quick/standard depth):

| Badge | Composite | Elo | Stars |
|---|---|---|---|
| Platinum | ≥90 | ≥1600 | ★★★★★ |
| Gold | ≥80 | ≥1500 | ★★★★ |
| Silver | ≥70 | ≥1400 | ★★★ |
| Bronze | ≥60 | ≥1300 | ★★ |
| no_badge | else | — | — |

### 6.4 Anti-patterns (verbatim from `static.py`)

| ID | Severity | Trigger |
|---|---|---|
| `OVER_CONSTRAINED` | 0.10 | MUST/NEVER/ALWAYS count > 15 |
| `EMPTY_DESCRIPTION` | 0.10 | description trimmed length < 20 |
| `MISSING_TRIGGER` | 0.15 | regex `\buse\s+(?:this\s+skill\s+)?when\b\|\buse\s+proactively\b\|\btrigger\s+when\b` does not match |
| `BLOATED_SKILL` | 0.10 | line_count > 800 AND no `references/` dir |
| `ORPHAN_REFERENCE` | 0.05 | markdown link to `references/X` where X doesn't exist |
| `DEAD_CROSS_REF` | 0.05 | cross-reference path doesn't resolve |

### 6.5 Statistical methods (verbatim from `stats.py`)

```python
# Wilson score 95% CI
z = 1.960
p_hat = successes / n
denominator = 1 + z**2 / n
center = (p_hat + z**2 / (2*n)) / denominator
margin = (z / denominator) * sqrt(p_hat*(1 - p_hat)/n + z**2/(4*n**2))
return max(0, center - margin), min(1, center + margin)
```

```python
# Bootstrap percentile CI (1000 resamples, seed=42)
sample = [rng.choice(data) for _ in range(n)]   # with replacement
means = sorted(sample_means)
return means[floor(α/2 · 1000)], means[ceil((1-α/2) · 1000) - 1]
```

```python
# Clopper-Pearson exact CI via Beta PPF (Newton on Beta CDF, Simpson's rule)
lower = 0 if k=0 else _beta_ppf(α/2, k, n-k+1)
upper = 1 if k=n else _beta_ppf(1-α/2, k+1, n-k)
```

All pure-Python. Zero scipy/numpy. Beta PPF is implemented from scratch via Newton's method on the Beta CDF computed via Simpson's-rule numerical integration over the Beta PDF.

### 6.6 LLM judge anchored rubrics (verbatim from `judge.py`)

```
ORCHESTRATION_RUBRIC
0.0 Poor       — Skill acts as standalone agent; manages own tool calls and sub-tasks.
0.25 Below avg — Some orchestration logic mixed with worker tasks.
0.5 Average    — Delegates some tasks but coordinates multi-step flows itself.
0.75 Good      — Mostly worker; inputs/outputs documented, minimal coordination.
1.0 Excellent  — Pure worker role; composable, clear contracts, no orchestration.

SCOPE_RUBRIC
0.0 Too thin       — Stub or trivial wrapper with near-zero unique value.
0.25 Under-scoped  — Covers only a narrow slice; misses obvious related tasks.
0.5 Average        — Reasonable scope but either too broad or somewhat narrow.
0.75 Well-scoped   — Covers one coherent domain; neither bloated nor sparse.
1.0 Perfectly cal. — Minimal surface area, maximum cohesion, ideal composability.
```

Model assignments inside the judge:

```python
_MODEL_MAP = {
  "haiku":  "claude-haiku-4-5-20251001",
  "sonnet": "claude-sonnet-4-6",
  "opus":   "claude-opus-4-7",
}
# Triggering: Haiku (10 prompts × 2 — should/shouldn't trigger)
# Orchestration / Output / Scope: Sonnet (anchored rubric)
```

### 6.7 Monte Carlo simulation (verbatim from `monte_carlo.py`)

```python
# Per-run wrap
prompt_full = "You are evaluating a skill. Apply the skill if appropriate.\n\n" + skill_content + "\n\n" + prompt

# Quality is heuristic
quality_score = min(1.0, len(result_text) / 500) if activated else 0.0

# MC composite (used internally before engine renormalization)
score = (
    0.40 * activation_rate        # via Wilson CI
  + 0.30 * (1 - min(1, cv))       # via bootstrap CI
  + 0.20 * (1 - p_fail)           # via Clopper-Pearson CI
  + 0.10 * efficiency_norm
)
# efficiency_norm = max(0, 1 - median_tokens / 8000)
```

> **DSSP-flagged weakness (§11.1)**: `quality_score = len/500` is a length proxy, not a correctness proxy. A verbose-but-wrong skill scores well on MC.

### 6.8 CLI surface

```
uv run plugin-eval score <path> --depth {quick|standard|deep|thorough} [--threshold N]
uv run plugin-eval certify <path>                              # = deep + Elo
uv run plugin-eval compare <skill-a> <skill-b> --depth quick
uv run plugin-eval init <plugins-dir> --corpus-dir ~/.plugineval/corpus
```

Flags: `--output {json|markdown|html}`, `--verbose`, `--concurrency 1..20` (default 4), `--auth {max|api-key}` (Max plan default; api-key requires `ANTHROPIC_API_KEY`), `--threshold N` (CI gate — exit 1 if composite < N).

Also exposed as Claude-Code-native slash commands inside the plugin: `/eval`, `/certify`, `/compare` and two agents (`eval-orchestrator`, `eval-judge`).

### 6.9 Self-documenting skill

`plugins/plugin-eval/skills/evaluation-methodology/SKILL.md` (22 KB) describes its own scoring system as a Claude-readable artifact. **Recursive UQ pattern** — the framework documents itself in the same shape it evaluates. Worth replicating: any audit tool should be its own first audit subject.

## 7. Catalog overview

### 7.1 Plugin distribution by category (80 total)

documentation (3), development (8), workflows (4), testing (3), utilities (5), ai-ml (3), data (2), operations (5), infrastructure (3), performance (2), quality (3 — `comprehensive-review`, `performance-testing-review`, `plugin-eval`), modernization (2), database (3), security (5), api (2), marketing (3), business (3), blockchain (1), finance (1), payments (1), gaming (1), accessibility (1), languages (8), creative (3), governance (3 — `protect-mcp`, `signed-audit-trails`, `review-agent-governance`), other (~15).

### 7.2 Three-tier model strategy (verbatim from README)

| Tier | Model | # Agents | Use case |
|---|---|---|---|
| 1 | Opus 4.7 | 42 | Critical architecture, security, ALL code review, production coding (language pros, frameworks) |
| 2 | inherit | 42 | Complex tasks; user picks via `--model` (AI/ML, backend, frontend/mobile, specialized) |
| 3 | Sonnet | 51 | Support with intelligence (docs, testing, debugging, network, API docs, DX, legacy, payments) |
| 4 | Haiku | 18 | Fast operational tasks (SEO, deployment, simple docs, sales, content, search) |

Costs cited (per Mtok in/out): Opus 4.7 $5/$25, Sonnet 4.6 $3/$15, Haiku 4.5 $1/$5.

> Insight: this is the cleanest published example of explicit option-cost stratification (RL.3.6 Options) in the surveyed corpus. ruflo's tier assignment is implicit; here it is the central design axis.

### 7.3 Sample plugin contents (6 deep reads)

| Plugin | Agents | Commands | Skills | Pattern |
|---|---|---|---|---|
| `agent-teams` | 4 (team-lead/reviewer/debugger/implementer) | 7 (`/team-spawn`, `/team-debug`, `/team-feature`, ...) | 6 (parallel-debugging, multi-reviewer-patterns, ...) | tmux-based experimental orchestration |
| `agent-orchestration` | 1 (context-manager: haiku) | 2 | — | meta-orchestrator |
| `comprehensive-review` | 3 (architect-review, code-reviewer, security-auditor — all opus) | 2 | — | pure agent+command, no skills |
| `developer-essentials` | 1 | — | 11 | knowledge-heavy baseline |
| `python-development` | 3 (django/fastapi/python-pro: sonnet) | 1 | 16 | language-specific exemplar |
| `incident-response` | 6 | 2 | 3 | crisis-workflow |

Sample SKILL.md frontmatter (`async-python-patterns`):
```yaml
---
name: async-python-patterns
description: Master Python asyncio, concurrent programming, and async/await patterns for high-performance applications. Use when building async APIs, concurrent systems, or I/O-bound applications requiring non-blocking operations.
---
```

→ description style: present-tense imperative noun phrase + "Use when [verb-ing] X, Y, or Z" with multiple comma-separated triggers — **exactly the high-pushiness pattern PluginEval rewards**.

## 8. Hook / settings / MCP audit

**Repo root**: no `settings.json` template, no top-level `hooks/`, no `.claude/hooks/` config. Tree:

```
.claude-plugin/   .github/   .gitignore   CLAUDE.md
LICENSE   Makefile   README.md   docs/   plugins/   tools/
```

**PluginEval is purely a Python CLI + standard Claude Code agent/command/skill markdown — it does NOT install hooks**.

**Two plugins do bring hooks** (per their marketplace descriptions):
- `block-no-verify` — PreToolUse hook preventing `--no-verify` on git commits
- `protect-mcp` — Cedar policy enforcement + Ed25519 signed receipts on every tool call (DRO.8 partial; not validated against source in this audit)

**No MCP server definitions** at the marketplace level. `meigen-ai-design` references an external MCP server.

→ Compared to ruflo (4-layer hook stack + 314 MCP tools), wshobson/agents is **hook-free** at the repo level. The novelty is concentrated in `plugin-eval`, not in runtime guardrails.

## 9. Comparison with ruflo + 14-agent corpus

| Dimension | ruflo | wshobson/agents | 14-agent corpus best-in-class |
|---|---|---|---|
| Total DSSP score | 4.5/12 | 3.5/12 | ECC 3.0/12 / ForgeCode 2.5/12 |
| **UQ.3 (uncertainty quantification)** | none | **★★ pure-Python Wilson + bootstrap + Clopper-Pearson + Elo + CI gate** | none (some have Cohen's kappa, no end-to-end CI) |
| **OPE.3.4 (off-policy eval)** | none | **★ Monte Carlo activation rate** | none (DGM has trace replay but no statistical eval) |
| **PRM.3.7** | partial (witness chain over commit hash) | **★ anchored rubric judges** | ForgeCode partial |
| **Game.2** | **★ Federation BNE** (multi-agent consensus) | partial (tmux experimental teams) | OpenHands sequential |
| **DRO.8 (tail-risk)** | **★ Ed25519 witness chain** (sha256 + ':ruflo-witness/v1') | partial (`signed-audit-trails`, `protect-mcp` plugins, not core) | none |
| **OR.9 (scheduling)** | **★★ SwarmAI distributed task queue** | none | none |
| **RL.3.6 (Options)** | partial (~80 specialty agents) | **★ 80 plugins × 185 agents × 3-tier model stratification** | — |
| Hook depth | 4-layer | 0 (repo) + 2 hook-installing plugins | ECC 3-layer / ForgeCode 2-layer |
| MCP surface | 314 tools / 32 plugins | 0 / 1 external | varies |
| Use case fit (solo) | low (federation/swarm needed) | medium (UQ.3 directly liftable) | high (small surface) |

### 9.1 Where wshobson/agents wins

**UQ.3 + OPE.3.4 + PRM.3.7 trio**: no other surveyed system has all three. ruflo signs commits but doesn't measure skill quality; ECC has anti-pattern lists but no CI; ForgeCode has runtime recovery but no calibrated activation eval.

**Three-tier model strategy as DSSP option-cost axis**: ruflo's tier choice is implicit per agent; wshobson makes the cost-quality trade an explicit catalog dimension.

### 9.2 Where wshobson/agents loses

- **No witness chain**: no cryptographic provenance for skill outputs (ruflo wins DRO.8)
- **No federation**: no multi-agent consensus protocol (ruflo wins Game.2★)
- **No scheduling**: no distributed task queue (ruflo wins OR.9★★)
- **No core hooks**: relies entirely on description-driven activation; no deterministic gate (ECC wins prevent-mode)
- **No runtime recovery**: no doom-loop detection or pending-todos gate (ForgeCode wins recover-mode)

## 10. Drift / weaknesses

### 10.1 Heuristic MC quality score

`quality_score = min(1.0, len(result_text) / 500)` (Layer 3, `monte_carlo.py`). Verbose-but-wrong skills score 1.0; concise-correct skills under 500 chars score < 1.0. **This is the single largest UQ flaw in PluginEval**: 60% of `output_quality` weight is from MC, which is length-proxied. Layer 2 judge (Sonnet rubric, 40% weight) is the only correctness signal at standard+ depth.

Mitigation when adopting: pair PluginEval with task-specific golden tests. Don't trust output_quality for truth-critical skills.

### 10.2 Hardcoded thresholds

200–600 line sweet spot, 800 line bloat threshold, 8000 token cap, 0.5 penalty floor, 15 MUST/NEVER/ALWAYS limit — all hardcoded constants in `static.py`. None configurable via CLI flag. Calibrated against the 153-skill internal corpus; unvalidated against external benchmarks.

### 10.3 Plugin-level eval intentionally degraded

`evaluate_plugin()` runs Layer 1 only. Confidence label hardcoded `Estimated`. To get certified-grade scores, eval skills individually.

### 10.4 Documentation count drift

README claims 80/185/153/100. marketplace.json metadata claims 79/184/150. architecture.md claims 79/99/107. agents.md count tables don't sum to either. → no automated catalog generator; counts are hand-edited and drift.

### 10.5 Self-orchestration penalty

`orchestration_wiring` static check **−0.15 if "orchestrat\*" / "coordinat\*" / "dispatch\*" appears**. This penalizes skills that self-declare orchestration, pushing them toward worker role. Reasonable design choice but biases against legitimate orchestrator skills (e.g., my own dssp-audit which IS an orchestrator over 12 branches).

## 11. Lift-able patterns (for harim-base)

### 11.1 PluginEval — the UQ.3 lift target

**Decision: vendor-by-reference, run externally, integrate via wrapper script.**

Path:
1. Clone wshobson/agents to a persistent location (e.g., `~/wshobson-agents` or treat as external dep)
2. `cd plugins/plugin-eval && uv sync --extra llm`
3. Wrapper script `scripts/eval-skills.sh` in claude-setup that runs `uv run plugin-eval score` against my 6 user-level skills
4. Output: per-skill markdown reports → consolidated activation rate / output consistency / failure rate / Wilson CI / bootstrap CI table

Why not full vendor: PluginEval is 10+ files of Python + dep on `claude-agent-sdk`. Vendoring couples claude-setup to PluginEval's release cadence. External-by-reference keeps the dependency loose.

Why not skip: this is **the** UQ.3★★ lift. No other audited system has it. Skipping forfeits the whole UQ axis on the DSSP scorecard.

**Cost estimate** (one-time, my 6 skills, depth=standard):
- L1 (free, instant) + L2 (4 LLM calls × 6 skills × Haiku/Sonnet mix) ≈ 24 calls ≈ ~$0.30
- depth=deep adds L3 50 runs × 6 skills = 300 Sonnet calls ≈ ~$3
- → **deep audit budget ≤ $5** for full corpus baseline

### 11.2 Anchored rubric pattern

The `ORCHESTRATION_RUBRIC` and `SCOPE_RUBRIC` 5-point anchored format is independently liftable. Worth using inside dssp-audit / gepa-reflection skills as a sub-routine for self-rating other agents.

### 11.3 Three-tier model strategy as explicit DSSP axis

Currently my harim-base uses Sonnet by default + Haiku for verifier-runner. Worth explicitly tagging skills with model tier in SKILL.md frontmatter (`model: opus|sonnet|haiku`). Defer until v0.7 — needs design.

### 11.5 SDK breaking-change patch (required as of 2026-05)

PluginEval `judge.py` and `monte_carlo.py` extract response text via
`getattr(message, "content", [])` on `ResultMessage`. claude-agent-sdk ≥0.1.50
**removed `.content` from `ResultMessage`** — the final text now lives at
`ResultMessage.result` directly. Without the patch, every LLM call returns
empty string → JSON parse fallback → all judge dimensions collapse to 0.5
("raw" fallback path). MC simulations report `activated=False` for every run.

**Verified by direct SDK probe** (2026-05-07):
```
TYPE: ResultMessage
ATTRS: ['duration_api_ms', 'duration_ms', 'is_error', 'num_turns', 'result',
        'session_id', 'stop_reason', 'structured_output', 'subtype',
        'total_cost_usd', 'usage']
result attr: PONG
content: none           # ← removed in newer SDK
```

**Fix** — both files: replace the per-block iteration with direct `.result`
access:
```python
# OLD (broken)
if isinstance(message, ResultMessage):
    for block in getattr(message, "content", []):
        if hasattr(block, "text"):
            result_text += block.text

# NEW (works on SDK ≥0.1.50)
if isinstance(message, ResultMessage):
    result_text = getattr(message, "result", None) or result_text
```

In `monte_carlo.py` also fix the usage-token extraction: the SDK now returns a
dict (not an object), and `total_tokens` is no longer a single field — sum
`input_tokens + output_tokens` instead. See `scripts/eval-skills.sh` prereq
note for repro.

### 11.6 Real-world eval result on the harim-base v0.6 corpus

Standard-depth eval (no MC) on the 6 user-level skills, run 2026-05-07 against
patched plugin-eval. Two passes shown — first uncovered a YAML frontmatter bug
in 2 skills (description colon-space tripping `yaml.safe_load`), second is
post-fix (single-quote wrap):

| skill | pre-fix composite | post-fix composite | Δ | badge |
|---|---|---|---|---|
| dssp-audit | 67.8 | 67.8 | — | Bronze |
| ecc-prevent-mode | 66.2 | 66.2 | — | Bronze |
| forgecode-recover-mode | 56.7 | 56.7 | — | No Badge |
| gepa-reflection | 58.2 | 58.2 | — | No Badge |
| **live-swe-reflection** | **35.7** | **57.9** | **+22.2** | No Badge |
| **monogram-commit** | **58.3** | **77.2** | **+18.9** | **Silver** |

Diagnosis on `live-swe-reflection` 35.7: PluginEval's static analyzer flagged
two anti-patterns — `EMPTY_DESCRIPTION` (0 chars detected) and `MISSING_TRIGGER`.
Root cause was a stray `: -` (colon-space-hyphen) in the description that YAML
interpreted as a nested mapping key, returning empty frontmatter. Same bug on
`monogram-commit` (had `"category: noun-slug"` patterns inside the unquoted
description). Fix: wrap entire description in single quotes; replace inline
`: ` with em-dash or backtick. Lift: 2/6 skills had a silent YAML bug that
PluginEval surfaced — DSSP UQ.3★★ paid off immediately.

**Deep-depth attempt aborted** — single-skill deep eval (50 MC runs, Sonnet)
took **28 + minutes** and timed out after the second skill spawned. The
plugin-eval doc's "2–5 minutes per skill" estimate is for short skill bodies
and short MC outputs. Reality on these skills (~400-line orchestrator-style
SKILL.md): each MC run produces verbose output, concurrency=4 doesn't help
because individual calls take ~30-60s each. Estimated full-corpus deep run:
**3–4 hours**. This is **out of solo-use budget** — the UQ.3 lift is
real but the wallclock cost is not amortizable for a 6-skill catalog. Standard
depth (no MC) is the **practical v0.6.1 baseline**. Re-evaluate at v0.7 if
either (a) the catalog grows to 12+ skills (justifying overnight CI runs),
or (b) plugin-eval gains a `--n-runs` flag to reduce MC budget.

The standard-depth result is sufficient: it caught the YAML bug
(2/6 skills broken silently), gave usable composite scores + judge dimensions,
and surfaced the orchestration-fitness systematic bias on legitimate
orchestrator skills. **UQ.3 lift returns positive ROI even at standard depth.**

### 11.7 NOT lifted

- **80 specialty plugins / 185 agents catalog** — same verdict as ruflo: decision fatigue > productivity for solo use.
- **Agent Teams (tmux experimental)** — Desktop unsupported; experimental flag risk.
- **Elo ranking system** — only meaningful with N>10 skills + frequent matchups; my catalog is 6 stable skills.
- **block-no-verify hook** — overlaps with my pending-todos-gate semantically; lower value.
- **protect-mcp Cedar policy** — over-engineering for solo.

## 12. Sources

- README.md
- docs/{architecture, agent-skills, agents, plugin-eval, plugins, usage}.md
- plugins/plugin-eval/src/plugin_eval/{engine, parser, models, cli, elo, corpus, stats}.py
- plugins/plugin-eval/src/plugin_eval/layers/{static, judge, monte_carlo}.py
- plugins/plugin-eval/agents/{eval-orchestrator, eval-judge}.md
- plugins/plugin-eval/skills/evaluation-methodology/SKILL.md
- plugins/plugin-eval/pyproject.toml
- plugins/{agent-teams, agent-orchestration, comprehensive-review, developer-essentials, python-development, incident-response}/**
- .claude-plugin/marketplace.json (80-plugin catalog)

Audit conducted 2026-05-07 against `pushedAt: 2026-05-02T21:35:13Z` snapshot. UQ.3 mechanism is the load-bearing find; rest of catalog is conventional progressive-disclosure scaffolding.
