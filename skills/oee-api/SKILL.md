# OEE API Skill

MCP skill for Overall Equipment Effectiveness (OEE) — availability, quality, performance, and combined OEE metrics at device, line, and factory levels.

## Overview

This skill provides 20 tools for interacting with the OEE API:

- **Authentication** (2): Login and check auth status
- **Availability** (4): Device, multi-device, line, and factory availability
- **Quality** (4): Device, multi-device, line, and factory quality rates
- **Performance** (5): Device, multi-device, line, factory performance, and device range analysis
- **OEE** (4): Combined OEE at device, multi-device, line, and factory levels
- **Status** (1): Current device OEE status
- **Alarm History** (1): OEE-related alarm history

## Prerequisites

### Authentication Required

Before using most tools, you need to authenticate. The `tenant_id` is required.

**IMPORTANT**: If you don't know the user's tenant_id, you must ask them for it.

```
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OEE_API_URL` | Yes | Base URL of the OEE API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## OEE Formula

```
OEE = Availability x Quality x Performance

Availability = (Planned Time - Downtime) / Planned Time
Quality     = Good Parts / Total Parts
Performance = (Total Parts x Ideal Cycle Time) / Operating Time
```

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

---

### Availability Tools

#### oee_availability_device
Get availability for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_availability_devices
Get availability for multiple devices.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_availability_line
Get availability for a production line.

**Parameters:**
- `line_uuid` (string, required): Line UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_availability_factory
Get availability for a factory.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Quality Tools

#### oee_quality_device
Get quality rate for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_quality_devices
Get quality rate for multiple devices.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_quality_line
Get quality rate for a production line.

**Parameters:**
- `line_uuid` (string, required): Line UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_quality_factory
Get quality rate for a factory.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Performance Tools

#### oee_performance_device
Get performance for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_performance_devices
Get performance for multiple devices.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_performance_line
Get performance for a production line.

**Parameters:**
- `line_uuid` (string, required): Line UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_performance_factory
Get performance for a factory.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_performance_device_range
Get performance trend for a device over a time range (daily breakdown).

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### OEE Tools (Combined)

#### oee_device
Get combined OEE (Availability x Quality x Performance) for a single device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_devices
Get combined OEE for multiple devices.

**Parameters:**
- `device_uuids` (array, required): Array of device UUIDs
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_line
Get combined OEE for a production line.

**Parameters:**
- `line_uuid` (string, required): Line UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

#### oee_factory
Get combined OEE for a factory.

**Parameters:**
- `factory_uuid` (string, required): Factory UUID
- `start_time` (string, required): Start time (ISO 8601)
- `end_time` (string, required): End time (ISO 8601)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Status Tools

#### oee_device_status
Get current OEE status for a device.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Alarm History Tools

#### oee_alarm_history
Get OEE-related alarm history.

**Parameters:**
- `device_uuid` (string, optional): Filter by device UUID
- `start_time` (string, optional): Start time (ISO 8601)
- `end_time` (string, optional): End time (ISO 8601)
- `alarm_code` (string, optional): Filter by alarm code
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

---

## Usage Examples

### Workflow: Check factory OEE

```
# 1. Get overall factory OEE
oee_factory(factory_uuid: "factory-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")

# 2. Drill down to lines
oee_line(line_uuid: "line-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")

# 3. Identify low-performing devices
oee_devices(device_uuids: ["dev-1", "dev-2", "dev-3"], start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")
```

### Workflow: Analyze availability issues

```
# 1. Check availability
oee_availability_device(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")

# 2. Check alarm history for root cause
oee_alarm_history(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")

# 3. Get performance trend
oee_performance_device_range(device_uuid: "device-uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")
```

## Error Handling

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check time range parameters |

## MCP Server

- **Package**: `@dotzero.ai/oee-mcp`
- **Tools**: 20 (6 basic + 14 advanced, unlocked after auth)

## Repository

https://gitlab.com/dotzero/dz-ai
