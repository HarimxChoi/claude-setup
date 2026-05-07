# Project priors — Tooling / MCP

## Track
Public-release npm/pip package (e.g., MCP server, scraper, CLI tool). Production-ready, MIT, semver.

## Stack assumptions
- TypeScript with strict mode + ES modules (no `require()`).
- Node 18+, vitest for tests.
- Playwright for browser automation.

## Commands
- `npm test`
- `npm run build`
- `npm run dev`
- `npm run bootstrap` (if applicable for first-run)

## Discipline
- Semver: breaking change = major bump. Document in CHANGELOG.md.
- README + README.ko.md parallel update for any user-facing change.
- Lifecycle hooks (`start`, `stop`) idempotent. SSRF guards on any URL input.
- CI green before publish. No `npm publish --force`.

## Forbidden
- `npm publish` without manual confirmation.
- Network calls in unit tests (mock or fixture only).
- Hardcoded credentials. Use env vars or config files.
- Releasing major version without 24h soak on `next` tag.

## Skill activation policy

| Skill | Tier | When |
|---|---|---|
| `monogram-commit` | T1 lifecycle | every `git commit` (auto via PreToolUse hook) |
| `forgecode-recover-mode` patterns | T1 lifecycle | tool errors, doom-loop, pending todos (auto) |
| `ecc-prevent-mode` | T2 priors | release CI gate design |
| `live-swe-reflection` | T2 priors | stuck debug loop |
| `dssp-audit` | T3 explicit | rare for tooling track; invoke via `/audit` if auditing other tools |

Track D primary triggers: `ecc-prevent-mode` (release CI) + `monogram-commit` (npm release commit hygiene).
