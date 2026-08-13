---
name: dotzero-spc
description: DotZero SPC 品質（量測配置、檢驗數據、管制圖、製程能力）。Use when 使用者問量測值有沒有超規、管制圖怎麼判、Cpk 多少、量測點怎麼設定（spc, control chart, cpk, out of spec）。MCP 工具可用時直接叫工具（spc_*）；本 skill 只給路由與已知陷阱。
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
API_URL=$(echo "$CONFIG" | jq -r '.spc_api_url // "https://dotzerotech-spc-backend.dotzero.app"')
TOKEN=$(get_valid_token)
```

## ⚠️ 路徑重點(必讀)

- **所有 v1 / v2 路由都以 `/` 結尾**。後端未掛 trailing-slash middleware,少了結尾斜線一律 404。範例的尾斜線不可省略。
- v3 路由則**不帶**結尾斜線(見最後一節)。
- v1 的 update / delete 用 **`PUT` / `DELETE`**,目標 uuid 走 **query 參數 `?UUID=`**,不在 path 上。
- 資源前綴是 `/v1/config`、`/v1/history`、`/v1/instrument`、`/v1/dashboard`、`/v1/rule`、`/v1/statistics`、`/v1/statisticCalculateResult`、`/v2/product`、`/v2/history`、`/v2/config/parent`(不是 `spcMeasurePointConfig` / `spcProducts` / `spcHistory` 之類)。

---

## Product Operations (V2)

### List Manufacture Products

```bash
curl -s "${API_URL}/v2/product/manufacture/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Stock Products

```bash
curl -s "${API_URL}/v2/product/stock/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Measure Config Operations (V1)

### List Measure Configs

支援的 query 過濾參數(皆選填,無分頁,一次回全部):`UUID`、`operationUUID`、`productUUID`、`controlPer`、`productStorageAction`、`getAttachmentURL`(`true` 時附帶附件 URL)。

```bash
curl -s "${API_URL}/v1/config/?controlPer=manufacture" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Measure Config

```bash
curl -s "${API_URL}/v1/config/${CONFIG_UUID}/" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Measure Config

```bash
curl -s -X POST "${API_URL}/v1/config/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dimension A - Length",
    "stdValue": 10.0,
    "measureAmount": 5
  }'
```

### Update Measure Config

`uuid` 走 query 參數 `?UUID=`,動詞是 `PUT`。

```bash
curl -s -X PUT "${API_URL}/v1/config/?UUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dimension A - Length (Updated)",
    "stdValue": 10.5
  }'
```

### Delete Measure Config

```bash
curl -s -X DELETE "${API_URL}/v1/config/?UUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Modes

```bash
curl -s "${API_URL}/v1/config/mode/" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Categories

```bash
curl -s "${API_URL}/v1/config/category/" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Measure History Operations (V1)

### Create Measurement

```bash
curl -s -X POST "${API_URL}/v1/history/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "spcMeasurePointConfigUUID": "config-uuid",
    "value": 10.02
  }'
```

### Filter List (Manufacture)

回傳某量測點在指定維度上的 distinct 值(工單 / 作業員 / 儀器 / 設備)。`filterType` 為必填 path 參數,可選:`workOrderOpHistoryWorker`、`workOrderOpHistory`、`spcMeasureInstrument`、`device`、`spcMeasureWorker`。

Query 參數:`spcMeasurePointConfigUUID`(必填)、`workOrderOpHistoryUUID`(選填)、`workOrderOpHistoryStartTime` / `workOrderOpHistoryEndTime`(選填,RFC3339)。

```bash
curl -s "${API_URL}/v1/history/filter-list/workOrderOpHistory/?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Filter List (Stock)

`filterType` 可選:`warehouse`、`serialNumber`、`workOrderID`、`productStorageHistoryWorker`、`spcMeasureWorker`、`productStorageHistoryUUID`。Query 參數:`spcMeasurePointConfigUUID`(必填)、`productStorageHistoryUUID`、`productStorageHistoryStartTime` / `productStorageHistoryEndTime`(RFC3339)。

```bash
curl -s "${API_URL}/v1/history/filter-list/warehouse/stock/?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Count History

```bash
curl -s "${API_URL}/v1/history/count/?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Batch Upsert

Body 是**裸 JSON array**(不要包 `{"items": ...}`)。

```bash
curl -s -X PATCH "${API_URL}/v1/history/batch/" \
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

Query 參數:`UUID`、`name`、`limit`(選填)。

```bash
curl -s "${API_URL}/v1/instrument/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Instrument

```bash
curl -s -X POST "${API_URL}/v1/instrument/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Caliper #001"}'
```

### Update / Delete Instrument

```bash
curl -s -X PUT "${API_URL}/v1/instrument/?UUID=${INSTRUMENT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Caliper #001 (Recalibrated)"}'

curl -s -X DELETE "${API_URL}/v1/instrument/?UUID=${INSTRUMENT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Dashboard Operations (V1)

### List Dashboards

```bash
curl -s "${API_URL}/v1/dashboard/" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Dashboard

```bash
curl -s -X POST "${API_URL}/v1/dashboard/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Quality Overview"}'
```

---

## Statistics Operations (V1)

### Nelson Rule Analysis

**必填 query 參數**(缺任一即 400):`spcMeasurePointConfigUUID`、`workOrderOpHistoryUUID`、`startTime`、`endTime`(後兩者為 RFC3339,且 `startTime <= endTime`)。

```bash
curl -s "${API_URL}/v1/statistics/nelson/?spcMeasurePointConfigUUID=${CONFIG_UUID}&workOrderOpHistoryUUID=${WO_UUID}&startTime=2026-07-01T00:00:00Z&endTime=2026-07-21T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Process Capability (Cp, Cpk)

必填參數同 Nelson。

```bash
curl -s "${API_URL}/v1/statistics/capability/?spcMeasurePointConfigUUID=${CONFIG_UUID}&workOrderOpHistoryUUID=${WO_UUID}&startTime=2026-07-01T00:00:00Z&endTime=2026-07-21T23:59:59Z" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Capability by Point(即席計算)

不需 config;直接帶原始資料點與規格界限。Query 參數:`points`(逗號分隔)、`USL`、`LSL`、`stdValue`、`measureAmount`。

```bash
curl -s "${API_URL}/v1/statistics/capability-by-point/?points=10.01,10.02,9.98&USL=10.5&LSL=9.5&stdValue=10&measureAmount=5" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Calculate Results(預算結果)

Query 參數:`range`(`day|week|month|custom`)、`metricName`(`Cpk|nelsonRule1..8|overSpecs`)、`limit`(必填,>=0)、自訂範圍時另帶 `workOrderOpHistoryStartTimeFrom` / `workOrderOpHistoryStartTimeTo`(RFC3339)。

```bash
curl -s "${API_URL}/v1/statisticCalculateResult/?range=week&metricName=Cpk&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### List Rules

```bash
curl -s "${API_URL}/v1/rule/" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## History V2 Operations

### List History

`spcMeasurePointConfigUUID` 為必填。無分頁,回全部符合結果。

```bash
curl -s "${API_URL}/v2/history/?spcMeasurePointConfigUUID=${CONFIG_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Batch Upsert History

裸 JSON array。欄位:`spcMeasurePointConfigUUID`、`value`、`groupName`、`workOrderOpHistoryUUID`、`productStorageHistoryUUID`、`spcMeasureInstrumentUUID`、`measureObjectID`、`workerID`、`booleanValue`(皆可選,除了 config uuid)。

```bash
curl -s -X PATCH "${API_URL}/v2/history/batch/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[
    {"spcMeasurePointConfigUUID": "config-uuid", "value": 10.01, "groupName": "batch-A"}
  ]'
```

### Ensure / Delete History by Group Name

沒有「by group id」路由。改用 `batch/groupName/`,body 為裸 array,每筆必填 `spcMeasurePointConfigUUID` 與 `groupName`(可選 `workOrderOpHistoryUUID` / `productStorageHistoryUUID`)。

- `PATCH`:對每個 (config, groupName) 若無資料則建立空白列。
- `DELETE`:刪除該群組的歷史列。

```bash
# 建立(若不存在)
curl -s -X PATCH "${API_URL}/v2/history/batch/groupName/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[{"spcMeasurePointConfigUUID": "config-uuid", "groupName": "batch-A"}]'

# 刪除
curl -s -X DELETE "${API_URL}/v2/history/batch/groupName/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[{"spcMeasurePointConfigUUID": "config-uuid", "groupName": "batch-A"}]'
```

### Config Parent Attachment (V2)

附件上傳為 **multipart**(form 欄位名 `attachment`),路徑帶 parent uuid。刪除用 JSON body `{"path": "..."}`。

```bash
# 上傳附件(png/jpg/pdf)
curl -s -X POST "${API_URL}/v2/config/parent/${PARENT_UUID}/attachment/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "attachment=@./spec.pdf"

# 刪除附件
curl -s -X DELETE "${API_URL}/v2/config/parent/${PARENT_UUID}/attachment/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"path": "https://.../spec.pdf"}'
```

---

## Quick Reference

### Products & Config

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List manufacture products | GET | `/v2/product/manufacture/` |
| List stock products | GET | `/v2/product/stock/` |
| List measure configs | GET | `/v1/config/` |
| Get measure config | GET | `/v1/config/{uuid}/` |
| Create measure config | POST | `/v1/config/` |
| Update measure config | PUT | `/v1/config/?UUID={uuid}` |
| Delete measure config | DELETE | `/v1/config/?UUID={uuid}` |
| List modes | GET | `/v1/config/mode/` |
| List categories | GET | `/v1/config/category/` |
| Config parent | GET/POST/PUT | `/v2/config/parent/` |
| Config parent attachment | POST/DELETE | `/v2/config/parent/{uuid}/attachment/` |

### Measure History

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Create measurement | POST | `/v1/history/` |
| Update measurement | PUT | `/v1/history/?UUID={uuid}` |
| Upsert measurement | PATCH | `/v1/history/` |
| Delete measurement | DELETE | `/v1/history/?UUID={uuid}` |
| Batch upsert (bare array) | PATCH | `/v1/history/batch/` |
| Batch delete | DELETE | `/v1/history/batch/` |
| Filter list (manufacture) | GET | `/v1/history/filter-list/{filterType}/` |
| Filter list (stock) | GET | `/v1/history/filter-list/{filterType}/stock/` |
| Count | GET | `/v1/history/count/` |
| Manufacture history | GET | `/v1/history/manufacture/` |
| Stock history | GET | `/v1/history/stock/` |
| List history (v2) | GET | `/v2/history/?spcMeasurePointConfigUUID=` |
| Batch upsert (v2, bare array) | PATCH | `/v2/history/batch/` |
| Ensure by group name (array body) | PATCH | `/v2/history/batch/groupName/` |
| Delete by group name (array body) | DELETE | `/v2/history/batch/groupName/` |

### Instruments & Dashboard

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List instruments | GET | `/v1/instrument/` |
| Create instrument | POST | `/v1/instrument/` |
| Update instrument | PUT | `/v1/instrument/?UUID={uuid}` |
| Delete instrument | DELETE | `/v1/instrument/?UUID={uuid}` |
| Batch delete instruments | DELETE | `/v1/instrument/batch/` |
| List dashboards | GET | `/v1/dashboard/` |
| Create dashboard | POST | `/v1/dashboard/` |
| Update dashboard | PUT | `/v1/dashboard/?UUID={uuid}` |
| Delete dashboard | DELETE | `/v1/dashboard/?UUID={uuid}` |

### Statistics

必填參數:nelson / capability 需 `spcMeasurePointConfigUUID` + `workOrderOpHistoryUUID` + `startTime` + `endTime`(RFC3339)。

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Nelson rules | GET | `/v1/statistics/nelson/` |
| Nelson by point | GET | `/v1/statistics/nelson-by-point/` |
| Capability | GET | `/v1/statistics/capability/` |
| Capability by point | GET | `/v1/statistics/capability-by-point/` |
| Calculate result | GET | `/v1/statisticCalculateResult/` |
| List rules | GET | `/v1/rule/` |

---

## V3 API(2026 新功能,唯讀查詢/報表)

v3 走同樣的 `Authorization: Bearer {token}`,但路由**不帶結尾斜線**。以下為對監控 / 報表 agent 有價值的查詢類端點:

| 用途 | Method | Endpoint |
|------|--------|----------|
| 工單量測歷史筆數 | GET | `/v3/count/workOrderSpcMeasurePointHistory` |
| 失控(out-of-control)筆數統計 | GET | `/v3/count/spcMeasurePointHistory/outOfControl` |
| 儀表板:過去記錄 | GET | `/v3/dashboard/pastRecord` |
| 儀表板:趨勢 runs | GET | `/v3/dashboard/trendRuns` |
| 報表搜尋 | GET | `/v3/spcReport/search` |
| 檢點表清單 / 含歷史 / 量測歷史 | GET | `/v3/spcInspectionSheets`、`/v3/spcInspectionSheets/withHistory`、`/v3/spcInspectionSheets/measureHistory` |
| v3 量測歷史查詢 | GET | `/v3/spcMeasurePointHistory/`、`/v3/spcMeasurePointHistory/v3` |
| 量測點特性庫 / 樣板 | GET | `/v3/spcMeasurePointMaster`、`/v3/spcMeasurePointTemplate` |
| 量測點設定清單 | GET | `/v3/measurePointConfigList` |
| 儀器清單 / 校正到期提醒 | GET | `/v3/instrument`、`/v3/instrument/dueReminders` |
| 儀器校正紀錄 | GET | `/v3/instrumentCalibration` |
| 出貨報告 / 量測歷史 | GET | `/v3/shippingReport`、`/v3/shippingReport/measureHistory` |

```bash
# 例:查儀器校正到期提醒
curl -s "${API_URL}/v3/instrument/dueReminders" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 400 | 缺必填參數 / 尾斜線缺失 / 型別錯誤 | 檢查參數、確認路徑帶 `/` 結尾 |
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | 路徑錯誤(常見:少了尾斜線,或用了舊的 spcXxx 前綴) | 對照上方 Quick Reference |
| 422 | Validation error | Check input parameters |
