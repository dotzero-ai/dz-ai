# 進階設定

給要自己註冊 MCP、切換環境或用腳本管理 token 的人。一般安裝見 [README](../README.md)。

## 手動註冊本機 MCP（不用 plugin）

Syntax is `claude mcp add <name> [-e KEY=value ...] -- <command> [args...]`.
The `--` separator is required: everything after it is the command Claude Code runs.

```bash
# Auth
claude mcp add dotzero-auth \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/auth-mcp

# Work Order
claude mcp add dotzero-workorder \
  -e WORK_ORDER_API_URL=https://work-order-api.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/work-order-mcp

# SPC
claude mcp add dotzero-spc \
  -e SPC_API_URL=https://dotzerotech-spc-backend.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/spc-mcp

# Equipment
claude mcp add dotzero-equipment \
  -e EQUIPMENT_API_URL=https://dotzerotech-equipment-api.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/equipment-mcp

# Device Topology
claude mcp add dotzero-device-topology \
  -e DEVICE_TOPOLOGY_API_URL=https://dotzerotech-device-topology.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/device-topology-mcp

# OEE
claude mcp add dotzero-oee \
  -e OEE_API_URL=https://dotzerotech-oee-api.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/oee-mcp

# Export (no env vars needed)
claude mcp add dotzero-export -- npx -y @dotzero.ai/export-mcp

# SCM / GDT / SD / WMS (read-only)
claude mcp add dotzero-scm \
  -e SCM_API_URL=https://dotzerotech-scm-backend.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/scm-mcp
claude mcp add dotzero-gdt \
  -e GDT_API_URL=https://gdt-backend.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/gdt-mcp
claude mcp add dotzero-sd \
  -e SD_API_URL=https://sales-distribution-api.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/sd-mcp
claude mcp add dotzero-wms \
  -e WMS_API_URL=https://dotzerotech-wms-backend.dotzero.app \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/wms-mcp
```

Verify with `claude mcp list`. Restart Claude Code after adding servers.

## 只用 skill（不跑 MCP）

For AI Agents that don't support MCP, use the REST API skills in `skills-only/`.

## 登入與 token（本機）

All DotZero services require authentication with a **tenant_id**.

## Using MCP Tools

```
auth_login(tenant_id: "your-tenant")   # opens the DotZero sign-in page; the password never goes through the AI
```

## Using Scripts

```bash
# Secure mode (password prompted, not saved in shell history)
./scripts/dotzero-login.sh user@example.com your-tenant-id

# Legacy mode (password visible in history)
./scripts/dotzero-login.sh user@example.com password your-tenant-id
```

## Token Management

Credentials are stored in `.dotzero/credentials.json` (auto-created on login, permissions set to owner-only).

```bash
# Get valid token (auto-refresh if expired)
./scripts/dotzero-token.sh get

# Check token status
./scripts/dotzero-token.sh check
```

**Important**: Add `.dotzero/` to your `.gitignore`.

## Which environment? (`DOTZERO_ENV`)

**Default is production.** Every server's built-in URL points at the production API
(`*.dotzero.app`). If your organisation runs additional DotZero environments, one variable
switches every server at once — set it before launching Claude Code:

```bash
DOTZERO_ENV=prod    claude   # production (also the default when unset)
DOTZERO_ENV=staging claude   # a non-production DotZero environment
```

- Only production `*.dotzero.app` hosts are rewritten. An explicit `*_API_URL` override
  (localhost, a preview deploy, your own gateway) is always left untouched.
- An invalid value **fails loudly** instead of quietly falling back to production.
- Credentials are stored **per environment** (non-production gets its own file next to
  `credentials.json`), so signing in to one environment no longer overwrites the token for
  another.
- Requires `@dotzero.ai/shared` 1.3.0+ (published 2026-08-21); servers pull the latest
  automatically via `npx -y`.

Why it exists: before this, the tools always answered from production. If you were testing
an app against a different environment and asked these tools for the "real" numbers, you
silently compared two environments — one query returned 315 work orders in one environment
and 307 in the other, 277 devices vs 274, while other services returned byte-identical
data. Some services share data across environments and some don't, so the mismatch stays
invisible until it makes you chase a bug that was never there.
