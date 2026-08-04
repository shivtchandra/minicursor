#!/usr/bin/env bash
# install-full-stack.sh — installs all 5 layers of the mini token-economy
# stack: Headroom (input compression), Caveman (output compression),
# mini-mcp (tools), the FRUGAL-RULES (behavior), and the enforcement gate
# (a PreToolUse hook that actually blocks non-compliant tool calls).
#
# Safe to re-run — every step checks before acting.
set -uo pipefail

PY="${PYTHON_BIN:-}"
BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}○${NC} $1"; }
step() { echo -e "\n${BOLD}$1${NC}"; }

echo -e "${BOLD}mini — full 5-layer token economy stack${NC}"
echo -e "${DIM}Headroom (reads) + Caveman (writes) + mini-mcp (tools) + rules (behavior) + gate (enforcement)${NC}"

# --- pre-flight -----------------------------------------------------------
# Find first python >= 3.10. Honor PYTHON_BIN override if set.
PYVER="0.0"
for PY_TRY in "$PY" python3.11 python3.12 python3.13 python3.10 python3; do
  [ -z "$PY_TRY" ] && continue
  command -v "$PY_TRY" >/dev/null 2>&1 || continue
  V="$("$PY_TRY" -c 'import sys;print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || echo "0.0")"
  if [ "$(printf '%s\n' "3.10" "$V" | sort -V | head -1)" = "3.10" ]; then
    PY="$PY_TRY"; PYVER="$V"; break
  fi
done
if [ "$PYVER" = "0.0" ]; then
  echo "Need Python 3.10+. None found. Run: brew install python@3.11"
  echo "Then: PYTHON_BIN=python3.11 bash install-full-stack.sh"
  exit 1
fi
ok "Python $PYVER ($PY)"

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI not found on PATH. Install it first, then re-run."
  exit 1
fi
ok "Claude Code CLI found"

# --- layer 1: headroom ------------------------------------------------------
step "1/5 Headroom (input compression)"
if $PY -c "import headroom" 2>/dev/null; then
  ok "already installed"
else
  $PY -m pip install --user -q headroom-ai && ok "installed" || warn "install failed — skip and continue manually: pip install headroom-ai"
fi
# Ensure the --user install bin dir is on PATH (Mac: ~/Library/Python/X.Y/bin, Linux: ~/.local/bin)
USERBASE="$($PY -m site --user-base 2>/dev/null)"
if [ -n "$USERBASE" ]; then
  case "$(uname -s)" in
    Darwin) USERBIN="$USERBASE/bin" ;;
    *)      USERBIN="$USERBASE/bin" ;;
  esac
  if [ -d "$USERBIN" ] && ! echo ":$PATH:" | grep -q ":$USERBIN:"; then
    SHELLRC="$HOME/.zshrc"; [ -n "${BASH_VERSION:-}" ] && SHELLRC="$HOME/.bashrc"
    if ! grep -qF "$USERBIN" "$SHELLRC" 2>/dev/null; then
      echo "export PATH=\"$USERBIN:\$PATH\"" >> "$SHELLRC"
      ok "added $USERBIN to PATH in $SHELLRC"
    fi
    export PATH="$USERBIN:$PATH"
  fi
fi
if command -v headroom >/dev/null 2>&1; then
  headroom mcp install >/dev/null 2>&1 && ok "wired into Claude Code" || warn "run manually: headroom mcp install"
else
  warn "headroom CLI not on PATH yet — you may need to restart your shell, then run: headroom mcp install"
fi

# --- layer 2: caveman --------------------------------------------------------
step "2/5 Caveman (output compression)"
if claude skills list 2>/dev/null | grep -qi caveman; then
  ok "already installed"
else
  git clone https://github.com/JuliusBrussee/caveman ~/.claude/skills/caveman >/dev/null 2>&1 \
    && ok "installed" \
    || warn "install failed — run manually: git clone https://github.com/JuliusBrussee/caveman ~/.claude/skills/caveman"
fi

# --- layer 3: mini-mcp --------------------------------------------------------
step "3/5 mini-mcp (frugal tools)"
$PY -m pip install --user -q "git+https://github.com/shivtchandra/minicursor" \
  && ok "installed" || { echo "pip install failed"; exit 1; }

if claude mcp list 2>/dev/null | grep -q "^mini"; then
  ok "MCP server already registered"
else
  claude mcp add mini --scope user -- "$PY" -m mini_mcp >/dev/null 2>&1 \
    && ok "MCP server registered (user scope — every project)" \
    || warn "run manually: claude mcp add mini --scope user -- $PY -m mini_mcp"
fi

# --- layer 4: rules --------------------------------------------------------
step "4/5 FRUGAL-RULES (behavior)"
HERE="$(cd "$(dirname "$0")" && pwd)"
RULES_FILE="$HERE/FRUGAL-RULES.md"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_MD" ] && grep -q "TOKEN ECONOMY RULES" "$CLAUDE_MD" 2>/dev/null; then
  # Upgrade-aware: strip the old block (from the header to EOF) before re-appending.
  CLAUDE_MD="$CLAUDE_MD" "$PY" - <<'PYEOF'
import os
path = os.environ["CLAUDE_MD"]
content = open(path).read()
start = content.find("TOKEN ECONOMY RULES (non-negotiable):")
if start != -1:
    open(path, "w").write(content[:start].rstrip() + "\n")
    print("old rules block removed — appending fresh")
PYEOF
  warn "existing rules removed — re-appending current version"
fi
{
  echo ""
  awk '
    /TOKEN ECONOMY RULES \(non-negotiable\):/ {flag=1}
    flag {print}
    flag && /^```$/ {c++; if(c==1) exit}
  ' "$RULES_FILE"
} >> "$CLAUDE_MD"
ok "rules appended to $CLAUDE_MD"

# --- layer 5: enforcement gate ---------------------------------------------
# Rules 1-4 are prose — a model can and does ignore prose under context
# pressure. This is the technical backstop: a PreToolUse hook that blocks
# Read (until repo_map has genuinely been called this session) and Edit
# (until apply_patch has genuinely failed twice in a row on that exact
# file), checked against real tool_use/tool_result blocks in the session
# transcript — not a text search that a tool merely being *mentioned*
# anywhere (e.g. in a system-reminder listing available tools) can satisfy.
step "5/5 Enforcement gate (PreToolUse hook)"
mkdir -p "$HOME/.claude/hooks"
cp "$HERE/hooks/mini-gate.py" "$HOME/.claude/hooks/mini-gate.py" \
  && ok "hook installed to ~/.claude/hooks/mini-gate.py" \
  || warn "copy failed — copy $HERE/hooks/mini-gate.py to ~/.claude/hooks/ manually"

SETTINGS_JSON="$HOME/.claude/settings.json"
HOOK_CMD="python3 $HOME/.claude/hooks/mini-gate.py"
SETTINGS_JSON="$SETTINGS_JSON" HOOK_CMD="$HOOK_CMD" "$PY" - <<'PYEOF'
import json
import os

path = os.environ["SETTINGS_JSON"]
hook_cmd = os.environ["HOOK_CMD"]

try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

# Real schema nests PreToolUse under "hooks", not at the settings root —
# verified by inspecting a live settings.json rather than assumed.
pre = data.setdefault("hooks", {}).setdefault("PreToolUse", [])
already_wired = any(
    "mini-gate.py" in h.get("command", "")
    for entry in pre
    for h in entry.get("hooks", [])
)
if not already_wired:
    pre.append({
        "matcher": "Read|Edit|Agent",
        "hooks": [{"type": "command", "command": hook_cmd}],
    })
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print("wired")
else:
    print("already wired")
PYEOF
if [ $? -eq 0 ]; then
  ok "PreToolUse hook registered in $SETTINGS_JSON"
else
  warn "settings.json merge failed — add this yourself:"
  echo '  { "PreToolUse": [ { "matcher": "Read|Edit|Agent", "hooks": [ { "type": "command", "command": "'"$HOOK_CMD"'" } ] } ] }'
fi

# --- verify -----------------------------------------------------------------
step "Done. Verify inside Claude Code:"
echo '  "what token economy rules are you following in this session?"'
echo '  "use repo_map to orient yourself in this project"'
echo '  "edit a file with the native Edit tool without trying apply_patch first" (should be blocked)'
echo ""
echo "Layers installed: Headroom + Caveman + mini-mcp + rules + enforcement gate."
echo "Any step marked ○ above needs a manual follow-up — copy the command shown."
