# claude-setup

개인용 Claude Code 환경 설정. clone 한 번에 어느 머신에서도 동일하게 재현. Hooks 기반 결정론적 가드, user-level skill 6개, DSSP 기반 multi-track priors 포함.

[**English README →**](./README.md)

## 구조

```
.
├── .claude-plugin/marketplace.json     # plugin 마켓플레이스 매니페스트
├── plugins/
│   └── harim-base/
│       ├── .claude-plugin/plugin.json
│       ├── hooks/                      # PreToolUse 가드 hook
│       ├── scripts/statusline.sh       # status bar (모델 + 브랜치 + ctx %)
│       └── skills/                     # 6 user-level skills
│           ├── dssp-audit/
│           ├── gepa-reflection/
│           ├── live-swe-reflection/
│           ├── monogram-commit/
│           ├── ecc-prevent-mode/
│           └── forgecode-recover-mode/
├── templates/
│   ├── user/{settings.json, CLAUDE.md}    # 자동 배포
│   ├── project/{CLAUDE.md.ml, .research, .tool, .readonly, .mcp.json}
│   └── rules/{python, markdown, tex}.md
├── .env.example
├── install.sh                          # POSIX (Mac/Linux/Git Bash)
└── install.ps1                         # Windows native PowerShell
```

## 구성

### Layer 0/1. Settings + priors (자동 배포)
- `~/.claude/settings.json`: permissions baseline (`rm -rf`, `curl`, `sudo`, `pip install`, `npm publish`, `.env` 읽기 deny), 좁은 allow list, `includeCoAuthoredBy: false`, statusLine.
- `~/.claude/CLAUDE.md`: 짧은 응답, 최소 diff, KR-EN bilingual, Monogram commit hygiene.

### Layer 4. Hooks (결정론적 가드)
- `strip-claude-attribution.sh`: commit 메시지 / branch / PR 제목 형식 강제 (monogram-commit 가이드 주입)
- `doom-loop-detect.sh`: PostToolUse에서 action signature 추적, `[A,A,A]` 또는 `[A,B,C]·[A,B,C]` 감지 시 reflection inject
- `pending-todos-gate.sh`: Stop 시 TodoWrite open item 있으면 종료 차단

JSON parse는 Node (Claude Code 전제조건)로 처리, jq fallback. silent fail-open 안 함.

### Layer 2. user-level skills 6개

| Skill | 종류 | 활성화 시점 |
|---|---|---|
| `dssp-audit` | capability uplift | agent 감사 / 12-branch 점수 / RL spine 활성화 측정 |
| `gepa-reflection` | capability uplift | 실패 예제 ≥3개 + feedback으로 prompt 개선 |
| `live-swe-reflection` | capability uplift | agent 반복 루프 빠짐 (single-sentence injection) |
| `monogram-commit` | encoded preference | commit / branch / PR 제목 작성 |
| `ecc-prevent-mode` | capability uplift | CI gate, anti-pattern list, hook profile, install manifest 설계 |
| `forgecode-recover-mode` | capability uplift | runtime error, doom-loop 감지, pending-todos gate |

Claude Code가 `plugins/harim-base/skills/<name>/SKILL.md`에서 자동으로 로드함.

### Layer 1 (프로젝트). CLAUDE.md 템플릿 4종

용도에 맞는 것을 `<project>/CLAUDE.md`로 복사:
- `CLAUDE.md.ml`: production ML (KPI discipline, EC2/local 하이브리드)
- `CLAUDE.md.research`: paper / research corpus (pre-registration, bootstrap CI)
- `CLAUDE.md.tool`: npm/pip 패키지 (semver, README/ko parallel)
- `CLAUDE.md.readonly`: 외부 pipeline 소유 repo (예: Monogram). Claude는 read-only

### Layer 3. `.mcp.json` 템플릿 (project-scope)

`templates/project/.mcp.json`에 MCP server 6개 (github, filesystem, memory, fetch, read-website, google-surf), `${VAR}` env placeholder 포함. project root에 복사 후 `.env` 채우면 됨.

### Path-scoped rules

`templates/rules/{python, markdown, tex}.md`. project의 `.claude/rules/`에 복사하면 매칭 파일에서만 활성화.

### statusLine

`bash plugins/harim-base/scripts/statusline.sh`. `[model] @branch ctx N%` 표시 (green/yellow/red threshold). 설치 스크립트에서 자동 설정함.

## 설치

사전 요구: Node 18+, git, [Claude Code CLI](https://docs.claude.com/code).

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh         # Mac/Linux/Git Bash
# 또는
powershell ./install.ps1   # Windows native
```

Claude Code 재시작. `~/.claude/settings.json`의 `pluginMarketplaces`, `enabledPlugins`, `statusLine`이 자동으로 잡힘.

## 검증

```
/plugin list                    # harim-base@harim-marketplace
/plugin marketplace list        # harim-marketplace
```

commit 메시지에서 monogram-commit 형식을 따르지 않으면 hook이 가이드를 inject.

## Layer 구조

| Layer | 메커니즘 | 본 repo |
|---|---|---|
| 0. settings.json | 권한, 모델, env, statusLine | ✓ |
| 1. CLAUDE.md | priors (user + project template 4종) | ✓ |
| 2. Skills + Subagents | capabilities (skill 6개) | ✓ |
| 3. MCP | 외부 도구 (템플릿) | ✓ |
| 4. Hooks | 결정론적 가드 (commit 형식, doom-loop, pending-todos) | ✓ |
| 5. Memory | auto-memory + project memory | (자동) |

## License

MIT.
