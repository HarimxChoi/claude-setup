# Monogram WebUI + Dashboard Port Plan

> Ruflo의 chat-UI MCP bridge 아키텍처(`ruflo/src/mcp-bridge/`,
> `ruflo/src/chat-ui/`, `ruflo/src/ruvocal/`, `v3/goal_ui/`)에서
> Monogram(Telegram → 5-stage LLM → markdown → mono repo)에
> 이식할 부분을 정리한 설계 문서.
>
> **목적**: Monogram에 대화형 WebUI + 라이브 대시보드를 추가해
> Telegram-only 입력의 단일 채널 한계를 해소하고, mono repo의
> 누적 상태(MEMORY.md, board.md, daily/, projects/, life/, log/,
> reports/, wiki/)를 가시화한다.
>
> **출처**:
> - DSSP audit `03-ruflo-dssp.md` §10-§14 (mcp-bridge / chat-UI 분석)
> - `ruvnet/ruflo/ruflo/src/mcp-bridge/index.js` (2,080 lines)
> - `ruvnet/ruflo/ruflo/rvf.manifest.json` (chat-ui-mcp v2.0)
> - `ruvnet/ruflo/v3/goal_ui/` (Vite + React + Tailwind + Supabase)
> - `HarimxChoi/monogram` README + `monogram-backup` 구조

---

## §1. 현재 Monogram 아키텍처 (요약)

```
                      ┌─────────────┐
                      │  Telegram   │  사용자 입력 채널 (현재 유일)
                      └──────┬──────┘
                             │
                             ▼
                  ┌────────────────────────┐
                  │  Monogram Pipeline     │
                  │  (5-stage LLM)         │
                  ├────────────────────────┤
                  │ 1. Orchestrator        │
                  │ 2. Classifier          │  category / type 결정
                  │ 3. Extractor           │  entity / metadata 추출
                  │ 4. Verifier            │  schema + dedup 검증
                  │ 5. Writer              │  markdown 렌더링
                  └────────┬───────────────┘
                           │
                           ▼
                  ┌────────────────────────┐
                  │  mono repo (private)   │
                  ├────────────────────────┤
                  │ MEMORY.md              │  영속 메모
                  │ board.md               │  현황판
                  │ config.md              │
                  │ daily/<date>/report.md │  morning brief 등
                  │ life/                  │  read-watch, places, …
                  │ log/                   │  pipeline trace
                  │ projects/              │
                  │ reports/               │
                  │ wiki/                  │  technical_link 등
                  └────────┬───────────────┘
                           │
                           ▼
                  ┌────────────────────────┐
                  │  Output surfaces       │
                  ├────────────────────────┤
                  │ git auto-commit        │  Monogram-style msg
                  │ Obsidian plugin        │  view in editor
                  │ encrypted GCS dashboard│  현재 dashboard
                  │ MCP server             │  Claude Code에서 query
                  └────────────────────────┘
```

**현재 limitations**:
1. **단일 입력 채널**: Telegram에 의존. PC에서 키보드로 빠르게 입력
   하려면 결국 Telegram desktop 거쳐야 함. 양손 코딩 중에 컨텍스트
   전환 비용.
2. **dashboard가 read-only + GCS-bound**: 보기만 가능. 응답하거나
   질문해서 mono의 누적 상태에 작용하는 path가 없음.
3. **mono repo state가 Claude Code/외부에서 사용하기에는 raw**:
   markdown 그대로라 시각화 layer 부재. board.md를 매번 grep해야 함.
4. **Pipeline이 외부 작용 못함**: Telegram drop을 markdown 만들 뿐
   추가 LLM call (e.g., "이 link 요약해줘")이 같은 세션 안에서
   조립 안 됨. 결과적으로 mono를 LLM과 함께 활용하려면 항상 Claude
   Code 세션을 따로 열어야 함.

---

## §2. Ruflo가 보유한 4가지 layer

`03-ruflo-dssp.md` §10-§14에서 정리된 Ruflo의 user-surface 4-layer:

### §2.1 mcp-bridge (`ruflo/src/mcp-bridge/index.js`, 2080 lines)

Express HTTP gateway. **12 tool groups** (core / intelligence /
agents / memory / devtools / security / browser / neural /
agentic-flow / claude-code / gemini / codex). **6 backends spawned**
via `npx -y <pkg> mcp start` (ruvector, ruflo, agentic-flow, claude,
gemini-mcp, @openai/codex). Routes:

- `POST /mcp/:groupName` — JSON-RPC for that group only
- `GET /mcp/:groupName` — SSE discovery
- `POST /mcp` — catch-all JSON-RPC
- `POST /chat/completions` — **OpenAI-compatible 프록시**
  → openai/gemini/openrouter (model 이름 prefix로 라우팅)
- `GET /models` — OpenAI-compatible model list
- `GET /mcp-servers` — `{name, url, tools, group}` 목록
- `GET /autopilot/detail/:token` — lazy-fetch tool result

핵심 패턴: `BACKEND_DEFS` 테이블에 외부 MCP server 등록 → bridge는
이들을 spawn하고 tool list를 prefix-filter로 group에 라우팅.
**chat-completions 부분이 가장 lift 가치 큼** — 동일 prompt 안에서
mcp tool call을 결정적으로 실행 (predictable parallel tool calling).

### §2.2 chat-ui (`ruflo/src/chat-ui/`)

HuggingFace `chat-ui-db` 기반. `Dockerfile` + `patch-mcp-url-safety.sh`
(HTTPS-only restriction을 sed로 patching, 사설 docker network에서
HTTP MCP URL 동작하게 함). 정적 자산 + branding.

`MCP_SERVERS` env var에 JSON literal로 group endpoint 목록을 주입:
```json
[
  {"url": "http://mcp-bridge:3001/mcp/agents", "name": "agents"},
  {"url": "http://mcp-bridge:3001/mcp/memory", "name": "memory"},
  ...
]
```

### §2.3 ruvocal (`ruflo/src/ruvocal/`)

별도 SvelteKit + Vite + Tailwind 앱. 자체 `package.json` /
`Dockerfile` / `cloudbuild.yaml` / mcp-bridge 서브모듈 / models 디렉토리.
voice-themed UI. **Same MCP bridge as backend** — chat-ui의 sister
product. 의미: bridge layer가 stable하면 frontend는 swap-able.

### §2.4 goal_ui (`v3/goal_ui/`)

Vite + React + Tailwind + Supabase. plain-English 목표를
GOAP A* planner가 decompose하는 **dashboard + control plane** UI.
agents 페이지(`/agents`)는 spawn된 모든 agent의 role, current step,
memory namespace, token budget, status를 **live**로 보여줌.

핵심 패턴: **Dashboard는 read 뿐만 아니라 control도** — 클릭으로
runaway worker kill, agent reassign, plan rerun.

---

## §3. Monogram + Ruflo 통합 설계

### §3.1 목표

Monogram에 **두 가지 surface 추가**:
1. **WebUI 채팅** — Telegram 대체/보완. PC에서 직접. 같은 5-stage
   pipeline에 feed. 추가로 mono의 누적 상태에 질문 가능 ("내가 이번
   주 적은 technical_link 다 보여줘", "오늘 morning brief 다시
   생성해줘", "이 코드 패턴 어떤 daily 에 있었지?").
2. **Live dashboard** — board.md 실시간 렌더링, daily/ 캘린더,
   life/ 카테고리 차트, log/ 최근 pipeline trace, technical_link
   클러스터링.

두 surface 모두 **하나의 backend = monogram-bridge**가 매개.
monogram-bridge는 ruflo의 `mcp-bridge/index.js`의 simplified clone.

### §3.2 아키텍처 (포팅 후)

```
                                          입력 채널 (3개)
                                          ───────────────
                          ┌──────────────┐
                          │   Telegram   │ ← 현재 유지
                          └──────┬───────┘
                                 │
                          ┌──────┴────────────┐
                          │   WebUI (chat)    │ ← 신규
                          │   localhost:3000  │
                          └──────┬────────────┘
                                 │
                          ┌──────┴────────────┐
                          │   Claude Code     │ ← MCP server
                          │   (MCP client)    │
                          └──────┬────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │   monogram-bridge            │  ← 핵심 신규 layer
                  │   (Express, ~600 lines)      │
                  ├──────────────────────────────┤
                  │ POST /chat/completions       │  OpenAI 호환 프록시
                  │      → Anthropic / OpenAI    │
                  │ POST /mcp/:group             │  JSON-RPC 라우팅
                  │ GET  /mcp/:group (SSE)       │
                  │ GET  /dashboard/board        │  realtime board.md
                  │ GET  /dashboard/recent       │  최근 commits
                  │ GET  /dashboard/clusters     │  link clustering
                  │ GET  /dashboard/health       │  pipeline status
                  │ POST /pipeline/inject        │  pipeline 직접 호출
                  └──────────┬───────────────────┘
                             │
                  ┌──────────┴────────────────┐
                  ▼                           ▼
             ┌─────────┐              ┌──────────────┐
             │ Pipeline│              │ MCP backend  │
             │ 5-stage │              │ (Monogram)   │
             └────┬────┘              └──────┬───────┘
                  │                          │
                  ▼                          ▼
             ┌─────────────────────────────────────┐
             │              mono repo               │
             │   (markdown 영속 store + git)         │
             └─────────────────────────────────────┘
                             ▲
                             │ render
                  ┌──────────┴───────────┐
                  │   WebUI Dashboard    │ ← 신규
                  │   localhost:3001     │
                  └──────────────────────┘
```

### §3.3 monogram-bridge의 endpoint 맵

| Endpoint | 모방한 ruflo endpoint | 용도 |
|---|---|---|
| `POST /chat/completions` | `mcp-bridge/index.js:923` | 사용자가 webUI에서 던진 프롬프트를 anthropic/openai/openrouter로 프록시. 답변 안에 monogram MCP tool call 결정적 병렬 실행 가능 |
| `POST /mcp/:group` | 동일 | JSON-RPC. group은 `pipeline / memory / dashboard / log` 등 monogram-specific |
| `GET /mcp/:group` (SSE) | 동일 | discovery |
| `GET /dashboard/board` | (신규) | board.md → JSON 렌더링. 캐시 5초 |
| `GET /dashboard/recent` | (신규) | mono repo의 최근 30개 commits + categorize |
| `GET /dashboard/clusters` | (신규) | wiki/ 기반 technical_link 클러스터링 (단순 tag-based 시작, 추후 embedding) |
| `GET /dashboard/health` | (신규) | pipeline 상태 + last drop ts + queue length |
| `POST /pipeline/inject` | (신규) | webUI 메시지를 5-stage pipeline에 주입. Telegram을 우회하는 path. response는 SSE로 stage별 progress |

### §3.4 MCP tool surface (monogram-specific)

ruflo는 314 tools. monogram은 ~30 tools면 충분. 4 그룹으로:

#### Group: `pipeline`
- `pipeline_inject(text, source_hint?)` — drop 처리 트리거
- `pipeline_status()` — 큐 / 마지막 처리 시간
- `pipeline_replay(drop_id)` — 특정 drop 재처리
- `pipeline_classify(text)` — Classifier만 단독 실행 (preview)

#### Group: `memory`
- `memory_search(query, namespace?, limit?)` — mono repo 전체 grep + ranking
- `memory_recent(category, limit?)` — recent technical_link / life / paper / etc.
- `memory_get(path)` — 특정 markdown 읽기
- `memory_store(category, content, slug?)` — 직접 추가 (Telegram 우회)
- `memory_link_cluster(min_similarity?)` — wiki cluster
- `memory_ingest_url(url, category?)` — URL fetch + summarize + 저장

#### Group: `dashboard`
- `dashboard_board()` — board.md 구조화 view
- `dashboard_brief_today()` — daily/<today>/report.md 가져오기
- `dashboard_brief_generate(date?, force?)` — morning brief 재생성
- `dashboard_calendar(month?)` — 한 달 daily 활동 매트릭스
- `dashboard_categories(window_days?)` — life/projects 카테고리 분포

#### Group: `log`
- `log_recent(N?)` — pipeline trace 최근 N
- `log_search(query, since?)` — log/ 검색
- `log_drop_detail(drop_id)` — drop 단위 디테일

총 **~22 tools**. ruflo의 ~314의 7% 수준이지만 monogram 사용자가
실제로 daily 에서 호출하는 surface는 모두 커버.

### §3.5 WebUI 두 surface

#### A. Chat WebUI (입력 + 대화)

**근거**: ruflo `chat-ui` (HF chat-ui patched).

**Monogram 적용**:
- ruflo가 한 것: HF chat-ui에 sed-patch로 HTTPS-only 우회 + custom
  branding + MCP_SERVERS env 주입.
- monogram에 그대로 lift: chat-ui Docker image 가져와 `MCP_SERVERS`
  에 monogram-bridge group endpoint 주입. Branding도 monogram 컬러.
- 차이점: monogram chat은 **사용자가 mono repo 안에서 대화** —
  prompt에 자동으로 "이 사용자의 mono repo 컨텍스트는 [board.md
  요약 + recent technical_link 5개]" 같은 system 부분이 prepend
  되어야 함. monogram-bridge가 chat/completions request 받을 때
  동적으로 inject.

#### B. Dashboard WebUI (live 상태)

**근거**: ruflo `goal_ui` (Vite + React + Tailwind + Supabase) +
ruvocal (SvelteKit) — 두 프론트엔드가 같은 bridge에 접속.

**Monogram 적용**:
- 가장 가벼운 옵션: **Vite + React + Tailwind + shadcn/ui** (ruflo
  goal_ui와 동일 stack, Supabase는 제거 — mono repo가 store).
- 4 페이지:
  1. **Home** — board.md 시각화 + 오늘 brief 카드 + 최근 5 drops
  2. **Calendar** — daily/ 활동 heatmap (GitHub contribution graph
     스타일)
  3. **Wiki** — technical_link 클러스터링 (force-directed graph)
  4. **Pipeline** — log/ 최근 trace + queue + replay 버튼

- 백엔드: monogram-bridge `/dashboard/*` endpoints만.
- 데이터 fetch: 5초 polling (간단) → 추후 SSE / websocket.

### §3.6 Pipeline 통합

webUI에서 들어온 메시지가 Telegram drop 같은 처리를 받으려면
`/pipeline/inject`가 5-stage를 호출해야 함:

```
[webUI POST /pipeline/inject]
       │
       ▼
[monogram-bridge]  →  source="webui" 태그 부착
       │
       ▼
[Pipeline.process()]  ← Telegram drop과 같은 entry point
       │
   Orchestrator → Classifier → Extractor → Verifier → Writer
       │
       ▼
[mono repo write]
       │
       ▼
[git auto-commit]  ← Monogram-style msg, source=webui 식별 가능
       │
       ▼
[bridge stream SSE]  → progress updates back to webUI
       │
       ▼
[webUI render]  → "Drop 처리됨: 카테고리 X, 저장 위치 Y"
```

핵심 결정: **Telegram drop과 webUI drop을 동일 5-stage로 라우트**.
source="telegram"|"webui"|"claude-code-mcp"|"manual"으로 구분만.
이러면 Monogram 본 정체성 (LLM pipeline = 단일 진실의 원천)을 유지.

---

## §4. 4-phase 이식 로드맵

### Phase 1 — monogram-bridge MVP (3 hours)
- Express server, port 3001
- `/chat/completions` 프록시 (anthropic만 시작; openai 추가 옵션)
- `/mcp/pipeline`, `/mcp/memory`, `/mcp/dashboard`, `/mcp/log`
- ruflo의 `mcp-bridge/index.js` 패턴 lift, 12-group → 4-group으로
  단순화
- 외부 backend spawn 없음 (monogram이 자체 backend)
- 단일 파일 ~600 lines

**결과**: Claude Code MCP client에서 `claude mcp add monogram --
node monogram-bridge/index.js`로 등록 가능.

### Phase 2 — chat WebUI (2 hours)
- HF chat-ui Docker image fetch
- `patch-mcp-url-safety.sh` lift (Ruflo 그대로)
- `dotenv-local.txt` 생성 — `MCP_SERVERS` JSON literal 주입
- monogram branding (color: 본인 monogram 인장 색상)
- `docker compose` 로컬 stack 정의

**결과**: `localhost:3000`에서 채팅 → `localhost:3001/chat/completions`
프록시 → mono repo state가 system prompt에 inject → Claude/Codex에
질문하며 동시에 monogram MCP tool 호출 가능.

### Phase 3 — dashboard WebUI (4 hours)
- Vite + React + Tailwind + shadcn/ui scaffold (ruflo goal_ui mimic)
- 4 page: Home / Calendar / Wiki / Pipeline
- `/dashboard/*` endpoint 호출, 5초 polling
- markdown render (react-markdown + remark-gfm)
- force-directed graph (d3-force) for wiki cluster
- heatmap (custom canvas) for calendar

**결과**: `localhost:3001` 별도 포트에서 dashboard. 본인 mono repo
누적 상태가 매일 한 화면에 보임.

### Phase 4 — pipeline integration + webhook (3 hours)
- `/pipeline/inject` SSE endpoint
- chat-ui custom plugin: 메시지가 "drop:" prefix로 시작하면
  자동으로 `/pipeline/inject` 호출 (단순 chat과 분리)
- pipeline replay UI (Pipeline 페이지)
- log/ trace를 dashboard에 stream

**결과**: Monogram의 모든 입력을 webUI 한 곳에서 — drop 추가도,
chat 질의도, dashboard 보기도, replay도 가능.

**총 견적: ~12 hours / 2-3일 part-time work**.

---

## §5. 위험 요소 + 완화

| 위험 | 영향 | 완화 |
|---|---|---|
| HF chat-ui patch가 미래 update와 conflict | 중 | 본인 fork 유지. ruflo도 `patch-mcp-url-safety.sh` sed pattern 으로 동일 위험 감수 중. |
| mono repo가 web에 노출 | 고 | localhost-only 운영. Cloud 배포 시 OAuth (ruflo 처럼). secret prefix grep (ruflo `package-rvf.sh` 패턴) 추가 가능 |
| pipeline replay가 race condition (Telegram drop과 동시) | 중 | source-tag 기반 drop_id로 dedup. `pipeline.process()`에 lock. |
| webUI dashboard 5초 polling이 mono repo 무거워짐 | 저 | 캐시 + git 변경 감지 (fs.watch). 추후 SSE로 push. |
| chat completions 비용 spike (사용자가 webUI에서 무한 chat) | 중 | budget circuit breaker — ruflo `cost-tracker` 0.16.1의 ADR-097 패턴 lift 가능 |
| 시작 cost (~12h)이 너무 큼 | 중 | Phase 1만 먼저 달성하면 Claude Code에서 MCP server로 monogram 활용 가능. WebUI는 나중. |

---

## §6. 구체 변경 파일 목록

monogram repo (HarimxChoi/monogram) 안에 추가/수정:

```
monogram/
├── src/
│   ├── (기존 5-stage pipeline 그대로)
│   └── bridge/                     # 신규
│       ├── index.js                # ~600 lines, ruflo mcp-bridge lift
│       ├── tools/
│       │   ├── pipeline.js         # pipeline_* tools
│       │   ├── memory.js           # memory_* tools
│       │   ├── dashboard.js        # dashboard_* tools
│       │   └── log.js              # log_* tools
│       ├── proxy.js                # /chat/completions 프록시
│       ├── system-prompt.js        # mono repo state → system prompt
│       └── package.json
├── webui/                          # 신규 (chat WebUI)
│   ├── chat-ui/                    # HF chat-ui fork (또는 submodule)
│   ├── Dockerfile
│   ├── patch-mcp-url-safety.sh     # ruflo lift
│   └── docker-compose.yml          # bridge + chat-ui + dashboard
├── dashboard/                      # 신규 (Vite React)
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   ├── src/
│   │   ├── App.tsx
│   │   ├── pages/
│   │   │   ├── Home.tsx            # board + brief + recent drops
│   │   │   ├── Calendar.tsx        # daily heatmap
│   │   │   ├── Wiki.tsx            # technical_link cluster
│   │   │   └── Pipeline.tsx        # log + queue + replay
│   │   └── components/
│   │       ├── BoardCard.tsx
│   │       ├── HeatMap.tsx
│   │       └── ClusterGraph.tsx
│   └── Dockerfile
├── docs/
│   └── ARCHITECTURE-WEBUI.md       # 본 문서의 monogram 안 사본
├── scripts/
│   ├── start-webui.sh              # docker compose up
│   └── stop-webui.sh
└── README.md                       # WebUI 섹션 추가
```

monogram-backup repo / mono repo는 변경 없음. 모든 신규 surface는
read-only 또는 monogram pipeline을 통한 write.

---

## §7. Ruflo 패턴 직접 lift (verbatim 가능)

| Ruflo 파일 | 수정 후 monogram 위치 | lift 정도 |
|---|---|---|
| `ruflo/src/mcp-bridge/index.js` (2080 lines) | `monogram/src/bridge/index.js` | 70% lift, 4-group으로 simplify, 6 backend spawn 제거 |
| `ruflo/src/mcp-bridge/mcp-stdio-kernel.js` (140 lines) | `monogram/src/bridge/stdio-kernel.js` | 100% lift (private docker network HMAC tunnel) |
| `ruflo/src/mcp-bridge/test-harness.js` (~470 lines) | `monogram/src/bridge/test-harness.js` | 80% lift, group 이름만 변경 |
| `ruflo/src/chat-ui/Dockerfile` | `monogram/webui/Dockerfile` | 90% lift |
| `ruflo/src/chat-ui/patch-mcp-url-safety.sh` | `monogram/webui/patch-mcp-url-safety.sh` | 100% lift |
| `ruflo/src/scripts/generate-config.js` (200 lines) | `monogram/scripts/generate-webui-config.js` | 60% lift, mongo→monogram brand 적용 |
| `ruflo/src/scripts/deploy.sh` (~115 lines) | `monogram/scripts/deploy-webui.sh` | 50% lift, GCP Cloud Run 부분만 |
| `v3/goal_ui/package.json` + Vite config | `monogram/dashboard/package.json` + Vite config | 40% lift (Supabase 제거) |
| `ruflo/src/scripts/package-rvf.sh` (~110 lines, secret prefix grep) | `monogram/scripts/package-release.sh` | 80% lift |
| `scripts/inventory-capabilities.mjs` (9.7KB) | `monogram/scripts/inventory-tools.mjs` | 30% lift, monogram의 22 tool만 inventory |

대략 **2,500 lines lift + 1,500 lines 신규 = 4,000 lines** 규모.

---

## §8. Claude-side 통합

monogram이 Claude Code MCP client에 등록되면:

```
~/.claude.json mcpServers:
  monogram:
    command: node
    args: ["/path/to/monogram/src/bridge/index.js"]
    env:
      MONO_REPO: "/path/to/mono"
      MONOGRAM_PORT: "3001"
```

또는 webUI 사용 시:
```
  monogram:
    command: npx
    args: ["-y", "monogram-cli", "mcp", "start"]
```

이 경우 Claude Code 세션에서:
- "최근 일주일 paper drop 보여줘" → `mcp__monogram__memory_recent`
  자동 호출
- "오늘 morning brief 만들어줘" →
  `mcp__monogram__dashboard_brief_generate(force=true)`
- "이 코드 패턴 mono에 어디 있었지?" →
  `mcp__monogram__memory_search`

세션 안에서 mono repo 누적이 일등시민으로 다뤄짐. **monogram의
LLM pipeline + Claude Code agent loop가 합쳐지는 첫 번째 surface**.

---

## §9. 다음 단계 결정 포인트

선택 1 — **Phase 1 only (3시간)**:
- bridge만 만들면 webUI 없이도 Claude Code에서 MCP로 monogram
  활용. dashboard / chat은 추후.

선택 2 — **Phase 1 + 2 (5시간)**:
- bridge + chat-ui. 입력 채널 다양화 + Claude Code 통합 둘 다 가능.
  dashboard는 추후.

선택 3 — **Phase 1 + 2 + 3 (9시간)**:
- bridge + chat-ui + dashboard. 본격 use.

선택 4 — **Phase 1-4 전체 (~12시간)**:
- pipeline replay + SSE까지. 매일 사용 production-grade.

---

## §10. Sources

- `03-ruflo-dssp.md` (sister DSSP audit, this repo)
- `ruvnet/ruflo` GitHub main branch, 2026-05-07 snapshot
- HarimxChoi/monogram README + structure
- HF chat-ui-db (`huggingface/chat-ui`)
- `v3/goal_ui/` Vite + React + Tailwind (ruflo)
- `paper/integration/02-sota-related-work.md` §3.6 (meta-router landscape)

본 plan은 monogram 작업 시작 전 reference document. 실행 시
업데이트 필요 (현재 status: spec-only).
