# FRUGAL RULES — one doctrine, every app
# mini v0.3.1 — 5-layer stack: enforcement, not suggestion

Rules alone are passive text — a real session audit proved the model reads
whole files and screenshots trivially despite being told not to. v0.3.0
added infrastructure plus two behavioral rules on DECISION SPEED and
VERIFICATION PROPORTIONALITY. v0.3.1 fixed the enforcement layer itself: it
existed only as an untracked file with a bypassable check (a tool merely
being *listed* as available satisfied it, whether or not the model ever
called it) — now tracked in this repo, checked against real tool-call
evidence, and actually wired in by the installer.

## The 5 layers (this is the full stack now)

```
Headroom  → compresses everything the model READS (proxy-level, automatic)
Caveman   → compresses everything the model WRITES (skill-level, automatic)
mini-mcp  → changes WHAT gets read in the first place (repo_map, read_range,
            apply_patch, park_state, resume_state)
GATE      → PreToolUse hook (hooks/mini-gate.py) that technically BLOCKS
            Read until repo_map has genuinely been called, and Edit until
            apply_patch has genuinely failed twice in a row on that exact
            file — checked against real tool_use/tool_result blocks in the
            session transcript, not text the tool's own name happens to
            appear near
RULES     → governs BEHAVIOR: when to ask vs explore, when to verify vs trust
```

Headroom and Caveman are infrastructure — once installed they work whether
or not the model "remembers" a rule. mini-mcp tools change the shape of
what's available to call. The gate is the only layer that can actually stop
a tool call rather than hope the model self-polices — everything else here
depends, one way or another, on the model choosing to comply. The rules
below govern judgment calls no proxy can make for the model: when to stop
and ask, when a check is worth its cost.

---

## Install all 5 layers

Easiest: run `install-full-stack.sh` from this repo — it does all 5 steps
below, checks before acting on each, and is safe to re-run.

```bash
# 1. Headroom — input compression (proxy + MCP)
pip install headroom-ai
headroom mcp install

# 2. Caveman — output compression (skill)
claude skills add github:JuliusBrussee/caveman

# 3. mini-mcp — the tools
python3.11 -m pip install git+https://github.com/shivtchandra/minicursor
claude mcp add mini --scope user -- python3.11 -m mini_mcp

# 4. These rules — paste the block below into ~/.claude/CLAUDE.md

# 5. The enforcement gate — copy the hook and wire it into settings.json
mkdir -p ~/.claude/hooks
cp hooks/mini-gate.py ~/.claude/hooks/mini-gate.py
# then merge into ~/.claude/settings.json (nested under "hooks"):
#   { "hooks": { "PreToolUse": [ { "matcher": "Read|Edit|Agent",
#     "hooks": [ { "type": "command",
#       "command": "python3 ~/.claude/hooks/mini-gate.py" } ] } ] } }
```

---

## The rules (canonical text — paste into ~/.claude/CLAUDE.md)

```
TOKEN ECONOMY RULES (non-negotiable):

CONTEXT
1. ORIENT CHEAP — MANDATORY TOOL, NOT A SUGGESTION. On ANY task touching an
   existing codebase, call mcp__mini__repo_map FIRST — before Read, Grep,
   ls, find, or an Explore/general-purpose agent. This applies even to
   tasks that feel small or research-only. Only after repo_map fails to
   answer the question do you grep, and only after grep locates the line
   do you read a tight range with mcp__mini__read_range. Never read a
   whole file to orient. "It's just a quick lookup" is not an exception.

EDITING
2. PATCH, DON'T REWRITE — MANDATORY TOOL, NOT A SUGGESTION. Use
   mcp__mini__apply_patch for every edit to an existing file. Do not use
   the native Edit tool unless apply_patch fails twice in a row on the
   same file (ambiguous match, etc.) — then say so before falling back.
   Never re-emit an entire existing file. New files only when the file is
   actually new. If a rewrite touches >80% of a file, flag it first.

VERIFICATION — PROPORTIONAL, NOT REFLEXIVE
3. GATE, DON'T NARRATE. Verify with real checks (build, tests, lint, or
   javascript_tool JSON), then fix failures. No prose summary after — the
   diff and the passing check ARE the report.
3b. MATCH THE CHECK TO THE STAKES. A one-line CSS tweak, a typo fix, a
   variable rename does NOT need a browser screenshot — read the diff, trust
   it, move on. Reserve screenshots/browser checks for: new layout, visual
   art placement, anything where pixels are the actual deliverable, or a
   multi-file change you haven't verified any other way. Default to the
   cheapest check that actually proves the fix (JSON state read > screenshot;
   compiler/linter output > either). Escalate to a browser only when the
   cheap check can't answer the question.

OUTPUT
4. BIG OUTPUTS GO TO .mini/. Long logs, stack traces, and command output get
   written to .mini/out.txt or .mini/err.txt and grepped — never pasted into
   the conversation. Never repeat the same error dump twice.

STATE
5. PARK STATE. When a phase completes or limits approach, write decisions +
   current state + next step to .mini/notes-<task>.md. A fresh session reads
   that file and resumes — context re-derivation is the biggest silent cost.

SCOPE
6. STAY ON TASK. No refactors, no scope creep, no unrequested improvements.
   Note anything else worth fixing in one line at the end — don't fix it
   silently.

FEEDBACK
7. ONE PASS PER FEEDBACK. When given a numbered list of changes, apply ALL
   in one pass — never one message per item.

IMAGES
8. IMAGES ARE EXPENSIVE (~1,500 tokens each). Only when pixels ARE the
   deliverable. For logic/color/state, use javascript_tool JSON — ~200
   tokens and proves more. Never a redundant screenshot; never screenshot
   something already verified another way.

ERRORS
9. CONSOLE/ERROR DUMPS GO TO .mini/err.txt. Grep for the ONE relevant line.
   Never paste the same error twice. After fixing on disk, verify with
   node/python/tsc — not by re-reading the browser console.

REPORTS
10. NO PROSE SUMMARIES AFTER PHASES. The diff + passing check is the report.
    One line max: what changed, whether it passed.

DECISION SPEED  ← new
11. ASK, DON'T EXPLORE, WHEN BLOCKED ON INTENT. If a message is ambiguous
    about WHAT the user wants (which file, which direction, which of two
    valid approaches), ask ONE short question immediately — do not spend
    tool calls reading files, greping, or exploring the repo to guess the
    answer first. Exploration is for finding WHERE something is when the
    intent is already clear; it is never a substitute for asking when the
    intent itself is unclear. One clarifying question costs less than any
    exploratory read. If the ambiguity is resolvable from context already
    in the conversation, resolve it silently and proceed — don't ask what
    you can already infer. The failure mode this fixes: burning tokens
    trying to guess instead of a 5-second question.

VERIFICATION SPEED  ← new
12. DON'T DEFAULT TO THE BROWSER. After any fix, ask: "does a compiler,
    linter, type-check, or a one-line JSON read already answer whether this
    worked?" Use that first. Open a browser or take a screenshot only when
    NONE of those can confirm the fix — i.e., the check genuinely requires
    seeing rendered pixels. Small fixes (typos, single CSS property, one
    variable, one import) get zero verification theater — read the patch
    back, confirm it matches intent, done. This rule exists because
    reflexive browser-checking on every trivial change was measured as a
    real, repeated waste in production use.

DEFAULT, NOT OPT-IN  ← new
13. THESE RULES ARE ACTIVE ON EVERY SESSION AND EVERY TASK, NOT ONLY WHEN
    THE USER SAYS "use mini" / "use the rules" / names the stack. If mini's
    MCP tools (repo_map, read_range, apply_patch, park_state, resume_state)
    are present in this session's tool list, rules 1 and 2 are mandatory
    from message one — silently, without announcing it. A user having to
    ask for the frugal stack on a given turn is itself a rule violation on
    the PRIOR turn.
```

---

## Connect to your app

### Claude Code
```bash
claude mcp add mini --scope user -- python3.11 -m mini_mcp
```
Paste the rules block above into `~/.claude/CLAUDE.md`.

### Cursor
`~/.cursor/mcp.json`:
```json
{ "mcpServers": { "mini": { "command": "python3.11", "args": ["-m", "mini_mcp"] } } }
```
Paste rules into Settings → Rules for AI.

### Codex
`~/.codex/config.toml`:
```toml
[mcp_servers.mini]
command = "python3.11"
args = ["-m", "mini_mcp"]
```
Paste rules into `AGENTS.md`.

---

## Tools provided by mini-mcp

| Tool | What it does |
|---|---|
| `repo_map` | Files + signatures, 8K cap — orient without reading |
| `read_range` | Lines start..end, numbered — tight windows only |
| `apply_patch` | Exact old→new, uniqueness-checked — zero wasted output tokens |
| `park_state` | Append progress to .mini/notes-<task>.md |
| `resume_state` | Read parked state at session start |

## The enforcement gate (`hooks/mini-gate.py`)

A Claude Code `PreToolUse` hook, matched on `Read|Edit|Agent`:

- **Read** is blocked until `mcp__mini__repo_map` has a genuine `tool_use`
  entry in the session transcript this turn — not just a mention of the
  tool's name (system-reminders list every available tool by name; that
  used to be enough to satisfy a naive text search, which is the bug fixed
  in v0.3.1).
- **Edit** is blocked on a given file until `mcp__mini__apply_patch` has
  actually failed twice in a row *on that exact file* (checked via the
  matching `tool_result` blocks' `is_error` flag) — one failure gets told
  to retry, zero attempts gets told to try apply_patch first, and a file
  whose most recent apply_patch succeeded stays on apply_patch rather than
  silently falling back to Edit.
- **Agent** spawns of read-heavy subagent types (`Explore`, `Plan`,
  `general-purpose`, `claude`, `worker-core`, `worker-lite`, `worker-max`)
  are blocked unless the spawn prompt itself instructs the subagent to use
  `mcp__mini__read_range` — subagents get their own transcript, so this is
  the only point where the parent session can enforce Rule 1 onto them.

This is the layer that makes rules 1 and 2 *mandatory* rather than
best-effort: exit 2 with a stderr reason blocks the tool call outright and
feeds the reason back to the model, rather than hoping it remembers.

## What Headroom and Caveman add (not built by this project — pair with it)

- **Headroom** ([chopratejas/headroom](https://github.com/chopratejas/headroom)):
  proxy/MCP layer that compresses tool outputs, files, logs, and history
  before they reach the model. 15–20% reduction on typical coding-agent
  sessions, 60–95% on JSON-heavy tool output. Works automatically once
  installed — no rule-following required.
- **Caveman** ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)):
  skill that compresses model output into terse, technically-accurate
  prose. ~65% output token reduction, measured. Note: output tokens are a
  small fraction of most bills — the input-side tools (Headroom, mini-mcp)
  matter more, but it's a free, zero-effort stack.

## Honest note on what "rules" can and can't do

Rules 1–10 describe good behavior. A model can and sometimes will ignore
them under context pressure — that's why layers 1–3 (Headroom, Caveman,
mini-mcp) exist as structural backstops that don't depend on the model
remembering anything, and why the gate exists on top of rules 1/2
specifically: a real audit found a model correctly *stating* it was
following rules 1/2 while its actual tool calls did not, because the
enforcement check at the time only searched for the tool's name anywhere in
transcript text — satisfied by the tool merely being listed as available,
not by it being called. The gate now checks genuine tool_use/tool_result
evidence instead, so compliance is verifiable from the transcript, not
self-reported. Rules 11 and 12 are different: they're judgment calls (when
to ask, when to verify) that no proxy can make on the model's behalf, so
they stay as rules — but they're written from a real audit of where a
session wasted time and tokens, not as theory.
