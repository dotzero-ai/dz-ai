---
name: dotzero-device-topology
description: DotZero 設備拓撲管理。群組、工廠、產線、設備的階層結構，警報與警報代碼管理。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero Device Topology

Manage factory device topology — groups, factories, lines, devices, plant floors, alarms, and alarm codes. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `device_topology_api_url` set

## Setup

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "device_topology_api_url": "https://dotzerotech-device-topology.dotzero.app"
# }
```

## Read Config and Token

```bash
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.device_topology_api_url')
TOKEN=$(get_valid_token)
```

## 階層結構 (Hierarchy)

```
Group (群組)
  └── Factory (工廠)
        └── Line (產線)
              └── Device (設備)
```

**重要**: 此 API 使用 **PUT** 進行更新操作（非 PATCH）。

---

## Group Operations

### List Groups

```bash
curl -s "${API_URL}/v1/groups?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Group

```bash
curl -s "${API_URL}/v1/groups/${GROUP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Group

```bash
curl -s -X POST "${API_URL}/v1/groups" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Asia Pacific"}'
```

### Update Group

```bash
curl -s -X PUT "${API_URL}/v1/groups/${GROUP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Asia Pacific (Updated)"}'
```

### Delete Group

```bash
curl -s -X DELETE "${API_URL}/v1/groups/${GROUP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Factory Operations

### List Factories

```bash
curl -s "${API_URL}/v1/factories?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Factory

```bash
curl -s -X POST "${API_URL}/v1/factories" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Taoyuan Factory"}'
```

### Update Factory

```bash
curl -s -X PUT "${API_URL}/v1/factories/${FACTORY_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Taoyuan Factory A"}'
```

---

## Line Operations

### List Lines

```bash
curl -s "${API_URL}/v1/lines?factoryUUID=${FACTORY_UUID}&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Line

```bash
curl -s -X POST "${API_URL}/v1/lines" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Line A1", "factoryUUID": "factory-uuid"}'
```

---

## Device Operations

### List Devices

```bash
curl -s "${API_URL}/v1/devices?lineUUID=${LINE_UUID}&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Device

```bash
curl -s -X POST "${API_URL}/v1/devices" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "CNC-001", "lineUUID": "line-uuid"}'
```

---

## Topology Operations

### Get Topology Count

```bash
curl -s "${API_URL}/v1/topology/count" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Full Topology

```bash
curl -s "${API_URL}/v1/topology/all" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Alarm Operations

### List Alarms

```bash
curl -s "${API_URL}/v1/alarms?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Alarm Codes

```bash
curl -s "${API_URL}/v1/alarmCodes?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Batch Create Alarm Codes

```bash
curl -s -X POST "${API_URL}/v1/alarmCodes/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[{"code": "E001", "name": "Emergency Stop"}, {"code": "E002", "name": "Overtemp"}]'
```

---

## Quick Reference

### Groups & Factories

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List groups | GET | `/v1/groups` |
| Get group | GET | `/v1/groups/{uuid}` |
| Create group | POST | `/v1/groups` |
| Update group | PUT | `/v1/groups/{uuid}` |
| Delete group | DELETE | `/v1/groups/{uuid}` |
| List factories | GET | `/v1/factories` |
| Get factory | GET | `/v1/factories/{uuid}` |
| Create factory | POST | `/v1/factories` |
| Update factory | PUT | `/v1/factories/{uuid}` |
| Delete factory | DELETE | `/v1/factories/{uuid}` |

### Lines & Devices

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List lines | GET | `/v1/lines` |
| Get line | GET | `/v1/lines/{uuid}` |
| Create line | POST | `/v1/lines` |
| Update line | PUT | `/v1/lines/{uuid}` |
| Delete line | DELETE | `/v1/lines/{uuid}` |
| List devices | GET | `/v1/devices` |
| Get device | GET | `/v1/devices/{uuid}` |
| Create device | POST | `/v1/devices` |
| Update device | PUT | `/v1/devices/{uuid}` |
| Delete device | DELETE | `/v1/devices/{uuid}` |

### Topology & Plant Floors

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Topology count | GET | `/v1/topology/count` |
| Topology all | GET | `/v1/topology/all` |
| Get plant floor | GET | `/v1/plantFloors/{uuid}` |
| Create plant floor | POST | `/v1/plantFloors` |
| Update plant floor | PUT | `/v1/plantFloors/{uuid}` |
| Delete plant floor | DELETE | `/v1/plantFloors/{uuid}` |

### Alarms & Alarm Codes

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List alarms | GET | `/v1/alarms` |
| Get alarm | GET | `/v1/alarms/{uuid}` |
| Create alarm | POST | `/v1/alarms` |
| Update alarm | PUT | `/v1/alarms/{uuid}` |
| Delete alarm | DELETE | `/v1/alarms/{uuid}` |
| List alarm codes | GET | `/v1/alarmCodes` |
| Get alarm code | GET | `/v1/alarmCodes/{uuid}` |
| Create alarm code | POST | `/v1/alarmCodes` |
| Update alarm code | PUT | `/v1/alarmCodes/{uuid}` |
| Delete alarm code | DELETE | `/v1/alarmCodes/{uuid}` |
| Batch alarm codes | POST | `/v1/alarmCodes/batch` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 404 | Resource not found | Verify UUID |
| 422 | Validation error | Check input parameters |
