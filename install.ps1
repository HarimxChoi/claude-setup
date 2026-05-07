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
Write-Host "[1/6] checking prerequisites..."
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
Write-Host "[2/6] installing user-level templates..."
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
Write-Host "[3/6] (chmod no-op on Windows; bash invocation handles execution)"
Write-Host "  ok"

# 4. .env
Write-Host "[4/6] seeding .env..."
$envPath = Join-Path $RepoDir ".env"
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $RepoDir ".env.example") $envPath
    Write-Host "  created .env from .env.example"
    Write-Host "  EDIT $envPath to fill GITHUB_PAT and other secrets"
} else {
    Write-Host "  .env exists, leaving alone"
}

# 5. register marketplace + enable plugin
Write-Host "[5/6] registering harim-marketplace..."
$settingsPath = Join-Path $ClaudeDir "settings.json"
$env:SETTINGS_PATH = $settingsPath
$env:REPO_DIR_FWD = $RepoDir
node -e "const fs=require('fs');const p=process.env.SETTINGS_PATH;const repo=process.env.REPO_DIR_FWD;const s=JSON.parse(fs.readFileSync(p,'utf8'));s.pluginMarketplaces=s.pluginMarketplaces||[];if(!s.pluginMarketplaces.includes(repo))s.pluginMarketplaces.push(repo);s.enabledPlugins=s.enabledPlugins||[];const ref='harim-base@harim-marketplace';if(!s.enabledPlugins.includes(ref))s.enabledPlugins.push(ref);fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');console.log('  registered:',repo);console.log('  enabled:',ref);"

# 6. configure statusLine
Write-Host "[6/6] configuring statusLine..."
$scriptPath = "$RepoDir/plugins/harim-base/scripts/statusline.sh"
$env:SETTINGS_PATH = $settingsPath
$env:STATUSLINE_PATH = $scriptPath
node -e "const fs=require('fs');const p=process.env.SETTINGS_PATH;const sp=process.env.STATUSLINE_PATH;const s=JSON.parse(fs.readFileSync(p,'utf8'));s.statusLine={type:'command',command:`bash \""+sp+"\"`,padding:1};fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');console.log('  statusLine ->',sp);"

Write-Host ""
Write-Host "==> done. restart Claude Code; marketplace + plugin + statusLine auto-activate."
