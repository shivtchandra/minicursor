# mini — a 4-layer token-economy stack for AI coding agents

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white) ![MCP](https://img.shields.io/badge/MCP-server-black) ![License](https://img.shields.io/badge/License-MIT-green)

> Tooling + rules to remove waste in agent coding sessions: input bloat, noisy output, unnecessary reads, and reflex verification.

mini is a compact stack that combines structural proxies, compression, a small set of MCP tools, and a short, pragmatic ruleset that together reduce cost and noise when models interact with codebases.

## Quick summary

- Purpose: prevent agents from needlessly reading whole files, producing verbose prose, or taking expensive verification steps when not required.
- Key idea: rules alone are fragile. Add structural layers (input/output compression) and small tools that change *what* the model can read and write.
- Built-by: Shiva (shivtchandra) — indie dev.

## What’s in the stack

1. Headroom — input compression (reduce what the model reads)
2. Caveman — output compression (reduce filler/hedging in model outputs)
3. mini-mcp — five small MCP tools that control what the model can request
4. Rules — 12 short rules (FRUGAL-RULES.md) that capture judgment decisions the model can't make automatically

## mini-mcp tools

- `repo_map` — a compact map of files + signatures used to orient without reading whole files (8K cap)
- `read_range` — read a numbered line range: `start..end` (tight windows only)
- `apply_patch` — provide exact old→new patches (uniqueness-checked) to avoid long rewrite outputs
- `park_state` — append progress/notes to `.mini/notes-<task>.md`
- `resume_state` — read parked state at session start

These tools intentionally avoid large context reads and encourage precise, minimal changes.

## Install (all-in-one)

Requirements: Python 3.10+ (3.11 recommended), Claude Code CLI (or other MCP-capable client) already installed.

Clone and run the installer to set up the full stack (Headroom, Caveman, mini-mcp, and rules):

```bash
git clone https://github.com/shivtchandra/minicursor
cd minicursor
bash install-full-stack.sh
```

The installer will:
- Install Headroom and Caveman integrations (third-party projects)
- Install mini-mcp and register the `mini` MCP server for your client
- Append the FRUGAL rules block into `~/.claude/CLAUDE.md` (safe to re-run)

### Layer-by-layer install (manual)

```bash
# Headroom — input compression
pip install headroom-ai && headroom mcp install

# Caveman — output compression (via Claude skill)
claude skills add github:JuliusBrussee/caveman

# mini-mcp — the MCP tools served from this package
python3.11 -m pip install git+https://github.com/shivtchandra/minicursor
claude mcp add mini --scope user -- python3.11 -m mini_mcp

# Rules — paste FRUGAL-RULES.md into ~/.claude/CLAUDE.md (or see file for details)
```

## Quick usage examples

Inside Claude Code or any MCP-capable client, try:

```
what token economy rules are you following in this session?
use repo_map to orient yourself in this project
```

Cursor example (`~/.cursor/mcp.json`):

```json
{ "mcpServers": { "mini": { "command": "python3.11", "args": ["-m", "mini_mcp"] } } }
```

Codex example (`~/.codex/config.toml`):

```toml
[mcp_servers.mini]
command = "python3.11"
args = ["-m", "mini_mcp"]
```

## Why this design

- Rules without structural constraints get ignored under heavy context pressure.
- Headroom and Caveman enforce structural limits outside the model's memory.
- mini-mcp changes the set of available actions so the model cannot accidentally read or write huge amounts of context.
- Two judgment rules (ASK vs. EXPLORE, VERIFY vs. TRUST) remain because they are decisions a proxy cannot reliably make for the model.

Read the full rationale in FRUGAL-RULES.md.

## Limitations

- Headroom and Caveman are third-party projects (MIT). They are not maintained in this repo.
- `repo_map` is signature/regex-based, not a full symbol graph or LSP replacement — it’s for orientation.
- The rules are textual and therefore subject to the same limits as any text-based guard.

## Changelog (high-level)

- v0.3.0 — Introduced the 4-layer stack (Headroom + Caveman), rules 11 and 12, one-command installer.
- v0.2.0 — Added rules 8–10 (images, error dumps, prose summaries).
- v0.1.0 — Initial release: 5 tools, 7 rules.

## Contributing

Contributions welcome. Open issues or PRs, or reach out via GitHub Discussions if you'd like to talk about design decisions.

## License

MIT — see LICENSE file.

---

Suggested hashtags & GitHub topics

Use these when sharing on social platforms (X/Twitter, LinkedIn) and as GitHub repo topics to improve discoverability.

- Hashtags for posts: #AI #AIAgents #AgentTools #LLM #LLMTools #DeveloperTools #Productivity #CodeAI #PromptEngineering #OpenSource #Python

- More focused tags (for audiences interested in cost or agent design): #TokenEconomy #MCP #Tooling #Efficiency #CostOptimization

- GitHub topics you can add on the repo: ai-agents, mcp, tools, prompt-engineering, python, open-source, code-assistant

Tips: use a short demo GIF showing the repo_map + apply_patch flow, and a 1–2 sentence TL;DR focusing on cost savings and fewer token-burned roundtrips.

---

Built by [Shiva](https://github.com/shivtchandra)
