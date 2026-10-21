#!/usr/bin/env bash
# One-shot installer for the qa-test skill + everything it needs to run.
#
# After this, the whole workflow is:
#   git clone … && cd …/.agents/skills/qa-test && ./install.sh
#   cd /any/app && claude          # then:  /qa-test '<feature>'
#
# It does THREE things:
#   1. installs the skill into ~/.claude/skills/qa-test (symlink, or --copy)
#   2. registers the Playwright MCP server (the authoring browser) at user scope
#   3. builds a dedicated Python venv (~/.qa-test/venv) with pytest-playwright +
#      Chromium — the runner the skill uses for EVERY app, so you never manage
#      per-app deps or virtualenvs.
#
# Re-running is safe/idempotent. Overrides:
#   ./install.sh --copy                 # copy the skill instead of symlinking
#   CLAUDE_DIR=/custom ./install.sh     # different ~/.claude
#   QA_TEST_HOME=/custom ./install.sh   # different home for the runner venv
#   PYTHON=python3.12 ./install.sh      # pick the interpreter for the venv
#   PLAYWRIGHT_MCP_VERSION=0.0.84 ./install.sh   # register another Playwright MCP release
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DEST="$CLAUDE_DIR/skills/qa-test"
QA_TEST_HOME="${QA_TEST_HOME:-$HOME/.qa-test}"
VENV="$QA_TEST_HOME/venv"
PY="${PYTHON:-python3}"
# The Playwright MCP release this skill is tested with. @playwright/mcp is pre-1.0 and each
# release bundles its own Playwright alpha, so "@latest" would change the authoring browser on
# every machine whenever upstream publishes. Bump it deliberately: see INSTALL.md,
# "Upgrading the Playwright MCP".
PLAYWRIGHT_MCP_VERSION="${PLAYWRIGHT_MCP_VERSION:-0.0.83}"
MCP_PKG="@playwright/mcp@$PLAYWRIGHT_MCP_VERSION"
MCP_ADD="claude mcp add --scope user playwright -- npx -y $MCP_PKG"
MODE="symlink"
[ "${1:-}" = "--copy" ] && MODE="copy"

have() { command -v "$1" >/dev/null 2>&1; }

echo "qa-test installer"
echo "================="

# ── 1. the skill ────────────────────────────────────────────────────────────
if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: $SRC/SKILL.md not found — run this from the repo." >&2
  exit 1
fi
mkdir -p "$CLAUDE_DIR/skills"
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  BACKUP="$DEST.bak.$(date +%Y%m%d%H%M%S)"
  echo "• existing $DEST → backing up to $BACKUP"
  mv "$DEST" "$BACKUP"
fi
if [ "$MODE" = "symlink" ]; then
  ln -s "$SRC" "$DEST"; echo "✓ skill symlinked → $DEST"
else
  cp -R "$SRC" "$DEST"; echo "✓ skill copied → $DEST"
fi

# ── 2. the Playwright MCP (authoring browser; needs claude CLI + Node) ───────
echo
if have claude; then
  if ! registered="$(claude mcp get playwright 2>/dev/null)"; then
    if claude mcp add --scope user playwright -- npx -y "$MCP_PKG" >/dev/null 2>&1; then
      echo "✓ Playwright MCP registered (user scope, $MCP_PKG)"
    else
      echo "! could not register the Playwright MCP automatically. Run it yourself:"
      echo "    $MCP_ADD"
    fi
  else
    command_line="$(printf '%s\n' "$registered" | sed -n 's/^[[:space:]]*Command:[[:space:]]*//p' | head -n 1)"
    args="$(printf '%s\n' "$registered" | sed -n 's/^[[:space:]]*Args:[[:space:]]*//p' | head -n 1)"
    if [ "$command_line" = "npx" ] && [ "$args" = "-y $MCP_PKG" ]; then
      echo "✓ Playwright MCP already registered ($MCP_PKG)"
    elif [ "$command_line" = "npx" ] && printf '%s' "$args" | grep -Eq '^-y @playwright/mcp@[^[:space:]]+$'; then
      # This installer's own registration at another version (earlier releases wrote @latest):
      # move it to the pinned one. A command set up by hand is left alone.
      if claude mcp remove --scope user playwright >/dev/null 2>&1 \
         && claude mcp add --scope user playwright -- npx -y "$MCP_PKG" >/dev/null 2>&1; then
        echo "✓ Playwright MCP re-registered: ${args#-y } → $MCP_PKG"
      else
        echo "! could not re-register the Playwright MCP. Run it yourself:"
        echo "    claude mcp remove --scope user playwright"
        echo "    $MCP_ADD"
      fi
    else
      echo "• Playwright MCP already registered with your own command — left as it is."
      echo "  The skill is tested with $MCP_PKG. To switch to it:"
      echo "    claude mcp remove --scope user playwright"
      echo "    $MCP_ADD"
    fi
  fi
  have node || echo "! Node not found — the Playwright MCP needs it. Install Node 18+."
else
  echo "! 'claude' CLI not found — skipping MCP registration."
  echo "  After installing Claude Code, run:"
  echo "    $MCP_ADD"
fi

# ── 3. the dedicated test-runner venv (pytest-playwright + Chromium) ─────────
echo
if have "$PY"; then
  echo "• building test-runner venv at $VENV (this is the runner for every app)"
  mkdir -p "$QA_TEST_HOME"
  [ -d "$VENV" ] || "$PY" -m venv "$VENV"
  if "$VENV/bin/python" -m pip install --quiet --upgrade pip \
     && "$VENV/bin/python" -m pip install --quiet pytest-playwright \
     && "$VENV/bin/python" -m playwright install chromium; then
    echo "✓ runner ready → $VENV/bin/pytest  (pytest-playwright + Chromium)"
  else
    echo "! the runner venv didn't finish setting up — see the errors above,"
    echo "  fix the cause (network? python venv module?), then re-run ./install.sh"
  fi
else
  echo "! '$PY' not found — cannot build the test-runner venv."
  echo "  Install Python 3 (or set PYTHON=...), then re-run ./install.sh"
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo
echo "Done. Next:"
echo "  1. restart Claude Code so the skill + MCP register"
echo "  2. cd into ANY app, run 'claude', then:  /qa-test '<feature>'"
