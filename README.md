# claude-setup

Portable Claude Code setup — ECC-grade operator surface with multi-tier deterministic routing + PluginEval-driven UQ.3 measurement. DSSP ~3.5/12 (ForgeCode operator-surface tier + DT.7 / DRO.8 / UQ.3 increments after ruflo and wshobson/agents audits).

**v0.6.2** — Windows Desktop App hook fix (claude-code issue [#22700](https://github.com/anthropics/claude-code/issues/22700)): `bash` command in `settings.json` hooks fails on Windows Desktop because it uses system PATH (Git for Windows default = `Git\cmd` only, no `Git\bin`). `install.sh` + `install.ps1` now detect `bash.exe` full path (`C:/Program Files/Git/bin/bash.exe` or fallback) and inject absolute path in hooks block + statusLine. Re-run installer after upgrade.

**v0.6.0** — UQ.3 lift: external dep on wshobson/agents `plugin-eval` for skill-quality scoring (Wilson CI / bootstrap CI / Clopper-Pearson CI). New `scripts/eval-skills.sh` wrapper runs `uv run plugin-eval score` against the 6 user-level skills with markdown summary output.

**v0.5.0** — triaged ruflo lifts: extended Bash deny list (`git push --force`, `git reset --hard`, `chmod 777`, `find ... -delete`); `/skills` introspection command; doom-loop JSONL extended with `{tool, ses}` so `/reflect` can pull in-session trajectory; verifier-runner delegation prior + memory namespace prior in user CLAUDE.md.

**v0.4.0** — doom-loop detection, pending-todos completion gate, verifier-runner subagent, skillOverrides routing, slash commands, lifecycle skill activation.

[**한국어 README →**](./README.ko.md)

## Layout

```
.
├── .claude-plugin/marketplace.json     # plugin marketplace manifest
├── plugins/
│   └── harim-base/
│       ├── .claude-plugin/plugin.json
│       ├── hooks/                      # PreToolUse anonymity hook
│       ├── scripts/statusline.sh       # status bar (model + branch + ctx %)
│       └── skills/                     # 6 user-level skills
│           ├── dssp-audit/
│           ├── gepa-reflection/
│           ├── live-swe-reflection/
│           ├── monogram-commit/
│           ├── ecc-prevent-mode/
│           └── forgecode-recover-mode/
├── templates/
│   ├── user/{settings.json, CLAUDE.md}    # auto-deployed by install
│   ├── project/{CLAUDE.md.ml, .research, .tool, .readonly, .mcp.json}
│   └── rules/{python, markdown, tex}.md
├── scripts/
│   └── eval-skills.sh                  # PluginEval wrapper (DSSP UQ.3)
├── docs/
│   ├── 03-ruflo-dssp.md                # ruflo DSSP audit (4.5/12)
│   ├── 04-wshobson-dssp.md             # wshobson/agents DSSP audit (3.5/12)
│   └── monogram-webui-port-plan.md
├── .env.example
├── install.sh                          # POSIX (Mac/Linux/Git Bash)
└── install.ps1                         # Windows native PowerShell
```

## What it gives you

### Layer 0/1 — Settings + priors (auto-deployed)
- `~/.claude/settings.json` — permissions baseline (deny `rm -rf`, `curl`, `sudo`, `pip install`, `npm publish`, `.env` reads), narrow allow list, `includeCoAuthoredBy: false`, statusLine.
- `~/.claude/CLAUDE.md` — short response style, smallest-diff edits, KR-EN bilingual, Monogram commit hygiene.

### Layer 4 — Three deterministic hooks

| Hook | Event | Role |
|---|---|---|
| `strip-claude-attribution.sh` | PreToolUse Bash | (1) BLOCKS attribution leakage in git commit / branch / push / `gh pr create` (2) INJECTS monogram-commit guidance on every `git commit` (Tier 1 lifecycle skill activation) |
| `doom-loop-detect.sh` | PostToolUse all | Logs action signatures to JSONL; on `[A,A,A]` 3-rep or `[A,B,C][A,B,C]` cycle, injects reflection. Silent stdout when no pattern (#34713 mitigation). |
| `pending-todos-gate.sh` | Stop | Scans transcript for latest TodoWrite; blocks termination via `decision:block` JSON if pending items exist. Uses `stop_hook_active` flag to prevent infinite loops. |

`HOOK_PROFILE` env var: `"minimal"` (skip all) / `"standard"` (default) / `"strict"`. All hooks use Node for JSON parse (Claude Code prereq).

### Layer 2 — 6 skills with multi-tier deterministic routing

| Skill | Tier | skillOverride | Activation |
|---|---|---|---|
| `monogram-commit` | T1 lifecycle | `user-invocable-only` | Auto on `git commit` via PreToolUse hook (100%); `/commit` for explicit |
| `forgecode-recover-mode` | T1 lifecycle | `user-invocable-only` | Auto via doom-loop hook + pending-todos hook (100%); skill body for documentation |
| `live-swe-reflection` | T2 priors | `name-only` | Mentioned in project CLAUDE.md; description short enough |
| `ecc-prevent-mode` | T2 priors | `name-only` | Mentioned in project CLAUDE.md (CI / governance work) |
| `dssp-audit` | T3 explicit + T4 auto | `on` | `/audit` slash command + auto-discovery |
| `gepa-reflection` | T3 explicit + T4 auto | `on` | `/reflect` slash command + auto-discovery |

**Multi-tier rationale**: LLM-as-router has ~50% activation ceiling (devty 2026 empirical study). Multi-tier combination (T1 lifecycle hooks + T2 task-typed CLAUDE.md + T3 slash commands) achieves effective ~85% coverage without the latency / #34713 risk of forced-eval UserPromptSubmit hooks.

### Layer 2 — verifier-runner subagent

`plugins/harim-base/agents/verifier-runner.md` — Haiku-based subagent for high-noise output isolation. Runs tests/lint/type-checks, returns ≤500-char pass/fail summary. Read-only.

### Layer 2 — 4 slash commands

`plugins/harim-base/commands/{audit, reflect, commit, skills}.md` — explicit invocation paths for T3 skills + `/skills` introspection (lists active skills with activation tier, flags dead weight / drift / missing-command).

### Layer 1 (project) — 4 CLAUDE.md templates

Copy the matching one to `<project>/CLAUDE.md`:
- `CLAUDE.md.ml` — production ML (KPI discipline, EC2/local hybrid, no aggregate-only claims)
- `CLAUDE.md.research` — paper / research corpus (pre-registration, bootstrap CI, verbatim citation)
- `CLAUDE.md.tool` — npm/pip package (semver, README/ko parallel, SSRF guards)
- `CLAUDE.md.readonly` — repo owned by external pipeline (e.g., Monogram); Claude stays read-only

### Layer 3 — `.mcp.json` template (project-scope)

`templates/project/.mcp.json` includes 6 MCP servers (github, filesystem, memory, fetch, read-website, google-surf) with `${VAR}` env placeholders. Copy to project root + edit `.env`.

### Path-scoped rules

`templates/rules/{python, markdown, tex}.md` — copy to project's `.claude/rules/` to apply only on matching files.

### statusLine

`bash plugins/harim-base/scripts/statusline.sh` — shows `[model] @branch ctx N%` with green/yellow/red thresholds. Auto-configured by installer.

### Layer 2 — UQ.3 skill-quality measurement (external dep)

`scripts/eval-skills.sh` wraps wshobson/agents `plugin-eval` (Wilson CI / bootstrap CI / Clopper-Pearson CI / Elo). Lift target identified in `docs/04-wshobson-dssp.md`. One-time setup:

```bash
git clone https://github.com/wshobson/agents.git ~/wshobson-agents
cd ~/wshobson-agents/plugins/plugin-eval && uv sync --extra llm
# then from claude-setup root:
scripts/eval-skills.sh standard          # ~$0.30, all 6 skills, "Assessed"
scripts/eval-skills.sh deep              # ~$3, 50 MC runs each, "Certified"
```

Output: per-skill markdown reports + summary table at `~/.claude/harim-base/eval-reports/summary-<ts>.md` with composite score, grade (A+~F), badge (Bronze~Platinum), confidence label.

## Install

Prereqs: Node 18+, git, Claude Code (CLI or Desktop app).

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh         # Mac/Linux/Git Bash
# or
powershell ./install.ps1   # Windows native
```

**install.sh deploys 2 ways** (both run automatically):
1. **Plugin path** (Claude Code CLI): adds repo to `pluginMarketplaces`; activate via `/plugin install harim-base@harim-marketplace`
2. **User-level path** (Claude Desktop / fallback): copies skills/agents/commands/rules to `~/.claude/<type>/` and injects hooks block (with absolute paths) into `~/.claude/settings.json`

Restart Claude Code or Claude Desktop after install. Hooks fire on Bash calls; skills/agents/commands appear in their respective lists.

## Verify

```
/plugin list                    # harim-base@harim-marketplace
/plugin marketplace list        # harim-marketplace
```

Try a commit with `Co-Authored-By: Claude` in the body — anonymity hook blocks it.

## Layered architecture

| Layer | Mechanism | This repo |
|---|---|---|
| 0 — settings.json | permissions, model, env, statusLine | ✓ |
| 1 — CLAUDE.md | priors (user + 4 project templates) | ✓ |
| 2 — Skills + Subagents | capabilities (6 skills) | ✓ |
| 3 — MCP | external tools (template) | ✓ |
| 4 — Hooks | deterministic enforcement (anonymity) | ✓ |
| 5 — Memory | auto-memory + project memory | (auto) |

## License

MIT.
