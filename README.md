# AI Setup

AI agent configuration for PLANEKS projects: the company engineering standard plus the working setup. Reference copy, not a runnable project — the `src/` tree holds only `AGENTS.md` files, no code.

## Contents

| Path | What it is |
|---|---|
| `AI-DEVELOPER-MANIFESTO.md` | The AI Developer Manifesto. What the developer's role is when AI writes the code: principles, responsibility, what we do not accept. |
| `AI-ENGINEERING-STANDARDS.md` | PLANEKS AI Engineering Standards. Company rules for working with AI: risk levels, security, prompting, PR flow, accountability, metrics. |
| `AGENTS.md`, `src/AGENTS.md`, `src/frontend/AGENTS.md` | Tool-agnostic project rules (root, backend, frontend). The boilerplate's source of truth for any coding agent. |
| `CLAUDE.md` | Claude Code entry point. Imports the three `AGENTS.md` files, points at the vendored standards. |
| `.agents/skills/` | Thirteen task skills in the open Agent Skills format (`django-backend`, `react-frontend`, `verify-change`, `qa-test`, ...). Index in its `README.md`. |
| `.claude/skills` | Symlink to `.agents/skills/` so Claude Code discovers the same skills. |
| `.claude/CLAUDE_*.md` | Vendored company-wide standards: base, python, django, react, architecture. Read on demand, not auto-imported into context. |
| `.claude/settings.json` | Claude Code permissions (allow/deny lists), plugins, hooks and statusline wiring. |
| `.claude/hooks/`, `.claude/statusline.sh` | Per-session caveman-mode flag hook and the status line script. |
| `.mcp.json` | MCP server config. |
| `docs/ai-agents.md`, `docs/mcp.md` | How the agent setup and MCP are wired in the source repo, including the Windows symlink caveat. |

## Caveats

Paths and commands inside the copied files refer to the boilerplate's stack: `compose.dev.yml`, the Docker entrypoint verbs, the `src/<app>/api/` layout. Adapt them before dropping the files into another project.

