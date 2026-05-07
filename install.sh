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
// Same Windows Desktop App workaround as hooks block (issue #22700)
const candidates = [
  "C:/Program Files/Git/bin/bash.exe",
  "C:/Program Files/Git/usr/bin/bash.exe",
  "C:/Program Files (x86)/Git/bin/bash.exe",
  "/opt/homebrew/bin/bash",
  "/usr/local/bin/bash",
  "/usr/bin/bash",
  "/bin/bash",
];
let bashPath = "bash";
for (const c of candidates) {
  try { fs.accessSync(c, fs.constants.X_OK); bashPath = c; break; } catch {}
}
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
s.statusLine = { type: "command", command: `"${bashPath}" "${sp}"`, padding: 1 };
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log("  statusLine ->", sp);
NODE_EOF

# 7. ensure skillOverrides present (template ships them, but re-merge in case user has older settings)
echo "[7/9] ensuring skillOverrides..."
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

# 8. inject hooks block into ~/.claude/settings.json with absolute paths
# (Claude Desktop local-agent-mode reads hooks from rpm-installed plugins or user settings;
#  user settings path is the more reliable activation route across environments)
echo "[8/9] injecting hooks block into user settings..."
# Windows Desktop App workaround (claude-code issue #22700):
# Desktop's hook runner uses system PATH (Machine), which Git for Windows
# default install does NOT populate with bash.exe. Use FULL bash path.
SETTINGS_PATH="$CLAUDE_DIR/settings.json" REPO_DIR="$REPO_DIR_FWD" node - <<'NODE_EOF'
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const repo = process.env.REPO_DIR;
const s = JSON.parse(fs.readFileSync(p, 'utf8'));

// Detect bash full path (Windows Desktop App needs absolute path; macOS/Linux fine with `bash`)
const candidates = [
  "C:/Program Files/Git/bin/bash.exe",
  "C:/Program Files/Git/usr/bin/bash.exe",
  "C:/Program Files (x86)/Git/bin/bash.exe",
  "/opt/homebrew/bin/bash",
  "/usr/local/bin/bash",
  "/usr/bin/bash",
  "/bin/bash",
];
let bashPath = "bash";  // fallback
for (const c of candidates) {
  try { fs.accessSync(c, fs.constants.X_OK); bashPath = c; break; } catch {}
}
console.log("  bash:", bashPath);

const mkHook = (script) => ({
  type: "command",
  command: `"${bashPath}" "${repo}/plugins/harim-base/hooks/${script}"`,
  timeout: 5
});
s.hooks = s.hooks || {};
s.hooks.PreToolUse = [{ matcher: "Bash", hooks: [mkHook("strip-claude-attribution.sh")] }];
s.hooks.PostToolUse = [{ matcher: "", hooks: [mkHook("doom-loop-detect.sh")] }];
s.hooks.Stop = [{ matcher: "", hooks: [mkHook("pending-todos-gate.sh")] }];
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log("  hooks: PreToolUse + PostToolUse + Stop registered");
NODE_EOF

# 9. deploy skills/agents/commands/rules to user-level (Claude Desktop reads from ~/.claude/<type>/)
echo "[9/9] deploying skills/agents/commands/rules to user-level..."
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/rules"
cp -r "$REPO_DIR/plugins/harim-base/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
cp "$REPO_DIR/plugins/harim-base/agents/"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
cp "$REPO_DIR/plugins/harim-base/commands/"*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$REPO_DIR/plugins/harim-base/rules/"*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true
echo "  skills: $(ls "$CLAUDE_DIR/skills/" 2>/dev/null | wc -l) | agents: $(ls "$CLAUDE_DIR/agents/" 2>/dev/null | wc -l) | commands: $(ls "$CLAUDE_DIR/commands/" 2>/dev/null | wc -l) | rules: $(ls "$CLAUDE_DIR/rules/" 2>/dev/null | wc -l)"

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
