#!/usr/bin/env bash
# eval-skills.sh — run wshobson/agents PluginEval against this harness's user-level skills
# DSSP UQ.3 lift (see docs/04-wshobson-dssp.md §11.1)
#
# usage:
#   scripts/eval-skills.sh                      # standard depth, all 6 skills
#   scripts/eval-skills.sh deep                 # deep depth (50 MC runs each)
#   scripts/eval-skills.sh standard dssp-audit  # one skill only
#
# prereqs (one-time):
#   1. clone wshobson/agents to $HOME/wshobson-agents (or set PLUGIN_EVAL_DIR)
#      git clone https://github.com/wshobson/agents.git $HOME/wshobson-agents
#   2. cd $HOME/wshobson-agents/plugins/plugin-eval
#      uv sync --extra llm   # or --extra api if you prefer ANTHROPIC_API_KEY
#   3. authenticate (Claude Code Max plan or ANTHROPIC_API_KEY env)
#   4. SDK ≥0.1.50 patch: ResultMessage.content removed; we patch judge.py +
#      monte_carlo.py to use ResultMessage.result instead. See
#      docs/04-wshobson-dssp.md §11.5 for diff.

set -euo pipefail

DEPTH="${1:-standard}"   # quick | standard | deep | thorough
ONLY="${2:-}"            # optional single skill name
PLUGIN_EVAL_DIR="${PLUGIN_EVAL_DIR:-$HOME/wshobson-agents/plugins/plugin-eval}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"
OUT_DIR="${OUT_DIR:-$HOME/.claude/harim-base/eval-reports}"
AUTH="${AUTH:-max}"      # max | api-key
export PYTHONIOENCODING=utf-8   # Windows cp949 fix

if [[ ! -d "$PLUGIN_EVAL_DIR" ]]; then
  echo "ERROR: PluginEval not found at $PLUGIN_EVAL_DIR" >&2
  echo "       set PLUGIN_EVAL_DIR or:" >&2
  echo "       git clone https://github.com/wshobson/agents.git \$HOME/wshobson-agents" >&2
  echo "       cd \$HOME/wshobson-agents/plugins/plugin-eval && uv sync --extra llm" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
SUMMARY="$OUT_DIR/summary-$TS.md"

echo "# harim-base skill eval — $TS" > "$SUMMARY"
echo "" >> "$SUMMARY"
echo "depth: $DEPTH | auth: $AUTH | plugin-eval: $PLUGIN_EVAL_DIR" >> "$SUMMARY"
echo "" >> "$SUMMARY"
echo "| skill | composite | badge | confidence |" >> "$SUMMARY"
echo "|---|---|---|---|" >> "$SUMMARY"

skills=()
if [[ -n "$ONLY" ]]; then
  skills=("$ONLY")
else
  for d in "$SKILLS_DIR"/*/; do
    name="$(basename "$d")"
    [[ -f "$d/SKILL.md" ]] || continue
    skills+=("$name")
  done
fi

cd "$PLUGIN_EVAL_DIR"
for skill in "${skills[@]}"; do
  path="$SKILLS_DIR/$skill"
  echo ""
  echo "==> evaluating $skill (depth=$DEPTH)..."
  report="$OUT_DIR/$skill-$TS.md"
  uv run plugin-eval score "$path" \
      --depth "$DEPTH" \
      --output markdown \
      --auth "$AUTH" \
      > "$report" || { echo "  FAILED — see $report" >&2; continue; }

  # extract one-line summary from the markdown report's score table
  composite=$(grep -m1 -oE '\| Score \| \*\*[0-9.]+/100\*\* \|' "$report" | grep -oE '[0-9.]+/100' | head -1 || echo "?")
  conf=$(grep -m1 -oE '\| Confidence \| [A-Za-z+]+ \|' "$report" | awk -F'\\| ' '{print $3}' | tr -d '|' | xargs || echo "?")
  badge=$(grep -m1 -oE '\| Badge \| [A-Za-z_ ]+\|' "$report" | awk -F'\\| ' '{print $3}' | tr -d '|' | xargs || echo "?")
  echo "| $skill | $composite | $badge | $conf |" >> "$SUMMARY"
done

echo ""
echo "==> done. summary: $SUMMARY"
