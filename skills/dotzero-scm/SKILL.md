---
name: dotzero-scm
description: DotZero SCM 供應鏈與供應商管理。查詢待交貨、待品檢、供應商績效、可請款品項。支援自動 token 刷新。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero SCM (Supply Chain Management)

Query supply chain and supplier data — deliverable POs, inspectable deliveries, supplier performance, and billable items. Works with any AI Agent that can execute curl commands or use WebFetch.

所有端點皆為唯讀查詢（read-only），不會變更任何資料。

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `scm_api_url` set

## Setup

Ensure config has the SCM API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "scm_api_url": "https://dotzerotech-scm-backend.dotzero.app"
# }
```

## Get Valid Token

**重要**: Token 會在 1 小時後過期。使用 `dotzero-auth` skill 中的 `get_valid_token` 函數。

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.scm_api_url // "https://dotzerotech-scm-backend.dotzero.app"')
TOKEN=$(get_valid_token)
```

---

## Dashboard (V1)

### Dashboard Counters（供應鏈狀態總覽）

一次取得各階段待辦計數，是做供應鏈狀態總覽的最佳單一入口。無 permission gate — 每個角色看到自己 scope 的計數（供應商看自己，採購方看全租戶）。

```bash
curl -s "${API_URL}/v1/dashboard/counters" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**: 無 query 參數。

**回傳說明**: 單一 JSON 物件，恰好 4 個計數欄位：

| 欄位 | 說明 |
|------|------|
| `pending_quote` | 待報價（採購單品項尚無報價單價） |
| `pending_po_confirmation` | 已報價、待確認的採購單品項 |
| `deliverable` | 已確認、待交貨的採購單品項（剩餘數量 > 0） |
| `overdue` | 已逾交期且仍有剩餘數量的品項 |

---

## Identity (V1)

### Get Me（身分/角色）

查詢目前 token 的身分脈絡。無 permission gate。

```bash
curl -s "${API_URL}/v1/me" \
  -H "Authorization: Bearer ${TOKEN}"
```

**回傳說明**: 單一 JSON 物件：`user_email`、`tenant_id`、`supplier_id`（採購方為 `null`）、`role`、`display_name`。

---

## Delivery Operations (V1)

### List Deliverable POs（待交貨 / 剩餘可交）

列出尚未交貨完成的採購單品項，含已交數量與剩餘可交數量。

```bash
curl -s "${API_URL}/v1/deliveries/deliverable" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**: 無 query 參數。

**回傳說明**: 回傳裸 JSON 陣列，每筆為一個採購單品項。常見欄位：

| 欄位 | 說明 |
|------|------|
| `uuid` | 品項唯一識別碼 |
| `po_number` | 採購單號 |
| `line_no` | 採購單行號 |
| `material_code` | 物料代碼 |
| `material_desc` | 物料說明 |
| `qty` | 訂購數量 |
| `delivered_qty` | 已交數量 |
| `remaining_qty` | 剩餘可交數量 |
| `unit` | 單位 |
| `delivery_date` | 交期 |
| `inspection_required` | 是否需要品檢 |

**jq 範例** — 只看料號、剩餘可交數量與交期：

```bash
curl -s "${API_URL}/v1/deliveries/deliverable" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.[] | {po_number, material_code, remaining_qty, delivery_date}'
```

---

## QA Operations (V1)

### List Inspectable Deliveries（待品檢清單）

列出已交貨、等待品質檢驗的送貨品項。需 `scm.qa.read` 權限。

```bash
curl -s "${API_URL}/v1/qa/inspectable" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**: 無 query 參數。

**回傳說明**: 回傳裸 JSON 陣列，每筆為一個待品檢送貨品項。常見欄位：

| 欄位 | 說明 |
|------|------|
| `delivery_uuid` | 送貨單唯一識別碼 |
| `delivery_no` | 送貨單號 |
| `po_number` | 對應採購單號 |
| `line_no` | 採購單行號 |
| `material_code` | 物料代碼 |
| `material_desc` | 物料說明 |
| `delivered_qty` | 交貨數量 |
| `unit` | 單位 |
| `delivery_date` | 交貨日期 |

**jq 範例** — 列出待品檢的送貨單與料號：

```bash
curl -s "${API_URL}/v1/qa/inspectable" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.[] | {delivery_no, material_code, delivered_qty, delivery_date}'
```

**錯誤處理**: 若回 `403`，代表缺少 `scm.qa.read` 權限，請聯絡管理員開通。

---

## Supplier Performance Operations (V1)

### Supplier Performance（供應商績效）

查詢指定月份各供應商的績效指標（不良率、準時率、配合度分數）。

```bash
# 指定月份（YYYY-MM）
curl -s "${API_URL}/v1/performance?period=2026-06" \
  -H "Authorization: Bearer ${TOKEN}"

# 不帶 period 則回傳當月（Asia/Taipei 時區）
curl -s "${API_URL}/v1/performance" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**:

| 參數 | 必填 | 格式 | 說明 |
|------|------|------|------|
| `period` | 選填 | `YYYY-MM` | 績效統計月份，例如 `2026-06`。省略則為當月（Asia/Taipei 時區）。格式錯誤回 `400`。 |

**回傳說明**: 回傳裸 JSON 陣列，每列為一家供應商。三個指標欄位（`defect_rate`、`on_time_rate`、`cooperation_score`）**一律為物件** `{computed, override, effective, is_manual, override_uuid, remark}`，從不會是純數值 — 取 `.effective` 為顯示值，`.is_manual` 表示人工覆寫。常見欄位：

| 欄位 | 說明 |
|------|------|
| `supplier_id` | 供應商 ID |
| `supplier_code` | 供應商代碼 |
| `supplier_name` | 供應商名稱 |
| `period` | 統計期間 |
| `defect_rate` | 不良率（物件，取 `.effective`） |
| `on_time_rate` | 準時交貨率（物件，取 `.effective`） |
| `cooperation_score` | 配合度分數（物件，取 `.effective`） |

**jq 範例** — 取供應商名稱與有效指標值：

```bash
curl -s "${API_URL}/v1/performance?period=2026-06" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.[] | {
      supplier_name,
      period,
      defect_rate:  .defect_rate.effective,
      on_time_rate: .on_time_rate.effective
    }'
```

---

## Invoice Operations (V1)

### List Billable Items（可請款品項）

列出已交貨、尚可開立請款的品項，並可用報價單價估算可請款金額。

```bash
curl -s "${API_URL}/v1/invoices/billable" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**: 無 query 參數。

**回傳說明**: 回傳裸 JSON 陣列，每筆為一個可請款品項。常見欄位：

| 欄位 | 說明 |
|------|------|
| `uuid` | 品項唯一識別碼 |
| `po_number` | 採購單號 |
| `line_no` | 採購單行號 |
| `material_code` | 物料代碼 |
| `material_desc` | 物料說明 |
| `qty` | 訂購數量 |
| `delivered_qty` | 已交數量 |
| `invoiced_qty` | 已請款數量 |
| `billable_qty` | 可請款數量 |
| `unit` | 單位 |
| `quoted_unit_price` | 報價單價 |

**jq 範例** — 估算每筆可請款金額（可請款數量 × 報價單價）：

```bash
curl -s "${API_URL}/v1/invoices/billable" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.[] | {
      po_number, material_code, billable_qty, quoted_unit_price,
      billable_amount: ((.billable_qty // 0) * (.quoted_unit_price // 0))
    }'
```

---

## Other Read Endpoints (V1)

以下清單端點皆回傳裸 JSON 陣列。**注意尾斜線**：這些路由註冊為 group `GET("/")`，gin 會把 `/v1/quotes` 301 轉址到 `/v1/quotes/` — curl 不加 `-L` 會拿不到 body，請直接使用含尾斜線的路徑。

### List PO Items / Quotes（採購單品項 / 報價）

```bash
curl -s "${API_URL}/v1/quotes/" -H "Authorization: Bearer ${TOKEN}"
```

無 query 參數。需 `scm.quote.read` 權限。

### List Deliveries（交貨紀錄）

```bash
curl -s "${API_URL}/v1/deliveries/" -H "Authorization: Bearer ${TOKEN}"
```

無 query 參數。需 `scm.delivery.read` 權限。

### List QA Inspections（品檢結果）

```bash
curl -s "${API_URL}/v1/qa/" -H "Authorization: Bearer ${TOKEN}"
```

無 query 參數。需 `scm.qa.read` 權限。

### List Invoices（發票清單）

```bash
curl -s "${API_URL}/v1/invoices/?status=pending" -H "Authorization: Bearer ${TOKEN}"
```

| 參數 | 必填 | 說明 |
|------|------|------|
| `status` | 選填 | `pending`（待付款）/ `paid`（已付款）/ `voided`（已作廢）。省略則回所有未作廢發票。 |

每筆含 `attachment_count`（附件數）。需 `scm.billing.read` 權限。

### List Suppliers（供應商清單）

```bash
curl -s "${API_URL}/v1/suppliers/?include_inactive=false" -H "Authorization: Bearer ${TOKEN}"
```

| 參數 | 必填 | 說明 |
|------|------|------|
| `include_inactive` | 選填 | **預設含停用供應商**；僅明傳 `false` 才排除停用。 |

需 `scm.supplier.read` 權限。

### List Announcements（公告）

```bash
curl -s "${API_URL}/v1/announcements/" -H "Authorization: Bearer ${TOKEN}"
```

無 query 參數。需 `scm.announcement.read` 權限（供應商僅見發布期間內的公告）。

---

## Quick Reference

| Operation | Method | Endpoint | Query | Permission |
|-----------|--------|----------|-------|------------|
| 狀態總覽計數 | GET | `/v1/dashboard/counters` | — | 無（依角色 scope） |
| 身分/角色 | GET | `/v1/me` | — | 無 |
| 待交貨清單 | GET | `/v1/deliveries/deliverable` | — | `scm.delivery.read` |
| 待品檢清單 | GET | `/v1/qa/inspectable` | — | `scm.qa.read` |
| 供應商績效 | GET | `/v1/performance` | `period=YYYY-MM`（選填，預設當月 Asia/Taipei） | `scm.performance.read` |
| 可請款品項 | GET | `/v1/invoices/billable` | — | `scm.billing.read` |
| 採購品項/報價 | GET | `/v1/quotes/` | — | `scm.quote.read` |
| 交貨紀錄 | GET | `/v1/deliveries/` | — | `scm.delivery.read` |
| 品檢結果 | GET | `/v1/qa/` | — | `scm.qa.read` |
| 發票清單 | GET | `/v1/invoices/` | `status=pending|paid|voided`（選填） | `scm.billing.read` |
| 供應商清單 | GET | `/v1/suppliers/` | `include_inactive`（選填，預設含停用） | `scm.supplier.read` |
| 公告 | GET | `/v1/announcements/` | — | `scm.announcement.read` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 400 | Bad Request — 參數/格式驗證失敗（如 `period` 非 `YYYY-MM`） | Check query parameters |
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied — 缺該端點對應的 permission key（見 Quick Reference 的 Permission 欄） | Check user permissions |
| 404 | Resource not found | Verify endpoint path（清單端點需含尾斜線） |
