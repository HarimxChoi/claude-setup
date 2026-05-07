#!/usr/bin/env bash
# doom-loop-detect: PostToolUse hook
# Implements ForgeCode's doom-loop pattern detection (DSSP §1.6 RL.3.6 partial / OL.5 heuristic).
# Logs action signatures to JSONL, scans last N=5 for repetition patterns.
#
# Output discipline (#34713 mitigation):
#   - exit 0 + ZERO stdout/stderr when no loop detected (no false-error label)
#   - exit 0 + stdout JSON ONLY when actually injecting reflection

set -euo pipefail
INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then exit 0; fi

# Decide log location: project-relative if available, else ~/.claude/harim-base/
LOG_DIR="${CLAUDE_PROJECT_DIR:-$HOME/.claude/harim-base}/.harim"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
LOG_FILE="$LOG_DIR/action-log.jsonl"

# Extract record from JSON: tool, sig (tool|argSlice), session id
REC=$(printf '%s' "$INPUT" | node -e '
  try {
    const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const name = d.tool_name || "?";
    const input = JSON.stringify(d.tool_input || {});
    const argSlice = input.slice(0, 32);
    const sig = `${name}|${argSlice}`;
    const ses = d.session_id || process.env.CLAUDE_SESSION_ID || "";
    const rec = { ts: Math.floor(Date.now()/1000), tool: name, sig, ses };
    process.stdout.write(JSON.stringify(rec));
  } catch (e) { process.stdout.write(""); }
')

[[ -z "$REC" ]] && exit 0

echo "$REC" >> "$LOG_FILE"
SIG=$(printf '%s' "$REC" | node -e 'try{process.stdout.write(JSON.parse(require("fs").readFileSync(0,"utf8")).sig||"")}catch{}')

# Keep only last 100 lines (rolling window)
if [[ $(wc -l < "$LOG_FILE" 2>/dev/null || echo 0) -gt 100 ]]; then
  tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Scan last 6 entries for [A,A,A] (3-rep) or [A,B,C][A,B,C] (cycle)
PATTERN_DETECTED=$(node -e '
  const fs = require("fs");
  const path = process.argv[1];
  try {
    const lines = fs.readFileSync(path, "utf8").trim().split("\n").slice(-6);
    if (lines.length < 3) { process.exit(0); }
    const sigs = lines.map(l => { try { return JSON.parse(l).sig; } catch { return null; } }).filter(Boolean);
    const n = sigs.length;
    // 3-rep: last 3 identical
    if (n >= 3 && sigs[n-1] === sigs[n-2] && sigs[n-2] === sigs[n-3]) {
      process.stdout.write("REP3");
      process.exit(0);
    }
    // 2-rep cycle: last 6 are [A,B,C,A,B,C]
    if (n >= 6 && sigs[n-1] === sigs[n-4] && sigs[n-2] === sigs[n-5] && sigs[n-3] === sigs[n-6]) {
      process.stdout.write("CYCLE2");
      process.exit(0);
    }
  } catch (e) {}
' "$LOG_FILE")

if [[ -z "$PATTERN_DETECTED" ]]; then
  exit 0  # no loop, silent (no #34713 label)
fi

# Inject reflection via additionalContext (PostToolUse JSON output)
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[doom-loop-detect] Pattern detected: $PATTERN_DETECTED. Last actions are repeating without progress. Step back, reconsider the approach. Identify the assumption that, if false, would change the path. Try a fundamentally different angle before the next tool call."
  }
}
EOF
exit 0
