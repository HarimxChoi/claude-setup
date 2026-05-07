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
# jq is optional — anonymity hook uses node first, jq second.
command -v jq   >/dev/null 2>&1 || echo "  note: jq not found (optional; hook uses node)."
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
echo "[4/5] seeding .env..."
if [[ ! -f "$REPO_DIR/.env" ]]; then
  cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
  echo "  created .env from .env.example"
  echo "  EDIT $REPO_DIR/.env to fill GITHUB_PAT and other secrets"
else
  echo "  .env exists, leaving alone"
fi

# 5. register marketplace + enable plugin in user settings (idempotent JSON merge via node)
echo "[5/6] registering harim-marketplace + enabling harim-base..."
REPO_DIR_FWD="$(echo "$REPO_DIR" | sed 's|\\|/|g')"
SETTINGS_PATH="$CLAUDE_DIR/settings.json" REPO_DIR="$REPO_DIR_FWD" node - <<'NODE_EOF'
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const repo = process.env.REPO_DIR;
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
s.pluginMarketplaces = s.pluginMarketplaces || [];
if (!s.pluginMarketplaces.includes(repo)) s.pluginMarketplaces.push(repo);
s.enabledPlugins = s.enabledPlugins || [];
const ref = "harim-base@harim-marketplace";
if (!s.enabledPlugins.includes(ref)) s.enabledPlugins.push(ref);
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log("  registered marketplace:", repo);
console.log("  enabled plugin:", ref);
NODE_EOF

# 6. configure statusLine pointing to the harim-base script
echo "[6/7] configuring statusLine..."
SCRIPT_PATH="$REPO_DIR_FWD/plugins/harim-base/scripts/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json" STATUSLINE_PATH="$SCRIPT_PATH" node - <<'NODE_EOF'
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const sp = process.env.STATUSLINE_PATH;
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
s.statusLine = { type: "command", command: `bash "${sp}"`, padding: 1 };
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log("  statusLine ->", sp);
NODE_EOF

# 7. ensure skillOverrides present (template ships them, but re-merge in case user has older settings)
echo "[7/7] ensuring skillOverrides..."
SETTINGS_PATH="$CLAUDE_DIR/settings.json" node - <<'NODE_EOF'
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
const defaults = {
  "monogram-commit": "user-invocable-only",
  "forgecode-recover-mode": "user-invocable-only",
  "live-swe-reflection": "name-only",
  "ecc-prevent-mode": "name-only"
};
s.skillOverrides = Object.assign({}, defaults, s.skillOverrides || {});
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log("  skillOverrides:", Object.keys(s.skillOverrides).length, "entries");
NODE_EOF

cat <<EOF

==> done. next steps:

  start (or restart) a Claude Code session — marketplace + plugin auto-register.

  inside Claude Code, verify:
    /plugin list           # should show harim-base@harim-marketplace

verify the anonymity hook:
  ask Claude to run: git commit -m "test 🤖 Generated"
  hook should block with explanation.

per-device prereqs (new machine):
  npm install -g @anthropic-ai/claude-code
  brew install jq        # macOS
  sudo apt install jq    # Debian/Ubuntu
  # Windows Git Bash: jq via choco / scoop

EOF
