# Equipment API Skill

MCP skill for equipment monitoring — real-time machine status, alarm tracking, idle time analysis, part counts, and state counts by factory/line.

## Overview

This skill provides 12 tools for interacting with the Equipment API:

- **Authentication** (2): Login and check auth status
- **Alarms** (1): List equipment alarms
- **Idles** (1): List idle time records
- **Machine Status** (5): Real-time status, history, part counts (single and batch)
- **Off Time** (1): List off-time records
- **State Counts** (2): Aggregate state counts by factory or line

## Prerequisites

### Authentication

All tools require authentication. Call `auth_login` first — every data request without a valid token returns 401. Recommended: pass only `tenant_id` to open browser login (credentials never pass through the AI).

```
auth_login(tenant_id: "tenant-id")
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `EQUIPMENT_API_URL` | Yes | Base URL of the Equipment API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Tools Reference

### Authentication Tools

#### auth_login
Authenticate to obtain a JWT token.

**Parameters:**
- `tenant_id` (string, required): Tenant ID
- `email` (string, optional): User email — omit to open browser login (recommended)
- `password` (string, optional): User password — omit to open browser login

Recommended usage: `auth_login(tenant_id: "your-tenant-id")` opens a browser for the user to enter credentials.

#### auth_status
Check if the client is authenticated.

**Parameters:** None

---

### Alarm Tools

#### equip_alarm_list
List equipment alarm records.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339)
- `end_time` (string, required): End time (RFC3339)
- `limit` (number, default: 20): Max results (1-100)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Idle Tools

#### equip_idle_list
List equipment idle time records.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339)
- `end_time` (string, required): End time (RFC3339)
- `limit` (number, default: 20): Max results (1-100)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Machine Status Tools

#### equip_machine_status_history
Get the machine status at a specific point in time (returns a single record, the latest at or before `time`).

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `time` (string, required): Point in time (RFC3339) — returns latest status at or before this
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_machine_status_part_counts
Get part count data for a device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339)
- `end_time` (string, required): End time (RFC3339)
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_machine_status_part_counts_batch
Get part counts for multiple devices in one call.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, required): Start time (RFC3339), applied to all devices
- `end_time` (string, required): End time (RFC3339), applied to all devices
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_machine_status_realtime
Get real-time machine status for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_machine_status_realtime_batch
Get real-time machine status for multiple devices.

**Parameters:**
- `device_uuids` (string, required): Comma-separated device UUIDs (e.g. "dev-1,dev-2,dev-3")
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Off Time Tools

#### equip_off_time_list
List equipment off-time records.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339)
- `end_time` (string, required): End time (RFC3339)
- `limit` (number, default: 20): Max results (1-100)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### State Count Tools

#### equip_state_counts_factory
Get aggregated equipment state counts for a factory.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_state_counts_line
Get aggregated equipment state counts for a production line.

**Parameters:**
- `line_uuid` (string, required): Line UUID
- `response_format` ('markdown'|'json', default: 'markdown')

---

## Usage Examples

### Workflow: Monitor factory equipment

```
# 1. Get factory-level state overview
equip_state_counts_factory(factory_uuid: "factory-uuid")

# 2. Drill into a specific line
equip_state_counts_line(line_uuid: "line-uuid")

# 3. Check real-time status of machines
equip_machine_status_realtime_batch(device_uuids: "device-1,device-2,device-3")
```

### Workflow: Investigate alarms

```
# 1. List recent alarms (device_uuid, start_time, end_time all required)
equip_alarm_list(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-08T23:59:59Z")

# 2. Check idle time for a problematic device
equip_idle_list(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-08T23:59:59Z")

# 3. Get part count data for the period
equip_machine_status_part_counts(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-08T23:59:59Z")
```

## Error Handling

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |

## MCP Server

- **Package**: `@dotzero.ai/equipment-mcp`
- **Tools**: 12 (all require authentication; call `auth_login` first)

## Repository

https://github.com/dotzero-ai/dz-ai
