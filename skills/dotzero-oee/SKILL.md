---
name: dotzero-oee
description: DotZero OEE 分析。設備/產線/工廠的可用率、品質率、稼動率、綜合OEE，設備狀態與警報歷史。
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
API_URL=$(echo "$CONFIG" | jq -r '.oee_api_url')
TOKEN=$(get_valid_token)
```

## OEE 公式

```
OEE = 可用率 (Availability) x 品質率 (Quality) x 稼動率 (Performance)

可用率 = (計畫時間 - 停機時間) / 計畫時間
品質率 = 良品數 / 總產出數
稼動率 = (總產出數 x 理想週期時間) / 運轉時間
```

---

## Availability Operations

### Device Availability

```bash
curl -s "${API_URL}/v1/availability/device?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device Availability

```bash
curl -s "${API_URL}/v1/availability/devices?deviceUUIDs=${UUID1},${UUID2}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Availability

```bash
curl -s "${API_URL}/v1/availability/line?lineUUID=${LINE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Availability

```bash
curl -s "${API_URL}/v1/availability/factory?factoryUUID=${FACTORY_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quality Operations

### Device Quality

```bash
curl -s "${API_URL}/v1/quality/device?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Quality

```bash
curl -s "${API_URL}/v1/quality/line?lineUUID=${LINE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Quality

```bash
curl -s "${API_URL}/v1/quality/factory?factoryUUID=${FACTORY_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Performance Operations

### Device Performance

```bash
curl -s "${API_URL}/v1/performance/device?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Device Performance Range (Daily Trend)

```bash
curl -s "${API_URL}/v1/performance/device/range?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line Performance

```bash
curl -s "${API_URL}/v1/performance/line?lineUUID=${LINE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory Performance

```bash
curl -s "${API_URL}/v1/performance/factory?factoryUUID=${FACTORY_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## OEE Operations (Combined)

### Device OEE

```bash
curl -s "${API_URL}/v1/oee/device?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Multi-Device OEE

```bash
curl -s "${API_URL}/v1/oee/devices?deviceUUIDs=${UUID1},${UUID2}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Line OEE

```bash
curl -s "${API_URL}/v1/oee/line?lineUUID=${LINE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Factory OEE

```bash
curl -s "${API_URL}/v1/oee/factory?factoryUUID=${FACTORY_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Status & Alarm Operations

### Device Status

```bash
curl -s "${API_URL}/v1/status/device?deviceUUID=${DEVICE_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Alarm History

```bash
curl -s "${API_URL}/v1/alarms?deviceUUID=${DEVICE_UUID}&startTime=2026-02-01T00:00:00Z&endTime=2026-02-07T23:59:59Z&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quick Reference

### Availability

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device availability | GET | `/v1/availability/device` |
| Multi-device availability | GET | `/v1/availability/devices` |
| Line availability | GET | `/v1/availability/line` |
| Factory availability | GET | `/v1/availability/factory` |

### Quality

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device quality | GET | `/v1/quality/device` |
| Multi-device quality | GET | `/v1/quality/devices` |
| Line quality | GET | `/v1/quality/line` |
| Factory quality | GET | `/v1/quality/factory` |

### Performance

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device performance | GET | `/v1/performance/device` |
| Multi-device performance | GET | `/v1/performance/devices` |
| Line performance | GET | `/v1/performance/line` |
| Factory performance | GET | `/v1/performance/factory` |
| Device range (trend) | GET | `/v1/performance/device/range` |

### OEE (Combined)

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device OEE | GET | `/v1/oee/device` |
| Multi-device OEE | GET | `/v1/oee/devices` |
| Line OEE | GET | `/v1/oee/line` |
| Factory OEE | GET | `/v1/oee/factory` |

### Status & Alarms

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Device status | GET | `/v1/status/device` |
| Alarm history | GET | `/v1/alarms` |

**共用查詢參數**: `deviceUUID`, `lineUUID`, `factoryUUID`, `startTime`, `endTime`

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 404 | Resource not found | Verify UUID |
| 422 | Validation error | Check time range parameters |
