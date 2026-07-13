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

# 不帶 period 則回傳預設期間
curl -s "${API_URL}/v1/performance" \
  -H "Authorization: Bearer ${TOKEN}"
```

**參數說明**:

| 參數 | 必填 | 格式 | 說明 |
|------|------|------|------|
| `period` | 選填 | `YYYY-MM` | 績效統計月份，例如 `2026-06`。省略則用後端預設期間。 |

**回傳說明**: 回傳裸 JSON 陣列，每列為一家供應商。指標欄位可能是純數值，或包含 `effective` 值的物件（取 `effective` 為有效值）。常見欄位：

| 欄位 | 說明 |
|------|------|
| `supplier_id` | 供應商 ID |
| `supplier_code` | 供應商代碼 |
| `supplier_name` | 供應商名稱 |
| `period` | 統計期間 |
| `defect_rate` | 不良率 |
| `on_time_rate` | 準時交貨率 |
| `cooperation_score` | 配合度分數 |

**jq 範例** — 取供應商名稱與有效指標值（相容純值 / 物件兩種格式）：

```bash
curl -s "${API_URL}/v1/performance?period=2026-06" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.[] | {
      supplier_name,
      period,
      defect_rate:  (.defect_rate.effective  // .defect_rate),
      on_time_rate: (.on_time_rate.effective // .on_time_rate)
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

## Quick Reference

| Operation | Method | Endpoint | Query |
|-----------|--------|----------|-------|
| 待交貨清單 | GET | `/v1/deliveries/deliverable` | — |
| 待品檢清單 | GET | `/v1/qa/inspectable` | — |
| 供應商績效 | GET | `/v1/performance` | `period=YYYY-MM`（選填） |
| 可請款品項 | GET | `/v1/invoices/billable` | — |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied（待品檢需 `scm.qa.read`） | Check user permissions |
| 404 | Resource not found | Verify endpoint path |
| 422 | Validation error | Check query parameters（如 `period` 格式 `YYYY-MM`） |
