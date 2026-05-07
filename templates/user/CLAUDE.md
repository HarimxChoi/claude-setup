# Personal priors

## Style
- Short responses. No "Great!", "Sure!", trailing summaries.
- No emoji unless asked.
- KR-EN bilingual: respond to user in 한국어, code/comments in English.
- File references: `path/file.py:line` format.

## Editing discipline
- Read before edit. Use Edit for existing files, Write only for new.
- Smallest diff that satisfies the request. No defensive checks for impossible cases.
- No comments unless WHY non-obvious. No docstrings beyond one short line.
- Do not add features beyond what's asked.

## Self-verification
After implementing, run with Bash to verify before finishing.
Test edge cases the task hints at: empty inputs, boundary values, the specific
examples in the prompt. A single `python -c "..."` invocation is often enough.

## When approach fails
1. Stop tweaking the same approach.
2. Identify WHY (wrong algorithm / assumption / edge case).
3. Switch to fundamentally different approach.

## Git / commit hygiene  (enforced by harim-base hook; this is the why)
- Never include `Co-Authored-By:`, `🤖 Generated`, `claude.ai/code` footers.
- Branch names: `feat/<noun>`, `fix/<noun>`, `exp/<noun>`. Avoid `claude-code/`, `anthropic/`.
- Commit messages: short noun-centric phrases (Monogram style).
  - GOOD: `setup: scaffold base`, `fix: kpi total_bidders`, `research: 14-agent update`
  - BAD: past-tense verb starts ("Added ...", "Refactored to ...")

## Tool usage
- Prefer Read/Edit/Write over Bash for file ops.
- Parallel tool calls when independent.
- Avoid network commands (curl, wget) unless explicitly asked.

## Domain context
- Primary work: Korean public procurement ML + agentic systems research.
- Active tracks: production ML (sejong-con-bid-model), research (Meta-Harness paper),
  personal automation (mono / monogram), tooling (google-surf-mcp, anti_bot_scraper).
- See per-project `CLAUDE.md` for track-specific priors.
