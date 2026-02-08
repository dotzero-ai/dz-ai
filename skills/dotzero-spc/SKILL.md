---
name: dotzero-spc
description: DotZero SPC 品質管理。量測配置、檢驗數據記錄、管制圖分析、製程能力計算。支援自動 token 刷新。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero SPC (Statistical Process Control)

Manage SPC measurement configurations, record inspection data, and analyze quality metrics. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `spc_api_url` set

## Setup

Ensure config has the SPC API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "spc_api_url": "https://dotzerotech-spc-backend.dotzero.app"
# }
```

## Get Valid Token

**重要**: Token 會在 1 小時後過期。使用 `dotzero-auth` skill 中的 `get_valid_token` 函數。

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.spc_api_url')
TOKEN=$(get_valid_token)
```

---

## Product Operations (V2)

### List Manufacture Products

```bash
curl -s "${API_URL}/v2/spcProducts/manufacture?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Stock Products

```bash
curl -s "${API_URL}/v2/spcProducts/stock?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Measure Config Operations (V1)

### List Measure Configs

```bash
curl -s "${API_URL}/v1/spcMeasurePointConfig?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Measure Config

```bash
curl -s "${API_URL}/v1/spcMeasurePointConfig/${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Measure Config

```bash
curl -s -X POST "${API_URL}/v1/spcMeasurePointConfig" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dimension A - Length",
    "stdValue": 10.0,
    "measureAmount": 5
  }'
```

### Update Measure Config

```bash
curl -s -X PATCH "${API_URL}/v1/spcMeasurePointConfig/${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dimension A - Length (Updated)",
    "stdValue": 10.5
  }'
```

### Delete Measure Config

```bash
curl -s -X DELETE "${API_URL}/v1/spcMeasurePointConfig/${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Modes

```bash
curl -s "${API_URL}/v1/spcMeasurePointConfig/modes" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Categories

```bash
curl -s "${API_URL}/v1/spcMeasurePointConfig/categories" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Measure History Operations (V1)

### Create Measurement

```bash
curl -s -X POST "${API_URL}/v1/spcMeasurePointHistory" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "spcMeasurePointConfigUUID": "config-uuid",
    "value": 10.02
  }'
```

### Filter History (Manufacture)

```bash
curl -s "${API_URL}/v1/spcMeasurePointHistory/filter/list?spcMeasurePointConfigUUID=${CONFIG_UUID}&limit=50" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Filter History (Stock)

```bash
curl -s "${API_URL}/v1/spcMeasurePointHistory/filter/list/stock?spcMeasurePointConfigUUID=${CONFIG_UUID}&limit=50" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Count History

```bash
curl -s "${API_URL}/v1/spcMeasurePointHistory/count?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Batch Upsert

```bash
curl -s -X PATCH "${API_URL}/v1/spcMeasurePointHistory/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[
    {"spcMeasurePointConfigUUID": "uuid", "value": 10.01},
    {"spcMeasurePointConfigUUID": "uuid", "value": 10.03}
  ]'
```

---

## Instrument Operations (V1)

### List Instruments

```bash
curl -s "${API_URL}/v1/spcInstrument?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Instrument

```bash
curl -s -X POST "${API_URL}/v1/spcInstrument" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Caliper #001"}'
```

---

## Dashboard Operations (V1)

### List Dashboards

```bash
curl -s "${API_URL}/v1/spcDashboard?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Dashboard

```bash
curl -s -X POST "${API_URL}/v1/spcDashboard" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Quality Overview"}'
```

---

## Statistics Operations (V1)

### Nelson Rule Analysis

```bash
curl -s "${API_URL}/v1/spcStatistics/nelson?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Process Capability (Cp, Cpk)

```bash
curl -s "${API_URL}/v1/spcStatistics/capability?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Calculate Results

```bash
curl -s "${API_URL}/v1/spcStatistics/calculateResult?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## History V2 Operations

### Batch Upsert History

```bash
curl -s -X PATCH "${API_URL}/v2/spcHistory/batch" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"items": [...]}'
```

### Get by Group

```bash
curl -s "${API_URL}/v2/spcHistory/group/${GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Delete by Group

```bash
curl -s -X DELETE "${API_URL}/v2/spcHistory/group/${GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Quick Reference

### Products & Config

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List manufacture products | GET | `/v2/spcProducts/manufacture` |
| List stock products | GET | `/v2/spcProducts/stock` |
| List measure configs | GET | `/v1/spcMeasurePointConfig` |
| Get measure config | GET | `/v1/spcMeasurePointConfig/{uuid}` |
| Create measure config | POST | `/v1/spcMeasurePointConfig` |
| Update measure config | PATCH | `/v1/spcMeasurePointConfig/{uuid}` |
| Delete measure config | DELETE | `/v1/spcMeasurePointConfig/{uuid}` |
| List modes | GET | `/v1/spcMeasurePointConfig/modes` |
| List categories | GET | `/v1/spcMeasurePointConfig/categories` |

### Measure History

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Create measurement | POST | `/v1/spcMeasurePointHistory` |
| Upsert measurement | PUT | `/v1/spcMeasurePointHistory` |
| Update measurement | PATCH | `/v1/spcMeasurePointHistory/{uuid}` |
| Delete measurement | DELETE | `/v1/spcMeasurePointHistory/{uuid}` |
| Batch upsert | PATCH | `/v1/spcMeasurePointHistory/batch` |
| Batch delete | DELETE | `/v1/spcMeasurePointHistory/batch` |
| Filter list (manufacture) | GET | `/v1/spcMeasurePointHistory/filter/list` |
| Filter list (stock) | GET | `/v1/spcMeasurePointHistory/filter/list/stock` |
| Count | GET | `/v1/spcMeasurePointHistory/count` |
| Manufacture history | GET | `/v1/spcMeasurePointHistory/manufacture` |
| Stock history | GET | `/v1/spcMeasurePointHistory/stock` |

### Instruments & Dashboard

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List instruments | GET | `/v1/spcInstrument` |
| Create instrument | POST | `/v1/spcInstrument` |
| Update instrument | PATCH | `/v1/spcInstrument/{uuid}` |
| Delete instrument | DELETE | `/v1/spcInstrument/{uuid}` |
| Batch delete instruments | DELETE | `/v1/spcInstrument/batch` |
| List dashboards | GET | `/v1/spcDashboard` |
| Create dashboard | POST | `/v1/spcDashboard` |
| Update dashboard | PATCH | `/v1/spcDashboard/{uuid}` |
| Delete dashboard | DELETE | `/v1/spcDashboard/{uuid}` |

### Statistics

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Nelson rules | GET | `/v1/spcStatistics/nelson` |
| Capability | GET | `/v1/spcStatistics/capability` |
| Capability by point | GET | `/v1/spcStatistics/capabilityByPoint` |
| Calculate result | GET | `/v1/spcStatistics/calculateResult` |
| List rules | GET | `/v1/spcRule` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify UUID |
| 422 | Validation error | Check input parameters |
