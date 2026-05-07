# claude-setup installer (Windows native PowerShell)
# Mirror of install.sh for users who prefer PS over Git Bash.

$ErrorActionPreference = "Stop"

$RepoDir = ($PSScriptRoot -replace '\\', '/')
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$ClaudeDirFwd = ($ClaudeDir -replace '\\', '/')

Write-Host "==> claude-setup installer (PowerShell)"
Write-Host "    repo:   $RepoDir"
Write-Host "    target: $ClaudeDirFwd"
Write-Host ""

# 1. prereqs
Write-Host "[1/9] checking prerequisites..."
foreach ($cmd in @("node", "git")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "  ERROR: $cmd not found."
        exit 1
    }
}
$nodeMajor = [int](node -p "process.versions.node.split('.')[0]")
if ($nodeMajor -lt 18) {
    Write-Error "  ERROR: Node $nodeMajor; need >= 18."
    exit 1
}
Write-Host "  ok"

# 2. user-level templates
Write-Host "[2/9] installing user-level templates..."
if (-not (Test-Path $ClaudeDir)) { New-Item -Path $ClaudeDir -ItemType Directory | Out-Null }
$ts = [int][double]::Parse((Get-Date -UFormat %s))
foreach ($f in @("settings.json", "CLAUDE.md")) {
    $target = Join-Path $ClaudeDir $f
    if (Test-Path $target) {
        $backup = "$target.bak.$ts"
        Write-Host "  existing $f -> $backup"
        Copy-Item $target $backup
    }
    Copy-Item (Join-Path $RepoDir "templates/user/$f") $target
}
Write-Host "  ok"

# 3. hook executable (no-op on Windows; bash invocation handles it)
Write-Host "[3/9] (chmod no-op on Windows; bash invocation handles execution)"
Write-Host "  ok"

# 4. .env
Write-Host "[4/9] seeding .env..."
$envPath = Join-Path $RepoDir ".env"
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $RepoDir ".env.example") $envPath
    Write-Host "  created .env from .env.example"
    Write-Host "  EDIT $envPath to fill GITHUB_PAT and other secrets"
} else {
    Write-Host "  .env exists, leaving alone"
}

# 5. register marketplace + enable plugin
Write-Host "[5/9] registering harim-marketplace + enabling harim-base..."
$settingsPath = Join-Path $ClaudeDir "settings.json"
$env:SETTINGS_PATH = $settingsPath
$env:REPO_DIR_FWD = $RepoDir
node -e "const fs=require('fs');const p=process.env.SETTINGS_PATH;const repo=process.env.REPO_DIR_FWD;const s=JSON.parse(fs.readFileSync(p,'utf8'));const ref='harim-base@harim-marketplace';if(Array.isArray(s.enabledPlugins)){const o={};for(const e of s.enabledPlugins)o[e]=true;s.enabledPlugins=o;}s.enabledPlugins=s.enabledPlugins||{};s.enabledPlugins[ref]=true;s.extraKnownMarketplaces=s.extraKnownMarketplaces||{};s.extraKnownMarketplaces['harim-marketplace']={source:{source:'directory',path:repo}};delete s.pluginMarketplaces;fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');console.log('  registered:',repo);console.log('  enabled:',ref);"

# 6. configure statusLine (use FULL bash path — Desktop App uses system PATH)
Write-Host "[6/9] configuring statusLine..."
$scriptPath = "$RepoDir/plugins/harim-base/scripts/statusline.sh"
$env:SETTINGS_PATH = $settingsPath
$env:STATUSLINE_PATH = $scriptPath
node -e @"
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const sp = process.env.STATUSLINE_PATH;
const candidates = ['C:/Program Files/Git/bin/bash.exe','C:/Program Files/Git/usr/bin/bash.exe','C:/Program Files (x86)/Git/bin/bash.exe'];
let bashPath = 'bash';
for (const c of candidates) { try { fs.accessSync(c, fs.constants.X_OK); bashPath = c; break; } catch {} }
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
s.statusLine = { type: 'command', command: '"' + bashPath + '" "' + sp + '"', padding: 1 };
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log('  bash:', bashPath);
console.log('  statusLine ->', sp);
"@

# 7. ensure skillOverrides
Write-Host "[7/9] ensuring skillOverrides..."
$env:SETTINGS_PATH = $settingsPath
node -e "const fs=require('fs');const p=process.env.SETTINGS_PATH;const s=JSON.parse(fs.readFileSync(p,'utf8'));const d={'monogram-commit':'user-invocable-only','forgecode-recover-mode':'user-invocable-only','live-swe-reflection':'name-only','ecc-prevent-mode':'name-only'};s.skillOverrides=Object.assign({},d,s.skillOverrides||{});fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');console.log('  skillOverrides:',Object.keys(s.skillOverrides).length,'entries');"

# 8. inject hooks block with FULL bash path (claude-code issue #22700 — Windows
#    Desktop App uses system PATH which lacks Git\bin; `bash` resolution fails silently)
Write-Host "[8/9] injecting hooks block into user settings..."
$env:SETTINGS_PATH = $settingsPath
$env:REPO_DIR_FWD = $RepoDir
node -e @"
const fs = require('fs');
const p = process.env.SETTINGS_PATH;
const repo = process.env.REPO_DIR_FWD;
const candidates = ['C:/Program Files/Git/bin/bash.exe','C:/Program Files/Git/usr/bin/bash.exe','C:/Program Files (x86)/Git/bin/bash.exe'];
let bashPath = 'bash';
for (const c of candidates) { try { fs.accessSync(c, fs.constants.X_OK); bashPath = c; break; } catch {} }
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
const mkHook = (script) => ({ type: 'command', command: '"' + bashPath + '" "' + repo + '/plugins/harim-base/hooks/' + script + '"', timeout: 5 });
s.hooks = s.hooks || {};
s.hooks.PreToolUse = [{ matcher: 'Bash', hooks: [mkHook('strip-claude-attribution.sh')] }];
s.hooks.PostToolUse = [{ matcher: '', hooks: [mkHook('doom-loop-detect.sh')] }];
s.hooks.Stop = [{ matcher: '', hooks: [mkHook('pending-todos-gate.sh')] }];
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log('  bash:', bashPath);
console.log('  hooks: PreToolUse + PostToolUse + Stop registered');
"@

# 9. deploy skills/agents/commands/rules
Write-Host "[9/9] deploying skills/agents/commands/rules to user-level..."
foreach ($d in @("skills","agents","commands","rules")) {
    $dst = Join-Path $ClaudeDir $d
    if (-not (Test-Path $dst)) { New-Item -Path $dst -ItemType Directory | Out-Null }
}
$pluginRoot = Join-Path $RepoDir "plugins/harim-base"
if (Test-Path "$pluginRoot/skills") { Copy-Item -Recurse -Force "$pluginRoot/skills/*" (Join-Path $ClaudeDir "skills") }
if (Test-Path "$pluginRoot/agents") { Copy-Item -Force "$pluginRoot/agents/*.md" (Join-Path $ClaudeDir "agents") }
if (Test-Path "$pluginRoot/commands") { Copy-Item -Force "$pluginRoot/commands/*.md" (Join-Path $ClaudeDir "commands") }
if (Test-Path "$pluginRoot/rules") { Copy-Item -Force "$pluginRoot/rules/*.md" (Join-Path $ClaudeDir "rules") }
Write-Host "  deployed"

Write-Host ""
Write-Host "==> done. restart Claude Code/Desktop; hooks + statusLine + plugin auto-activate."
Write-Host "    Windows note: install.ps1 detects Git bash full path (issue #22700 mitigation)."
