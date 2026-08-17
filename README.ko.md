# claude-setup

한국어 | [English](./README.md)

> 반복 실패를 복구하고 미완료 작업을 확인하며, skill과 프로젝트별 작업 원칙을 어느 환경에서든 다시 구성하는 Claude Code 설정입니다.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why

권한, 지침, hook과 skill을 매번 손으로 설정하면 같은 Agent도 컴퓨터마다 다르게 동작합니다. 같은 tool call을 반복하며 접근법을 바꾸지 못하거나, 남은 작업이 있는데도 session을 끝내는 문제도 생깁니다. ML, 연구, package와 read-only repository는 서로 다른 작업 원칙이 필요하지만, 그 원칙을 프로젝트마다 처음부터 다시 만들 필요는 없다고 생각했습니다.

## How

Windows와 POSIX installer가 기존 사용자 설정을 먼저 backup한 뒤 동일한 settings, hook, skill, command, status line과 project template을 배포합니다. 세 개의 lifecycle hook이 반복되는 tool pattern을 감지하고, 종료 시 미완료 TodoWrite 항목을 보여주며, Git metadata 규칙을 적용합니다. 여섯 개의 재사용 가능한 skill, 네 개의 slash command, verifier subagent와 네 종류의 project prior가 더 깊은 복구 절차와 작업별 원칙을 제공합니다.

## Result

한 저장소에서 Windows, macOS와 Linux의 Claude Code 작업환경을 동일하게 복원할 수 있습니다. 반복 실패는 접근법을 바꾸기 위한 recovery prompt로 드러나고, 미완료 작업은 session 종료 전에 확인되며, 각 repository는 production ML·research·tool·read-only 원칙을 필요한 경우에만 적용할 수 있습니다.

## 설치되는 구성

| Layer | 설치 내용 |
|---|---|
| User settings | 권한 baseline, status line, skill routing |
| Hooks | 반복 감지, pending-work gate, Git metadata guard |
| Skills | DSSP audit, GEPA reflection, runtime recovery, prevent-mode, reflection, commit style |
| Commands | `/audit`, `/reflect`, `/commit`, `/skills` |
| Agent | test와 build 출력을 분리하는 `verifier-runner` |
| Project priors | `ml`, `research`, `tool`, `readonly` CLAUDE.md template |
| Rules | Python, Markdown, LaTeX path-scoped rule |

## 설치

Node 18+, Git, Claude Code가 필요하며 Windows에서는 Git Bash가 필요합니다.

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh                 # macOS, Linux, Git Bash
# 또는
powershell ./install.ps1       # Windows PowerShell
```

Installer는 기존 `~/.claude/settings.json`과 `~/.claude/CLAUDE.md`를 timestamp가 붙은 backup file로 복사한 뒤 새 설정을 배포합니다. 설치 후 Claude Code 또는 Claude Desktop을 재시작합니다.

```text
/plugin list
/plugin marketplace list
```

## 복구·완료 hook

| Hook | Event | 동작 |
|---|---|---|
| `doom-loop-detect.sh` | 모든 tool call 이후 | `A, A, A` 또는 `A, B, C, A, B, C` action signature를 감지하고 전제나 접근법을 바꾸는 prompt를 주입 |
| `pending-todos-gate.sh` | Stop | 최신 TodoWrite에 pending item이 남아 있으면 첫 종료를 가로채고 항목을 표시 |
| `strip-claude-attribution.sh` | Bash 실행 전 | commit·branch·worktree·PR command의 금지된 AI attribution을 차단하고 `git commit` 전에 짧은 commit 형식을 주입 |

Git metadata hook은 `HOOK_PROFILE=minimal|standard|strict`를 지원하며 기본값은 `standard`입니다.

## 권한 baseline

User template은 읽기 중심 작업과 일반적인 test command를 허용하고, recursive deletion, `sudo`, force push, hard reset, package publish와 secret file read처럼 범위가 넓거나 영향이 큰 command를 차단합니다. 설치 전 [`templates/user/settings.json`](./templates/user/settings.json)을 확인하고 각 컴퓨터의 trust boundary에 맞게 조정해야 합니다.

## 재사용 가능한 skill

| Skill | 역할 |
|---|---|
| `forgecode-recover-mode` | error, 반복 동작과 미완료 작업 이후의 bounded recovery |
| `live-swe-reflection` | 같은 접근이 반복될 때 한 문장으로 관점을 전환 |
| `ecc-prevent-mode` | design-time gate, anti-pattern과 hook profile 설계 |
| `dssp-audit` | Agent activation과 mechanism coverage audit |
| `gepa-reflection` | 실제 failure와 feedback을 바탕으로 prompt 수정 |
| `monogram-commit` | 짧고 명사 중심인 commit·branch·PR 이름 생성 |

## Project prior

용도에 맞는 template을 `<project>/CLAUDE.md`로 복사합니다.

- [`CLAUDE.md.ml`](./templates/project/CLAUDE.md.ml): production ML, KPI provenance, local/remote hybrid execution
- [`CLAUDE.md.research`](./templates/project/CLAUDE.md.research): preregistration, uncertainty와 연구 근거
- [`CLAUDE.md.tool`](./templates/project/CLAUDE.md.tool): npm/pip packaging, semver, README parity와 network safety
- [`CLAUDE.md.readonly`](./templates/project/CLAUDE.md.readonly): 다른 pipeline이 소유한 repository의 read-only 작업

## Skill 평가

[`scripts/eval-skills.sh`](./scripts/eval-skills.sh)는 `wshobson/agents` PluginEval을 실행하는 wrapper입니다. 외부 harness를 설치한 뒤 standard 또는 deep profile로 평가할 수 있습니다.

```bash
git clone https://github.com/wshobson/agents.git ~/wshobson-agents
cd ~/wshobson-agents/plugins/plugin-eval && uv sync --extra llm

cd ~/claude-setup
scripts/eval-skills.sh standard
scripts/eval-skills.sh deep
```

Skill별 Markdown report와 summary table을 만들며, 두 번째 인수로 skill name을 지정하면 해당 skill만 평가합니다.

## Repository 구조

```text
plugins/harim-base/hooks/       lifecycle hook
plugins/harim-base/skills/      재사용 skill 6개
plugins/harim-base/commands/    slash command 4개
plugins/harim-base/agents/      verifier-runner
templates/user/                 user settings와 CLAUDE.md
templates/project/              project prior 4종과 MCP template
templates/rules/                path-scoped rule
install.sh                      POSIX installer
install.ps1                     Windows installer
```

## 라이선스

MIT
