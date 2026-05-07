---
description: Generate Monogram-style commit message for current staged changes
---

Apply the `monogram-commit` skill to the user's staged changes.

## Procedure
1. Run `git diff --staged --stat` to see what's being committed
2. If diff is non-trivial, run `git diff --staged` for content
3. Propose a commit message in format `<category>: <short-noun-phrase>`

## Categories
- `setup` — scaffolding, install, config
- `feat` — new capability for end-user
- `fix` — bug or correctness fix
- `refactor` — internal restructuring, no behavior change
- `research` — research notes, audits, paper sections
- `experiment` — exploratory branch, may revert
- `docs` — README, comments, design docs
- `chore` — tooling, deps, CI

## Discipline
- ≤72 chars total
- All lowercase except proper nouns
- No past-tense verb starts ("Added", "Refactored")
- No `Co-Authored-By:`, `🤖`, `claude.ai/code` (anonymity hook will block)

## After proposing
Show the user the message, ask to confirm or refine, then execute `git commit -m "..."`.
