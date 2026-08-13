---
name: dotzero-wms
description: DotZero WMS 倉儲（庫存查詢、低於安全庫存、工單揀料進度）。Use when 使用者問某張工單 / 序號的料夠不夠、哪些低於安全庫存要補、揀料到哪（stock query, low stock, picking progress）。MCP 工具可用時直接叫工具（wms_*）；本 skill 只給路由與已知陷阱。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero WMS (Warehouse Management System)

Query warehouse stock, low-stock alerts, and work-order picking progress. Works with any AI Agent that can execute curl commands or use WebFetch.

所有工具皆為**唯讀查詢**，不會變更任何倉儲資料。

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `wms_api_url` set

## Setup

Ensure config has the WMS API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "wms_api_url": "https://dotzerotech-wms-backend.dotzero.app"
# }
```

## Get Valid Token

**重要**: Token 會在 1 小時後過期。使用 `dotzero-auth` skill 中的 `get_valid_token` 函數。

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.wms_api_url // "https://dotzerotech-wms-backend.dotzero.app"')
TOKEN=$(get_valid_token)
```

---

## Stock Query (庫存查詢)

依工單或序號查詢產品庫存明細。**POST body 查詢**：請帶 `work_order_id_list` 或 `serial_number_list` 至少一個（皆為陣列）。

> ⚠️ 後端不擋空查詢：兩個 list 皆空（或送 `{}`）仍回 200，且會**傾印該 tenant 全部庫存**（可能極大）。**勿送空 body**；只有 body 完全缺漏或非法 JSON 才回 400。

### By Work Order (依工單查庫存)

```bash
curl -s -X POST "${API_URL}/v1/wms-backend/queryProductStorage" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "work_order_id_list": ["WO-2026-0001"]
  }' | jq '.[] | {work_order_id, serial_number, qty, warehouse_storage_uuid, expiration_date}'
```

### By Serial Number (依序號查庫存)

```bash
curl -s -X POST "${API_URL}/v1/wms-backend/queryProductStorage" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "serial_number_list": ["SN-000123", "SN-000124"]
  }' | jq '.[] | {serial_number, product_uuid, qty}'
```

**參數**（body，兩者至少擇一，皆為字串陣列）：

| Field | Type | Required | 說明 |
|-------|------|----------|------|
| `work_order_id_list` | string[] | 擇一 | 工單編號清單 |
| `serial_number_list` | string[] | 擇一 | 產品序號清單 |

**回傳**：裸 JSON 陣列，每筆為一庫存記錄，含以下欄位：

| Field | 說明 |
|-------|------|
| `uuid` | 庫存記錄 UUID |
| `work_order_id` | 所屬工單編號 |
| `product_uuid` | 產品 UUID |
| `serial_number` | 產品序號 |
| `qty` | 庫存數量 |
| `warehouse_storage_uuid` | 儲位 UUID |
| `expiration_date` | 效期 |

---

## Low Stock List (低於安全庫存清單)

列出所有低於安全庫存水位的產品，並計算缺口量。無需任何參數。

```bash
curl -s "${API_URL}/v1/wms-backend/minimalStockLevelProductCount" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{
    count,
    alerts: [.wms_alert_product_details[] | {
      product_number: .product.number,
      product_name: .product.name,
      total_qty,
      minimum_stock_level: .minimal_stock_level,
      shortage: (.minimal_stock_level - .total_qty)
    }]
  }'
```

**參數**：無。

**回傳**：JSON 物件：

| Field | 說明 |
|-------|------|
| `count` | 低於安全庫存的產品數 |
| `wms_alert_product_details` | 明細陣列，每筆含 `product`（`uuid`/`number`/`name`）、`total_qty`（現有總量）、`minimal_stock_level`（安全庫存量）、`product_storage`（儲位清單） |

> 缺口量 = `minimal_stock_level - total_qty`（正值代表短缺）。

---

## Picking Progress (工單揀料完成進度)

查詢工單揀料完成率報表。日期格式為 **YYYY-MM-DD**（非 RFC3339）。

**必填規則**：`plannedDateStart`/`plannedDateEnd`（預計發料日）與 `pickedDateStart`/`pickedDateEnd`（已發料日）**兩組日期區間至少擇一組（成對提供）**；兩組皆缺才回 400。單獨提供 picked 區間也合法，可用來過濾「實際發料日」落在區間內的完成記錄。若無特定需求，建議帶 planned 區間（如本週一至週日）。

```bash
# 明確指定區間
curl -s -G "${API_URL}/v1/wms-backend/workOrderPickingCompletionRate" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "plannedDateStart=2026-07-06" \
  --data-urlencode "plannedDateEnd=2026-07-12" | jq '.'
```

```bash
# 預設本週一~週日（macOS date；Linux 用 date -d）
FROM=$(date -v-mon "+%Y-%m-%d" 2>/dev/null || date -d "monday this week" "+%Y-%m-%d")
TO=$(date -v+sun "+%Y-%m-%d" 2>/dev/null || date -d "sunday this week" "+%Y-%m-%d")
curl -s -G "${API_URL}/v1/wms-backend/workOrderPickingCompletionRate" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "plannedDateStart=${FROM}" \
  --data-urlencode "plannedDateEnd=${TO}" | jq '.'
```

**參數**（query）：

| Param | Type | Required | 說明 |
|-------|------|----------|------|
| `plannedDateStart` | string (YYYY-MM-DD) | 兩組擇一（成對） | 預計發料日起，用於篩選發料計畫 |
| `plannedDateEnd` | string (YYYY-MM-DD) | 兩組擇一（成對） | 預計發料日迄 |
| `pickedDateStart` | string (YYYY-MM-DD) | 兩組擇一（成對） | 已發料日起，用於過濾實際發料日 |
| `pickedDateEnd` | string (YYYY-MM-DD) | 兩組擇一（成對） | 已發料日迄 |

**回傳**：後端揀料完成率報表原樣透傳（JSON 物件）。

---

## Storage History (倉儲異動歷史)

查詢庫存異動記錄（入庫/出庫/領料等），支援多條件過濾與分頁。**query 參數為 camelCase**（與其他 endpoint 的 snake_case body 不同）。

```bash
curl -s -G "${API_URL}/v1/wms-backend/queryProductStorageHistory" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "workOrderID=WO-2026-0001" \
  --data-urlencode "updateTimeStart=2026-07-01" \
  --data-urlencode "updateTimeEnd=2026-07-21" \
  --data-urlencode "limit=50" | jq '{total, data: [.data[] | {work_order_id, serial_number, qty, action, update_time}]}'
```

**參數**（query，皆選填）：

| Param | 說明 |
|-------|------|
| `page` | 設 `all` 時回傳全部（無分頁、忽略過濾） |
| `start` | 分頁起始 index（預設 0） |
| `limit` | 每頁筆數（預設 10） |
| `workOrderID` | 工單編號 |
| `productNumber` / `productName` | 產品編號 / 名稱 |
| `serialNumber` | 產品序號 |
| `warehouseName` / `warehouseUUID` | 倉庫名稱 / UUID |
| `warehouseStorageName` / `warehouseStorageUUID` | 儲位名稱 / UUID |
| `workerName` / `workerID` | 操作人員名稱 / ID |
| `action` | 異動類型 |
| `updateTimeStart` / `updateTimeEnd` | 異動時間區間 |
| `memo` | 備註 |
| `expirationDateStartTime` / `expirationDateEndTime` | 效期區間 |

**回傳**：`{ total, startingIndex, limit, data }`，`data` 為異動記錄陣列（含 `wooh` 工序歷史詳情，無關聯時為 `null`）。

> 批次版：`POST /v1/wms-backend/groupQueryProductStorageHistory`，body `{"work_order_id_list": [...], "create_time_start": "...", "create_time_end": "..."}`。

---

## Work Order Picking History (工單領料記錄)

依工單查領料記錄，雙視角回傳：IO 操作流水 + 依工序的 BOM 領料狀態。

```bash
curl -s -G "${API_URL}/v1/wms-backend/workOrderPickingHistory" \
  -H "Authorization: Bearer ${TOKEN}" \
  --data-urlencode "workOrderID=WO-2026-0001" | jq '{
    io_count: (.io_records | length),
    operations: [.operations[] | {op_order, operation_name, is_completed}]
  }'
```

**參數**（query）：

| Param | Type | Required | 說明 |
|-------|------|----------|------|
| `workOrderID` | string | 是 | 工單單號（缺少回 400） |

**回傳**：

| Field | 說明 |
|-------|------|
| `io_records` | IO 領料流水陣列，每筆含 `create_time`、`product_uuid`/`product_number`/`product_name`、`qty`、`w_name`（倉庫）、`ws_name`（儲位）、`serial_number`、`worker_name`、`memo` |
| `operations` | 依工序陣列，每筆含 `op_order`、`operation_uuid`/`operation_code`/`operation_name`、`is_completed`、`bom_list`（每筆含 `product_uuid`/`product_number`/`product_name`、`required_qty`、`picked_qty`、`is_completed`） |

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Stock query (庫存查詢) | POST | `/v1/wms-backend/queryProductStorage` |
| Low stock list (低庫存) | GET | `/v1/wms-backend/minimalStockLevelProductCount` |
| Picking progress (揀料進度) | GET | `/v1/wms-backend/workOrderPickingCompletionRate` |
| Storage history (異動歷史) | GET | `/v1/wms-backend/queryProductStorageHistory` |
| Storage history batch (批次異動歷史) | POST | `/v1/wms-backend/groupQueryProductStorageHistory` |
| Picking history (領料記錄) | GET | `/v1/wms-backend/workOrderPickingHistory` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 400 | 缺少必要參數（揀料進度 planned/picked 兩組日期區間皆缺、領料記錄未帶 `workOrderID`、庫存查詢 body 缺漏或非法 JSON） | 補齊成對日期區間（planned 或 picked 擇一組）或必要參數。注意：庫存查詢送 `{}` 不會 400，而是回傳全 tenant 庫存 |
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify work order id / serial number |
| 422 | Validation error | Check input parameters |
