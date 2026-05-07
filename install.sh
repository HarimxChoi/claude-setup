#!/usr/bin/env bash
# claude-setup installer
# 1. checks prereqs
# 2. backs up + installs user-level templates to ~/.claude/
# 3. makes hook scripts executable
# 4. seeds .env from .env.example

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "==> claude-setup installer"
echo "    repo:   $REPO_DIR"
echo "    target: $CLAUDE_DIR"
echo

# 1. prereqs
echo "[1/4] checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "  ERROR: node not found. Install Node 18+." >&2; exit 1; }
command -v git  >/dev/null 2>&1 || { echo "  ERROR: git not found." >&2; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "  WARN: jq not found. Anonymity hook will fail-open. Install: https://stedolan.github.io/jq/" >&2; }
NODE_MAJOR=$(node -p "parseInt(process.versions.node.split('.')[0])")
if [[ "$NODE_MAJOR" -lt 18 ]]; then
  echo "  ERROR: Node $NODE_MAJOR detected; need >= 18." >&2
  exit 1
fi
echo "  ok"

# 2. user-level templates
echo "[2/4] installing user-level templates..."
mkdir -p "$CLAUDE_DIR"

if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
  backup="$CLAUDE_DIR/settings.json.bak.$(date +%s)"
  echo "  existing settings.json -> $backup"
  cp "$CLAUDE_DIR/settings.json" "$backup"
fi
cp "$REPO_DIR/templates/user/settings.json" "$CLAUDE_DIR/settings.json"

if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  backup="$CLAUDE_DIR/CLAUDE.md.bak.$(date +%s)"
  echo "  existing CLAUDE.md -> $backup"
  cp "$CLAUDE_DIR/CLAUDE.md" "$backup"
fi
cp "$REPO_DIR/templates/user/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  ok"

# 3. hook executable
echo "[3/4] making hook scripts executable..."
chmod +x "$REPO_DIR/plugins/harim-base/hooks/"*.sh 2>/dev/null || true
echo "  ok"

# 4. .env
echo "[4/4] seeding .env..."
if [[ ! -f "$REPO_DIR/.env" ]]; then
  cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
  echo "  created .env from .env.example"
  echo "  EDIT $REPO_DIR/.env to fill GITHUB_PAT and other secrets"
else
  echo "  .env exists, leaving alone"
fi

cat <<EOF

==> done. next steps inside Claude Code:

  cd $REPO_DIR && claude

  /plugin marketplace add $REPO_DIR
  /plugin install harim-base@harim-marketplace
  /plugin list           # verify harim-base appears

verify the anonymity hook:
  ask Claude to run: git commit -m "test 🤖 Generated"
  hook should block with explanation.

per-device prereqs (new machine):
  npm install -g @anthropic-ai/claude-code
  brew install jq        # macOS
  sudo apt install jq    # Debian/Ubuntu
  # Windows Git Bash: jq via choco / scoop

EOF
