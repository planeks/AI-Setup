# AI coding agents

Shared agent configuration ships with the repo. Skills follow the open
[Agent Skills](https://agentskills.io) spec; MCP servers ([MCP](mcp.md)) work
with any MCP-capable agent. The rest of `.claude/` targets Claude Code.

## Skills

Skills live in `.agents/skills/` (the directory Codex and other spec-compliant
tools scan); Claude Code reads them through the `.claude/skills` symlink. They
load on demand — zero context cost until used. Invoke manually with
`/<skill-name>`:

- `run-tests` — pytest and Vitest through docker compose.
- `django-migrations` — create/apply/check migrations, resolve number conflicts.
- `lint-fix` — ruff, ESLint, Prettier, autofix and CI check variants.
- `docker-services` — dev stack reference: services, ports, logs, entrypoint.

### Windows note

Git recreates the `.claude/skills` symlink only when Windows allows creating
symlinks. Without that permission the clone contains a plain text file with
the target path inside, and Claude Code finds no skills (Codex is unaffected —
it reads `.agents/skills/` directly). WSL does not have this problem.

To fix it:

1. Enable symlink support once: turn on **Developer Mode** (Settings → System →
   For developers), or run Git as a user with the "Create symbolic links"
   privilege.
2. Tell git to use symlinks: `git config core.symlinks true` (or clone with
   `git clone -c core.symlinks=true ...`).
3. Recreate the file from the index:

   ```bash
   git checkout -- .claude/skills
   ```

Verify: `.claude/skills` should list the skill folders, not print a path.

## Claude Code

**Permissions** (`.claude/settings.json`): read-only and routine commands
(git inspection, lint/test via `compose.dev.yml`, official doc sites) are
pre-approved. Reading `.env*`, the prod compose file, `down -v`, destructive
git, and deploy/backup scripts are denied — a guardrail, not a security
boundary. Personal overrides: `.claude/settings.local.json` (gitignored).

**Plugins** (installed on first trust): `pyright-lsp`, `typescript-lsp`,
`code-review`, `code-simplifier`, `security-guidance`, `frontend-design`,
`context7`, `caveman`. All from the official marketplace except `caveman`
(community: `github.com/JuliusBrussee/caveman`).

**Status line** — model, branch, context usage, caveman mode:

```
[Fable 5] feature/my-branch | ctx 16% (157k/1.0M) | caveman:full
```

*How it installs itself.* There is no install step. The checked-in
`.claude/settings.json` contains a `statusLine` entry pointing at
`.claude/statusline.sh`. When you start Claude Code in the repo and accept the
workspace trust prompt, it picks the setting up and from then on runs the
script on every render, piping session JSON (model, tokens, workspace) to its
stdin and displaying whatever the script prints. The only requirement is `jq`
(`sudo apt install jq` / `brew install jq`).

*Caveman badge is per-session.* The caveman plugin tracks its level in one
global flag file, so two parallel sessions would show each other's level. The
`SessionStart` and `UserPromptSubmit` hooks in `.claude/settings.json` run
`.claude/hooks/caveman-session-flag.sh`, which keeps a flag per session id
(`~/.claude/.caveman-session-<id>`). The status line prefers that flag and
falls back to the plugin's global one. Note the plugin itself still reads the
global flag for its per-turn prompt reinforcement, so with parallel sessions
at different levels the model in the other session may drift; the badge stays
correct.

*Debugging.* If the line does not appear:

1. Run the script by hand with mock input — it must print one line:

   ```bash
   echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25}}' \
     | ./.claude/statusline.sh
   ```

2. Not executable? `chmod +x .claude/statusline.sh`.
3. `jq` missing? The command above will say so.
4. `claude --debug` logs the exit code and stderr of the first status line run.
5. `disableAllHooks: true` in any settings file also disables the status line.

*Installing manually.* If the project setting does not load for you (declined
trust, or your own settings override it), add the same block to
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/statusline.sh"
  }
}
```

Or run `/statusline` in a session and ask for it interactively.

## Saving tokens

Config handles the big part (deferred MCP schemas, on-demand skills, short
instruction files). Habits: pick the model per task (`/model`), `/clear`
between unrelated tasks, lower `/effort` for routine work, use subagents for
broad searches, `/caveman` for compressed output. The status line's context
percentage is what every turn costs.
