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

Equipment API is publicly accessible but authentication is supported for tenant-specific data.

```
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `EQUIPMENT_API_URL` | Yes | Base URL of the Equipment API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Tools Reference

### Authentication Tools

#### auth_login
Authenticate with email, password, and tenant_id.

**Parameters:**
- `email` (string, required): User email address
- `password` (string, required): User password
- `tenant_id` (string, required): Tenant ID

#### auth_status
Check if the client is authenticated.

**Parameters:** None

---

### Alarm Tools

#### equip_alarm_list
List equipment alarm records.

**Parameters:**
- `device_uuid` (string, optional): Filter by device UUID
- `alarm_code` (string, optional): Filter by alarm code
- `start_time` (string, optional): Start time filter (ISO 8601)
- `end_time` (string, optional): End time filter (ISO 8601)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Idle Tools

#### equip_idle_list
List equipment idle time records.

**Parameters:**
- `device_uuid` (string, optional): Filter by device UUID
- `start_time` (string, optional): Start time filter (ISO 8601)
- `end_time` (string, optional): End time filter (ISO 8601)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Machine Status Tools

#### equip_machine_status_history
Get machine status history.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, optional): Start time (ISO 8601)
- `end_time` (string, optional): End time (ISO 8601)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_part_counts
Get part count data for a device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, optional): Start time (ISO 8601)
- `end_time` (string, optional): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_part_counts_batch
Get part counts for multiple devices in one call.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, optional): Start time (ISO 8601)
- `end_time` (string, optional): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_realtime
Get real-time machine status for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### equip_realtime_batch
Get real-time machine status for multiple devices.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Off Time Tools

#### equip_off_time_list
List equipment off-time records.

**Parameters:**
- `device_uuid` (string, optional): Filter by device UUID
- `start_time` (string, optional): Start time (ISO 8601)
- `end_time` (string, optional): End time (ISO 8601)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
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
equip_realtime_batch(device_uuids: ["device-1", "device-2", "device-3"])
```

### Workflow: Investigate alarms

```
# 1. List recent alarms
equip_alarm_list(start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-08T23:59:59Z")

# 2. Check idle time for a problematic device
equip_idle_list(device_uuid: "device-uuid")

# 3. Get part count data for the period
equip_part_counts(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-08T23:59:59Z")
```

## Error Handling

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |

## MCP Server

- **Package**: `@dotzero.ai/equipment-mcp`
- **Tools**: 12 (all public, no auth gating)

## Repository

https://gitlab.com/dotzero/dz-ai
