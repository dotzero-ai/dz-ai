# DotZero AI Tools

MCP servers and Claude Code skills for [DotZero](https://dotzero.app) manufacturing execution systems (MES).

## Quick Install

```bash
npx @dotzero.ai/setup
```

This registers all MCP servers, creates `.dotzero/config.json`, and updates `.gitignore`.
After setup, restart Claude Code and run `auth_login` to authenticate.

## What's Included

### MCP Servers (217 tools)

| Server | Package | Tools | Description |
|--------|---------|-------|-------------|
| dotzero-auth | `@dotzero.ai/auth-mcp` | 3 | Authentication (login, refresh, status) |
| dotzero-workorder | `@dotzero.ai/work-order-mcp` | 98 | Work orders, products, routes, operations, devices, quality, warehouse, WMS |
| dotzero-spc | `@dotzero.ai/spc-mcp` | 41 | SPC measurement configs, inspection data, control charts, statistics |
| dotzero-equipment | `@dotzero.ai/equipment-mcp` | 12 | Real-time machine status, alarms, idle time, part counts |
| dotzero-device-topology | `@dotzero.ai/device-topology-mcp` | 37 | Factory/line/device hierarchy, plant floors, alarm codes |
| dotzero-oee | `@dotzero.ai/oee-mcp` | 20 | Availability, quality, performance, OEE at device/line/factory |

### Cross-Platform Skills (REST API)

Works with any AI Agent that supports curl/WebFetch, no MCP required:

| Skill | Description |
|-------|-------------|
| `dotzero-auth` | Authentication and token management |
| `dotzero-workorder` | Work order and production management |
| `dotzero-spc` | SPC quality control and measurement |
| `dotzero-equipment` | Equipment monitoring |
| `dotzero-device-topology` | Device topology management |
| `dotzero-oee` | OEE analysis |

## Installation Options

### Option 1: Full Plugin (MCP + Skills)

Install the complete plugin with MCP servers and skills:

```bash
npx @dotzero.ai/setup
```

### Option 2: Manual MCP Setup

```bash
# Auth
claude mcp add dotzero-auth \
  --command "npx" \
  --args "-y" "@dotzero.ai/auth-mcp" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Work Order
claude mcp add dotzero-workorder \
  --command "npx" \
  --args "-y" "@dotzero.ai/work-order-mcp" \
  --env "WORK_ORDER_API_URL=https://work-order-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# SPC
claude mcp add dotzero-spc \
  --command "npx" \
  --args "-y" "@dotzero.ai/spc-mcp" \
  --env "SPC_API_URL=https://dotzerotech-spc-backend.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Equipment
claude mcp add dotzero-equipment \
  --command "npx" \
  --args "-y" "@dotzero.ai/equipment-mcp" \
  --env "EQUIPMENT_API_URL=https://dotzerotech-equipment-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Device Topology
claude mcp add dotzero-device-topology \
  --command "npx" \
  --args "-y" "@dotzero.ai/device-topology-mcp" \
  --env "DEVICE_TOPOLOGY_API_URL=https://dotzerotech-device-topology.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# OEE
claude mcp add dotzero-oee \
  --command "npx" \
  --args "-y" "@dotzero.ai/oee-mcp" \
  --env "OEE_API_URL=https://dotzerotech-oee-api.dotzero.app" \
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

### Work Order API (98 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Work Orders | 7 | CRUD + details + count |
| Products | 6 | CRUD + details + copy |
| Workers | 5 | CRUD + delete |
| Operation History | 7 | CRUD + batch + timeline |
| Reports & Analytics | 8 | Reports, weekly, analytics, rankings, summary |
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

### SPC API (41 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Products V2 | 2 | Manufacture + stock product lists |
| History V2 | 4 | Batch upsert/query/delete by group |
| Config Parent V2 | 5 | Parent config CRUD + attachments |
| Measure Config V1 | 9 | Measure point config CRUD + modes + categories |
| Measure History V1 | 11 | History CRUD + batch + filtering + counting |
| Instruments V1 | 5 | Instrument CRUD + batch delete |
| Rules V1 | 1 | Control chart rules |
| Dashboard V1 | 6 | Dashboard CRUD + manufacture entries |
| Statistics V1 | 4 | Nelson rules, capability, calculation |

### Equipment API (12 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Alarms | 1 | Alarm records |
| Idles | 1 | Idle time records |
| Machine Status | 5 | History, part counts, real-time (single + batch) |
| Off Time | 1 | Off-time records |
| State Counts | 2 | Factory + line aggregations |

### Device Topology API (37 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Groups | 5 | Organizational group CRUD |
| Factories | 5 | Factory CRUD |
| Lines | 5 | Production line CRUD |
| Devices | 5 | Device/machine CRUD |
| Plant Floors | 4 | Plant floor layout CRUD |
| Alarms | 5 | Alarm record CRUD |
| Alarm Codes | 6 | Alarm code CRUD + batch |
| Topology | 2 | Count + full tree |

### OEE API (20 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Availability | 4 | Device, multi-device, line, factory |
| Quality | 4 | Device, multi-device, line, factory |
| Performance | 5 | Device, multi-device, line, factory, device range |
| OEE (Combined) | 4 | Device, multi-device, line, factory |
| Status | 1 | Device OEE status |
| Alarm History | 1 | OEE-related alarms |

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

Proprietary. See [LICENSE](LICENSE) for details.

## Support

- [Documentation](https://github.com/dotzero-ai/dz-ai/blob/main/README.md)
- [Issues](https://github.com/dotzero-ai/dz-ai/issues)
- Email: support@dotzero.app
