# mini — a 4-layer token economy stack for AI coding agents

> Not one tool. Four layers that each fix a different kind of waste —
> because rules alone don't work. A real session audit proved it: told not
> to read whole files, the model read them anyway. Told not to screenshot
> every fix, it screenshotted anyway. Rules are suggestions. This is
> infrastructure plus the two rules that infrastructure can't replace.

## The 4 layers

```
Headroom  →  compresses everything the model READS   (proxy, automatic)
Caveman   →  compresses everything the model WRITES   (skill, automatic)
mini-mcp  →  changes WHAT gets read in the first place (5 tools)
rules     →  governs judgment: when to ask, when to verify (2 new rules)
```

Headroom and Caveman are structural — they work whether or not the model
"remembers" anything. mini-mcp's tools change what's available to call.
The rules cover the two decisions no proxy can make for the model: **should
I ask or should I explore**, and **does this fix need a browser check or
not**. Both came directly from real, measured waste in production sessions.

## Install everything in one command

```bash
git clone https://github.com/shivtchandra/minicursor
cd minicursor
bash install-full-stack.sh
```

Installs Headroom, Caveman, mini-mcp, and appends the rules to
`~/.claude/CLAUDE.md`. Safe to re-run. Requires Python 3.10+ and the
Claude Code CLI already installed.

### Or install layers individually

```bash
# Headroom — input compression
pip install headroom-ai && headroom mcp install

# Caveman — output compression
claude skills add github:JuliusBrussee/caveman

# mini-mcp — the tools
python3.11 -m pip install git+https://github.com/shivtchandra/minicursor
claude mcp add mini --scope user -- python3.11 -m mini_mcp

# rules — paste FRUGAL-RULES.md's rule block into ~/.claude/CLAUDE.md
```

## What each layer actually does

| Layer | Fixes | Measured effect | Built by |
|---|---|---|---|
| Headroom | Input bloat — full files, logs, history | ~15-20% on coding agents, 60-95% on JSON | [chopratejas/headroom](https://github.com/chopratejas/headroom) |
| Caveman | Output verbosity — filler, hedging | ~65% output tokens (small % of most bills) | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) |
| mini-mcp | What gets read at all | repo_map avoids whole-file reads entirely | this repo |
| Rules | Judgment: ask vs explore, verify vs trust | qualitative — see below | this repo |

## The 5 mini-mcp tools

| Tool | What it does |
|---|---|
| `repo_map` | Files + signatures, 8K cap — orient without reading |
| `read_range` | Lines start..end, numbered — tight windows only |
| `apply_patch` | Exact old→new, uniqueness-checked — zero wasted output tokens |
| `park_state` | Append progress to .mini/notes-<task>.md |
| `resume_state` | Read parked state at session start |

## The 12 rules (full text in FRUGAL-RULES.md)

```
1-2   Orient cheap, patch don't rewrite
3-3b  Gate don't narrate — and match the check to the stakes
4-5   Big outputs to files, park state across sessions
6-7   Stay on task, one pass per feedback round
8-9   Images are expensive, errors go to files
10    No prose summaries — the diff is the report
11    ASK, DON'T EXPLORE — one question beats five tool calls
      when the ambiguity is about intent, not location
12    DON'T DEFAULT TO THE BROWSER — screenshot only when pixels
      are the actual deliverable, not for every trivial fix
```

Rules 11 and 12 exist because of specific, named failures observed in real
sessions: burning tool calls to guess what the user meant instead of
asking, and reflexively screenshotting one-line CSS fixes. Full rationale
in [FRUGAL-RULES.md](FRUGAL-RULES.md).

## Connect to your app

### Claude Code
```bash
claude mcp add mini --scope user -- python3.11 -m mini_mcp
```

### Cursor
`~/.cursor/mcp.json`:
```json
{ "mcpServers": { "mini": { "command": "python3.11", "args": ["-m", "mini_mcp"] } } }
```

### Codex
`~/.codex/config.toml`:
```toml
[mcp_servers.mini]
command = "python3.11"
args = ["-m", "mini_mcp"]
```

## Verify it's working

Inside Claude Code:
```
what token economy rules are you following in this session?
use repo_map to orient yourself in this project
```

## How this was built

I built a full multi-agent orchestration system first — cost-routed model
tiers, task boards, watchdog agents, cross-provider dispatch. It was
elaborate. I ran it on a real task, burned my entire 5-hour Claude window,
shipped nothing. One strong model with no orchestration shipped the same
task the next day.

The rules-only version of mini came next — and a real session audit showed
even a well-written rules file gets ignored under context pressure. So
v0.3.0 stops relying on the model remembering anything: Headroom and
Caveman enforce structurally, mini-mcp's tools change what's callable, and
the two judgment rules that remain (11, 12) exist only because they came
from real, named waste — not because I think rules work reliably. They
don't, alone. This is what does.

## Honest limitations

- Headroom and Caveman are third-party projects — not built or maintained
  here. Both are open source, MIT-licensed, install independently.
- mini-mcp's `repo_map` is regex-based signature extraction, not a symbol
  graph — good for orienting, not a replacement for an LSP.
- Rules 11-12 are still text a model reads, same limitation as rules 1-10.
  The difference is they're judgment calls with no structural fix possible
  — Headroom can't decide when to ask a question for you.

## Changelog

**v0.3.0** — Added the 4-layer stack (Headroom + Caveman integration),
rules 11 (decision speed) and 12 (verification proportionality) from real
usage feedback, one-command full-stack installer.

**v0.2.0** — Added rules 8-10 from session audit (images, error dumps,
prose summaries).

**v0.1.0** — Initial release. 5 tools, 7 rules.

## License

MIT — take it, use it, improve it.

Built by [Shiva](https://github.com/shivtchandra) — indie dev from Tamil
Nadu, shipping mobile, web, and SaaS.
