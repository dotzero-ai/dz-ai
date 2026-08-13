# MCP Tool Reference

Tool-schema documentation for the DotZero MCP servers: every tool name, what it takes,
and what it returns. **Reference material — nothing here is a skill.**

## Why these are not in `skills/`

These 12 files used to sit in `skills/`, which made the skill list look twice as long as
it really was. They were moved out in 2026-08 because they fail every test of what a
skill is:

| | `skills/dotzero-*` | `docs/mcp-reference/*` (here) |
|---|---|---|
| YAML frontmatter (`name` / `description`) | yes | **no** — nothing for the agent to match on |
| How it gets used | agent auto-loads it when the description matches the request | a human or agent reads it on purpose |
| What it contains | runnable `curl` recipes + endpoint semantics | MCP tool schemas (name, params, response shape) |
| Number of `curl` examples | dozens | **0** |
| Needs an MCP server installed | no — plain REST | **yes** |

A skill without frontmatter can never be auto-triggered, so leaving these under `skills/`
bought nothing and cost clarity.

## You need an MCP server for any of this to work

Every tool named in these files (`workorder_list`, `oee_device`, `spc_statistics_capability`, …)
only exists after the matching MCP server is registered with your agent. Without one,
the tools simply are not there and the AI has nothing to call.

```bash
# Fastest path — registers all servers and writes .dotzero/config.json
npx @dotzero.ai/setup
```

Manual registration, per server, is listed in [dotzero-all.md](./dotzero-all.md#manual-setup).

If you cannot (or do not want to) run MCP servers, use the cross-platform REST skills in
`skills/` instead — those are pure `curl` against the public APIs and need no MCP at all.

## Files

| File | MCP server | Tools |
|------|-----------|-------|
| [dotzero-all.md](./dotzero-all.md) | *(index of all of them)* | 263 |
| [auth.md](./auth.md) | `@dotzero.ai/auth-mcp` | 3 |
| [work-order-api.md](./work-order-api.md) | `@dotzero.ai/work-order-mcp` | 103 |
| [spc-api.md](./spc-api.md) | `@dotzero.ai/spc-mcp` | 49 |
| [equipment-api.md](./equipment-api.md) | `@dotzero.ai/equipment-mcp` | 12 |
| [device-topology-api.md](./device-topology-api.md) | `@dotzero.ai/device-topology-mcp` | 39 |
| [oee-api.md](./oee-api.md) | `@dotzero.ai/oee-mcp` | 23 |
| [export-api.md](./export-api.md) | `@dotzero.ai/export-mcp` | 13 |
| [gdt-api.md](./gdt-api.md) | `@dotzero.ai/gdt-mcp` | 5 |
| [scm-api.md](./scm-api.md) | `@dotzero.ai/scm-mcp` | 6 |
| [sd-api.md](./sd-api.md) | `@dotzero.ai/sd-mcp` | 5 |
| [wms-api.md](./wms-api.md) | `@dotzero.ai/wms-mcp` | 5 |

> Tool counts come from `scripts/count_mcp_tools.py`, which reads the tool definitions in
> `packages/*-mcp` directly. **Re-run it after changing any MCP tool** and update the
> numbers here, in the root `README.md`, in `llms.txt` and in
> `.claude-plugin/marketplace.json` — those four are the only places that quote them.
