# mini — a 5-layer token-economy stack for AI coding agents

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white) ![MCP](https://img.shields.io/badge/MCP-server-black) ![License](https://img.shields.io/badge/License-MIT-green)

> Tooling + rules to remove waste in agent coding sessions: input bloat, noisy output, unnecessary reads, reflex verification, and rules that quietly go unenforced.

mini is a compact stack that combines structural proxies, compression, a small set of MCP tools, a hard enforcement gate, and a short, pragmatic ruleset that together reduce cost and noise when models interact with codebases.

## Quick summary

- Purpose: prevent agents from needlessly reading whole files, producing verbose prose, taking expensive verification steps when not required, or silently skipping the rules that say not to do those things.
- Key idea: rules alone are fragile — a real session audit found a model stating it was following the rules while its actual tool calls weren't, because the only thing checking was a substring search that any tool's name showing up anywhere in context would satisfy. Add structural layers (input/output compression), small tools that change *what* the model can read and write, and a gate that actually blocks the tool call when it doesn't comply.
- Built by: Shiva (shivtchandra) — indie dev.

## What's in the stack

1. Headroom — input compression (reduce what the model reads)
2. Caveman — output compression (reduce filler/hedging in model outputs)
3. mini-mcp — five small MCP tools that control what the model can request
4. Gate — a PreToolUse hook (`hooks/mini-gate.py`) that blocks Read until
   `repo_map` has genuinely been called this session, and blocks Edit until
   `apply_patch` has genuinely failed twice in a row on that exact file —
   checked against real tool-call records in the session transcript, not a
   text search a tool's name can satisfy just by being mentioned
5. Rules — 12 short rules (FRUGAL-RULES.md) that capture judgment decisions the model can't make automatically

## mini-mcp tools

- `repo_map` — a compact map of files + signatures used to orient without reading whole files (8K cap)
- `read_range` — read a numbered line range: `start..end` (tight windows only)
- `apply_patch` — provide exact old→new patches (uniqueness-checked) to avoid long rewrite outputs
- `park_state` — append progress/notes to `.mini/notes-<task>.md`
- `resume_state` — read parked state at session start

These tools intentionally avoid large context reads and encourage precise, minimal changes.

## Install (all-in-one)

Requirements: Python 3.10+ (3.11 recommended), Claude Code CLI (or other MCP-capable client) already installed.

Clone and run the installer to set up the full stack (Headroom, Caveman, mini-mcp, the gate, and rules):

```bash
git clone https://github.com/shivtchandra/minicursor
cd minicursor
bash install-full-stack.sh
```

The installer will:
- Install Headroom and Caveman integrations (third-party projects)
- Install mini-mcp and register the `mini` MCP server for your client
- Append the FRUGAL rules block into `~/.claude/CLAUDE.md` (safe to re-run)
- Copy `hooks/mini-gate.py` to `~/.claude/hooks/` and wire the PreToolUse
  registration into `~/.claude/settings.json`

### Layer-by-layer install (manual)

```bash
# Headroom — input compression
pip install headroom-ai && headroom mcp install

# Caveman — output compression (via Claude skill)
claude skills add github:JuliusBrussee/caveman

# mini-mcp — the MCP tools served from this package
python3.11 -m pip install git+https://github.com/shivtchandra/minicursor
claude mcp add mini --scope user -- python3.11 -m mini_mcp

# Gate — copy hooks/mini-gate.py to ~/.claude/hooks/, then merge into
# ~/.claude/settings.json (nested under "hooks", not the settings root):
#   { "hooks": { "PreToolUse": [ { "matcher": "Read|Edit|Agent",
#     "hooks": [ { "type": "command",
#       "command": "python3 ~/.claude/hooks/mini-gate.py" } ] } ] } }

# Rules — paste FRUGAL-RULES.md into ~/.claude/CLAUDE.md (or see file for details)
```

## Quick usage examples

Inside Claude Code or any MCP-capable client, try:

```
what token economy rules are you following in this session?
use repo_map to orient yourself in this project
```

With the gate installed, try to confirm it's actually blocking (not just stating rules): ask it to edit a file with the native Edit tool without trying `apply_patch` first — it should be refused.

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
- The gate exists because even "structural enforcement" turned out to have a gap: its first version checked for a tool's name anywhere in transcript text, which system-reminders satisfy just by listing available tools — regardless of whether the model ever called them. The gate now parses real `tool_use`/`tool_result` records instead, so compliance is verifiable, not self-reported.
- Two judgment rules (ASK vs. EXPLORE, VERIFY vs. TRUST) remain because they are decisions a proxy cannot reliably make for the model.

Read the full rationale in FRUGAL-RULES.md.

## Limitations

- Headroom and Caveman are third-party projects (MIT). They are not maintained in this repo.
- `repo_map` is signature/regex-based, not a full symbol graph or LSP replacement — it's for orientation.
- The rules are textual and therefore subject to the same limits as any text-based guard.
- The gate only sees what's in the transcript it's handed. It's a real technical check, not a theoretical one — but it can't verify anything a tool call didn't actually log.

## Changelog (high-level)

- v0.3.1 — Fixed a real bypass in the gate: it checked for a tool's name anywhere in transcript text, satisfied by the tool merely being listed as available. Now parses genuine tool_use/tool_result blocks, and correctly tracks "apply_patch failed twice in a row on this exact file" instead of "ever succeeded/failed anywhere." The gate is now tracked in this repo and installed by `install-full-stack.sh` instead of existing only as an untracked file.
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
