#!/usr/bin/env bash
# install-full-stack.sh — installs all 4 layers of the mini token-economy
# stack: Headroom (input compression), Caveman (output compression),
# mini-mcp (tools), and the FRUGAL-RULES (behavior).
#
# Safe to re-run — every step checks before acting.
set -uo pipefail

PY="${PYTHON_BIN:-python3.11}"
BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}○${NC} $1"; }
step() { echo -e "\n${BOLD}$1${NC}"; }

echo -e "${BOLD}mini — full 4-layer token economy stack${NC}"
echo -e "${DIM}Headroom (reads) + Caveman (writes) + mini-mcp (tools) + rules (behavior)${NC}"

# --- pre-flight -----------------------------------------------------------
if ! command -v "$PY" >/dev/null 2>&1; then
  warn "$PY not found. Trying python3..."
  PY="python3"
fi
PYVER="$($PY -c 'import sys;print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || echo "0.0")"
if [ "$(printf '%s\n' "3.10" "$PYVER" | sort -V | head -1)" != "3.10" ]; then
  echo "Need Python 3.10+. Found $PYVER. Run: brew install python@3.11"
  echo "Then: PYTHON_BIN=python3.11 bash install-full-stack.sh"
  exit 1
fi
ok "Python $PYVER"

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI not found on PATH. Install it first, then re-run."
  exit 1
fi
ok "Claude Code CLI found"

# --- layer 1: headroom ------------------------------------------------------
step "1/4 Headroom (input compression)"
if $PY -c "import headroom" 2>/dev/null; then
  ok "already installed"
else
  $PY -m pip install --user -q headroom-ai && ok "installed" || warn "install failed — skip and continue manually: pip install headroom-ai"
fi
if command -v headroom >/dev/null 2>&1; then
  headroom mcp install >/dev/null 2>&1 && ok "wired into Claude Code" || warn "run manually: headroom mcp install"
else
  warn "headroom CLI not on PATH yet — you may need to restart your shell, then run: headroom mcp install"
fi

# --- layer 2: caveman --------------------------------------------------------
step "2/4 Caveman (output compression)"
if claude skills list 2>/dev/null | grep -qi caveman; then
  ok "already installed"
else
  git clone https://github.com/JuliusBrussee/caveman ~/.claude/skills/caveman >/dev/null 2>&1 \
    && ok "installed" \
    || warn "install failed — run manually: git clone https://github.com/JuliusBrussee/caveman ~/.claude/skills/caveman"
fi

# --- layer 3: mini-mcp --------------------------------------------------------
step "3/4 mini-mcp (frugal tools)"
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
step "4/4 FRUGAL-RULES (behavior)"
HERE="$(cd "$(dirname "$0")" && pwd)"
RULES_FILE="$HERE/FRUGAL-RULES.md"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_MD" ] && grep -q "TOKEN ECONOMY RULES" "$CLAUDE_MD" 2>/dev/null; then
  warn "TOKEN ECONOMY RULES already present in $CLAUDE_MD — not duplicating."
  echo "  To upgrade to v0.3.0: remove the old block from $CLAUDE_MD, then re-run this script."
else
  {
    echo ""
    awk '
      /TOKEN ECONOMY RULES \(non-negotiable\):/ {flag=1}
      flag {print}
      flag && /^```$/ {c++; if(c==1) exit}
    ' "$RULES_FILE"
  } >> "$CLAUDE_MD"
  ok "rules appended to $CLAUDE_MD"
fi

# --- verify -----------------------------------------------------------------
step "Done. Verify inside Claude Code:"
echo '  "what token economy rules are you following in this session?"'
echo '  "use repo_map to orient yourself in this project"'
echo ""
echo "Layers installed: Headroom + Caveman + mini-mcp + rules."
echo "Any step marked ○ above needs a manual follow-up — copy the command shown."
