---
name: dotzero-oee
description: DotZero OEE 分析（設備 / 產線 / 工廠的可用率、表現率、良率、綜合 OEE）。Use when 使用者問 OEE / 稼動率為何偏低、要三率拆解或比較機台與產線（oee, availability, performance, quality rate）。MCP 工具可用時直接叫工具（oee_*）；本 skill 只給路由與已知陷阱。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero OEE (Overall Equipment Effectiveness)

Calculate and analyze OEE metrics — availability, quality, performance — at device, line, and factory levels. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `oee_api_url` set

## Setup

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "oee_api_url": "https://dotzerotech-oee-api.dotzero.app"
# }
```

## Read Config and Token

```bash
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.oee_api_url // "https://dotzerotech-oee-api.dotzero.app"')
TOKEN=$(get_valid_token)
```

## OEE 公式

```
OEE = 可用率 (Availability) x 品質率 (Quality) x 稼動率 (Performance)

可用率 = (計畫時間 - 停機時間) / 計畫時間
品質率 = 良品數 / 總產出數
稼動率 = (總產出數 x 理想週期時間) / 運轉時間
```

## 共用時間參數

所有帶時間區間的端點都使用 query 參數 `from` 與 `to`（**必填**，RFC3339 格式，如 `2026-02-01T00:00:00Z`）。缺少或格式錯誤會回 500 `From time cannot be parsed.`。

---

## Availability Operations

### Device Availability

```bash
curl -s "${API_URL}/availability/device/${DEVICE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device Availability

單數 `/device` 路徑（無 path 參數），`deviceUUID` query 參數用逗號分隔多個 UUID：

```bash
curl -s "${API_URL}/availability/device?deviceUUID=${UUID1},${UUID2}&from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Device Availability Range (Daily Trend)

```bash
curl -s "${API_URL}/availability/device/${DEVICE_UUID}/range?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Availability

```bash
curl -s "${API_URL}/availability/line/${LINE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Availability

```bash
curl -s "${API_URL}/availability/factory/${FACTORY_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quality Operations

### Device Quality

```bash
curl -s "${API_URL}/quality/device/${DEVICE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device Quality

```bash
curl -s "${API_URL}/quality/device?deviceUUID=${UUID1},${UUID2}&from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Device Quality Range (Daily Trend)

```bash
curl -s "${API_URL}/quality/device/${DEVICE_UUID}/range?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Quality

```bash
curl -s "${API_URL}/quality/line/${LINE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Quality

```bash
curl -s "${API_URL}/quality/factory/${FACTORY_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Performance Operations

### Device Performance

```bash
curl -s "${API_URL}/performance/device/${DEVICE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device Performance

```bash
curl -s "${API_URL}/performance/device?deviceUUID=${UUID1},${UUID2}&from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Device Performance Range (Daily Trend)

```bash
curl -s "${API_URL}/performance/device/${DEVICE_UUID}/range?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Performance

```bash
curl -s "${API_URL}/performance/line/${LINE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Performance

```bash
curl -s "${API_URL}/performance/factory/${FACTORY_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

**選填參數** `onlyCalculateHasDoneWooh=true`：只計算已完工工單（適用 multi-device / line / factory performance 與 OEE 端點）。

---

## OEE Operations (Combined)

### Device OEE

```bash
curl -s "${API_URL}/oee/device/${DEVICE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device OEE

```bash
curl -s "${API_URL}/oee/device?deviceUUID=${UUID1},${UUID2}&from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line OEE

```bash
curl -s "${API_URL}/oee/line/${LINE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory OEE

```bash
curl -s "${API_URL}/oee/factory/${FACTORY_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Status & Alarm Operations

### Device Status

```bash
curl -s "${API_URL}/status/device/${DEVICE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Alarm History

回傳指定時間區間內該設備的完整警報陣列（無分頁、無 `limit`/`alarmCode` 過濾）：

```bash
curl -s "${API_URL}/alarmCode/history/device/${DEVICE_UUID}?from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Tag Statistics

查任意 tag 數值統計（如耗電量、產量計數）。`tagName` 與 `type` 必填，`type` 目前僅支援 `sum`，回傳 `{"value": <number>}`（四捨五入至小數 2 位）：

```bash
curl -s "${API_URL}/tagStatus/device/${DEVICE_UUID}?tagName=${TAG_NAME}&type=sum&from=2026-02-01T00:00:00Z&to=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quick Reference

### Availability

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device availability | GET | `/availability/device/{deviceUUID}` |
| Multi-device availability | GET | `/availability/device?deviceUUID=a,b` |
| Device daily trend | GET | `/availability/device/{deviceUUID}/range` |
| Line availability | GET | `/availability/line/{lineUUID}` |
| Factory availability | GET | `/availability/factory/{factoryUUID}` |

### Quality

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device quality | GET | `/quality/device/{deviceUUID}` |
| Multi-device quality | GET | `/quality/device?deviceUUID=a,b` |
| Device daily trend | GET | `/quality/device/{deviceUUID}/range` |
| Line quality | GET | `/quality/line/{lineUUID}` |
| Factory quality | GET | `/quality/factory/{factoryUUID}` |

### Performance

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device performance | GET | `/performance/device/{deviceUUID}` |
| Multi-device performance | GET | `/performance/device?deviceUUID=a,b` |
| Device daily trend | GET | `/performance/device/{deviceUUID}/range` |
| Line performance | GET | `/performance/line/{lineUUID}` |
| Factory performance | GET | `/performance/factory/{factoryUUID}` |

### OEE (Combined)

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device OEE | GET | `/oee/device/{deviceUUID}` |
| Multi-device OEE | GET | `/oee/device?deviceUUID=a,b` |
| Line OEE | GET | `/oee/line/{lineUUID}` |
| Factory OEE | GET | `/oee/factory/{factoryUUID}` |

### Status, Alarms & Tags

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device status | GET | `/status/device/{deviceUUID}` |
| Alarm history | GET | `/alarmCode/history/device/{deviceUUID}` |
| Tag statistics (sum) | GET | `/tagStatus/device/{deviceUUID}?tagName=...&type=sum` |

**共用查詢參數**: `from`, `to`（RFC3339，必填）；多設備查詢用 `deviceUUID`（逗號分隔）；performance/OEE 的 multi-device/line/factory 另支援選填 `onlyCalculateHasDoneWooh=true`

---

## Error Handling

此 API 除認證外幾乎所有錯誤（UUID 找不到、時間格式錯誤、參數缺失）一律回 **500** 並附純文字訊息，需看 response body 判斷原因。

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 500 `Cannot find this device.` | UUID 錯誤 | Verify UUID |
| 500 `From time cannot be parsed.` | `from`/`to` 缺失或非 RFC3339 | Check time parameters |
