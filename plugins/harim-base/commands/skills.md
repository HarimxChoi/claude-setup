---
description: List active skills with activation tier (T1-T4) and flag dead weight
---

Audit which skills are loaded and how each is wired to fire.

## Procedure

1. Read `~/.claude/settings.json` and extract the `skillOverrides` map.
2. List directories under `~/.claude/skills/`. For each, read `SKILL.md` frontmatter (`name`, `description`).
3. Cross-reference each skill against `skillOverrides`:
   - `user-invocable-only` → **T1 lifecycle** (fired by hook or explicit `/command`)
   - `name-only` → **T2 priors** (mentioned by name in `CLAUDE.md`; narrow auto)
   - `on` or absent → **T3 + T4** (slash command + auto-discovery)
4. Cross-reference against `~/.claude/commands/*.md` to confirm T3 commands map to a skill.
5. Cross-reference against `~/.claude/CLAUDE.md` to confirm T2 skills are actually mentioned.

## Output

A table:

```
| skill | tier | activation surface | description |
|---|---|---|---|
```

After the table, list:
- **DEAD WEIGHT**: skills present in `~/.claude/skills/` with no tier wiring AND no CLAUDE.md mention AND no slash command.
- **DRIFT**: skills with `name-only` override but no CLAUDE.md mention (T2 broken).
- **MISSING COMMAND**: skills with `on` override but no `~/.claude/commands/<name>.md` (T3 unrealized).

Keep the report under 40 lines. No prose beyond the table + 3 bullets.
