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

## Recommended skill triggers
- Commit / PR → `monogram-commit`
- Stuck debug loop → `live-swe-reflection`
- Runtime error handling → `forgecode-recover-mode`
- Release CI gate → `ecc-prevent-mode`
