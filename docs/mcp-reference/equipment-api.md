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
List one device's alarms that overlap the period, newest first. The API returns the whole period in one response; `limit`/`offset` page through it client-side (`has_more` / `next_offset`). Each page re-runs the whole query, so prefer a shorter period over paging.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339 with offset); before `end_time`, at most 31 days
- `end_time` (string, required): End time (RFC3339 with offset)
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Idle Tools

#### equip_idle_list
List one device's idle periods that overlap the period, newest first. Paged client-side like `equip_alarm_list`.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339 with offset); before `end_time`, at most 31 days
- `end_time` (string, required): End time (RFC3339 with offset)
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
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
Get how many parts a device produced in a period: the sum and the part-count readings it is computed from. The API reads every status row of the period, so the period may span at most 7 days.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339 with offset); before `end_time`, at most 7 days
- `end_time` (string, required): End time (RFC3339 with offset)
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_machine_status_part_counts_batch
Get how many parts each of several devices produced in the same period; results come back in the order of `device_uuids`. The API computes the devices one after another, so cost grows with devices × days.

**Parameters:**
- `device_uuids` (array, required): 1-10 device UUIDs. Keep the list short (one line's devices); never every device in the tenant
- `start_time` (string, required): Start time (RFC3339 with offset), applied to all devices; before `end_time`, at most 7 days
- `end_time` (string, required): End time (RFC3339 with offset), applied to all devices
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
List one device's off-time periods that overlap the period, newest first. Paged client-side like `equip_alarm_list`.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (RFC3339 with offset); before `end_time`, at most 31 days
- `end_time` (string, required): End time (RFC3339 with offset)
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### State Count Tools

#### equip_state_counts_factory
Get how many devices in a factory are offline, running, idle and in alarm right now (each device counted once, by its latest status). No time range.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_state_counts_line
Get how many devices in a production line are offline, running, idle and in alarm right now (each device counted once, by its latest status). No time range.

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
equip_alarm_list(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00+08:00", end_time: "2026-02-08T00:00:00+08:00")

# 2. Check idle time for a problematic device
equip_idle_list(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00+08:00", end_time: "2026-02-08T00:00:00+08:00")

# 3. Get part count data for the period
equip_machine_status_part_counts(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00+08:00", end_time: "2026-02-08T00:00:00+08:00")
```

## Error Handling

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |
| Timeout / 5xx | The server may still be computing: do not resend the same call; narrow the period. After a timeout or 504 the identical request is refused for 120 s (`Not sent: the same request timed out N s ago…`) |

## MCP Server

- **Package**: `@dotzero.ai/equipment-mcp`
- **Tools**: 12 (all require authentication; call `auth_login` first)

## Repository

https://github.com/dotzero-ai/dz-ai
