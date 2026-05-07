# claude-setup

Portable Claude Code setup. Drop on any device, run install, get a consistent agent environment with hook-enforced anonymity, 6 user-level skills, and DSSP-aligned multi-track priors.

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
├── .env.example
├── install.sh                          # POSIX (Mac/Linux/Git Bash)
└── install.ps1                         # Windows native PowerShell
```

## What it gives you

### Layer 0/1 — Settings + priors (auto-deployed)
- `~/.claude/settings.json` — permissions baseline (deny `rm -rf`, `curl`, `sudo`, `pip install`, `npm publish`, `.env` reads), narrow allow list, `includeCoAuthoredBy: false`, statusLine.
- `~/.claude/CLAUDE.md` — short response style, smallest-diff edits, KR-EN bilingual, Monogram commit hygiene.

### Layer 4 — Anonymity hook (deterministic enforcement)
`harim-base/hooks/strip-claude-attribution.sh` BLOCKS:
- `git commit` with `Co-Authored-By: Claude`, `🤖 Generated`, `claude.ai/code`, `noreply@anthropic.com`
- `git branch / checkout -b / push origin` with `claude-code/`, `anthropic/`, `claude/`
- `gh pr create` with the same attribution patterns

Hook uses Node (Claude Code prereq) for JSON parse — falls back to jq if needed; never silently fail-open.

### Layer 2 — 6 user-level skills

| Skill | Type | Triggered when |
|---|---|---|
| `dssp-audit` | capability uplift | auditing an agent / scoring 12-branch / RL spine activation |
| `gepa-reflection` | capability uplift | refining a prompt with ≥3 failed examples + feedback |
| `live-swe-reflection` | capability uplift | agent stuck in repetitive loop (single-sentence injection) |
| `monogram-commit` | encoded preference | drafting commit / branch / PR title |
| `ecc-prevent-mode` | capability uplift | designing CI gates, anti-pattern lists, hook profiles, install manifests |
| `forgecode-recover-mode` | capability uplift | runtime errors, doom-loop detection, pending-todos gates |

Skills auto-discovered by Claude Code from `plugins/harim-base/skills/<name>/SKILL.md`.

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

## Install

Prereqs: Node 18+, git, [Claude Code CLI](https://docs.claude.com/code).

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh         # Mac/Linux/Git Bash
# or
powershell ./install.ps1   # Windows native
```

Restart Claude Code. Marketplace + plugin + statusLine auto-activate via `~/.claude/settings.json` `pluginMarketplaces` + `enabledPlugins` + `statusLine` entries.

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
