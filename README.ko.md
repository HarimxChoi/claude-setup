# claude-setup

휴대용 Claude Code 세팅. 어떤 디바이스에서든 clone + install로 일관된 에이전트 환경 복원.

[**English README →**](./README.md)

## 구조

```
.
├── .claude-plugin/marketplace.json     # plugin 마켓플레이스 매니페스트
├── plugins/
│   └── harim-base/
│       ├── .claude-plugin/plugin.json
│       └── hooks/                      # PreToolUse 익명성 hook
├── templates/user/
│   ├── settings.json                   # user-level Claude Code 설정
│   └── CLAUDE.md                       # user-level priors
├── .env.example
└── install.sh
```

## 무엇을 하는가

1. **익명성 hook** — `harim-base/hooks/strip-claude-attribution.sh`가 `git commit / branch / push / gh pr create` 명령에서 Claude/Anthropic 흔적이 leak되는 것을 차단. Monogram 스타일 (짧고 명사 중심) commit 메시지를 강제.
2. **Permissions baseline** — 합리적인 deny list (`rm -rf`, `curl`, `sudo`, `pip install`, `npm publish`, `.env` 읽기), 좁은 allow list (Read/Glob/Grep, `python`, `pytest`, git read-only).
3. **Working-style priors** — 짧은 응답, 군더더기 없음, 최소 diff, Bash로 self-verification, KR-EN bilingual.

## 설치

사전 요구: Node 18+, git, jq, [Claude Code CLI](https://docs.claude.com/code).

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh
```

Claude Code 안에서:

```
/plugin marketplace add ~/claude-setup
/plugin install harim-base@harim-marketplace
/plugin list
```

## 익명성 hook 검증

Claude에게 `Co-Authored-By: Claude` 또는 `🤖 Generated`가 포함된 commit 메시지로 commit하도록 요청하세요. Hook이 exit 2 + 재작성 가이드와 함께 차단합니다.

## Layer 구조

| Layer | 메커니즘 | 본 repo |
|---|---|---|
| 0 — settings.json | 권한, 모델, env | ✓ |
| 1 — CLAUDE.md | priors | ✓ user-level |
| 2 — Skills + Subagents | capabilities | 다음 phase |
| 3 — MCP | 외부 도구 | 다음 phase |
| 4 — Hooks | 결정론적 강제 | ✓ 익명성 |
| 5 — Memory | auto-memory + project memory | (자동) |

## License

MIT.
