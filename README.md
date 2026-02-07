# DotZero AI Tools

MCP servers and Claude Code skills for [DotZero](https://dotzero.app) manufacturing execution systems (MES).

## Quick Install

```bash
npx @dotzero.ai/setup
```

This registers both MCP servers, creates `.dotzero/config.json`, and updates `.gitignore`.
After setup, restart Claude Code and run `auth_login` to authenticate.

## What's Included

### MCP Servers (98 tools)

| Server | Package | Tools | Description |
|--------|---------|-------|-------------|
| dotzero-auth | `@dotzero.ai/auth-mcp` | 3 | Authentication (login, refresh, status) |
| dotzero-workorder | `@dotzero.ai/work-order-mcp` | 95 | Work orders, products, routes, operations, devices, quality, warehouse, WMS |

### Cross-Platform Skills (REST API)

Works with any AI Agent that supports curl/WebFetch, no MCP required:

| Skill | Description |
|-------|-------------|
| `dotzero-auth` | Authentication and token management |
| `dotzero-workorder` | Work order and production management |

## Installation Options

### Option 1: Full Plugin (MCP + Skills)

Install the complete plugin with MCP servers and skills:

```bash
npx @dotzero.ai/setup
```

### Option 2: Manual MCP Setup

```bash
# Add Auth MCP
claude mcp add dotzero-auth \
  --command "npx" \
  --args "-y" "@dotzero.ai/auth-mcp" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Add Work Order MCP
claude mcp add dotzero-workorder \
  --command "npx" \
  --args "-y" "@dotzero.ai/work-order-mcp" \
  --env "WORK_ORDER_API_URL=https://work-order-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"
```

### Option 3: Skills Only (No MCP)

For AI Agents that don't support MCP, use the REST API skills in `skills-only/`.

## Authentication

All DotZero services require authentication with a **tenant_id**.

### Using MCP Tools

```
auth_login(email: "user@example.com", password: "password", tenant_id: "your-tenant")
```

### Using Scripts

```bash
./scripts/dotzero-login.sh user@example.com password your-tenant-id
```

### Token Management

Credentials are stored in `.dotzero/credentials.json` (auto-created on login).

```bash
# Get valid token (auto-refresh if expired)
./scripts/dotzero-token.sh get

# Check token status
./scripts/dotzero-token.sh check
```

**Important**: Add `.dotzero/` to your `.gitignore`.

## MCP Tool Categories

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Work Orders | 7 | CRUD + details + count |
| Products | 6 | CRUD + details + copy |
| Workers | 5 | CRUD + delete |
| Operation History | 7 | CRUD + batch + timeline |
| Reports & Analytics | 5 | Reports, weekly, analytics |
| Routes | 7 | CRUD + by product + copy |
| Operations | 5 | CRUD + delete |
| Route Operations | 6 | CRUD + by route |
| Devices | 5 | CRUD + delete |
| Stations | 6 | CRUD + device list |
| Defect Reasons | 4 | CRUD |
| Defect Categories | 4 | CRUD |
| Abnormal History | 5 | CRUD + by work order |
| Abnormal Config | 4 | Categories + states |
| Op Product BOM | 4 | CRUD |
| Warehouses | 4 | CRUD |
| Warehouse Storage | 4 | CRUD |
| Product Storage | 3 | List + get + by product |
| WMS | 4 | Inventory, storage, history, stock |

## Work Order Status Values

| Value | Status | Description |
|-------|--------|-------------|
| 1 | Not Started | Work order created but not yet started |
| 2 | In Progress | Work order currently being processed |
| 3 | Completed | Work order finished successfully |
| 4 | Incomplete | Work order stopped before completion |

## Manufacturing Terminology

| Common Name | Formal Name | API Resource |
|-------------|-------------|-------------|
| Big WO | Parent Work Order | `/v1/workOrders/` |
| Small WO | Sub/Child Work Order | `/v1/workOrderOpHistory/` |

## Requirements

- Node.js >= 18
- Claude Code >= 1.0.0
- A DotZero account with tenant_id

## License

MIT

## Support

- [Documentation](https://github.com/dotzero-ai/dz-ai/blob/main/README.md)
- [Issues](https://github.com/dotzero-ai/dz-ai/issues)
- Email: support@dotzero.app
