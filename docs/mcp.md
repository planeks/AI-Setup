# Model Context Protocol (MCP)

## What is MCP?

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is an open protocol that allows AI assistants and development tools to connect to external data sources and tools through a standard interface. An MCP server exposes capabilities—such as logs, traces, documentation, or API operations—that a compatible MCP client can discover and use.

MCP servers run separately from the AI assistant. Only enable servers you trust, and review the data and actions they expose before using them.

## Configured MCP server

This repository defines MCP servers in two client-specific project files:

- [`.mcp.json`](../.mcp.json) for Claude Code and other compatible clients.
- [`.codex/config.toml`](../.codex/config.toml) for Codex CLI, the Codex IDE
  extension, and the ChatGPT desktop app.

Both files currently configure one server:

### Spotlight

[Spotlight](https://spotlightjs.com/) is a local observability and debugging tool. Its MCP server lets compatible AI tools inspect application telemetry such as errors, logs, and performance traces, making it easier to investigate runtime behavior.

The server is registered under the name `spotlight` and is started with:

```bash
npx -y --prefer-online @spotlightjs/spotlight@latest mcp
```

This command downloads the latest Spotlight package when needed and starts it in MCP mode. Node.js and `npx` must therefore be available on the developer machine.

Codex loads `.codex/config.toml` only after the repository is trusted. Other
compatible MCP clients should discover the server from `.mcp.json`. The exact
setup and approval flow depend on the editor or AI tool being used.
