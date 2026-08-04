# Changelog

## v0.3.1
- **Found and fixed a real enforcement bypass.** The PreToolUse hook that
  gates Rule 1 (repo_map before Read) and Rule 2 (apply_patch before Edit)
  existed only as an undocumented loose file on one machine — never tracked
  in this repo, never wired into `install-full-stack.sh`. Worse, its check
  was a naive substring search over raw transcript text (`"mcp__mini__
  repo_map" in text`), which is satisfied the moment the tool is merely
  *listed* as available (e.g. in a system-reminder) — regardless of whether
  the model ever actually called it. In practice this meant the "hard gate"
  allowed unrestricted native Read/Edit for an entire session as soon as
  the tool names appeared anywhere in context, which is essentially always.
- Rewrote the hook (`hooks/mini-gate.py`, now tracked in this repo) to parse
  the session transcript's real `tool_use`/`tool_result` JSONL blocks —
  checking that repo_map was genuinely invoked, and that apply_patch
  genuinely failed twice in a row *on that exact file* (tracking the
  trailing failure streak per file, not "ever succeeded/failed anywhere,"
  which would otherwise permanently unblock or permanently block Edit based
  on unrelated past attempts).
- Added this as an explicit 5th layer — **enforcement gate** — to
  `install-full-stack.sh`, which now copies the hook to
  `~/.claude/hooks/mini-gate.py` and merges the PreToolUse registration into
  `~/.claude/settings.json` (correctly nested under `"hooks"`, verified
  against a live settings file rather than assumed — the first draft of
  this merge got the schema wrong and would have silently written to a
  no-op location). Idempotent: safe to re-run, checks before acting like
  every other step.
- Updated FRUGAL-RULES.md to document the enforcement layer, which the
  "4 layers" framing omitted entirely despite being the mechanism that
  makes rules 1/2 non-optional instead of prose.

## v0.3.0
- Fixed repo_map SKIP_DIRS: was missing .dart_tool, .gradle, Pods,
  DerivedData, Carthage, GeneratedPluginRegistrant, etc. — leaked build/
  cache junk into the map on Flutter/iOS/Android repos, burning ~1,400+
  tokens before truncating and forcing a grep fallback anyway. Now skips
  any dotted directory generically, plus an explicit vendor-dir list.
- Added rules 11, 12 from real usage: DECISION SPEED (ask, don't explore,
  when blocked on intent) and VERIFICATION SPEED (don't default to the
  browser — match the check to the stakes)
- Added rule 13: DEFAULT, NOT OPT-IN — rules 1/2 are mandatory the moment
  mini's MCP tools are present in the session, not only when the user
  explicitly invokes the stack. Rules 1/2 now name the exact tools
  (mcp__mini__repo_map, mcp__mini__apply_patch) instead of describing
  behavior generically — removes the "or ls/find" escape hatch that let
  models default back to native tools.

## v0.2.0
- Added rules 8, 9, 10 discovered from real Claude Code session audit:
  - Rule 8: Images cost ~1,500 tokens — use javascript_tool JSON for
    logic/color/state verification instead of screenshots
  - Rule 9: Console/error dumps go to .mini/err.txt, never into conversation
  - Rule 10: No prose summaries after phases — diff + passing check is the report
- Reorganised rules into labelled sections (CONTEXT / EDITING / VERIFICATION /
  OUTPUT / STATE / SCOPE / FEEDBACK / IMAGES / ERRORS / REPORTS)
- Updated install instructions to use pip install mini-mcp globally

## v0.1.0
- Initial release: repo_map, read_range, apply_patch, park_state, resume_state
- FRUGAL-RULES with 7 core token economy rules
- Works with Claude Code, Cursor, Codex
