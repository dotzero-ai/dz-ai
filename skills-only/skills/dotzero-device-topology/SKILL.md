---
name: dotzero-device-topology
description: DotZero 設備拓撲（群組 / 工廠 / 產線 / 設備階層、警報代碼）。Use when 使用者要看廠區與產線階層、找某台機的 device UUID、查警報代碼定義（factory line device hierarchy, device uuid, alarm code）。MCP 工具可用時直接叫工具（topo_*）；本 skill 只給路由與已知陷阱。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero Device Topology

Manage factory device topology — groups, factories, lines, devices, plant floors, alarms, and alarm codes. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Log in first via `dotzero-auth` (MCP `auth_login`, or the terminal fallback described there)
2. Credentials live in `.dotzero/credentials.json` — the project's `.dotzero/` if it exists, otherwise `~/.dotzero/` (same lookup as the MCP servers)
3. `config.json` is optional — without it the production URL below is used

## Read Config and Token

每次 Bash 呼叫都是新的 shell：這三行要跟後面的 curl 放在**同一個指令**裡。

```bash
DZ=$([ -d .dotzero ] && echo .dotzero || echo "$HOME/.dotzero")
API_URL=$(jq -r '.device_topology_api_url // empty' "$DZ/config.json" 2>/dev/null); API_URL=${API_URL:-https://dotzerotech-device-topology.dotzero.app}
TOKEN=$(jq -r .token "$DZ/credentials.json")
```

回 401 = token 過期：照 `dotzero-auth` 的「Manual Token Refresh」換新後重試；refresh 也失敗就重新登入。

## 階層結構 (Hierarchy)

```
Group (群組)
  └── Factory (工廠)
        └── Line (產線)
              └── Device (設備)
```

**重要**:
- 此 API 使用 **PUT** 進行更新操作（非 PATCH），且 PUT 為**整筆取代**（full replace）——必填欄位一律要帶（factory 需 `groupUuid`、line 需 `factoryUuid`、name 必填）。唯一例外:plant floor 名稱用 `PATCH /v1/plantFloors/{uuid}/name`。
- **collection 路徑務必帶結尾斜線**(`/v1/groups/`、`/v1/factories/` …)。後端 echo v3 無 trailing-slash redirect,少斜線直接 404。單筆資源路徑 `/v1/groups/{uuid}` 不受影響。
- **分頁無效**:後端不讀 `limit`/`offset`,list 一律回該 tenant/過濾條件下的全部資料。factories / lines / devices / alarmCodes 一律帶父層 UUID 縮小範圍,不要撈全部;逾時或 5xx 不要重送同一個請求(伺服器可能還在處理),改縮小範圍。

---

## Group Operations

### List Groups

```bash
curl -s "${API_URL}/v1/groups/" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Group

```bash
curl -s "${API_URL}/v1/groups/${GROUP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Group

```bash
curl -s -X POST "${API_URL}/v1/groups/" \
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

`groupUUID` is **required** (backend errors "The groupUUID is not given." without it). Get group UUIDs from List Groups.

```bash
curl -s "${API_URL}/v1/factories/?groupUUID=${GROUP_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Factory

`groupUuid` is **required** and must reference an existing group.

```bash
curl -s -X POST "${API_URL}/v1/factories/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Taoyuan Factory", "groupUuid": "'"${GROUP_UUID}"'"}'
```

### Update Factory

PUT is a full replace — `name` and `groupUuid` are both required.

```bash
curl -s -X PUT "${API_URL}/v1/factories/${FACTORY_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Taoyuan Factory A", "groupUuid": "'"${GROUP_UUID}"'"}'
```

---

## Line Operations

### List Lines

`factoryUUID` is **required**. Get factory UUIDs from List Factories.

```bash
curl -s "${API_URL}/v1/lines/?factoryUUID=${FACTORY_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Line

Body key is `factoryUuid` (camelCase, matching the JSON schema). The query param on list is `factoryUUID`.

```bash
curl -s -X POST "${API_URL}/v1/lines/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Line A1", "factoryUuid": "factory-uuid"}'
```

---

## Device Operations

### List Devices

`lineUUID` is **required**. Get line UUIDs from List Lines; to find one device by name, use `GET /v1/topology/search/device?name=`.

```bash
curl -s "${API_URL}/v1/devices/?lineUUID=${LINE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Device

Body key is `lineUuid` (camelCase). The query param on list is `lineUUID`.

```bash
curl -s -X POST "${API_URL}/v1/devices/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "CNC-001", "lineUuid": "line-uuid"}'
```

---

## Topology Operations

### Get Topology Count

All zeros can also mean the account lacks topology read permission: this endpoint still answers 200 with zeros, while the other topology endpoints return 401.

```bash
curl -s "${API_URL}/v1/topology/count" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Full Topology

Returns the whole tenant's tree (every group, factory, line and device): use it only when the user explicitly asks for the whole topology.

```bash
curl -s "${API_URL}/v1/topology/all" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Alarm Operations

> An **alarm** is a named **group** (tenant-wide container), not a per-device record. Alarm codes belong to an alarm group via `alarmUuid`.

### List Alarms (groups)

```bash
curl -s "${API_URL}/v1/alarms/" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Alarm (group)

```bash
curl -s -X POST "${API_URL}/v1/alarms/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Spindle Alarms"}'   # name required, 1-20 chars, unique per tenant
```

### List Alarm Codes

`alarmUUID` is **required** (backend errors "The alarmUUID is not given." without it).

```bash
curl -s "${API_URL}/v1/alarmCodes/?alarmUUID=${ALARM_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Alarm Code

`code` is an **integer**; `alarmUuid` is **required**. There is no `name` field.

```bash
curl -s -X POST "${API_URL}/v1/alarmCodes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"code": 1001, "alarmUuid": "'"${ALARM_UUID}"'", "category": "Controller", "level": 2, "messageEn": "Emergency Stop", "messageTc": "緊急停止"}'
```

### Batch Add/Remove Alarm Codes

`POST /v1/alarmCodes/batch` **adds and deletes** (it does NOT update). Body is `{add:[...], remove:[...]}` — both keys required (send `[]` for the unused side). Add items need `code`+`alarmUuid`; remove items are matched by `uuid`.

```bash
curl -s -X POST "${API_URL}/v1/alarmCodes/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"add": [{"code": 1001, "alarmUuid": "'"${ALARM_UUID}"'", "messageEn": "Emergency Stop"}], "remove": [{"uuid": "'"${OLD_ALARM_CODE_UUID}"'"}]}'
```

---

## Quick Reference

### Groups & Factories

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List groups | GET | `/v1/groups/` |
| Get group | GET | `/v1/groups/{uuid}` |
| Create group | POST | `/v1/groups/` |
| Update group | PUT | `/v1/groups/{uuid}` |
| Delete group | DELETE | `/v1/groups/{uuid}` |
| List factories (needs `?groupUUID=`) | GET | `/v1/factories/` |
| List all factories (whole tenant; only when the user explicitly asks for everything) | GET | `/v1/factories/all` |
| Get factory | GET | `/v1/factories/{uuid}` |
| Create factory | POST | `/v1/factories/` |
| Update factory | PUT | `/v1/factories/{uuid}` |
| Delete factory | DELETE | `/v1/factories/{uuid}` |

### Lines & Devices

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List lines (needs `?factoryUUID=`) | GET | `/v1/lines/` |
| List all lines (whole tenant; only when the user explicitly asks for everything) | GET | `/v1/lines/all` |
| Get line | GET | `/v1/lines/{uuid}` |
| Create line | POST | `/v1/lines/` |
| Update line | PUT | `/v1/lines/{uuid}` |
| Delete line | DELETE | `/v1/lines/{uuid}` |
| List devices (needs `?lineUUID=`) | GET | `/v1/devices/` |
| List all devices (whole tenant; only when the user explicitly asks for everything) | GET | `/v1/devices/all` |
| Device count under node | GET | `/v1/devices/count?type=&uuid=` |
| Get device | GET | `/v1/devices/{uuid}` |
| Create device | POST | `/v1/devices/` |
| Update device | PUT | `/v1/devices/{uuid}` |
| Delete device | DELETE | `/v1/devices/{uuid}` |

### Topology & Plant Floors

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Topology count | GET | `/v1/topology/count` |
| Topology all (whole tenant; only when the user explicitly asks for everything) | GET | `/v1/topology/all` |
| Search device by name | GET | `/v1/topology/search/device?name=` |
| List plant floors | GET | `/v1/plantFloors/` (opt. `?topologyType=&topologyUuid=`) |
| Get plant floor | GET | `/v1/plantFloors/{uuid}` |
| Create plant floor (body `{canvas, intervalTime?}`) | POST | `/v1/plantFloors/` |
| Update plant floor | PUT | `/v1/plantFloors/{uuid}` |
| Set plant floor name | PATCH | `/v1/plantFloors/{uuid}/name` |
| Delete plant floor | DELETE | `/v1/plantFloors/{uuid}` |

### Alarms & Alarm Codes

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List alarm groups | GET | `/v1/alarms/` |
| Get alarm group | GET | `/v1/alarms/{uuid}` |
| Create alarm group | POST | `/v1/alarms/` |
| Create alarm group + codes | POST | `/v1/alarms/withAlarmCodes` |
| Update alarm group | PUT | `/v1/alarms/{uuid}` |
| Delete alarm group | DELETE | `/v1/alarms/{uuid}` |
| List alarm codes (needs `?alarmUUID=`) | GET | `/v1/alarmCodes/` |
| Get alarm code | GET | `/v1/alarmCodes/{uuid}` |
| Create alarm code | POST | `/v1/alarmCodes/` |
| Update alarm code | PUT | `/v1/alarmCodes/{uuid}` |
| Delete alarm code | DELETE | `/v1/alarmCodes/{uuid}` |
| Batch add/remove alarm codes | POST | `/v1/alarmCodes/batch` |

---

## Error Handling

此 API 幾乎所有錯誤都回 **HTTP 500 + 純文字訊息**(含「找不到資源」與「驗證失敗」)。只有認證失敗回 401。

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token 過期/無效 | Refresh token 或重新登入 |
| 500 + 文字訊息 | 驗證失敗、缺必填 query 參數、或資源不存在 | 讀訊息本文(如 "The groupUUID is not given."、"invalid groupUuid") |
| 逾時 / 其他 5xx | 伺服器忙或仍在處理 | 不要重送同一個請求;帶父層 UUID 縮小範圍 |
