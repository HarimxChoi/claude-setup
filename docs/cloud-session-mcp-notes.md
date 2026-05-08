# Cloud session MCP compatibility — notes

**날짜**: 2026-05-07
**상태**: 미실행 메모. v0.7+ 검토용.
**소스**: https://code.claude.com/docs/ko/claude-code-on-the-web

## 핵심 발견

Claude Code의 **클라우드 세션** (claude.ai/code, Anthropic VM에서 실행) vs **로컬 세션** (사용자 PC에서 실행) 사이에 config가 transfer 되는 범위가 다름. user-level config는 안 가고, project-level (저장소에 commit된) config만 감.

## Transfer 매트릭스 (공식 문서 verbatim)

| 항목 | 클라우드 transfer | 이유 |
|---|---|---|
| 저장소 `CLAUDE.md` | ✅ | 복제본의 일부 |
| 저장소 `.claude/settings.json` (hooks 포함) | ✅ | 복제본의 일부 |
| 저장소 `.mcp.json` | ✅ | 복제본의 일부 |
| 저장소 `.claude/rules/` | ✅ | 복제본의 일부 |
| 저장소 `.claude/skills/`, `.claude/agents/`, `.claude/commands/` | ✅ | 복제본의 일부 |
| `.claude/settings.json`의 `enabledPlugins` | ✅ | 마켓플레이스에서 자동 설치 |
| 사용자 `~/.claude/CLAUDE.md` | ❌ | 머신 한정 |
| `~/.claude/settings.json` 의 user-level 설정 | ❌ | 머신 한정 |
| **`claude mcp add`로 등록한 MCP (default scope=local)** | **❌** | `~/.claude.json`에 씀 |
| **`claude mcp add --scope project ...`** | **✅** | `<repo>/.mcp.json`에 씀 |
| API 토큰 / 자격증명 | ❌ | 비밀 저장소 부재 |
| 대화형 인증 (AWS SSO 등) | ❌ | 브라우저 로그인 필요 |

## `claude mcp add` 명령어

| scope | 저장 위치 | 클라우드 transfer |
|---|---|---|
| `local` (default) | `~/.claude.json` | ❌ |
| `user` | `~/.claude.json` (전 프로젝트) | ❌ |
| `project` | `<repo>/.mcp.json` | ✅ |

→ 클라우드 가져가려면 `--scope project` 필수.

## 클라우드 VM 환경 (사전 설치)

- Node 20/21/22 + npm/yarn/pnpm/bun
- Python 3.x (pip/poetry/uv/black/mypy/pytest/ruff)
- Ruby/PHP/Java/Go/Rust/C/C++
- Docker (docker compose 포함)
- PostgreSQL 16 + Redis 7.0
- git, jq, yq, ripgrep, tmux, vim, nano
- **chromedriver** (있음)
- **Chromium 브라우저 자체는 없음** ← Playwright 기반 MCP에 영향
- 4 vCPU / 16 GB RAM / 30 GB disk

## stdio MCP 클라우드 호환 패턴

### 최소 동작 (npx-based MCP)

```json
// <repo>/.mcp.json
{
  "mcpServers": {
    "google-surf": {
      "command": "npx",
      "args": ["-y", "google-surf-mcp"],
      "env": {
        "SURF_HEADLESS": "true",
        "SURF_PROFILE_ROOT": "${HOME}/.google-surf-mcp",
        "SURF_LOCALE": "en-US"
      }
    }
  }
}
```

- `npx -y` flag = 미설치 시 npm registry에서 자동 fetch
- cloud Trusted network에 npm registry 포함 → 첫 호출 시 자동 다운로드
- 별도 `npm install` 단계 불필요

### Playwright 기반 MCP 추가 단계 (Chromium 설치)

```json
// <repo>/.claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|resume",
      "hooks": [{
        "type": "command",
        "command": "[ \"$CLAUDE_CODE_REMOTE\" = \"true\" ] && npx -y playwright install chromium 2>/dev/null || true"
      }]
    }]
  }
}
```

- `CLAUDE_CODE_REMOTE` env = 클라우드에서만 `true` → 로컬은 skip (이미 Chrome 있음)
- `|| true` = 설치 실패 시에도 세션 시작 허용

### Network access — 외부 도메인 접근

- 클라우드 환경 기본 = **Trusted** (npm/PyPI/GitHub 등 패키지 레지스트리만)
- google.com 등 검색 대상은 **Trusted에 없음**
- 환경 UI에서 **Custom** 선택 + 도메인 추가:
  - `google.com`
  - `*.google.com`
- claude.ai/code → 환경 선택 → Edit → Network access → Custom

## 클라우드 한정 caveat (Solo 사용자 관점)

1. **Profile ephemerality**: cloud VM은 매 세션 fresh. 쿠키/로그인 상태 매번 초기화 → CAPTCHA / 봇 차단 빈도↑.
   - 완화: setup script로 환경 캐시에 프로필 사전 빌드 (7일 캐시 유효)
2. **Secrets**: 비밀 저장소 없음. 환경 변수로 등록해야 하는데 환경 편집 권한 있는 모두에게 visible.
3. **Setup script vs SessionStart hook**:
   - Setup script = 클라우드 환경 attach (저장소 transfer ❌), 환경 캐시 ✓
   - SessionStart hook = 저장소 attach (transfer ✓), 매 세션 실행 (캐시 ✗)
   - 클라우드만 + 캐시 효과 → setup script
   - 로컬+클라우드 통일 + 매번 보장 → SessionStart hook
4. **`$CLAUDE_ENV_FILE`**: SessionStart hook이 export 쓰면 후속 Bash가 source. 환경 변수 분기 처리에 사용.

## harim-base 통합 가능성 (v0.7+ 후보)

현재 harim-base는 **user-level deploy** (`~/.claude/skills/`, `~/.claude/agents/`, ...) → 클라우드 세션 transfer 안 됨.

클라우드 호환하려면:
- 옵션 A: project-level dual-deploy 추가 (`<repo>/.claude/skills/` 등도 함께 배포)
- 옵션 B: harim-base를 **plugin marketplace** 형태로 배포 + `enabledPlugins`로 project settings에서 enable → 클라우드 세션 시작 시 자동 설치
- 옵션 C: 현 user-level 유지, 클라우드 세션 미지원으로 명시

옵션 B가 정공법 (plugin 인프라 활용). 단 v0.6.x에서 hook 기능 자체가 Desktop에서 dead 상태 → 기반이 흔들림. Hook 인프라 안정화 후 검토.

## 미실행 항목 (사용자 결정 후 진행)

- [ ] `<repo>/.mcp.json` 작성 + commit (어느 repo?)
- [ ] `<repo>/.claude/settings.json` SessionStart hook 추가
- [ ] 클라우드 환경 UI에서 Network access Custom + Google 도메인
- [ ] (선택) Setup script로 chromium pre-install + 캐싱
- [ ] (선택) v0.7에서 harim-base plugin marketplace 형태 검토

## 즉시 실행 가능한 한 줄 (참고용)

```bash
# 어느 project root에서든
claude mcp add --scope project google-surf -- npx -y google-surf-mcp
```

→ 그 repo의 `.mcp.json`에 자동 추가됨. 이후 commit + push.

## Sources

- https://code.claude.com/docs/ko/claude-code-on-the-web (클라우드 환경)
- https://code.claude.com/docs/ko/mcp (MCP scope, transport)
- https://code.claude.com/docs/ko/remote-control (대안 — 로컬 PC를 클라우드 UI에서 컨트롤)
- https://code.claude.com/docs/ko/hooks#sessionstart (SessionStart hook 스펙)
