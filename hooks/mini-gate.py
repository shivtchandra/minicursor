#!/usr/bin/env python3
"""PreToolUse hard gate for FRUGAL RULES 1/2 — enforces mini-mcp
repo_map-before-Read and apply_patch-before-Edit at the tool-call level,
not just via prompt text. Exit 0 = allow. Exit 2 = block (stderr is fed
back to the model as the reason).

v2 (fixed): checks genuine tool_use invocations parsed from the transcript
JSONL, not a naive substring search over raw transcript text. The v1
substring check was trivially defeated: system-reminders list available
tool NAMES (e.g. "mcp__mini__repo_map is now available") purely because
the tool is installed, not because it was ever called — so `"mcp__mini__
repo_map" in text` was satisfied from turn one of every session regardless
of whether the model actually invoked it. This version walks the transcript's
real tool_use/tool_result blocks instead."""
import json
import sys

EXEMPT = (".mini/", "CLAUDE.md", "AGENTS.md", "/.claude/", "/.codex/",
          "settings.json", "settings.local.json", "/.git/")

# Subagent types that read source files and therefore must be told to read
# frugally. Anything not listed here (statusline-setup, caveman:* agents,
# etc.) is either non-read-heavy or already output-compressed.
READ_HEAVY_AGENTS = {
    "Explore", "Plan", "general-purpose", "claude",
    "worker-core", "worker-lite", "worker-max",
}

# A compliant agent prompt must mention one of these, i.e. must instruct the
# subagent to use ranged reads instead of whole-file Read.
FRUGAL_MARKERS = ("mcp__mini__read_range", "read_range")


def allow():
    sys.exit(0)


def block(reason):
    sys.stderr.write(reason + "\n")
    sys.exit(2)


def gate_agent(tool_input):
    """RULE 1 survives delegation: a read-heavy subagent may only be spawned
    with a prompt that tells it to read frugally. Subagents run in their own
    sessions, so the Read gate below never sees their tool calls — the spawn
    itself is the only enforceable point."""
    subagent = tool_input.get("subagent_type") or "general-purpose"
    if subagent not in READ_HEAVY_AGENTS:
        allow()
        return

    prompt = tool_input.get("prompt", "") or ""
    if any(marker in prompt for marker in FRUGAL_MARKERS):
        allow()
        return

    block(
        f"RULE 1 (ORIENT CHEAP) applies to subagents too — a '{subagent}' "
        f"agent was spawned without frugal-read instructions. Subagent reads "
        f"bypass this hook entirely, so the prompt itself must tell the agent "
        f"to use mcp__mini__repo_map to orient, grep to locate, and "
        f"mcp__mini__read_range for tight line windows — NOT whole-file Read. "
        f"Add that instruction to the prompt and retry."
    )


def parse_transcript(path):
    """Returns (tool_uses, results_by_id) from the session JSONL.
    tool_uses: ordered list of (name, input_dict, tool_use_id).
    results_by_id: tool_use_id -> is_error (bool), for tool_result blocks.
    A tool_use block only proves the model actually called the tool — unlike
    a raw substring match, it can't be satisfied by a tool merely being
    mentioned in a system-reminder or another message's text."""
    tool_uses = []
    results_by_id = {}
    if not path:
        return tool_uses, results_by_id
    try:
        with open(path, "r", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                content = obj.get("message", {}).get("content")
                if not isinstance(content, list):
                    continue
                for block_ in content:
                    if not isinstance(block_, dict):
                        continue
                    btype = block_.get("type")
                    if btype == "tool_use":
                        tool_uses.append((
                            block_.get("name", ""),
                            block_.get("input", {}) or {},
                            block_.get("id", ""),
                        ))
                    elif btype == "tool_result":
                        tid = block_.get("tool_use_id", "")
                        if tid:
                            results_by_id[tid] = bool(block_.get("is_error", False))
    except OSError:
        pass
    return tool_uses, results_by_id


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        allow()
        return

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}
    transcript_path = data.get("transcript_path", "")

    if tool_name == "Agent":
        gate_agent(tool_input)
        return

    if tool_name not in ("Read", "Edit"):
        allow()
        return

    file_path = tool_input.get("file_path", "") or ""
    if any(marker in file_path for marker in EXEMPT):
        allow()
        return

    tool_uses, results_by_id = parse_transcript(transcript_path)

    if tool_name == "Read":
        called_repo_map = any(name == "mcp__mini__repo_map" for name, _, _ in tool_uses)
        if called_repo_map:
            allow()
        else:
            block(
                "RULE 1 (ORIENT CHEAP) — mcp__mini__repo_map has not actually "
                "been called yet this session (its name appearing in a tool "
                "list or system-reminder does not count as calling it). Call "
                "it first, then grep, then mcp__mini__read_range for a tight "
                "line range. Read is blocked until repo_map is genuinely "
                "invoked."
            )
        return

    if tool_name == "Edit":
        # Rule 2 allows falling back to Edit only after apply_patch fails
        # TWICE IN A ROW on this exact file — so look at the trailing run of
        # consecutive failures for this file, not "ever succeeded/failed
        # anywhere," which would either permanently unblock Edit after one
        # unrelated past success or permanently block it after one old
        # failure that was since fixed.
        attempts_on_file = [
            (name, inp, tid) for name, inp, tid in tool_uses
            if name == "mcp__mini__apply_patch" and inp.get("path") == file_path
        ]

        trailing_failures = 0
        for _, _, tid in reversed(attempts_on_file):
            if results_by_id.get(tid) is True:
                trailing_failures += 1
            else:
                break

        if trailing_failures >= 2:
            allow()
            return

        if trailing_failures == 1:
            block(
                f"RULE 2 (PATCH, DON'T REWRITE) — apply_patch has failed once "
                f"on {file_path}. Try it one more time (fix the old_str match "
                f"— usually needs more surrounding context for uniqueness) "
                f"before falling back to Edit; the rule requires two failures "
                f"in a row, not one."
            )
            return

        if attempts_on_file:
            # Most recent attempt on this file succeeded — no active failure
            # streak, so there's no basis to fall back to Edit right now.
            block(
                f"RULE 2 (PATCH, DON'T REWRITE) — apply_patch's most recent "
                f"attempt on {file_path} succeeded. Use apply_patch for this "
                f"change too, not Edit."
            )
            return

        block(
            f"RULE 2 (PATCH, DON'T REWRITE) — mcp__mini__apply_patch has not "
            f"actually been tried yet for {file_path} this session (a tool "
            f"name merely appearing in transcript text does not count as "
            f"trying it). Try apply_patch first; fall back to Edit only if "
            f"it fails twice in a row on this exact file."
        )
        return

    allow()


if __name__ == "__main__":
    main()
