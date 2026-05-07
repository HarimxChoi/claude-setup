# harim-base v0.6.1 — self-audit (DSSP framework)

**System under audit**: `HarimxChoi/claude-setup`@`3a3ace3`
**Audit date**: 2026-05-07
**Audit method**: 동일 DSSP 6-step (cf. `03-ruflo-dssp.md`, `04-wshobson-dssp.md`)
**Empirical signal**: PluginEval standard-depth run, 6 skills, 2026-05-07

---

## §1. POMDP 5-tuple

| 요소 | 실제 구현 |
|---|---|
| **State `s`** | `(session_trajectory, todo_state, hook_log, settings_state, skill_catalog_state)` — partial; trajectory only persists via doom-loop JSONL (rolling 100 lines, project-scoped) |
| **Action `a`** | Claude tool surface (Bash, Read/Edit/Write, MCP tools, slash commands) — gated by Layer 0 deny list, Layer 4 PreToolUse veto, Layer 4 doom-loop reflection inject |
| **Observation `o`** | tool results ∪ hook `additionalContext` ∪ user messages ∪ statusline (`[model] @branch ctx N%`) ∪ PluginEval grade/badge (post-hoc) |
| **Reward `r`** | implicit (user satisfaction); explicit channels = (a) PluginEval composite ∈ [0,100], (b) commit success vs hook block, (c) Stop-gate todo-pending count |
| **Discount `γ`** | per-session; cross-session memory only via `~/.claude/memory/` MCP (project-prefixed per CLAUDE.md prior) and doom-loop JSONL |

**Verifier-soundness master variable** — multi-tiered, layer-specific:

| Layer | Verifier | Soundness | Coverage gap |
|---|---|---|---|
| 0 (deny list) | regex match | high | only explicit patterns; semantic equivalents (e.g. `bash -c "rm ..."`) bypass |
| 4 (anonymity) | regex match | high | ~0 false-negative on attribution leakage |
| 4 (doom-loop) | sig-equality REP3/CYCLE2 | low | catches naive loops, misses semantic loops (different params, same intent) |
| 4 (todo-gate) | transcript-scan TodoWrite | medium | depends on Claude using TodoWrite |
| Skill activation | description-match LLM router | **~50% ceiling** (devty 2026 empirical) | multi-tier T1-T4 raises to ~85% but no formal bound |
| PluginEval (external) | static + LLM judge + (MC unavailable) | medium at standard | depth=deep needed for Wilson CI / bootstrap; budget-blocked |
| verifier-runner subagent | Haiku rerun on test/lint output | medium | trust-but-verify caveat; not invoked automatically |

**Master variable bottleneck**: 솔로 use case에서는 **I (information) bottleneck dominant**. 과거 세션의 trajectory가 doom-loop JSONL 외엔 indexed 저장 부재. C/T는 saturating.

---

## §2. Task-class profile

| Task class | 빈도 | 현 verifier | 잔여 위험 |
|---|---|---|---|
| Production ML (sejong-con-bid) | 일상 | KPI discipline (CLAUDE.md.ml) + python rules + verifier-runner | 데이터 누설 |
| Research paper (Meta-Harness) | 주간 | research template (pre-registration, bootstrap CI, verbatim citation) + tex rules | 인용 정확성 |
| Personal automation (monogram) | 산발 | readonly template (외부 파이프라인 격리) | 권한 경계 |
| Tooling (google-surf, anti_bot) | 산발 | tool template (semver, SSRF guards) | 의존성 신선도 |
| **Harness 자체 유지보수** | **현 세션** | **PluginEval (external) + 본 self-audit** | **확장-피로** |

5번째 task class — **harness reflexivity** — 가 v0.6에서 처음 first-class로 격상. PluginEval lift가 그 trigger.

---

## §3. 12-branch theorem coverage

| Branch | Mechanism in harim-base v0.6.1 | Score |
|---|---|---|
| RL.3.1 AlphaZero | — | — |
| RL.3.2 PSRL | — | — |
| RL.3.3 Q-learning | — | — |
| **RL.3.4 OPE** | PluginEval Layer 1+2 (standard depth) — judge-layer F1 / rubric scoring on 6-skill catalog. Layer 3 MC budget-blocked (28 min/skill). | **★** |
| RL.3.5 HER | — | — |
| **RL.3.6 Options** | 6 skills × T1-T4 skillOverrides + 1 verifier-runner subagent. Small option library; no model-tier explicit (deferred v0.7). | partial |
| **RL.3.7 PRM** | verifier-runner subagent = per-step verification proxy; gepa-reflection 5-pt minibatch acceptance gate = process-level reward. Not pure PRM. | partial |
| Game.2 | — (솔로) | — |
| **UQ.3** | PluginEval external — at standard depth: judge layer rubric (anchored 5-pt). At deep: Wilson CI / bootstrap CI / Clopper-Pearson — **measured-but-unaffordable**. | **★** (would be ★★ if deep budget) |
| IT.4 | — | — |
| **OL.5** | gepa-reflection skill (verbatim ASI prompt, 2-tier acceptance) + doom-loop JSONL trajectory accumulation. Per-failure feedback loop intact. | partial |
| Causal.6 | — | — |
| **DT.7** | **다층 투명성**: skillOverrides explicit → `/skills` introspection → doom-loop JSONL `{ts, tool, sig, ses}` → statusline `ctx N%` → PluginEval grade/badge → Monogram commit lifecycle traceable | **★★** |
| **DRO.8** | **다층 prevent**: deny list 17개 + anonymity hook PreToolUse + pending-todos-gate Stop + monogram-commit lifecycle inject. Defense-in-depth tail-risk reduction. | **★** |
| OR.9 | — | — |
| Submodular.10 | — | — |
| OS.11 | — | — |
| AL.12 | — | — |

**Activation footprint**: DT.7★★ + UQ.3★ + DRO.8★ + RL.3.4★ = 4 strong (+1 from double-star), 3 partials (RL.3.6, RL.3.7, OL.5).
**Score**: **~3.5/12**.

---

## §4. Theorem activation + predicted ceiling

### Strong axes
- **DT.7★★**: 솔로 하네스 중 가장 깊은 투명성. 모든 결정이 statusline / hook log / `/skills` 명령으로 가시화. 14-agent corpus 어떤 시스템도 이 정도 self-introspection 없음.
- **DRO.8★**: 다층 prevent — 한 layer 실패해도 다음 layer가 잡음. ECC's prevent-mode와 동급. ruflo의 witness chain만큼 강력하진 않지만 솔로엔 그 비용 부적합.
- **UQ.3★**: PluginEval lift — standard depth만으로도 양의 ROI (YAML bug 2건 적발). 시도된 모든 surveyed 시스템 중 14-agent + ruflo는 0, wshobson만 ★★, harim 현재 ★ (deep depth 차단).
- **RL.3.4★**: OPE — PluginEval Monte Carlo 미실행 상태에서도 judge layer가 4-dim rubric off-policy 평가 제공.

### Partial axes
- **RL.3.6 (Options)**: 6 skills로는 작은 option library. ruflo 314 / wshobson 153 대비 1-2 order of magnitude 작음. 의도된 절제 (decision fatigue 방지).
- **RL.3.7 (PRM)**: verifier-runner subagent가 per-step verification 대용. 정식 PRM (학습된 reward model) 아님.
- **OL.5 (Online learning)**: gepa-reflection + doom-loop JSONL이 per-failure / per-trajectory feedback 채널 제공. 현재 데이터 누적 미흡 — v0.7+에서 1-2주 사용 후 재평가.

### Predicted ceiling (verifier-soundness 적용)

**Task class별 ceiling**:
- **Commit hygiene** + **destructive command prevention**: **포화** (hard verifiers, 0 false-negative 측정).
- **Skill activation**: ~85% (multi-tier T1-T4 cap; LLM router 50% baseline 위로 35pp lift).
- **Skill quality**: standard depth 측정 가능, 6 스킬 평균 60.7/100. Deep depth 차단으로 quality_var ± Wilson CI 미측정.
- **Doom-loop recovery**: REP3/CYCLE2 catch rate 알려지지 않음 (false-negative 측정 어려움).
- **Session reflection**: doom-loop JSONL 누적 의존 — v0.6.1 출시 시점 = 콜드 스타트.

### Top-3 bottleneck (master variable 분류)

1. **I-bottleneck (information)** — cross-session memory가 doom-loop JSONL 100-line rolling window뿐. 1주일 이상 trajectory 손실. Mitigation: SessionEnd digest hook (defer, #34713 위험) 또는 외부 vector store.
2. **C-bottleneck (capacity)** — UQ.3 deep depth가 ~$5 + 3-4시간 wallclock 요구. 카탈로그 6 → 12+ 확장 또는 plugin-eval에 `--n-runs` flag 추가 전엔 차단.
3. **T-bottleneck (time)** — skill activation latency. Multi-tier 라우팅이 prompt time을 늘리지 않도록 하는 게 trade-off의 기반. 현재 OK.

---

## §5. Empirical evaluation (2026-05-07)

### PluginEval standard-depth run, 6 skills (post-fix)

| Skill | Composite | Badge | 주요 dim 점수 (judge-layer) |
|---|---|---|---|
| monogram-commit | 77.2 | **Silver** | trigger 0.85, scope 0.90 |
| dssp-audit | 67.8 | Bronze | trigger 0.71, orch 0.76 (penalty - orchestrator 자기-선언) |
| ecc-prevent-mode | 66.2 | Bronze | trigger 0.70, scope 0.75 |
| gepa-reflection | 58.2 | No Badge | trigger 0.60, orch 0.40 |
| live-swe-reflection | 57.9 | No Badge | post-fix (pre-fix 35.7, +22.2) |
| forgecode-recover-mode | 56.7 | No Badge | orch 0.33 (의도된 orchestrator) |

**Observed activation evidence**:
- 평균 composite **64.0/100** (D-grade region)
- Silver 1, Bronze 2, No Badge 3
- **2/6 skills (33%)에 silent YAML bug** (description colon-space → empty frontmatter) — PluginEval lift 직접 ROI
- **1 SDK breaking change** (claude-agent-sdk ≥0.1.50의 `ResultMessage.content` 제거) 적발 후 patch
- **Systematic bias 식별**: orchestration_wiring 정적 검사가 self-declared orchestrator 스킬에 −0.15 페널티 (`04-wshobson-dssp.md` §10.5)

### Drift / weakness

1. **Standard depth ≠ UQ.3★★**: deep-only Wilson CI / bootstrap CI / Clopper-Pearson 미실행. UQ.3★ 한정.
2. **MC quality score = `min(1, len/500)` 결함** (`04-wshobson-dssp.md` §10.1) — verbose-but-wrong 스킬에 점수 인플레이션 위험. 6-skill catalog에선 무관 (모두 짧음).
3. **Hook-fire 검증 (post-mortem on v0.6.1 → fixed in v0.6.2)**: 재부팅 후 검증 시 PostToolUse JSONL 누적 0 발견. 진단: claude-code issue **#22700** — Windows Desktop App이 `bash` 명령을 system PATH로 resolve하는데 Git for Windows 기본 설치는 `Git\cmd`만 등록 (`Git\bin` 미등록), `bash.exe` 미발견. **Hook 매칭은 되나 실행 silent fail**. Fix: settings.json hook command를 절대경로 (`C:/Program Files/Git/bin/bash.exe`)로 변경. install.sh + install.ps1 모두 detect-bash-path 로직 추가. v0.6.2에서 해소.
4. **Memory namespace prior가 enforce 아닌 prior**: `<project>:<entity>` 권고일 뿐 자동 감시 없음.
5. **verifier-runner subagent dead-weight 위험**: CLAUDE.md prior로만 위임 안내; 실제 사용 빈도 측정 없음.

---

## §6. Comparison with surveyed corpus

| 시스템 | DSSP | UQ.3 | DT.7 | DRO.8 | Hook layer | 솔로 적합도 |
|---|---|---|---|---|---|---|
| **harim-base v0.6.1** | **3.5** | ★ | ★★ | ★ | 3 | **N/A (자기)** |
| ruflo | 4.5 | — | ★ | ★ (witness) | 4 | low (federation 필요) |
| wshobson/agents | 3.5 | ★★ (full MC) | ★ | — (core) | 0 (repo) | medium (UQ liftable) |
| ECC | 3.0 | — | ★ | ★ (prevent) | 3 | high |
| ForgeCode | 2.5 | — | partial | partial | 2 | high |
| 14-agent best (ECC) | 3.0 | — | ★ | ★ | 3 | high |

### harim-base의 sui generis 영역
- **Multi-tier deterministic routing** (T1 lifecycle hook → T2 priors CLAUDE.md → T3 slash command → T4 auto-discovery) — 다른 어떤 시스템도 명시화하지 않음.
- **Lifecycle skill injection** (PreToolUse Bash on `git commit` → monogram-commit guidance 자동 주입) — wshobson/ruflo 모두 description-driven activation 의존.
- **Solo-tuned defaults** — 80+ specialty agents 카탈로그 의식적 거부, federation/swarm/witness chain 거부.
- **Bilingual prior + anonymity hook** — operational, not DSSP-scored.

### ruflo와의 ~1점 격차 분해
- Game.2★ (federation BNE): 솔로엔 0 가치.
- OR.9★★ (SwarmAI): 솔로엔 0 가치.
- DRO.8★ → ★ (witness chain): GPG sign이 95% 회수.

→ **Solo-relevant DSSP**로 재계산하면 harim-base 3.5 ≈ ruflo 3.5. **솔로 use case에선 saturated.**

---

## §7. Saturation argument

다음 lift 후보군 (이전 트라이아지 결과):

| 후보 | DSSP gain | 비용 | 판정 | 대기 조건 |
|---|---|---|---|---|
| Federation BNE | Game.2★ | 거대 | reject | 솔로 → 다중-사용자 전환 |
| SwarmAI scheduling | OR.9★★ | 거대 | reject | 멀티-머신 |
| Witness chain | DRO.8 +0.5 | 키 관리 | reject | GPG로 95% 회수 |
| 80+ specialty agents | RL.3.6 +1 | 결정피로 | reject | 카탈로그 N>20 사용 사례 |
| Agent Teams (tmux) | Game.2 partial | CLI 의존 | defer | Desktop → CLI 전환 |
| Irreversibility classifier (D) | DRO.8 +0.5 | 50줄 + UX 위험 | defer | near-miss 1건 누적 |
| UserPromptSubmit forced-eval (E) | activation +14pp | #34713 | defer | 업스트림 픽스 |
| SessionEnd digest | I-bottleneck +0.5 | 미검증 hook event | defer | 1주 사용 후 재평가 |
| Model-tier frontmatter | RL.3.6 +0.3 | 설계 | defer | v0.7 |
| Deep eval CI (overnight) | UQ.3 +1 | $5/run, 3-4h | defer | 카탈로그 N>12 |
| Elo skill matchup | OL.5 +0.3 | matchup 빈도 | reject | 현 N=6 |

**모든 후보가 (a) 솔로 부적합 reject, (b) 외부 신호 대기 defer, (c) 규모 임계 대기 defer** 중 하나에 속함.

→ **6-skill 카탈로그 + 솔로 + Desktop 환경 조합에서 v0.6.1이 효율적 천장**.

---

## §8. Conclusions

### Headline
- **harim-base v0.6.1 ≈ 3.5/12 DSSP** (DT.7★★ + UQ.3★ + DRO.8★ + RL.3.4★ + 3 partials)
- Solo-relevant DSSP 비교 시 ruflo와 동급, 14-agent corpus best (ECC) 초과
- 6-skill 카탈로그 / 솔로 / Desktop 조합에서 **saturated**

### Empirical validation
- PluginEval standard-depth run이 33% silent failure rate 적발 → UQ.3 lift ROI 실증
- 다층 prevent (deny + anonymity + todo-gate)가 commit/tool-safety 채널을 hard-verifier로 saturating
- DT.7 채널 4종 (statusline / `/skills` / JSONL / PluginEval) 모두 active

### Methodological notes
- Deep eval budget 차단 = 솔로 ad-hoc 환경에선 PluginEval Layer 3 (Monte Carlo) 부적합 — wallclock 28 min/skill, 6 스킬 풀 ~3-4시간
- Layer 1+2 (static + judge)만으로도 양의 ROI — Wilson CI / bootstrap CI 부재가 lift를 무효화하지 않음

### Reflexivity claim
본 self-audit 자체가 DT.7 활성화 사례. ruflo의 evaluation-methodology 재귀 패턴 (`04-wshobson-dssp.md` §6.9: "self-documenting skill")의 적용. **DSSP audit framework가 자기 자신에게 적용된 첫 사례**가 v0.6의 부산물.

---

## §9. Recommendation: stop here

추가 lift는 잡음/over-engineering. 다음 의미 있는 분기점:
1. **1-2주 일상 사용** → doom-loop JSONL · eval-reports · gepa-reflection trace 누적 → 실측 신호로 v0.7 lift candidate 결정
2. **카탈로그 N=6 → N=12** → deep eval CI 정당화 → UQ.3 ★★ 회수
3. **CLI 전환** → Agent Teams / experimental hook events 검토

지금은 **harness가 use case에 saturated**. Skip add-feature, focus 사용.

---

## Sources

- `templates/user/{settings.json, CLAUDE.md}` (Layer 0/1)
- `plugins/harim-base/{hooks, agents, commands, skills, rules}/**` (Layer 2/4)
- `plugins/harim-base/.claude-plugin/plugin.json` v0.6.0
- `.claude-plugin/marketplace.json` v0.6.0
- `scripts/eval-skills.sh`
- `~/.claude/harim-base/eval-reports/summary-20260507-{143259, 143934, 144012}.md`
- `~/.claude/harim-base/.harim/action-log.jsonl` (doom-loop trace)
- `docs/03-ruflo-dssp.md`, `docs/04-wshobson-dssp.md` (비교 audit)
