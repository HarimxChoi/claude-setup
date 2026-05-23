#!/usr/bin/env bash
# strip-claude-attribution: PreToolUse hook (Bash matcher)
# Two roles:
#   1. BLOCK Bash commands that leak Claude/Anthropic identity in git history.
#   2. INJECT monogram-commit skill guidance via additionalContext on `git commit`
#      (Tier 1 deterministic skill activation — bypasses LLM-router 50% ceiling).
#
# HOOK_PROFILE env var: "minimal" (skip all checks) | "standard" (default) | "strict"

set -euo pipefail

PROFILE="${HOOK_PROFILE:-standard}"
[[ "$PROFILE" == "minimal" ]] && exit 0   # fast-iteration escape hatch

INPUT=$(cat)

# Use node (always available — Claude Code requires Node 18+).
# Fall back to jq only if node missing.
if command -v node >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write((d.tool_input&&d.tool_input.command)||"")')
elif command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
  echo "[strip-claude-attribution] ERROR: neither node nor jq found, blocking to be safe" >&2
  exit 2
fi

if [[ -z "$CMD" ]]; then
  exit 0
fi

# Flatten newlines so multi-line commit messages match against single-line regex.
FLAT=$(printf '%s' "$CMD" | tr '\n\r' '  ')

# Pattern 1: commit messages with Claude attribution
if echo "$FLAT" | grep -qiE 'git[[:space:]]+commit.*(co-authored-by:[[:space:]]*claude|🤖[[:space:]]*generated|claude\.ai/code|noreply@anthropic\.com)'; then
  cat >&2 <<'EOF'
[strip-claude-attribution] BLOCKED: Claude attribution detected in commit message.

Forbidden patterns:
  - Co-Authored-By: Claude ...
  - 🤖 Generated with [Claude Code]
  - claude.ai/code
  - noreply@anthropic.com

Rewrite the message without these. Keep it short and noun-centric (Monogram style):
  GOOD: setup: scaffold base
        fix: kpi total_bidders
        research: 14-agent update
        feat: anti-bot grid sweep
  BAD:  Added authentication feature
        Refactored to use ESM
        🤖 Initial commit
EOF
  exit 2
fi

# Pattern 2: branch names with Claude/Anthropic
if echo "$FLAT" | grep -qiE 'git[[:space:]]+(branch|checkout[[:space:]]+-b|switch[[:space:]]+-c|push[[:space:]]+.*origin).*(claude-code|anthropic|/claude/|^claude/)'; then
  cat >&2 <<'EOF'
[strip-claude-attribution] BLOCKED: Claude/Anthropic substring in branch name.

Use neutral branch names:
  GOOD: feat/kpi-bracket-eval
        fix/total-bidders
        exp/anchor-cascade
  BAD:  claude-code/feat-x
        anthropic-feature
EOF
  exit 2
fi

# Pattern 2b: worktree add with Claude/Anthropic branch name
# `git worktree add <path> -b claude/foo` or `git worktree add -b claude/foo <path>`
if echo "$FLAT" | grep -qiE 'git[[:space:]]+worktree[[:space:]]+add.*(claude-code|anthropic|claude/)'; then
  cat >&2 <<'EOF'
[strip-claude-attribution] BLOCKED: Claude/Anthropic substring in worktree branch name.

Use neutral worktree branch names:
  GOOD: git worktree add ../wt-foo -b wt/foo
        git worktree add ../wt-foo -b exp/anchor
  BAD:  git worktree add ... -b claude/gifted-newton
        git worktree add ... -b claude-code/...
EOF
  exit 2
fi

# Pattern 3: PR creation via gh CLI with Claude attribution
if echo "$FLAT" | grep -qiE 'gh[[:space:]]+pr[[:space:]]+create.*(co-authored-by:[[:space:]]*claude|🤖[[:space:]]*generated|claude\.ai/code)'; then
  cat >&2 <<'EOF'
[strip-claude-attribution] BLOCKED: Claude attribution in gh pr create.

Remove the footer/co-author lines from --body before retrying.
EOF
  exit 2
fi

# Tier 1 deterministic skill activation:
# When user is about to run `git commit`, inject monogram-commit guidance.
# This compensates for LLM-router 50% activation ceiling on the most-used skill.
# Only emit JSON when actually injecting — silent exit otherwise (avoid #34713 false-error).
if echo "$FLAT" | grep -qiE 'git[[:space:]]+commit'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[monogram-commit auto-activate] Format: `<category>: <short-noun-phrase>`. Categories: setup/feat/fix/refactor/research/experiment/docs/chore. ≤72 chars, all lowercase, no past-tense verb starts, no Co-Authored-By/🤖/claude.ai/code. Examples: `fix: kpi total_bidders`, `setup: marketplace auto-register`, `research: 14-agent corpus update`."
  }
}
EOF
fi

exit 0
