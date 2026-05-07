---
name: monogram-commit
description: Generate short noun-centric commit messages, branch names, and PR titles in Monogram style. USE WHEN drafting a git commit message, naming a branch, drafting a pull request title, or summarizing a change. Format is "category: noun-slug" (e.g., "fix: kpi total_bidders", "setup: marketplace auto-register"). Pairs with the harim-base anonymity hook.
---

# Monogram-style commit messages

Short, noun-centric, attribution-free. Pairs with the `strip-claude-attribution.sh` hook (which BLOCKS attribution leakage; this skill PREVENTS the leakage from happening).

## When to invoke

- Drafting any `git commit -m "..."`
- Naming a branch (`git checkout -b ...`)
- Drafting a PR title or `gh pr create --title ...`
- Writing a CHANGELOG entry

## Format

```
<category>: <short-noun-phrase>
```

- 1 line, ≤72 chars total.
- All lowercase except proper nouns.
- No trailing period.
- No past-tense verb starts ("Added", "Fixed", "Refactored" → bad).
- No "I/we" pronouns.

## Categories

| category | when |
|---|---|
| `setup` | scaffolding, install, config |
| `feat` | new capability for end-user |
| `fix` | bug or correctness fix |
| `refactor` | internal restructuring, no behavior change |
| `research` | research notes, audits, paper sections |
| `experiment` | exploratory branch, may revert |
| `docs` | README, comments, design docs |
| `chore` | tooling, deps, CI |
| `revert` | revert of prior commit |

## Examples

✓ GOOD:
- `setup: scaffold base`
- `fix: kpi total_bidders KeyError`
- `research: 14-agent corpus update`
- `feat: anti-bot grid sweep`
- `refactor: etl module split`
- `experiment: anchor cascade v2`
- `docs: install ko translation`

✗ BAD:
- `Added new feature for ...` (past-tense verb start)
- `Update README` (vague "Update"; what aspect?)
- `🤖 Initial commit` (emoji + attribution)
- `Co-Authored-By: Claude <noreply@anthropic.com>` in trailer
- `feat/claude-code/x` in branch name
- `Initial commit by Claude` in author/body

## Branch naming

```
<category>/<noun-slug>
```

- `feat/kpi-bracket`
- `fix/total-bidders`
- `exp/anchor-cascade-v2`
- `research/dssp-six-step`

NEVER `claude-code/...`, `anthropic/...`, `claude/...`.

## PR title and body

- Title = first commit message (or summary in same format).
- Body: bullet list of changes. No "🤖 Generated with Claude Code". No `Co-Authored-By:` trailer.

## Anti-patterns

- Multi-paragraph commit bodies that re-explain the diff. Keep to 1-3 bullets max.
- "WIP" commits in main history (squash before merge).
- Emoji prefixes (`🐛 fix:`, `✨ feat:`). The anonymity hook blocks emoji-bot patterns; avoid setting precedent.
