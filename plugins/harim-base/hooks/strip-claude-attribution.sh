#!/usr/bin/env bash
# strip-claude-attribution: PreToolUse hook
# Blocks Bash commands that would leak Claude/Anthropic identity in git history.
# Reason: privacy preference — commit/branch/PR history must look human-authored.

set -euo pipefail

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

# Pattern 3: PR creation via gh CLI with Claude attribution
if echo "$FLAT" | grep -qiE 'gh[[:space:]]+pr[[:space:]]+create.*(co-authored-by:[[:space:]]*claude|🤖[[:space:]]*generated|claude\.ai/code)'; then
  cat >&2 <<'EOF'
[strip-claude-attribution] BLOCKED: Claude attribution in gh pr create.

Remove the footer/co-author lines from --body before retrying.
EOF
  exit 2
fi

exit 0
