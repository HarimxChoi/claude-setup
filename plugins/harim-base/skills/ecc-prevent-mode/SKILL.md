---
name: ecc-prevent-mode
description: Apply ECC's prevent-mode operator discipline before execution. USE WHEN setting up a new project's CI gate, drafting governance docs, defining anti-pattern lists in skill bodies, configuring hook profiles (minimal/standard/strict), or designing an install manifest with schema validation. Implements ECC's design-time defense pattern (zero runtime recovery; everything blocked at commit-time, hook-time, and prompt-time).
---

# ECC prevent-mode discipline

Lifted from Affaan Mustafa's ECC (Everything Claude Code). ECC's defense lives entirely in design-time: 8 CI validators, hook profile gating, skill anti-pattern lists. Zero runtime recovery. Use this skill to apply the same operator discipline.

## When to invoke

- Setting up CI for a new project
- Drafting AGENTS.md / CLAUDE.md / governance docs
- Designing an install manifest (multi-profile, schema-validated)
- Reviewing a PR for prevent-mode violations
- Configuring `pre-commit`, `husky`, or hooks.json

## When NOT to invoke

- Runtime task with mostly-sound verifier — ForgeCode's recover-mode is better fit (see `forgecode-recover-mode`).
- Research / unsound-verifier tasks — prevent-mode CI gates fire on noise.

## The four prevent-mode surfaces

### 1. Commit-time CI validators (8-validator gate)

Each is a deterministic check that BLOCKS commit if it fails:
1. **Schema validator** — ajv against install manifest schema
2. **Coverage validator** — ≥80% line coverage on changed code
3. **Lint** — eslint / ruff / clippy (project-appropriate)
4. **Type check** — tsc / mypy / cargo check
5. **Test runner** — full unit suite must pass
6. **Anti-pattern grep** — no TODO without ticket ref, no `console.log`, no `print(`
7. **Secret scan** — no leaked tokens / keys
8. **License header check** — every source file has SPDX header

Implementation: `husky` pre-commit + GitHub Actions workflow.

### 2. Hook profile gating (`HOOK_PROFILE` ∈ {minimal, standard, strict})

Tier hooks by environment:
- `minimal`: format + secret scan only (fast iteration, exploratory work)
- `standard`: + lint + types + unit tests (default for trusted operators)
- `strict`: + coverage gate + anti-pattern grep + license check (PR / release)

Switch via env var. Hooks read `${HOOK_PROFILE:-standard}` and skip when profile downgrades.

### 3. Anti-pattern lists in skill / CLAUDE.md bodies

Plain-English DON'T patterns embedded in skill instructions. Examples:
- "Do not modify `requirements-c4.txt` numpy pin without checking ngboost issue 362."
- "Do not aggregate KPI across brackets without per-bracket breakdown."
- "Do not push model artifacts to git (use S3)."

These are LLM-prompt-time guidance — not enforced, but reduces violations.

### 4. Install manifest schema (3-level taxonomy)

Stratify components: `profiles` (5) → `modules` (~18) → `components` (~310). Validate with ajv schema. Prevents missing/duplicate/malformed components by construction (OR.9 theorem activation).

```json
{
  "profile": "developer",
  "modules": ["lint", "test", "typing"],
  "components": [
    {"id": "eslint", "version": ">=8", "module": "lint"},
    ...
  ]
}
```

## Procedure

1. Identify the task class (developer / security / research / core / full).
2. Pick a hook profile (minimal / standard / strict) based on phase.
3. Draft the 8 validators as concrete commands.
4. List 3-7 anti-patterns specific to this codebase in CLAUDE.md.
5. (Optional) Define install manifest if cross-machine reproducibility matters.

## Reference

- Source: `research/foundations/01-ecc-dssp.md` (580 lines deep audit)
- Condensed: `paper/sections/08-ecc-condensed.md`
- Original repo: `affaan-m/everything-claude-code`

## Anti-patterns of this skill

- Forcing strict profile on exploratory work — kills iteration speed.
- 8 CI validators on a 50-line repo — overhead exceeds value.
- Anti-pattern lists that contradict CLAUDE.md elsewhere — Claude picks arbitrarily.
- Skipping the manifest schema when you don't have multi-machine reproducibility need (it's overhead).

## Companion skill

For runtime recovery (the layer ECC explicitly omits), use `forgecode-recover-mode`.
