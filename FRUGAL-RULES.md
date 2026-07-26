# FRUGAL RULES — one doctrine, every app
# mini v0.3.0 — 4-layer stack: enforcement, not suggestion

Rules alone are passive text — a real session audit proved the model reads
whole files and screenshots trivially despite being told not to. v0.3.0
stops asking nicely and adds infrastructure that makes waste structurally
harder, plus two new behavioral rules on DECISION SPEED and VERIFICATION
PROPORTIONALITY that came directly from user feedback on real usage.

## The 4 layers (this is the full stack now)

```
Headroom  → compresses everything the model READS (proxy-level, automatic)
Caveman   → compresses everything the model WRITES (skill-level, automatic)
mini-mcp  → changes WHAT gets read in the first place (repo_map, read_range,
            apply_patch, park_state, resume_state)
RULES     → governs BEHAVIOR: when to ask vs explore, when to verify vs trust
```

Headroom and Caveman are infrastructure — once installed they work whether
or not the model "remembers" a rule. mini-mcp tools change the shape of
what's available to call. The rules below govern judgment calls no proxy
can make for the model: when to stop and ask, when a check is worth its cost.

---

## Install all 4 layers

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
```

---

## The rules (canonical text — paste into ~/.claude/CLAUDE.md)

```
TOKEN ECONOMY RULES (non-negotiable):

CONTEXT
1. ORIENT CHEAP. Call repo_map or run `ls`/`find` first. Then grep to locate
   the exact file and line. Never read a whole file to orient — read a tight
   line range around the match; widen only if genuinely needed.

EDITING
2. PATCH, DON'T REWRITE. Edits are minimal exact replacements (apply_patch /
   Edit tool). Never re-emit an entire existing file. New files only when the
   file is actually new. If a rewrite touches >80% of a file, flag it first.

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
remembering anything. Rules 11 and 12 are different: they're judgment calls
(when to ask, when to verify) that no proxy can make on the model's behalf,
so they stay as rules — but they're written from a real audit of where a
session wasted time and tokens, not as theory.
