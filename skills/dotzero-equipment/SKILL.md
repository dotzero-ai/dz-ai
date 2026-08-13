---
name: dotzero-equipment
description: DotZero 設備監控（即時狀態、警報、閒置、產出數）。Use when 使用者問某台機現在在跑還是停、最近有哪些告警、閒置多久、做了幾件（machine status, alarm history, idle time, part count）。MCP 工具可用時直接叫工具（equip_*）；本 skill 只給路由與已知陷阱。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero Equipment Monitoring

Monitor equipment status, alarms, idle time, part counts, and state aggregations. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `equipment_api_url` set

## Setup

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "equipment_api_url": "https://dotzerotech-equipment-api.dotzero.app"
# }
```

## Read Config and Token

```bash
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.equipment_api_url // "https://dotzerotech-equipment-api.dotzero.app"')
TOKEN=$(get_valid_token)
```

---

## Alarm Operations

### List Alarms

```bash
curl -s "${API_URL}/alarms?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00Z&end=2026-02-08T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 for times): `uuid`, `start`, `end`

---

## Idle Time Operations

### List Idle Records

```bash
curl -s "${API_URL}/idles?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00Z&end=2026-02-08T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 for times): `uuid`, `start`, `end`

---

## Machine Status Operations

### Get Status History (point-in-time)

Returns the single latest status record at or before the given `time`.

```bash
curl -s "${API_URL}/machineStatus/history?uuid=${DEVICE_UUID}&time=2026-02-08T12:00:00Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (both required): `uuid`, `time` (RFC3339). Returns a single object, not a list.

### Get Part Counts

```bash
curl -s "${API_URL}/machineStatus/partCounts?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00Z&end=2026-02-08T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 for times): `uuid`, `start`, `end`

### Get Part Counts Batch

Body is a bare JSON array; one `{uuid, start, end}` object per device.

```bash
curl -s -X POST "${API_URL}/machineStatus/partCounts/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[{"uuid":"dev-1","start":"2026-02-01T00:00:00Z","end":"2026-02-08T23:59:59Z"},{"uuid":"dev-2","start":"2026-02-01T00:00:00Z","end":"2026-02-08T23:59:59Z"}]'
```

### Get Real-Time Status

```bash
curl -s "${API_URL}/machineStatus/realTime?uuid=${DEVICE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**: `uuid` (or `name`) — identifies the device. Omitting both returns every device in the tenant.

### Get Real-Time Batch

```bash
curl -s "${API_URL}/machineStatus/realTime/batch?uuids=${UUID1},${UUID2}" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (required): `uuids` — comma-separated device UUIDs.

---

## Off Time Operations

### List Off Time

```bash
curl -s "${API_URL}/offTime?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00Z&end=2026-02-08T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 for times): `uuid`, `start`, `end`

---

## State Count Operations

### Factory State Counts

```bash
curl -s "${API_URL}/stateCounts/factory/${FACTORY_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line State Counts

```bash
curl -s "${API_URL}/stateCounts/line/${LINE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List alarms | GET | `/alarms` |
| List idles | GET | `/idles` |
| Machine status history | GET | `/machineStatus/history` |
| Part counts (single) | GET | `/machineStatus/partCounts` |
| Part counts (batch) | POST | `/machineStatus/partCounts/batch` |
| Real-time status | GET | `/machineStatus/realTime` |
| Real-time batch | GET | `/machineStatus/realTime/batch` |
| Off time | GET | `/offTime` |
| State counts (factory) | GET | `/stateCounts/factory/{factoryUUID}` |
| State counts (line) | GET | `/stateCounts/line/{lineUUID}` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 404 | Resource not found | Verify UUID |
| 422 | Validation error | Check input parameters |
