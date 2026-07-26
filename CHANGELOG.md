# Changelog

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
