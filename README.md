# claude-setup

Portable Claude Code setup. Drop on any device, run install, get a consistent agent environment.

[**한국어 README →**](./README.ko.md)

## Layout

```
.
├── .claude-plugin/marketplace.json     # plugin marketplace manifest
├── plugins/
│   └── harim-base/
│       ├── .claude-plugin/plugin.json
│       └── hooks/                      # PreToolUse anonymity hook
├── templates/user/
│   ├── settings.json                   # user-level Claude Code settings
│   └── CLAUDE.md                       # user-level priors
├── .env.example
└── install.sh
```

## What it does

1. **Anonymity hook** — `harim-base/hooks/strip-claude-attribution.sh` blocks `git commit / branch / push / gh pr create` commands that leak Claude/Anthropic attribution. Forces Monogram-style commit messages (short, noun-centric).
2. **Permissions baseline** — sensible deny list (`rm -rf`, `curl`, `sudo`, `pip install`, `npm publish`, `.env` reads), narrow allow list (Read/Glob/Grep, `python`, `pytest`, git read-only).
3. **Working-style priors** — short responses, no fluff, smallest-diff edits, self-verification with Bash, KR-EN bilingual.

## Install

Prereqs: Node 18+, git, jq, [Claude Code CLI](https://docs.claude.com/code).

```bash
git clone https://github.com/HarimxChoi/claude-setup ~/claude-setup
cd ~/claude-setup
bash install.sh
```

Then inside Claude Code:

```
/plugin marketplace add ~/claude-setup
/plugin install harim-base@harim-marketplace
/plugin list
```

## Verify the anonymity hook

Ask Claude to run a commit message containing `Co-Authored-By: Claude` or `🤖 Generated`. The hook returns exit 2 with a rewrite suggestion.

## Layered architecture

| Layer | Mechanism | This repo |
|---|---|---|
| 0 — settings.json | permissions, model, env | ✓ |
| 1 — CLAUDE.md | priors | ✓ user-level |
| 2 — Skills + Subagents | capabilities | next phase |
| 3 — MCP | external tools | next phase |
| 4 — Hooks | deterministic enforcement | ✓ anonymity |
| 5 — Memory | auto-memory + project memory | (auto) |

## License

MIT.
