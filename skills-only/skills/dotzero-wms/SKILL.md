---
name: dotzero-wms
description: DotZero WMS 倉儲查詢。庫存查詢、低於安全庫存清單、工單揀料完成進度。支援自動 token 刷新。
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

依工單或序號查詢產品庫存明細。**POST body 查詢**：`work_order_id_list` 或 `serial_number_list` 至少擇一（皆為陣列），否則無法查詢。

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

查詢指定計畫日期區間的工單揀料完成率報表。日期格式為 **YYYY-MM-DD**（非 RFC3339）。

**注意**：`plannedDateStart` 與 `plannedDateEnd` 區間**必須提供**，否則後端回 400。若省略，建議預設帶入本週一至週日。

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
| `plannedDateStart` | string (YYYY-MM-DD) | 是 | 計畫日期起 |
| `plannedDateEnd` | string (YYYY-MM-DD) | 是 | 計畫日期迄 |

**回傳**：後端揀料完成率報表原樣透傳（JSON 物件）。

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Stock query (庫存查詢) | POST | `/v1/wms-backend/queryProductStorage` |
| Low stock list (低庫存) | GET | `/v1/wms-backend/minimalStockLevelProductCount` |
| Picking progress (揀料進度) | GET | `/v1/wms-backend/workOrderPickingCompletionRate` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 400 | 缺少必要參數（揀料進度未帶日期區間、庫存查詢 body 為空） | 補齊 `plannedDateStart`/`plannedDateEnd` 或 `work_order_id_list`/`serial_number_list` |
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify work order id / serial number |
| 422 | Validation error | Check input parameters |
