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
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DEST="$CLAUDE_DIR/skills/qa-test"
QA_TEST_HOME="${QA_TEST_HOME:-$HOME/.qa-test}"
VENV="$QA_TEST_HOME/venv"
PY="${PYTHON:-python3}"
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
  if claude mcp get playwright >/dev/null 2>&1; then
    echo "✓ Playwright MCP already registered"
  elif claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest >/dev/null 2>&1; then
    echo "✓ Playwright MCP registered (user scope)"
  else
    echo "! could not register the Playwright MCP automatically. Run it yourself:"
    echo "    claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest"
  fi
  have node || echo "! Node not found — the Playwright MCP needs it. Install Node 18+."
else
  echo "! 'claude' CLI not found — skipping MCP registration."
  echo "  After installing Claude Code, run:"
  echo "    claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest"
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
