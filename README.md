# claude-setup

[한국어](./README.ko.md) | English

> A portable Claude Code operator layer for recovery, completion checks, reusable skills, and project-specific working rules.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why

An agent can behave differently on every machine when permissions, instructions, hooks, and skills are configured by hand. Repeated tool calls can also consume a session without changing the approach, while unfinished work can disappear behind an early stop. ML, research, package, and read-only repositories need different working rules, but those rules should remain reusable.

## How

The Windows and POSIX installers back up the current user configuration, then deploy the same settings, hooks, skills, commands, status line, and project templates. Three lifecycle hooks watch for repeated tool patterns, surface unfinished TodoWrite items at stop time, and enforce neutral Git metadata. Six reusable skills, four slash commands, a verifier subagent, and four project priors provide the deeper recovery and task-specific behavior.

## Result

The same Claude Code working environment can be restored on Windows, macOS, or Linux from one repository. Failure states become explicit recovery prompts, unfinished work is surfaced before the session exits, and each repository can opt into production-ML, research, tool, or read-only rules without rebuilding the setup from scratch.

## What is installed

| Layer | Installed behavior |
|---|---|
| User settings | Permission baseline, status line, skill routing |
| Hooks | Repetition detection, pending-work gate, Git metadata guard |
| Skills | DSSP audit, GEPA reflection, runtime recovery, prevent-mode, reflection, commit style |
| Commands | `/audit`, `/reflect`, `/commit`, `/skills` |
| Agent | `verifier-runner` for isolated test and build output |
| Project priors | `ml`, `research`, `tool`, and `readonly` CLAUDE.md templates |
| Rules | Path-scoped Python, Markdown, and LaTeX rules |

## Install

Prerequisites: Node 18+, Git, Claude Code, and Git Bash on Windows.

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh                 # macOS, Linux, or Git Bash
# or
powershell ./install.ps1       # Windows PowerShell
```

The installer copies an existing `~/.claude/settings.json` and `~/.claude/CLAUDE.md` to timestamped backup files before replacing them. Restart Claude Code or Claude Desktop after installation.

```text
/plugin list
/plugin marketplace list
```

## Recovery and completion hooks

| Hook | Event | Behavior |
|---|---|---|
| `doom-loop-detect.sh` | After every tool call | Detects `A, A, A` or `A, B, C, A, B, C` action-signature patterns and injects a prompt to change the underlying assumption or approach |
| `pending-todos-gate.sh` | Stop | Intercepts the first stop when the latest TodoWrite state still contains pending items and returns their names |
| `strip-claude-attribution.sh` | Before Bash | Blocks disallowed AI-attribution strings in commits, branches, worktrees, and PR commands; injects the short commit format before `git commit` |

The Git metadata hook supports `HOOK_PROFILE=minimal|standard|strict`; `standard` is the default.

## Permission baseline

The user template allows read-oriented work and common test commands while denying broad or high-impact commands such as recursive deletion, `sudo`, force push, hard reset, publishing, and secret-file reads. Review [`templates/user/settings.json`](./templates/user/settings.json) before installation and adapt it to the machine's trust boundary.

## Reusable skills

| Skill | Purpose |
|---|---|
| `forgecode-recover-mode` | Bounded recovery after errors, repeated actions, or incomplete work |
| `live-swe-reflection` | One focused reflection when an approach is repeating without progress |
| `ecc-prevent-mode` | Design-time gates, anti-patterns, and hook profiles |
| `dssp-audit` | Agent activation and mechanism-coverage audit |
| `gepa-reflection` | Prompt revision from observed failures and feedback |
| `monogram-commit` | Short, noun-centric commit, branch, and PR naming |

## Project priors

Copy the matching template to `<project>/CLAUDE.md`:

- [`CLAUDE.md.ml`](./templates/project/CLAUDE.md.ml): production ML, KPI provenance, and hybrid local/remote execution
- [`CLAUDE.md.research`](./templates/project/CLAUDE.md.research): preregistration, uncertainty, and research evidence
- [`CLAUDE.md.tool`](./templates/project/CLAUDE.md.tool): npm/pip packaging, semver, README parity, and network safety
- [`CLAUDE.md.readonly`](./templates/project/CLAUDE.md.readonly): read-only work in repositories owned by another pipeline

## Evaluate a skill

[`scripts/eval-skills.sh`](./scripts/eval-skills.sh) wraps `wshobson/agents` PluginEval. After installing that external harness, run either the standard or deeper evaluation profile:

```bash
git clone https://github.com/wshobson/agents.git ~/wshobson-agents
cd ~/wshobson-agents/plugins/plugin-eval && uv sync --extra llm

cd ~/claude-setup
scripts/eval-skills.sh standard
scripts/eval-skills.sh deep
```

The script writes one Markdown report per skill and a summary table. It also accepts a skill name as the second argument to evaluate only that skill.

## Repository layout

```text
plugins/harim-base/hooks/       lifecycle hooks
plugins/harim-base/skills/      six reusable skills
plugins/harim-base/commands/    four slash commands
plugins/harim-base/agents/      verifier-runner
templates/user/                 user settings and CLAUDE.md
templates/project/              four project priors and MCP template
templates/rules/                path-scoped rules
install.sh                      POSIX installer
install.ps1                     Windows installer
```

## License

MIT
