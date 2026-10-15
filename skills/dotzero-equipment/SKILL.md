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

1. Log in first via `dotzero-auth` (MCP `auth_login`, or the terminal fallback described there)
2. Credentials live in `.dotzero/credentials.json` — the project's `.dotzero/` if it exists, otherwise `~/.dotzero/` (same lookup as the MCP servers)
3. `config.json` is optional — without it the production URL below is used

## Read Config and Token

每次 Bash 呼叫都是新的 shell：這三行要跟後面的 curl 放在**同一個指令**裡。

```bash
DZ=$([ -d .dotzero ] && echo .dotzero || echo "$HOME/.dotzero")
API_URL=$(jq -r '.equipment_api_url // empty' "$DZ/config.json" 2>/dev/null); API_URL=${API_URL:-https://dotzerotech-equipment-api.dotzero.app}
TOKEN=$(jq -r .token "$DZ/credentials.json")
```

回 401 = token 過期：照 `dotzero-auth` 的「Manual Token Refresh」換新後重試；refresh 也失敗就重新登入。

alarms / idles / offTime / partCounts 一律帶設備 `uuid` 與時間區間（RFC3339 帶時區偏移，query string 裡 `+` 寫成 `%2B`；上限見各節），不要不帶區間呼叫；逾時或 5xx 不要重送同一個請求（伺服器可能還在跑那個查詢），改縮短區間。

---

## Alarm Operations

### List Alarms

```bash
curl -s "${API_URL}/alarms?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00%2B08:00&end=2026-02-08T00:00:00%2B08:00" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 with offset for times): `uuid`, `start`, `end`. `start` before `end`, at most 31 days. No paging: the whole period comes back in one response.

---

## Idle Time Operations

### List Idle Records

```bash
curl -s "${API_URL}/idles?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00%2B08:00&end=2026-02-08T00:00:00%2B08:00" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 with offset for times): `uuid`, `start`, `end`. `start` before `end`, at most 31 days. No paging: the whole period comes back in one response.

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
curl -s "${API_URL}/machineStatus/partCounts?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00%2B08:00&end=2026-02-08T00:00:00%2B08:00" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 with offset for times): `uuid`, `start`, `end`. `start` before `end`, at most 7 days: the backend reads every status row of the period.

### Get Part Counts Batch

Body is a bare JSON array; one `{uuid, start, end}` object per device. Keep it short — at most 10 devices (e.g. one line's devices), never every device in the tenant — with the same ≤ 7-day period; the backend computes the devices one after another.

```bash
curl -s -X POST "${API_URL}/machineStatus/partCounts/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[{"uuid":"dev-1","start":"2026-02-01T00:00:00+08:00","end":"2026-02-08T00:00:00+08:00"},{"uuid":"dev-2","start":"2026-02-01T00:00:00+08:00","end":"2026-02-08T00:00:00+08:00"}]'
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
curl -s "${API_URL}/offTime?uuid=${DEVICE_UUID}&start=2026-02-01T00:00:00%2B08:00&end=2026-02-08T00:00:00%2B08:00" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** (all required, RFC3339 with offset for times): `uuid`, `start`, `end`. `start` before `end`, at most 31 days. No paging: the whole period comes back in one response.

---

## State Count Operations

No time parameters: both report how many devices are offline / running / idle / in alarm right now, by each device's latest status.

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
| Timeout / 5xx | Query too large; the server may still be running it | Do not resend the same request; narrow the period |
