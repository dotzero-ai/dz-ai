---
name: dotzero-equipment
description: DotZero 設備監控。即時機台狀態、警報紀錄、閒置時間、產出數量、工廠/產線設備狀態統計。
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
API_URL=$(echo "$CONFIG" | jq -r '.equipment_api_url')
TOKEN=$(get_valid_token)
```

---

## Alarm Operations

### List Alarms

```bash
curl -s "${API_URL}/alarms?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**: `deviceUUID`, `alarmCode`, `startTime`, `endTime`, `limit`, `start`

---

## Idle Time Operations

### List Idle Records

```bash
curl -s "${API_URL}/idles?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**: `deviceUUID`, `startTime`, `endTime`, `limit`, `start`

---

## Machine Status Operations

### Get Status History

```bash
curl -s "${API_URL}/machineStatus/history?deviceUUID=${DEVICE_UUID}&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Part Counts

```bash
curl -s "${API_URL}/machineStatus/partCounts?deviceUUID=${DEVICE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**: `deviceUUID` (required), `startTime`, `endTime`

### Get Part Counts Batch

```bash
curl -s -X POST "${API_URL}/machineStatus/partCounts/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"deviceUUIDs": ["dev-1", "dev-2", "dev-3"]}'
```

### Get Real-Time Status

```bash
curl -s "${API_URL}/machineStatus/realTime?deviceUUID=${DEVICE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Real-Time Batch

```bash
curl -s "${API_URL}/machineStatus/realTime/batch?deviceUUIDs=${UUID1},${UUID2}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Off Time Operations

### List Off Time

```bash
curl -s "${API_URL}/offTime?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**: `deviceUUID`, `startTime`, `endTime`, `limit`, `start`

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
