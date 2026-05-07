#!/usr/bin/env bash
# statusline: prints model + git branch + context % for Claude Code status bar.
# stdin: Claude Code session JSON
# stdout: 1 line for the status bar

set -e

INPUT=$(cat)

# Use node (Claude Code prereq, always available).
if ! command -v node >/dev/null 2>&1; then
  printf "[claude]"
  exit 0
fi

PARSED=$(printf '%s' "$INPUT" | node -e '
  try {
    const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const model = (d.model && d.model.display_name) || "?";
    const used = (d.context_window && d.context_window.used_percentage) || 0;
    const cwd = (d.workspace && d.workspace.current_dir) || (d.cwd) || "";
    process.stdout.write([model, used, cwd].join("\t"));
  } catch (e) {
    process.stdout.write("?\t0\t");
  }
')

MODEL=$(echo "$PARSED" | cut -f1)
USED=$(echo "$PARSED" | cut -f2)
CWD=$(echo "$PARSED" | cut -f3)

# Git branch (silent if not in repo).
BRANCH=""
if [[ -n "$CWD" ]] && cd "$CWD" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  B=$(git symbolic-ref --short HEAD 2>/dev/null || echo detached)
  BRANCH=" \033[32m@${B}\033[0m"
fi

# Context bar (color by usage threshold).
COLOR="\033[32m"  # green
[[ "$USED" -gt 60 ]] && COLOR="\033[33m"   # yellow
[[ "$USED" -gt 85 ]] && COLOR="\033[31m"   # red

printf "\033[36m[%s]\033[0m${BRANCH} ${COLOR}ctx %s%%\033[0m" "$MODEL" "$USED"
