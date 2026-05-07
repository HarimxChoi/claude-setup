#!/usr/bin/env bash
# pending-todos-gate: Stop hook
# Implements ForgeCode's pending-todos completion gate (DSSP §1.15 OS.11 partial).
# Uses stop_hook_active flag to prevent infinite loop (claudefa.st pattern).
#
# Output: exit 0 + JSON {decision:block,reason:...} if pending todos exist.

set -euo pipefail
INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then exit 0; fi

# Parse stop_hook_active and transcript_path
PARSED=$(printf '%s' "$INPUT" | node -e '
  try {
    const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
    process.stdout.write([
      d.stop_hook_active === true ? "1" : "0",
      d.transcript_path || ""
    ].join("\t"));
  } catch (e) { process.stdout.write("0\t"); }
')

ACTIVE=$(echo "$PARSED" | cut -f1)
TRANSCRIPT=$(echo "$PARSED" | cut -f2)

# stop_hook_active=true means we already blocked once. Let it through (prevent infinite loop).
if [[ "$ACTIVE" == "1" ]]; then exit 0; fi

# No transcript = nothing to scan
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

# Scan transcript for latest TodoWrite tool_use; check pending count
PENDING_JSON=$(node -e '
  const fs = require("fs");
  const path = process.argv[1];
  let lastTodos = null;
  try {
    const lines = fs.readFileSync(path, "utf8").split("\n").filter(l => l.trim());
    for (const line of lines) {
      try {
        const obj = JSON.parse(line);
        const content = obj?.message?.content;
        if (Array.isArray(content)) {
          for (const c of content) {
            if (c.type === "tool_use" && c.name === "TodoWrite") {
              lastTodos = c.input?.todos || [];
            }
          }
        }
      } catch {}
    }
  } catch {}
  if (!lastTodos) { process.exit(0); }
  const pending = lastTodos.filter(t => t.status !== "completed");
  if (pending.length === 0) { process.exit(0); }
  const list = pending.map(t => `[${t.status}] ${(t.content || "").slice(0,80)}`).join("; ");
  process.stdout.write(JSON.stringify({
    decision: "block",
    reason: `Pending todos detected (${pending.length}): ${list}. Complete or explicitly remove these before stopping.`
  }));
' "$TRANSCRIPT")

if [[ -n "$PENDING_JSON" ]]; then
  echo "$PENDING_JSON"
fi
exit 0
