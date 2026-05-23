# claude-setup

Portable Claude Code setup. Auto-strip attribution + doom-loop detection + completion gate + 6 user-level skills.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## What you get

- **Auto-anonymity** — strips `Co-Authored-By: Claude` and AI footer leakage from commits, branches, and `gh pr create`
- **Doom-loop detection** — interrupts when the agent repeats `A, A, A` or cycles `A, B, C, A, B, C`
- **Pending-todos gate** — blocks `Stop` when TodoWrite has open items
- **6 user-level skills** — `/audit`, `/reflect`, `/commit`, `/skills`, plus `live-swe-reflection` and `ecc-prevent-mode` as priors
- **4 project templates** — `.ml`, `.research`, `.tool`, `.readonly` CLAUDE.md
- **Multi-tier routing** — LLM-as-router ceiling is ~50%; lifecycle hooks + priors + slash commands lift effective coverage to ~85%

## Install

Prereqs: Node 18+, git, Claude Code.

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh         # Mac/Linux/Git Bash
# or
powershell ./install.ps1   # Windows
```

Restart Claude Code or Claude Desktop. Verify with `/plugin list`.

## Verify anonymity

Try a commit with `Co-Authored-By: Claude` in the body. The pre-Bash hook blocks it.

## Layered architecture

| Layer | What | Status |
|---|---|---|
| 0 — settings.json | permissions, model, env, statusLine | ✓ |
| 1 — CLAUDE.md | priors (user + 4 project templates) | ✓ |
| 2 — Skills + Subagents | 6 skills + verifier-runner | ✓ |
| 3 — MCP | template (.mcp.json with 6 servers) | ✓ |
| 4 — Hooks | anonymity + doom-loop + pending-todos | ✓ |
| 5 — Memory | auto-memory + project memory | (built-in) |

## Skills

| Skill | Tier | Invocation |
|---|---|---|
| `monogram-commit` | T1 lifecycle | Auto on `git commit`; `/commit` for explicit |
| `forgecode-recover-mode` | T1 lifecycle | Auto via doom-loop / pending-todos hook |
| `live-swe-reflection` | T2 prior | Mentioned in project CLAUDE.md |
| `ecc-prevent-mode` | T2 prior | Mentioned in project CLAUDE.md |
| `dssp-audit` | T3 + T4 | `/audit` |
| `gepa-reflection` | T3 + T4 | `/reflect` |

## Hooks

| Hook | Event | Role |
|---|---|---|
| `strip-claude-attribution.sh` | PreToolUse Bash | Blocks attribution leakage; injects monogram-commit guidance |
| `doom-loop-detect.sh` | PostToolUse all | Logs action signatures; on `[A,A,A]` or `[A,B,C]·[A,B,C]` injects reflection |
| `pending-todos-gate.sh` | Stop | Scans transcript for TodoWrite; blocks termination if pending items exist |

`HOOK_PROFILE` env: `minimal` / `standard` (default) / `strict`.

## Project templates

Copy the matching `CLAUDE.md.<type>` to `<project>/CLAUDE.md`:

- `.ml` — production ML (KPI discipline, no aggregate-only claims)
- `.research` — paper / research corpus (pre-registration, bootstrap CI)
- `.tool` — npm / pip package (semver, README/ko parallel, SSRF guards)
- `.readonly` — Claude stays read-only (when repo is owned by external pipeline)

## Why deterministic routing

LLM-as-router for skills has a measured ~50% activation ceiling (devty 2026 empirical study). This setup combines T1 lifecycle hooks (100% activation), T2 task-typed CLAUDE.md priors, and T3 slash commands to push effective coverage to ~85% without the latency of forced-eval `UserPromptSubmit` hooks.

## Skill quality scoring (optional)

`scripts/eval-skills.sh` wraps `wshobson/agents` `plugin-eval` with Wilson / bootstrap / Clopper-Pearson CI. One-time setup:

```bash
git clone https://github.com/wshobson/agents.git ~/wshobson-agents
cd ~/wshobson-agents/plugins/plugin-eval && uv sync --extra llm

cd ~/claude-setup
scripts/eval-skills.sh standard      # ~$0.30 all 6 skills
scripts/eval-skills.sh deep          # ~$3 deep MC
```

Output: per-skill markdown reports + summary table.

## Version history

- v0.6.2 — Windows Desktop App hook fix ([#22700](https://github.com/anthropics/claude-code/issues/22700))
- v0.6.0 — UQ.3 lift: PluginEval-based skill quality scoring
- v0.5.0 — `git push --force`, `git reset --hard`, `chmod 777`, `find -delete` deny list
- v0.4.0 — doom-loop detection, pending-todos gate, verifier-runner subagent

## License

MIT.
