# DSSP Audit — Ruflo (claude-flow v3.7)

> **Phase 8 deep audit.** Companion to `01-ecc-dssp.md` (ECC, 580 lines)
> and `02-forgecode-dssp.md` (ForgeCode, 1,117 lines). Establishes
> Ruflo's place in the 14-agent corpus master table (§9.1).
>
> **Audit boundary**: `ruvnet/ruflo` repo, main branch, snapshot
> 2026-05-07. Full file tree read by 6 parallel subagents (4 root docs
> + 6 directory subagents covering `.agents/`, `.claude/`,
> `.claude-plugin/`, `.githooks/`, `.github/`, `bin/`, `scripts/`,
> `docs/`, `plugin/`, `plugins/`, `ruflo/`, `tests/`, `archive/`,
> `v3/`). Out-of-scope: live MCP execution, the `flo.ruv.io` and
> `goal.ruv.io` hosted UIs (only their static source under
> `ruflo/src/ruvocal/` and `v3/goal_ui/`).
>
> **Method**: Standard DSSP 6-step. POMDP 5-tuple → task-class profile
> → 12-branch coverage → theorem activation → predicted ceiling +
> bottleneck → latent advantages. Verbatim excerpts from
> `package.json`, `marketplace.json`, hook scripts, witness manifest,
> Ed25519 derivation source.

---

## §1. Agent overview

Ruflo is the renamed and re-architected `claude-flow`. Three NPM
packages publish the same artifact under different names:
`@claude-flow/cli` (binary), `claude-flow` (umbrella), and `ruflo`
(alias umbrella). Current pinned version `3.7.0-alpha.11`. The repo
heading documents `ruflo@3.6.10` as the latest stable release; npm
shows branch heading toward `3.6.25`. CHANGELOG declares 6,000+
commits, 314 MCP tools, 16 agent roles + custom types, 19 AgentDB
controllers, and 21 native plugins (the marketplace ships 32; the
discrepancy between 21 documented and 32 declared is the largest
in-doc drift of any audited agent and should be flagged in
verification work).

Two install paths exist with non-overlapping surface area:

| | **Plugin path** (slash commands only) | **CLI path** (`npx ruflo init`) |
|---|---|---|
| Files in workspace | 0 | `.claude/`, `.claude-flow/`, `CLAUDE.md`, helpers, settings |
| MCP server registered | No | Yes |
| Hooks installed | No | Yes |
| Workers active | No | Yes |
| Daemon | No | Yes |

This split is operationally significant: per Anthropic's
[#1744](https://github.com/ruvnet/ruflo/issues/1744), users
frequently install the plugin path expecting full Ruflo capabilities
but receive only slash commands. From a DSSP perspective the two
paths constitute *different agents* with different POMDP profiles. The
CLI path is the canonical Ruflo and what this audit profiles unless
noted.

**Lineage**. Ruflo descends from a v2 monolith (`archive/v2/`,
38 src/ subdirs) frozen at `claude-flow@2.7.47`. The v3 rewrite
(per `archive/v2/CHANGELOG.md` and v3/CHANGELOG.md) removed 226,606
lines and 24 MB of dead code, eliminated 6+ duplicate swarm
coordinators (`hive-mind/`, `maestro/`, `swarm/` → unified
`UnifiedSwarmCoordinator` per ADR-003), unified 6+ memory fragments
into the AgentDB+SQLite hybrid (ADRs 006/009), replaced Jest with
Vitest (ADR-008), and dropped Deno (ADR-010). 10 ADRs drive the v3
redesign. v3 is structured as a pnpm + bun workspace with 24
`@claude-flow/*` packages and 16 `v3/plugins/`. This trajectory —
monolith → microkernel + plugin marketplace — is structurally
analogous to the v2 → v3 rewrite of agent harnesses generally and is
the central design move of Ruflo.

---

## §2. POMDP 5-tuple

| Element | Specification |
|---|---|
| $S$ | $(\text{workspace}, \text{conversation}, \text{agent}\_\text{registry}, \text{swarm}\_\text{state}, \text{memory}\_\text{store}\_\text{AgentDB+SQLite+RVF}, \text{HNSW}\_\text{index}, \text{routing}\_\text{state}\_\text{Thompson-bandit}, \text{daemon}\_\text{state}, \text{worker}\_\text{queue}\_\text{12-named}, \text{plugin}\_\text{registry}\_\text{32-marketplace}, \text{permission}\_\text{rules}, \text{federation}\_\text{peers}, \text{trust}\_\text{scores}, \text{audit}\_\text{log}, \text{witness}\_\text{manifest}\_\text{Ed25519})$ |
| $A$ | native Claude tools $\cup$ 314 MCP tools $\cup$ 60+ named subagent spawns $\cup$ 88 Codex `$skill-name` invocations $\cup$ 32 plugin commands $\cup$ 26 CLI commands × 140+ subcommands $\cup$ federation message dispatch — a *catalog-typed + tier-routed* action space |
| $\pi$ | base LLM $+$ tier-routed (Agent Booster WASM <1ms / Haiku ~500ms / Sonnet-Opus 2-5s) $+$ CLAUDE.md priors (42 KB) $+$ AGENTS.md Codex priors (21 KB) $+$ 27 hooks routed through `helpers/hook-handler.cjs` $+$ Thompson-sampling MCP tool router $+$ SONA self-optimizing neural arch $+$ 12 background workers triggered by events |
| $\rho$ | non-trivial: doom-loop reminder via `hooks_intelligence_*`, retry policy with attempts-remaining, error-count abort, snapshot rollback, federation peer downgrade on misbehavior, budget circuit breaker (ADR-097), AIDefence threat blocking. Counted **5 explicit runtime recovery mechanisms**, partial overlap with ForgeCode's 8. |
| $\tau$ | Stop hook + session-end with `--persist-state --export-metrics --generate-summary`. No formal goal-observability gate (TodoWrite-based gating exists but is heuristic, not Snell-martingale). |
| $V$ | multi-layer hybrid: design-time sound (Ed25519 witness signing, 35-category appliance test, vitest 1933/1933 baseline, federation 366/366), runtime mostly-sound (bash exit codes, hook-handler.cjs metrics tracking, AIDefence input gates, MutationGuard immutable memory ops), runtime unsound (skill description matching, LLM-as-router judgments). |

The architectural fault line: $\rho$ is **partially populated** (5
mechanisms) compared to ForgeCode's 8 (full) and ECC's 0 (none).
Ruflo sits between the two on the prevent/recover axis. Critically,
$V$ has *both* design-time soundness (cryptographic witness) and
runtime soundness (test baselines), making it the most layered
verifier in the audit corpus. The Ed25519 witness derived from
`sha256(gitCommit + ':ruflo-witness/v1')` is unprecedented in the
14-agent corpus — no other agent ships cryptographic proof-of-bytes.

---

## §3. Task-class profile

Ruflo is multi-class via the marketplace + the 5-tier task
complexity classifier. The CLI path supports:

- `developer`: SWE-bench-class coding. Mostly-sound verifier (test
  suite), medium-long horizon, sparse-terminal reward.
- `terminal`: TerminalBench-2-class shell agent work. Mostly-sound
  (bash exit codes), long horizon, combinatorial.
- `research`: information acquisition + paper analysis (the
  `discover-plugins` skill is a research surface). Unsound verifier,
  very long horizon, open-ended.
- `enterprise`: federation, audit logging, compliance. Mostly-sound
  with cryptographic backing (HIPAA/SOC2/GDPR audit modes).
- `domain` (legal/healthcare/financial via vertical plugins):
  domain-specific verifier soundness varies — financial-risk
  benefits from market-data backtesting; legal-contracts and
  healthcare-clinical have unsound-by-default verifiers requiring
  human review.

Most task classes inherit a common runtime stack but differ in
verifier soundness. This is **the same uniformity-of-treatment
weakness called out for ECC** (§7.3 of ecc-dssp): Ruflo applies the
same 27-hook surface to research and developer profiles despite
materially different verifier soundness. The structural mitigation
is `aidefence` (semantic safety) layered atop syntactic checks.

The `developer` profile is the primary one for ceiling estimation
because it has the cleanest empirical anchor (SWE-bench Verified
leaderboard).

---

## §4. 12-branch coverage

Score legend: $\star\star$ core leverage, $\star$ explicit use,
$\triangle$ implicit/partial, $\text{--}$ unused.

| Branch | Score | Mechanism |
|---|---|---|
| **RL.3.1** AlphaZero stack | $\text{--}$ | No MCTS / search expansion in agent loop |
| **RL.3.2** PSRL | $\triangle$ | LLM prior over action distributions; Thompson-sampling router approximates posterior over MCP tool utility but not the formal MDP-prior PSRL bound |
| **RL.3.3** Quality-Diversity | $\triangle$ | The 32-plugin marketplace acts as a behavioral-diversity archive; `discover-plugins` skill recommends per-context. No automated QD search loop (CycleQD-style); the diversity is hand-curated |
| **RL.3.4** Doubly-robust OPE | $\triangle$ | SONA + ReasoningBank trajectory learning + AgentDB persistence make replay infrastructure exist; counterfactual evaluation tooling not productised. Latent advantage ([→ §7](#7-latent-advantages)) |
| **RL.3.5** HER | $\triangle$ | RVF cognitive containers preserve full trajectories; partial relabeling via SONA pattern extraction. Not the AgentHER 4-stage pipeline. |
| **RL.3.6** Options framework | $\star$ | **12 named background workers** as the canonical option set + 32 plugins as second-tier options + 6-phase v3/swarm.config.ts. Compared to ForgeCode's 12 templates: ruflo's 12 workers are scheduled (`audit=1h critical`, `optimize=30m high`, `consolidate=2h low`...), giving them a clean semi-MDP structure. Just below ForgeCode in cleanness because workers fire on **schedules + events**, not just events. |
| **RL.3.7** Process Reward Models | $\star$ | Ed25519 witness signing + 35-category appliance test + vitest baseline + per-step bash exit codes via `helpers/hook-handler.cjs post-edit --update-memory`. The witness chain is a sound cryptographic verifier. The test baseline + hook-handler stream produce per-step rewards. Not a calibrated PRM in the Lightman sense (no step-quality regression), but the substrate is in place. |
| **Game.2** | $\star$ | Federation plugin (`@claude-flow/plugin-agent-federation`) implements zero-trust mTLS + ed25519 challenge-response + behavioral trust scoring (`0.4×success + 0.2×uptime + 0.2×threat + 0.2×integrity`) + raft/byzantine/gossip consensus topologies. This is the strongest Game.2 instantiation in the audit corpus, beating ForgeCode (no federation) and AlphaProof (single-agent). |
| **UQ.3** Conformal | $\triangle$ | Witness signature provides hash-equality verification (binary), not marginal-coverage. AIDefence input validation has confidence scores but no $1-\alpha$ guarantee. |
| **IT.4** Lindley info-gain | $\triangle$ | Knowledge-graph plugin extracts entities + traversals + pathfinder; pagerank-analyzer agent. No formal expected-information-gain query selection (BED-LLM). |
| **OL.5** Online learning | $\triangle$ | Thompson-sampling model router (3.7 release) is multi-armed bandit with cost-utility — partial regret minimization. Argmax after ~50 outcomes. Not formal $\sqrt{T}$-regret-bounded. |
| **Causal.6** | $\triangle$ | ADR plugin AgentDB store has typed causal edges (`supersedes / amends / depends-on / related`) — explicit causal DAG over decisions. No Pearl do-calculus, no counterfactual queries, but the structural substrate is uniquely present. |
| **DT.7** | $\star$ | Three explicit utility hierarchies: (1) tier routing Agent Booster < Haiku < Sonnet/Opus by complexity score; (2) trust-level governs federation message routing; (3) permissions allow/deny + 5-tier hook profile {minimal, standard, strict, ...}. |
| **DRO.8** Wasserstein minimax | $\star$ | budget circuit breaker per call (ADR-097); federation downgrades-on-misbehavior are adversarial worst-case; AIDefence treats all incoming as adversary by default; permissions deny-precedence over allow. Multiple structurally-distinct DRO instantiations. |
| **OR.9** | $\star\star$ | **32-plugin marketplace.json + 314 MCP-tool registry + 88 Codex skill catalog + 60+ subagent registry**. Validation in `marketplace.json`/`plugin.json` schemas. Plus `inventory-capabilities.mjs` regex-extracts the entire surface and feeds Ed25519 witness chain — making this the *only* combinatorial-surface validation that's cryptographically signed. Beats ECC's ajv schema (which validates structure but not bytes). |
| **Submodular.10** | $\triangle$ | `discover-plugins` skill is implicit greedy plugin selection by description matching — no formal submodular guarantee. `hooks_intelligence_*` periodic skill-stocktake exists but undocumented as submodular. |
| **OS.11** Optimal Stopping | $\triangle$ | Stop hook with `session-end --export-metrics`; no formal Snell martingale; no MFS-style halt-or-continue logic. |
| **AL.12** | $\triangle$ | DAA plugin's "ASK" phase + CronCreate-driven background monitoring + per-edit `update-memory` create active-learning-style query collection, but no formal AL.12 D-optimal selection. |

**Net: ~4.5/12** (RL.3.6 $\star$ + RL.3.7 $\star$ + Game.2 $\star$ +
DT.7 $\star$ + DRO.8 $\star$ + OR.9 $\star\star$ + 9 $\triangle$
partials).

Compared to the 14-agent corpus:
- ECC: 1.5/12 (operator-surface, prevent-mode, $\rho=0$)
- ForgeCode: 2.5/12 (operator-surface + recover-mode, $\rho=8$)
- AlphaProof / Aristotle: 3.5/12 (sound regime, formal verifier)
- Live-SWE-agent: ~1.5/12 (3 YAML files, prompt pattern only)
- **Ruflo: ~4.5/12** — by activation count the highest in the corpus

This is the **first audited agent that achieves an
architecturally-blue-ocean ≥4-layer composition**: RL.3.6 + RL.3.7 +
Game.2 + OR.9 + DT.7 + DRO.8 = 6-layer activation, satisfying the
Prop 1 architectural-novelty criterion ([paper sections] §2.3).
Among the 6, **OR.9 is the differentiator** — Ed25519-signed
manifest of all 314+ tool entry points is unprecedented in
LLM-agent literature.

---

## §5. Theorem activation (deep)

Of the 7 RL spine layers:

- **2 partially activate, no full activation** (RL.3.6 options
  $\star$, RL.3.7 PRM $\star$) — both fall short of $\star\star$
  because Ruflo's Options are scheduled+event-triggered (not pure
  semi-MDP) and Ruflo's PRM is hash-based (not regression-calibrated).
- **3 partially activate** (RL.3.5 partial via RVF cognitive
  containers; RL.3.4 partial via AgentDB persistence; RL.3.2 partial
  via Thompson router).
- **2 do not activate** (RL.3.1 AlphaZero — no MCTS; RL.3.3 QD —
  hand-curated marketplace, no automated search). RL.3.3 is the
  highest-marginal-lift latent layer (see §7).

Of the non-RL branches: **Game.2 $\star$, DT.7 $\star$, DRO.8
$\star$, OR.9 $\star\star$, plus 5 partials**. This is a uniformly
broader activation footprint than any other corpus member. Ruflo's
empirical strength derives from the *conjunction* of:

1. **OR.9 manifest combinatorics** with cryptographic witness
   (uniquely Ruflo) — guarantees that *every advertised tool exists
   in dist*. Eliminates a class of trust-but-verify bugs.
2. **RL.3.6 options** via 12 scheduled workers with explicit
   priority — provides horizon-factor sample-complexity reduction
   (Sutton-Precup-Singh 1999) on the *long-horizon enterprise/research*
   task class.
3. **RL.3.7 PRM substrate** via per-edit `update-memory` and
   appliance-test categories — gives dense per-step verification
   on a verifier-mostly-sound class.
4. **Game.2 federation** via mTLS + behavioral trust scoring —
   activates BNE coordination on multi-agent inter-organization
   tasks (the only audit corpus member to do this).
5. **DT.7 tier routing** with explicit cost-utility — minimizes
   compute cost on simple tasks (Agent Booster <1ms vs Sonnet 2-5s)
   without sacrificing quality on hard tasks.
6. **DRO.8 budget circuit breaker** + federation downgrade —
   bounded worst-case spending and trust degradation.

The two empirical vulnerabilities:
- **`developer` profile lacks RL.3.4 cassette OPE**: SQLite + AgentDB
  persistence already exists; replay-based OPE would activate RL.3.4
  with no new infrastructure. Latent.
- **`research` profile has unsound verifier**: skill description
  matching + LLM-as-router. UQ.3 conformal commit gate would address
  this; AIDefence is a partial substitute.

---

## §6. Predicted ceiling and bottleneck

Predicted ceiling on the `developer` profile (SWE-bench-class:
mostly-sound verifier, medium-long horizon, sparse-terminal reward):

$$
\text{ceiling}(\text{Ruflo, developer})
\;\approx\;
\text{baseline}
\;+\;
\underbrace{[+5\text{-}10\,\text{pp}]}_{\text{RL.3.6 12 workers + 32 plugins as options}}
\;+\;
\underbrace{[+2\text{-}5\,\text{pp}]}_{\text{RL.3.7 PRM via test + witness}}
\;+\;
\underbrace{[+0\text{-}3\,\text{pp}]}_{\text{OR.9 catalog completeness}}
\;+\;
\underbrace{[+1\text{-}3\,\text{pp}]}_{\text{DT.7 tier-routed cost saving (effective compute → effective quality)}}
\;\approx\;
\text{baseline} + {\sim}10\text{-}15\,\text{pp}.
$$

This is materially above ForgeCode's predicted ~+5.4 pp and ECC's
predicted ~+5 pp, and is the highest-predicted-ceiling agent in the
14-agent corpus *on the `developer` profile*. The empirical
TerminalBench-2 baseline is not directly published for Ruflo (the
README cites Codex CLI + GPT-5.5 = 82.0 % as the leaderboard top, with
Ruflo positioned as a complementary harness rather than a single-shot
TB2 benchmark entry). The MCP-server-as-substrate pattern means
Ruflo's effective ceiling is *inherited from whatever client invokes
it* (Claude Code, Codex CLI, or `flo.ruv.io`). This shifts the
ceiling-prediction question from "what does Ruflo score" to "by how
much does Ruflo lift its underlying client's score."

Top-3 bottlenecks (highest marginal lift if added):

1. **RL.3.4 cassette OPE** ($+3\text{-}6\,\text{pp}$). AgentDB +
   SQLite already store per-conversation trajectories with HNSW
   indexing. Cassette-replay-based OPE on top of the existing data
   would activate RL.3.4 with **no new infrastructure** —
   architecturally identical to ForgeCode's same latent advantage
   (see §8.6 of forgecode-dssp). The fact that *both* SOTA agents
   share this exact latent advantage is structurally significant
   and is the most-pursuable-by-next-paper result.
2. **RL.3.3 QD archive** ($+5\text{-}15\,\text{pp}$ depending on
   landscape deception). The 32-plugin marketplace is a hand-curated
   QD archive. Replacing the curation step with automated QD search
   over emitted plugin/skill candidates (DGM-style) would make the
   marketplace evolutionary rather than static. **The existing
   `ruflo-plugin-creator` is the entry point** — it already
   scaffolds + validates + publishes plugins; adding a search loop
   over candidate behavioral descriptors (the `category` field on
   `marketplace.json` entries is a 1D BC; richer BCs from skill
   descriptions are extractable) would close the RL.3.3 gap.
3. **UQ.3 conformal commit gate** ($+1\text{-}5\,\text{pp}$). Ed25519
   witness signing provides hash equality (binary). Adding a
   conformal $1-\alpha$ coverage guarantee on edit-time syntactic
   correctness would address the documented Berkeley RDI 2026
   benchmark-gameability concerns. The `aidefence` plugin is the
   natural host (it already implements a 14-type PII detection
   pipeline with adaptive calibration — the same architecture
   generalizes to coverage calibration).

---

## §7. Latent advantages

Ruflo carries five structurally-significant latent advantages —
infrastructure already present but underused as the relevant
DSSP-layer activation:

1. **AgentDB + HNSW + ONNX 384-d embeddings** = RL.3.4 OPE substrate.
   Persistent SQLite + RuVector pattern indexing already exists;
   doubly-robust OPE on top of the same data would activate
   RL.3.4 fully.
2. **32 plugins as behavioral descriptors** = RL.3.3 QD archive
   substrate. The `category` + `tags` fields on `marketplace.json`
   entries are a low-dimensional BC; an automated QD loop could
   replace hand-curation.
3. **Ed25519 witness chain** = UQ.3 conformal substrate. Already
   provides per-byte attestation; extending to per-prediction
   $1-\alpha$ coverage with a held-out calibration set is a small
   delta in implementation effort relative to existing infra.
4. **Federation behavioral trust score** = continuous-MDP-state
   substrate. The trust formula
   $0.4 \cdot s + 0.2 \cdot u + 0.2 \cdot t + 0.2 \cdot i$ defines a
   bounded continuous state observable to all peers — the substrate
   for cooperative-game RL on federation networks (RL.3.2 + Game.2
   composition, currently uncombined).
5. **88 Codex skills + 80+ Claude agents = 168+ named "options" with
   no learning loop**. Each is a hand-crafted RL.3.6 option, but no
   meta-router learns the option-selection policy. Same as
   ForgeCode's 12 templates and ECC's 231 options — present but
   unused. **An RL.3.6 + RL.3.4 meta-router that learns
   option-selection from cassette replay would activate both layers
   simultaneously**, which is the precise prescription DSSP makes
   for ForgeCode's bottleneck (§8.6 of forgecode-dssp). Ruflo and
   ForgeCode share this critical latent advantage.

These five overlap considerably with ECC's "RL.3.6 + RL.3.4 latent"
advantage and ForgeCode's "RL.3.4 OPE latent" advantage. The
composability is significant: a successor meta-harness that lifts
RL.3.4 from any of the three would benefit all three simultaneously,
because all three persist trajectories in compatible vector
representations (RVF in Ruflo, JSON in ForgeCode, file system in
ECC).

---

## §8. Skill catalog (detailed)

Ruflo ships skills at three layers. The aggregate is the largest
skill surface in the audit corpus.

### §8.1 `.claude/skills/` — 35 user-invocable skills

| # | Skill | Domain |
|---|---|---|
| 1-5 | `agentdb-{advanced, learning, memory-patterns, optimization, vector-search}` | AgentDB substrate |
| 6 | `agentic-jujutsu` | git diff analysis |
| 7 | `dual-mode` | Claude+Codex collaboration |
| 8-10 | `flow-nexus-{neural, platform, swarm}` | Flow Nexus cloud |
| 11-15 | `github-{code-review, multi-repo, project-management, release-management, workflow-automation}` | GitHub ops |
| 16 | `hive-mind-advanced` | Byzantine consensus |
| 17 | `hooks-automation` | hook patterns |
| 18 | `pair-programming` | dual-agent pair |
| 19 | `performance-analysis` | profiling |
| 20 | `reasoningbank-agentdb` | trajectory storage |
| 21 | `reasoningbank-intelligence` | pattern retrieval |
| 22 | `skill-builder` (21.9 KB SKILL.md) | meta-skill creator |
| 23 | `sparc-methodology` (24.9 KB SKILL.md) | 5-phase dev |
| 24 | `stream-chain` | streaming pipeline |
| 25 | `swarm-advanced` / `swarm-orchestration` | swarm control |
| 26-28 | `v3-{cli-modernization, core-implementation, ddd-architecture}` | v3 build |
| 29-32 | `v3-{integration-deep, mcp-optimization, memory-unification, performance-optimization}` | v3 perf |
| 33 | `v3-security-overhaul` | v3 security |
| 34 | `v3-swarm-coordination` | v3 swarm |
| 35 | `verification-quality` | witness chain |
| + | `worker-benchmarks`, `worker-integration` | workers |

### §8.2 `.agents/skills/` — 88 Codex-invocable skills

Pattern: every skill is `agent-<name>/SKILL.md` with frontmatter
`name: agent-<name>, type, color, capabilities[], priority, hooks{}`.
Pre-hook prints role announcement, post-hook runs lint or sync.

The 88 split into 6 tiers:
- **Core (8)**: agent-coder, agent-tester, agent-reviewer,
  agent-researcher, agent-planner, agent-coordination,
  agent-orchestrator-task, agent-implementer-sparc-coder
- **Coordination (12)**: agent-{adaptive, hierarchical, mesh,
  consensus, queen, sparc, sync, swarm}-coordinator,
  agent-coordinator-swarm-init, agent-collective-intelligence-coordinator,
  agent-byzantine-coordinator, agent-quorum-manager
- **Distributed-systems (5)**: agent-raft-manager, agent-gossip-coordinator,
  agent-crdt-synchronizer, agent-load-balancer, agent-resource-allocator
- **SPARC methodology (5)**: agent-specification, agent-pseudocode,
  agent-architecture, agent-refinement, agent-sparc-coordinator
- **GitHub (8)**: agent-github-modes, agent-github-pr-manager,
  agent-pr-manager, agent-issue-tracker, agent-multi-repo-swarm,
  agent-project-board-sync, agent-release-manager,
  agent-release-swarm, agent-repo-architect, agent-swarm-issue,
  agent-swarm-pr, agent-workflow-automation, agent-workflow
- **Specialized (40+)**: agent-pagerank-analyzer, agent-matrix-optimizer,
  agent-trading-predictor, agent-sona-learning-optimizer,
  agent-safla-neural, agent-neural-network, agent-data-ml-model,
  agent-arch-system-design, agent-architecture, agent-authentication,
  agent-payments, agent-agentic-payments, agent-app-store,
  agent-challenges, agent-sandbox, agent-user-tools,
  agent-spec-mobile-react-native, agent-dev-backend-api,
  agent-docs-api-openapi, agent-ops-cicd-github, agent-test-long-runner,
  agent-tdd-london-swarm, agent-production-validator,
  agent-performance-{analyzer, benchmarker, monitor, optimizer},
  agent-benchmark-suite, agent-topology-optimizer,
  agent-memory-coordinator, agent-swarm-memory-manager,
  agent-security-manager, agent-base-template-generator,
  agent-analyze-code-quality, agent-code-analyzer,
  agent-code-review-swarm, agent-goal-planner,
  agent-code-goal-planner, agent-migration-plan,
  agent-v3-integration-architect, agent-v3-memory-specialist,
  agent-v3-performance-engineer, agent-v3-queen-coordinator,
  agent-v3-security-architect, agent-worker-specialist,
  agent-scout-explorer, agent-agent

The 88 mirror the 80+ `.claude/agents/` markdown files — every
Codex `agent-X` skill has a corresponding `.claude/agents/.../X.md`.
This is intentional: dual-mode collaboration requires the same role
definitions on both surfaces.

### §8.3 Plugin-shipped skills (32 plugins × 1-9 skills each)

Median 2 per plugin. The `ruflo-browser` plugin ships 9 (the deepest
skill set): `browser-{auth-flow, extract, form-fill, login, record,
replay, scrape, screenshot-diff, test}`. Each is session-as-skill
with stateful artifacts stored in AgentDB + ruvector + RVF.

**Total skill surface across all three layers: 35 + 88 + ~64 (32×2
median) ≈ 187 skills.** This vastly exceeds ECC's 183 (which was the
prior corpus maximum), making Ruflo the new corpus skill-count
leader. *Per-skill activation rate is structurally similar to ECC*
(LLM-decided based on description matching), so the marginal value
of each additional skill drops as the catalog grows. The
`discover-plugins` skill is a partial mitigation but not a
formal submodular selector.

---

## §9. Agent catalog

`.claude/agents/` contains ~80+ markdown files with agent
definitions, organized in 13 topical subdirectories:

| Subdir | Files | Notable agents (with sizes) |
|---|---|---|
| `core/` | 5 | coder, planner, researcher, reviewer, tester (4-8 KB each) |
| `sparc/` | 4 | architecture, pseudocode, refinement, specification (6-13 KB) |
| `swarm/` | 3 | adaptive-, hierarchical-, mesh-coordinator (9-14 KB) |
| `consensus/` | 7 | byzantine-coordinator, **crdt-synchronizer (24 KB)**, gossip-coordinator, **performance-benchmarker (26 KB)**, **quorum-manager (27 KB)**, raft-manager, security-manager (19 KB) |
| `optimization/` | 5 | benchmark-suite, load-balancer, performance-monitor, resource-allocator, topology-optimizer (12-24 KB each) |
| `github/` | 13 | code-review-swarm, github-modes, issue-tracker, multi-repo-swarm, pr-manager, project-board-sync, release-manager, release-swarm, repo-architect, swarm-issue, swarm-pr, sync-coordinator, workflow-automation (5-15 KB) |
| `templates/` | 9 | automation-smart-agent, coordinator-swarm-init, github-pr-manager, implementer-sparc-coder, memory-coordinator, **migration-plan (17.6 KB)**, orchestrator-task, performance-analyzer, sparc-coordinator |
| `v3/` | 10 | database-specialist, project-coordinator, python-specialist, test-architect, typescript-specialist (all <340 byte stubs), v3-integration-architect (9.6 KB), v3-memory-specialist (8.5 KB), **v3-performance-engineer (12.3 KB)**, v3-queen-coordinator (2.6 KB), v3-security-architect (5.1 KB) |
| `flow-nexus/` | 9 | app-store, authentication, challenges, neural-network, payments, sandbox, swarm, user-tools, workflow.md (3-4 KB) |
| `hive-mind/` | 5 | collective-intelligence-coordinator, queen-coordinator, scout-explorer, swarm-memory-manager, worker-specialist |
| `goal/` | 3 | **agent.md (25 KB, SHA-equal to reasoning/agent.md)**, code-goal-planner.md (14 KB), goal-planner.md |
| `reasoning/` | 2 | **agent.md (duplicate of goal/agent.md)**, goal-planner.md |
| `dual-mode/` | 3 | codex-coordinator, codex-worker, dual-orchestrator (5-8 KB) |
| `sublinear/` | 5 | consensus-coordinator (12 KB), matrix-optimizer, pagerank-analyzer (11 KB), performance-optimizer (14 KB), trading-predictor |
| `testing/` | 2+subdirs | production-validator (11 KB), tdd-london-swarm + `unit/`, `validation/` |
| `neural/` | 1 | safla-neural |
| `payments/` | 1 | agentic-payments |
| `sona/` | 1 | sona-learning-optimizer |
| `custom/` | 1 | test-long-runner |
| `analysis/` | 2+subdir | analyze-code-quality, code-analyzer, `code-review/` |
| `architecture/system-design/` | (subdir only) | |
| `data/ml/` | (subdir only) | dev-backend-api.md (in development/backend/) |

**Notable issue: `goal/agent.md` and `reasoning/agent.md` share SHA**
— byte-identical 25-KB files. This duplication and the 5 stub
agents in `v3/` (<340 bytes) suggest the agent registry has
non-trivial dead code. The audit corpus has documented similar
patterns in ECC (the "skill stocktake" recommendation §7.7) but
Ruflo lacks a periodic deduplication audit.

`v3/agents/` contains 5 byte-identical YAML files
(architect/coder/reviewer/tester/security-architect, ~200-240 bytes
each) that are also present in `archive/agents-root/`. **These are
stale leftovers** — markdown frontmatter format won the schema
debate. The `archive/README.md` explicitly states they are not
wired in.

---

## §10. MCP tool surface

The 314 MCP tools (drift-tolerated: STATUS.md says 300, USERGUIDE
says 313, README says 314) are organized by `ruflo/src/mcp-bridge/`
into 12 tool groups. Each group has a prefix-based namespace and
either a built-in implementation or a backend-spawned implementation.

| # | Group | Backend | Prefixes | Toggle env var |
|---|---|---|---|---|
| 1 | core | builtin | (catch-all) | always on |
| 2 | intelligence | ruvector | `hooks_` | `MCP_GROUP_INTELLIGENCE` |
| 3 | agents | ruflo | `agent_, swarm_, task_, session_, ...` | always on |
| 4 | memory | ruflo | `memory_, agentdb_, embeddings_` | always on |
| 5 | devtools | ruflo | `hooks_, analyze_, performance_, github_, ...` | always on |
| 6 | security | ruflo | `aidefence_, security_` | off by default |
| 7 | browser | ruflo | `browser_` | off by default |
| 8 | neural | ruflo | `neural_, ruvllm_` | off by default |
| 9 | agentic-flow | agentic-flow | (varies) | off by default |
| 10 | claude-code | claude | (varies) | off by default |
| 11 | gemini | gemini-mcp | (varies) | off by default |
| 12 | codex | @openai/codex | (varies) | off by default |

The 6 spawn commands (verbatim from `BACKEND_DEFS` in
`ruflo/src/mcp-bridge/index.js`):

```js
{ name: "ruvector",     command: "npx", args: ["-y", "ruvector", "mcp", "start"] }
{ name: "ruflo",        command: "npx", args: ["-y", "ruflo", "mcp", "start"] }
{ name: "agentic-flow", command: "npx", args: ["-y", "agentic-flow@alpha", "mcp", "start"] }
{ name: "claude",       command: "claude", args: ["mcp", "serve"] }
{ name: "gemini-mcp",   command: "npx", args: ["-y", "gemini-mcp-server"] }
{ name: "codex",        command: "npx", args: ["-y", "@openai/codex", "mcp", "serve"] }
```

The bridge is itself a consumer of `ruflo` (spawns `npx -y ruflo mcp
start` for the agents/memory/devtools/security/browser/neural
groups). This is significant: **`ruflo mcp start` is used both as
the MCP server entry from Claude Code and as a backend invoked by
the chat-UI bridge**. Both paths end up at
`v3/@claude-flow/cli/bin/cli.js`.

Per-group tool naming (sampled from the marketplace plugin
descriptions):
- **Core**: 3 builtin tools (basic ping, capabilities, etc.)
- **Memory**: 15 `agentdb_*` (CRUD + Cypher + delete) + 10
  `embeddings_*` (incl. RaBitQ 32x quantization) + 3
  `ruvllm_hnsw_*` (WASM HNSW pattern router) + N `memory_*`
- **Agents**: 4 `swarm_*` + 8 `agent_*` + N `task_*` + N
  `session_*` (totaling the bulk of the 314)
- **Intelligence**: 6 `neural_*` + 10 `hooks_intelligence_*` + 9
  routing/meta + 4 SONA/MicroLoRA = 29 total
- **Federation**: 9 `federation_*` + 10 CLI commands
- **WASM**: 10 `wasm_*` (agent_create/prompt/tool/list/terminate/
  files/export + gallery_list/search/create)
- **Browser**: counts not explicit; ~per-skill 1-2 tools
- **Cost-tracker**: namespace-routed `memory_*`
- **Workflows**: 10 `workflow_*` (state-machine lifecycle)
- **Loop-workers**: 5 `hooks_worker-*` (list/dispatch/status/detect/
  cancel)
- **Jujutsu**: 6 `analyze_*` (diff, diff-risk, diff-classify,
  diff-reviewers, file-risk, diff-stats)
- **Autopilot**: 10 `autopilot_*`
- **DAA**: 8 `daa_*`
- **Knowledge graph**: per `knowledge-graph` plugin
- **ADR**: per `adr` plugin (lifecycle: create/index/supersede)

This is the **first audit corpus member with cryptographic per-tool
attestation** via the `inventory-capabilities.mjs` →
`sign-witness-from-inventory.mjs` → `regenerate-witness.mjs` chain
(see §13). Each tool's existence in `dist/` is verified at release
time and signed. CAP-MCP-* witness entries enforce one CAP per
source file with the alphabetically-first tool name as a literal
marker — a regression in tool removal triggers `markerVerified:
false` and aborts the release.

---

## §11. Marketplace catalog (32 plugins)

Marketplace is at `.claude-plugin/marketplace.json` (name
`harim-marketplace` — wait, name = `ruflo`, owner ruvnet). Lists 32
plugins under `./plugins/<name>`:

### Core & Orchestration (6)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-core` | 0.2.0 | Foundation: registers ruflo MCP server (300+ tools), 3 generalist agents, 3 first-run skills, plugin-discovery catalog. **The only plugin shipping `hooks/hooks.json`.** |
| `ruflo-swarm` | 0.2.0 | 4 swarm_* + 8 agent_* MCP tools, 6 topologies, Monitor stream, worktree isolation |
| `ruflo-autopilot` | 0.2.0 | Autonomous /loop with learning + prediction; 10 autopilot_* tools |
| `ruflo-loop-workers` | 0.2.0 | Cache-aware /loop + CronCreate workers; 5 hooks_worker-* tools and **12 background worker triggers** (ultralearn, optimize, consolidate, predict, audit, map, preload, deepdive, document, refactor, benchmark, testgaps) |
| `ruflo-workflows` | 0.2.0 | 10 workflow_* tools with state-machine lifecycle |
| `ruflo-federation` | 0.2.0 | Cross-installation zero-trust; ADR-097 budget circuit breaker; PII pipeline; audit log |

### Memory & Knowledge (5)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-agentdb` | 0.3.0 | AgentDB controller bridge (15 agentdb_*), RuVector ONNX (10 embeddings_*), WASM HNSW (3 ruvllm_hnsw_*) |
| `ruflo-rag-memory` | 0.2.0 | RuVector + HNSW + AgentDB semantic retrieval |
| `ruflo-rvf` | 0.2.0 | RVF format for cross-platform memory; cognitive containers, lineage tracking |
| `ruflo-ruvector` | 0.2.1 | `npx ruvector@0.2.25`; HNSW, adaptive LoRA, code-graph clustering, brain/SONA, **103 MCP tools** |
| `ruflo-knowledge-graph` | 0.2.0 | Entity extraction, relation mapping, pathfinder traversal |

### Intelligence & Learning (4)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-intelligence` | 0.3.0 | 4-step pipeline (RETRIEVE→JUDGE→DISTILL→CONSOLIDATE), 29 tools, IPFS pattern transfer |
| `ruflo-daa` | 0.2.0 | Dynamic Agentic Architecture; 8 daa_* tools; feeds JUDGE |
| `ruflo-ruvllm` | 0.2.0 | Local LLM inference (Ollama-compatible) + smart routing + MicroLoRA + SONA |
| `ruflo-goals` | 0.2.0 | GOAP A\* planning, deep-research orchestration, dossier/OSINT, evidence grading |

### Code Quality & Testing (4)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-testgen` | 0.2.0 | Test gap detection, coverage analysis, automated gen; canonical owner of SPARC Refinement-phase + `testgaps` worker |
| `ruflo-browser` | 0.2.0 | Session-as-skill: Playwright + RVF + ruvector + AgentDB + AIDefence gates. **9 skills (deepest in marketplace)** |
| `ruflo-jujutsu` | 0.2.0 | 6 analyze_* tools (diff/diff-risk/diff-classify/diff-reviewers/file-risk/diff-stats) |
| `ruflo-docs` | 0.2.0 | JSDoc/TSDoc/OpenAPI gen, drift detection, `document` worker; uses Haiku |

### Security & Compliance (2)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-security-audit` | 0.2.0 | CVE scanning, dependency vulnerabilities, policy gates, shell-injection detection |
| `ruflo-aidefence` | 0.2.0 | AI safety scanning, PII detection, prompt-injection defense, adaptive threat learning |

### Architecture & Methodology (3)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-adr` | 0.3.0 | ADR lifecycle (create/index/supersede), AgentDB hierarchical store + causal edges (supersedes/amends/depends-on/related) |
| `ruflo-ddd` | 0.2.0 | DDD scaffolding — bounded contexts, aggregates, events, value objects, repos, anti-corruption layers |
| `ruflo-sparc` | 0.2.0 | SPARC methodology with quality gates |

### DevOps & Observability (3)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-migrations` | 0.2.0 | Generate, validate, dry-run, rollback DB migrations; up-down pairs |
| `ruflo-observability` | 0.2.0 | Structured logging + tracing + metrics; correlation; anomaly detection |
| `ruflo-cost-tracker` | 0.16.1 | Token usage, model cost attribution, budget alerts; pairs with federation budget circuit breaker. **Highest version of any plugin.** |

### Extensibility (2)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-wasm` | 0.2.0 | 10 wasm_* tools (`@ruvector/rvagent-wasm` + `@ruvector/ruvllm-wasm`, ADR-070) |
| `ruflo-plugin-creator` | 0.2.0 | Scaffold + validate + publish plugins; ADR + smoke + Compatibility + namespace coordination + MCP-tool drift warnings |

### Domain-Specific (3)

| Plugin | v | What it does |
|---|---|---|
| `ruflo-iot-cognitum` | 0.2.0 | Cognitum Seed IoT — 5-tier device trust, telemetry anomaly (Z-score), fleet firmware, witness-chain verification |
| `ruflo-neural-trader` | 0.2.0 | `npx neural-trader` — self-learning strategies, Rust/NAPI backtesting, **112+ MCP tools**, swarm coordination |
| `ruflo-market-data` | 0.2.0 | Market-data ingestion — feed normalization, OHLCV vectorization, HNSW-indexed pattern matching |

### Cross-cutting structural facts

- **Hooks**: only `ruflo-core` ships hooks. Other 31 expose behavior
  through MCP tools and skills only.
- **MCP servers declared in plugin.json**: zero (all delegated to
  `ruflo-core`).
- **Rules / glob patterns**: zero. No declarative file scoping.
- **Skills count per plugin**: 2-9, median 2.
- **Agents count per plugin**: 1-3.
- **Commands count per plugin**: 1-2.
- **Manifest.json validation**: implicit in marketplace.json
  schema; no explicit ajv-validation tooling for the plugin
  registry (in contrast to ECC which has ajv).

---

## §12. Hook architecture (4-layer)

Ruflo deploys hooks at **four distinct layers**, the deepest hook
stack in the audit corpus. Each layer has a different temporal
scope:

### Layer 1: `.githooks/pre-commit` (commit-time)
- 661 bytes, single hook.
- API-key redaction guard. Runs `node dist-cjs/src/hooks/
  redaction-hook.js` if present (else warns "run npm run build").
- Exits 1 with "COMMIT BLOCKED" if redaction fails.

### Layer 2: `.claude/settings.json` hooks (Claude Code lifecycle)
- All events route through `node .claude/helpers/hook-handler.cjs`
  with subcommands (pre-bash, post-edit, route, session-restore,
  session-end, post-task, compact-manual, compact-auto). PreCompact
  has separate manual/auto matchers.
- SessionStart additionally runs `auto-memory-hook.mjs import`. Stop
  runs `auto-memory-hook.mjs sync`.
- Statusline: `node ${CLAUDE_PROJECT_DIR}/.claude/helpers/
  statusline.cjs`.

### Layer 3: `.claude-plugin/hooks/hooks.json` (plugin-published)
- PreToolUse Bash → `npx claude-flow@alpha hooks modify-bash`
- PreToolUse Write|Edit|MultiEdit → `npx claude-flow@alpha hooks
  modify-file`
- PostToolUse Bash → extracts command via jq, runs `claude-flow@alpha
  hooks post-command --track-metrics --store-results`
- PostToolUse Write|Edit|MultiEdit → extracts file_path, runs `hooks
  post-edit --format --update-memory`
- PreCompact (manual/auto) → echoes guidance text
- Stop → `npx claude-flow@alpha hooks session-end --generate-summary
  --persist-state --export-metrics`

### Layer 4: `plugins/ruflo-core/hooks/hooks.json` (plugin-internal)
- Mirrors Layer 3 (same 5 events, same npx claude-flow@alpha
  endpoints).
- The redundancy is intentional: Layer 3 is the marketplace-published
  manifest (read by users who install the plugin via slash
  command); Layer 4 is what's wired when the user clones the repo
  directly.

**Sample hook entry (verbatim, from
`plugins/ruflo-core/hooks/hooks.json` PostToolUse)**:

```json
"PostToolUse": [{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "cat | jq -r '.tool_input.file_path // .tool_input.path // empty' | tr '\\n' '\\0' | xargs -0 -I {} npx claude-flow@alpha hooks post-edit --file '{}' --format true --update-memory true"
  }]
}]
```

Every Edit triggers a memory-store event. This is the load-bearing
operator-discipline pattern.

### Cross-layer assessment

The 4-layer stack is **operationally redundant by design** — any
single layer failing leaves the others functional. The pattern is
documented at the `.claude/settings.json` level (the "central
dispatch via `hook-handler.cjs`") and at the marketplace level (the
`.claude-plugin/hooks/hooks.json` mirror). However:

- **Risk: #34713 false-error label** (documented in our own
  harim-base v0.4 audit). With 27 hooks, 5+ events, and 4 layers,
  the multiplicative noise during a single tool call is high. The
  `hook-handler.cjs` central dispatcher attempts to consolidate but
  doesn't avoid the underlying transcript-rendering bug.
- **Performance**: the `cat | jq | xargs -0 -I {} npx claude-flow
  ...` pattern fires per-edit, with cold-start cost. Mitigation: the
  `hook-handler.cjs` keeps a daemon connection.
- **No prevent-mode block on most events**: only PreToolUse Bash
  has a guard (modify-bash), and it modifies rather than denies.
  The Anti-Pattern is contained in the LLM-side CLAUDE.md priors
  ("NEVER commit secrets...") rather than enforced by a hook
  exit-2.

---

## §13. Verification system

Ruflo's verification is the **first cryptographically-signed
witness chain in the audit corpus**. Three mjs scripts compose an
idempotent pipeline:

### §13.1 `scripts/inventory-capabilities.mjs` (9.7 KB)
- Statically extracts every MCP tool / CLI command / plugin / agent
  via regex.
- Tool extraction:
  ```js
  const toolRe = /name:\s*['"]([a-z_][a-z0-9_-]*)['"]\s*,/g;
  ```
- Command extraction:
  ```js
  const cmdRe = /export\s+const\s+\w+Command(?::\s*Command)?\s*=\s*\{[^}]*?name:\s*['"]([\w-]+)['"][^}]*?description:\s*['"`]([^'"`\n]*)['"`]/gms;
  ```
- All outputs sorted + deduped → deterministic markdown / JSON.
- Project root resolution climbs ancestors looking for
  `verification.md`.

### §13.2 `scripts/sign-witness-from-inventory.mjs` (4.4 KB)
- Bridges `inventory-capabilities.mjs` and
  `regenerate-witness.mjs`.
- For each source file, plants a `CAP-MCP-<basename>` witness entry
  in `verification.md.json` with:
  - `id`: e.g., `CAP-MCP-server`
  - `desc`: brief
  - `file`: dist path (after src→dist rewrite)
  - `sha256`: empty (filled by regenerate)
  - `marker`: alphabetically-first tool name in the file (must
    literally exist in dist)
  - `markerVerified: false` (set true by regenerate)
- Idempotent merge: drops existing `CAP-MCP-*` entries, replants
  candidates.

### §13.3 `scripts/regenerate-witness.mjs` (4.4 KB)
- Re-hashes every cited file (SHA-256).
- Updates `gitCommit` + `releases.*` from `package.json`.
- Recomputes manifest hash.
- Re-derives Ed25519 keypair from commit-seeded SHA-256:
  ```js
  const seed = createHash('sha256').update(m.gitCommit + ':ruflo-witness/v1').digest();
  const ED25519_PKCS8_PREFIX = Buffer.from('302e020100300506032b657004220420', 'hex');
  const pkcs8 = Buffer.concat([ED25519_PKCS8_PREFIX, seed]);
  const privateKey = createPrivateKey({ key: pkcs8, format: 'der', type: 'pkcs8' });
  const publicKeyObj = createPublicKey(privateKey);
  ```
- The PKCS#8 DER is constructed manually with the Ed25519 OID prefix
  (`302e020100300506032b657004220420`) — bypasses the standard `KEY`
  format to derive deterministically.
- Re-signs.
- Idempotent: clean tree → identical output.

### §13.4 `scripts/verify-appliance.sh` (30.5 KB)
- ADR-058 self-contained appliance verification suite.
- 35 categories, 95+ checks against an installed `ruflo` to
  validate every capability (CLI, doctor, init, memory, swarm, MCP,
  RVF, persistence, offline, isolation, etc.).
- Flags: `--quick/-q`, `--category/-c NAME`, `--json/-j`.
- PASS / FAIL / WARN / SKIP counters; final report ASCII or JSON.
- Exits with `$FAIL` count (CI gating).

### §13.5 Deterministic chain composition
The chain is run on every release. The order is documented in
`sign-witness-from-inventory.mjs` comment:
```
inventory → build → sign-witness-from-inventory → regenerate-witness
```
This is **the most robust verification chain in the audit corpus**
and is the strongest single empirical anchor for trusting Ruflo's
catalog completeness claims. It directly addresses the Berkeley RDI
2026 benchmark-gameability concerns ([SOTA scan §3.5]) by making
"every advertised tool exists in dist" cryptographically attestable.

---

## §14. Cross-cutting patterns

### §14.1 Routing-centric (vs gate-centric)
Ruflo's discipline is **routing-centric**: 32 plugins routing intent
into ~314 MCP tools through a single foundation, with hooks only at
the foundation layer. This contrasts with ECC's gate-centric pattern
(8 CI validators that *block* commits) and ForgeCode's
recovery-centric pattern (8 runtime recovery mechanisms in the
loop). Ruflo's gate-equivalent is the Ed25519 witness chain
(commit-time gate), and its recovery-equivalent is the Thompson
router + 12 workers (runtime gate).

### §14.2 Single MCP server foundation
All 31 non-core plugins delegate to `ruflo-core`'s single registered
MCP server. This avoids the documented anti-pattern of "every plugin
re-registers its own MCP server" sprawl (call it the *MCP-fan-out
anti-pattern*).

### §14.3 Compute attribution drift
Documents disagree on capability counts:
- MCP tools: 300 (STATUS.md) vs 313 (USERGUIDE.md) vs 314 (README +
  CLAUDE.md).
- CLI: 26 (USERGUIDE groups) vs 49 (STATUS leaf commands).
- Plugins: 19 (index.md) vs 32 (STATUS, marketplace).
- Agents: 43 (STATUS) vs 60+ (USERGUIDE) vs 100+ (README).

Only STATUS.md is auto-generated (via `inventory-capabilities.mjs`).
The other three drift independently. **The DSSP audit weight on each
claim should be derived from STATUS.md unless explicitly verified
elsewhere**, since STATUS is the only doc participating in the
witness chain.

### §14.4 Attribution hardcoded
`Co-Authored-By: RuFlo <ruv@ruv.net>` and `🤖 Generated with
[RuFlo]` are hardcoded into `.claude/settings.json` `attribution`
block. This is structurally identical to (and the inverse of) our
harim-base anonymity hook — an explicit privacy choice in the
opposite direction. Material to compare to against ECC (which is
silent on attribution) and AlphaProof (which signs results with the
authors' names but not in commit messages).

### §14.5 Dual-mode 1st-class
Claude Code (🔵) + OpenAI Codex (🟢) collaboration is built into
the ground floor — `.claude/agents/dual-mode/` (3 files), `dual-mode`
skill, `@claude-flow/codex` package, `dual-mode-orchestrator`. This
is the only audit-corpus member with native dual-mode. The
implication for DSSP: 5 RL spine layers exist on each platform
independently, so dual-mode composition could activate
$2 \times 5 = 10$ option dimensions if sufficiently coupled (a
combination not reached today).

---

## §15. Comparison with 14-agent corpus

| Agent | Score | $\rho$ | Verifier | Distinctive |
|---|---|---|---|---|
| ECC | 1.5/12 | 0 | 8 CI validators (design-time sound) | install manifest taxonomy |
| ForgeCode | 2.5/12 | 8 | bash exit + test (mostly-sound runtime) | 12 templates as semi-MDP options |
| AlphaProof / Aristotle | 3.5/12 | 1 | Lean (sound) | sound-regime asymptotic optimality |
| Live-SWE-agent | 1.5/12 | 0 | Sonnet 4.5-amplifier sentence | 3 YAML files; minimal scaffold |
| **Ruflo** | **4.5/12** | **5** | **Ed25519 witness + appliance test + vitest** | **cryptographic catalog attestation; federation BNE; 4-layer hook stack** |
| AgentSquare | 2.5/12 | partial | proxy predictor | 4-axis taxonomy + module evolution |
| Voyager | 2.25/12 | 0 | unsound | curiosity-driven skill discovery |
| Reflexion | 1.5/12 | 1 | unsound | natural-language reflection |
| Self-Discover | 1.5/12 | 0 | unsound | reasoning module composition |
| DGM | 1.25/12 | 1 | Sonnet/Opus | self-improving via RL.3.3 |
| OpenHands | 1.25/12 | partial | mostly-sound | platform-bridge integration |
| AutoCodeRover (Sonar Foundation Agent) | 1.25-2.0/12 | 1 | mostly-sound | spec-inference + reviewer |
| Aider | 0.75/12 | 0 | unsound | git-native scaffold |
| KIRA | 0.75/12 | 0 | mostly-sound | Krafton TB2 entry |
| SWE-agent | 0.75/12 | 0 | mostly-sound | NeurIPS 2024 ACI baseline |

**Ruflo overtakes AlphaProof at 4.5/12 vs 3.5/12** to become the
new corpus-leader by activation count — but the comparison is
asymmetric: AlphaProof's 3.5/12 is **all-RL-spine ($\star\star$
RL.3.1, $\star$ RL.3.7, $\star$ OR.9)** with a sound verifier,
while Ruflo's 4.5 is **breadth-distributed across non-RL branches**
(Game.2, DT.7, DRO.8, OR.9 dominate). On a per-RL-layer basis
AlphaProof is still the strongest RL.3.1 instantiation. Ruflo's
unique contribution is *cross-branch composition* — the only audit
corpus member to compose 6 distinct branches at $\geq \star$ activation.

The proper framing for §10.3 of the paper: **Ruflo demonstrates that
~4.5/12 is empirically achievable through architectural breadth
without requiring a sound verifier on a single class**. This is
strong evidence for DSSP's blue-ocean composition thesis (Prop 1).

---

## §16. Drift / weaknesses

1. **Capability-count drift across 4 docs** (300/313/314 MCP, 19/32
   plugins, 43/60+/100+ agents) — only STATUS.md auto-generates.
2. **Attribution hardcoded in `.claude/settings.json`** — by design,
   but inflexible.
3. **Mega-doc `USERGUIDE.md` (290 KB)** — Diátaxis-violating; mixes
   tutorial + reference + explanation + how-to in one file.
4. **`docs/` directory has only 4 files** despite project's claimed
   scope. Most documentation lives in `v3/docs/adr/` (70+ ADRs not
   surfaced in `docs/`).
5. **File duplication**: `goal/agent.md` and `reasoning/agent.md`
   share SHA (25-KB each). `archive/agents-root/*.yaml` and
   `v3/agents/*.yaml` are byte-identical.
6. **5 stub agents in `v3/`** are 340-byte placeholders.
7. **`v3/agents/*.yaml` are stale** per `archive/README.md` ("never
   wired in"). Should have been deleted, not retained.
8. **Plugin tier 31/32 ship 0 hooks** — operator discipline
   concentrated in `ruflo-core` only. Other plugins rely on
   description-matching for activation, with the documented ~50%
   activation ceiling.
9. **No periodic skill stocktake** — ECC has it (§7.7 of
   ecc-dssp); Ruflo does not surface this audit.
10. **Documentation-only auto-generation gap**: `inventory-
    capabilities.mjs` produces STATUS.md; no equivalent script
    auto-generates USERGUIDE.md or README.md, leading to drift.
11. **`enabledPlugins` field in `.claude/settings.json`** appears in
    Ruflo and similar repos but is not explicitly documented in
    Anthropic's official Claude Code settings spec — hence
    potentially fragile.
12. **`mcp-bridge` is documented as deployment template, not
    canonical** — yet it's the path used by the public hosted demo
    (`flo.ruv.io`). Architectural ambiguity.

---

## §17. Lift-able patterns for Phase 11

(Audit deliverable for the paper's §10.3 prescription.)

### High-ROI lifts (do these in `core/extensions/`)

1. **Ed25519 commit-seeded witness chain** (Ruflo `regenerate-
   witness.mjs` + `inventory-capabilities.mjs`). Direct empirical
   anchor for DSSP master-variable verifier-soundness; supersedes
   the harim-base v0.4 anonymity hook as the canonical
   commit-time-sound mechanism. Applies to all 14-agent corpus
   members. ~80 lines + ~100 lines + ~50 lines.

2. **35-category appliance verification** (Ruflo
   `verify-appliance.sh`). Generalizable to any agent's CLI surface;
   makes runtime-soundness empirically testable. Direct lift to
   `meta_harness/adapters/<agent>/verify-appliance.sh`.

3. **3-script idempotent witness pipeline pattern** (Ruflo's
   inventory → sign → regenerate). Reproducible across audit corpus.
   The `markerVerified: false` regression detector is a
   particularly clean anti-tool-removal trick.

### Medium-ROI lifts (in `core/runners/`)

4. **`marketplace.json` schema for plugin distribution** (32 plugins
   with categories, tags, version, install commands). Replaces
   harim-base's single-plugin marketplace. Even if Phase 11 doesn't
   ship 32 plugins, the schema is the natural target for the
   meta-harness output.

5. **Single-MCP-server-foundation pattern** (`ruflo-core` registers,
   31 plugins delegate). Avoids MCP-fan-out anti-pattern. Important
   if Phase 11 grows to multiple plugin contributions.

6. **Hook-handler.cjs central dispatcher** (Ruflo
   `.claude/helpers/hook-handler.cjs`). Lifts the 5-event-→-1-script
   pattern; avoids the multiplicative noise problem of separate
   hooks. Could replace harim-base's 3 separate hook scripts.

### Low-ROI / domain-specific (skip)

7. **Federation plugin** — multi-machine, multi-org. Not relevant
   to Phase 11's 4-track personal stack.
8. **AgentDB + RuVector + ONNX 384-d** — significant infra; out of
   scope.
9. **Dual-mode (Codex + Claude)** — out of scope for harim-base.
10. **WASM Agent Booster** — significant build infrastructure;
    skip until justified by token budget.

---

## §18. Sources

### §18.1 Live repo
- `ruvnet/ruflo` GitHub, main branch, snapshot 2026-05-07
- README.md, CLAUDE.md, AGENTS.md, package.json, CHANGELOG.md,
  SECURITY.md, LICENSE
- `.claude/settings.json` (7.2 KB; 20.5 KB backup)
- `.claude-plugin/{plugin.json, marketplace.json, hooks/hooks.json}`
- `.githooks/pre-commit`
- `bin/{cli.js, npx-repair.js, npx-safe-launch.js}`
- `scripts/{cleanup-v3.sh, install.sh, inventory-capabilities.mjs,
  regenerate-witness.mjs, sign-witness-from-inventory.mjs,
  verify-appliance.sh}`
- `docs/{_config.yml, index.md, STATUS.md, USERGUIDE.md}`
- `plugins/{32 plugin dirs}/.claude-plugin/plugin.json`
- `plugins/ruflo-core/{hooks/hooks.json, agents/coder.md, skills/
  discover-plugins/SKILL.md}`
- `plugin/.claude-plugin/plugin.json` (legacy mirror)
- `ruflo/{bin/ruflo.js, src/mcp-bridge/index.js, src/scripts/}`
- `tests/{rvf-*.test.ts, context-persistence-hook.test.mjs,
  docker-regression/}`
- `archive/{README.md, v2/, agents-root/}`
- `v3/{README.md, CHANGELOG.md, CLAUDE.md, swarm.config.ts, @claude-
  flow/, plugins/, mcp/, implementation/, goal_ui/}`
- `verification.md` (81 KB), `verification.md.json` (18 KB),
  `verification-inventory.json` (94 KB), `verification-results.md`

### §18.2 ADRs cited (in Ruflo)
- ADR-001 agentic-flow as core foundation
- ADR-003 unified swarm coordinator
- ADR-004 microkernel
- ADR-005 MCP-first
- ADR-006 / ADR-009 memory unification
- ADR-008 Vitest replacement
- ADR-010 Deno removal
- ADR-026 3-tier model routing
- ADR-033 RUVOCAL WASM MCP integration
- ADR-058 appliance verification
- ADR-070 WASM Agent Booster
- ADR-096 encryption-at-rest
- ADR-097 federation budget circuit breaker

### §18.3 SOTA scan cross-references (from
`paper/integration/02-sota-related-work.md`)
- §1.1 RL.3.1 — AlphaProof / Aristotle / BFS-Prover (sound regime)
- §1.6 RL.3.6 — iStar implicit step rewards
- §1.7 RL.3.7 — AgentPRM
- §1.10 L3 IT — BED-LLM (ICLR 2026)
- §1.11 L4 UQ — Adaptive Conformal Prediction (2026)
- §1.12 L5 DRO — DRO-InstructZero, BalDRO
- §1.14 L7 Game — ECON BNE multi-agent
- §1.15 OS.11 — MFS Martingale Foresight Sampling
- §3.5 Berkeley RDI 2026 — benchmark gameability (key motivator
  for Ruflo's witness chain)

### §18.4 Inter-corpus references
- `01-ecc-dssp.md` — `§7` for prevent-mode parallel
- `02-forgecode-dssp.md` — `§8` for recover-mode parallel + RL.3.4
  latent overlap
- `paper/sections/10-cross-agent-pattern.md` `§9.1` — master table
  insertion point

---

**Score**: 4.5/12 (RL.3.6 $\star$ + RL.3.7 $\star$ + Game.2 $\star$
+ DT.7 $\star$ + DRO.8 $\star$ + OR.9 $\star\star$ + 9 partials).

**Net status**: First audit-corpus member with cryptographic catalog
attestation (Ed25519 witness chain). First cross-installation
zero-trust federation (Game.2 $\star$). Largest skill surface
(35 + 88 + ~64 = ~187). Highest predicted developer-profile ceiling
of any audited agent ($+10\text{-}15\,\text{pp}$).

**Architectural blue-ocean confirmation**: Ruflo composes 6
distinct DSSP branches at $\geq \star$ activation, satisfying the
Prop 1 architectural-novelty criterion and providing the strongest
empirical evidence to date for the framework's blue-ocean
composition thesis.

Phase 11 lift candidates: §17 lists 6 high/medium-ROI patterns to
fold into `meta_harness/adapters/` and `core/`. The Ed25519 witness
chain is the highest-ROI single lift across the entire 14-agent
corpus.
