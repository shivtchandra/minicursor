#!/usr/bin/env python3
"""
mini-mcp — mini's token-frugal tools as an MCP server, usable inside
Cursor, Codex app, and Claude Code simultaneously.

Install:  pip install mini-mcp
Connect: claude mcp add mini --scope user -- mini-mcp
Rules:    append FRUGAL-RULES.md to ~/.claude/CLAUDE.md
"""
import re
from pathlib import Path
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("mini")

SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist",
             "build", ".next", ".mini", "target", ".idea", ".vscode"}
SIG_RE = {
    ".py": re.compile(r"^\s*(?:class|def)\s+\w+.*?:", re.M),
    ".js": re.compile(r"^\s*(?:export\s+)?(?:async\s+)?(?:function\s+\w+|class\s+\w+|const\s+\w+\s*=\s*(?:async\s*)?\()", re.M),
    ".ts": re.compile(r"^\s*(?:export\s+)?(?:async\s+)?(?:function\s+\w+|class\s+\w+|interface\s+\w+|const\s+\w+\s*=\s*(?:async\s*)?\()", re.M),
    ".tsx": re.compile(r"^\s*(?:export\s+)?(?:function\s+\w+|class\s+\w+|const\s+\w+)", re.M),
    ".jsx": re.compile(r"^\s*(?:export\s+)?(?:function\s+\w+|class\s+\w+|const\s+\w+)", re.M),
    ".go": re.compile(r"^func\s+.*?\{", re.M),
    ".java": re.compile(r"^\s*(?:public|private|protected).*?\)\s*\{", re.M),
    ".kt": re.compile(r"^\s*(?:fun|class|object)\s+\w+", re.M),
}
MAP_CAP = 8000


@mcp.tool()
def repo_map(root: str = ".") -> str:
    """Compressed map of the repository: file paths + function/class
    signatures, capped at 8K chars. Call this ONCE at task start to orient
    instead of reading files. Grep for anything not shown in the map."""
    rootp = Path(root).resolve()
    lines, total = [], 0
    for p in sorted(rootp.rglob("*")):
        if any(part in SKIP_DIRS for part in p.parts) or not p.is_file():
            continue
        try:
            if p.stat().st_size > 400_000:
                continue
            entry = str(p.relative_to(rootp))
            rx = SIG_RE.get(p.suffix)
            if rx:
                sigs = [s.strip().rstrip("{:").strip()[:80]
                        for s in rx.findall(p.read_text(errors="ignore"))][:25]
                if sigs:
                    entry += "\n" + "\n".join(f"    {s}" for s in sigs)
            entry += "\n"
            if total + len(entry) > MAP_CAP:
                lines.append("  …map truncated (grep for the rest)…")
                break
            lines.append(entry)
            total += len(entry)
        except OSError:
            continue
    return "REPO MAP:\n" + "".join(lines)


@mcp.tool()
def read_range(path: str, start: int, end: int = -1) -> str:
    """Read ONLY lines start..end (1-indexed, end=-1 for EOF) of a file,
    numbered. Always prefer this over reading whole files: grep first to
    find the line, then read a tight window around it."""
    text = Path(path).read_text(errors="ignore").splitlines()
    s = max(1, start)
    e = len(text) if end == -1 else min(end, len(text))
    if s > len(text):
        return f"(file has only {len(text)} lines)"
    return "\n".join(f"{i}\t{text[i-1]}" for i in range(s, e + 1)) or "(empty)"


@mcp.tool()
def apply_patch(path: str, old_str: str, new_str: str) -> str:
    """Surgical file edit: replace old_str with new_str. old_str must match
    EXACTLY ONCE (include surrounding lines for uniqueness). Prefer this
    over rewriting files — it costs zero output tokens for unchanged code."""
    p = Path(path)
    s = p.read_text()
    n = s.count(old_str)
    if n == 0:
        return "PATCH FAILED: old_str not found — re-read the exact lines first."
    if n > 1:
        return f"PATCH FAILED: old_str appears {n}x — add surrounding lines."
    p.write_text(s.replace(old_str, new_str, 1))
    return f"patched {path}"


@mcp.tool()
def park_state(note: str, task: str = "session") -> str:
    """Append decisions/progress to .mini/notes-<task>.md so a FRESH session
    can resume without re-deriving context. Use when a phase completes or
    the session is near its usage limit."""
    d = Path(".mini")
    d.mkdir(exist_ok=True)
    (d / ".gitignore").write_text("*\n")
    f = d / f"notes-{re.sub(r'[^a-z0-9-]', '-', task.lower())[:40]}.md"
    with f.open("a") as fh:
        fh.write(note.rstrip() + "\n\n---\n\n")
    return f"parked -> {f} (next session: read this file first)"


@mcp.tool()
def resume_state(task: str = "session") -> str:
    """Read the parked state for a task so this session resumes instead of
    restarting. Call at the START of a session continuing earlier work."""
    f = Path(".mini") / f"notes-{re.sub(r'[^a-z0-9-]', '-', task.lower())[:40]}.md"
    if not f.exists():
        listing = "\n".join(str(x) for x in Path(".mini").glob("notes-*.md")) \
            if Path(".mini").exists() else "(none)"
        return f"No parked state for '{task}'. Existing notes:\n{listing}"
    return f.read_text()[-12_000:]


def main_entry():
    mcp.run()

if __name__ == "__main__":
    main_entry()
