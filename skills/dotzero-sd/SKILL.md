---
name: dotzero-sd
description: DotZero SD 銷售與配送。查詢銷售訂單清單、單筆訂單明細、客戶清單。支援自動 token 刷新。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero SD (Sales & Distribution)

Query sales orders and customers from the DotZero Sales & Distribution service. All operations are read-only. Works with any AI Agent that can execute curl commands or use WebFetch.

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `sd_api_url` set

## Setup

Ensure config has the SD API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "sd_api_url": "https://sales-distribution-api.dotzero.app"
# }
```

## Get Valid Token

**重要**: Token 會在 1 小時後過期。使用 `dotzero-auth` skill 中的 `get_valid_token` 函數。

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.sd_api_url // "https://sales-distribution-api.dotzero.app"')
TOKEN=$(get_valid_token)
```

---

## Order Operations

### List Sales Orders

銷售訂單清單。`query` 決定過濾模式：`all`（全部，不帶其他過濾）、`exact`（精確比對）、`fuzzy`（模糊比對）。**`query` 為必填、無預設**，省略或給其他值會回 400。

```bash
# 全部訂單（前 20 筆）
curl -s "${API_URL}/order?query=all&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"

# 精確過濾（依客戶編號 + 狀態）
curl -s "${API_URL}/order?query=exact&sdCustomerNumber=C0001&status=confirmed&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"

# 模糊過濾（依客戶名稱），並取需要欄位
curl -s "${API_URL}/order?query=fuzzy&sdCustomerName=Acme&limit=20" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.data[] | {uuid, number, sdCustomerName, status, totalAmount, deliveryDate}'
```

**Query 參數**:

| 參數 | 說明 | 適用模式 |
|------|------|----------|
| `query` | **必填**，過濾模式：`all` / `exact` / `fuzzy`（無預設，省略回 400） | 全部 |
| `status` | 訂單狀態（有效值見下方 Order Status Values） | exact / fuzzy |
| `sdCustomerNumber` | 客戶編號 | exact / fuzzy |
| `sdCustomerName` | 客戶名稱 | exact / fuzzy |
| `number` | 訂單編號（業務編號） | exact / fuzzy |
| `customerOrderNumber` | 客戶方訂單編號 | exact / fuzzy |
| `shipMethod` | 出貨方式 | exact / fuzzy |
| `shipAddress` | 出貨地址 | exact / fuzzy |
| `remarks` | 備註 | exact / fuzzy |
| `currency` | 幣別 | exact / fuzzy |
| `priority` | 優先度（整數） | exact / fuzzy |
| `deliveryDateFrom` / `deliveryDateTo` | 交貨日起迄（含），RFC3339 | exact / fuzzy |
| `createTimeFrom` / `createTimeTo` | 建立時間起迄（含），RFC3339 | exact / fuzzy |
| `updateTimeFrom` / `updateTimeTo` | 更新時間起迄（含），RFC3339 | exact / fuzzy |
| `totalAmountFrom` / `totalAmountTo` | 總金額起迄（含），十進位數字 | exact / fuzzy |
| `priorityFrom` / `priorityTo` | 優先度起迄（含），整數 | exact / fuzzy |
| `offset` | 分頁位移（預設 0） | 全部 |
| `limit` | 每頁筆數（預設 20） | 全部 |
| `orderBy` | 排序欄位，僅限 `createTime` / `updateTime` / `number` / `deliveryDate` / `totalAmount` / `priority`（預設 `createTime`，其他值回 400） | 全部 |
| `order` | 排序方向 `asc` / `desc`（預設 `desc`） | 全部 |

> - `query=all` 只能帶分頁 / 排序參數；帶任何過濾或區間參數會回 400 `query=all does not accept other parameters.`
> - `query=exact` / `fuzzy` 必須至少帶一個過濾條件，否則回 400 `query=exact/fuzzy requires at least one filter condition.`
> - 時間區間參數（`deliveryDate*` / `createTime*` / `updateTime*`）須為 RFC3339 格式（如 `2026-01-01T00:00:00Z`），純日期 `2026-07-01` 會回 400。

**回傳**: `{ "data": [...], "offset": N, "limit": N, "total": N }`。每筆訂單含 `uuid`、`number`、`sdCustomerName`、`sdCustomerNumber`、`status`、`totalAmount`、`currency`、`deliveryDate`、`priority` 等欄位。

### Get Sales Order

取得單一訂單明細（含品項）。**只接受 UUID**（不是業務訂單編號 `number`）。

```bash
ORDER_UUID="<order uuid>"
curl -s "${API_URL}/order/${ORDER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

> 若手上只有訂單編號（`number`），先用 List Sales Orders 以 `query=exact&number=...` 查出對應的 `uuid`，再帶入此端點。

**回傳**: 單筆訂單完整物件，含明細品項。

### Order Status Values

訂單與品項的有效狀態列舉，建構 `status` 過濾條件前可先查詢：

```bash
# 訂單狀態列舉
curl -s "${API_URL}/order/status" -H "Authorization: Bearer ${TOKEN}"
# ["open","confirmed","scheduled","in_production","ready_to_ship","partial_shipped","shipped","completed","cancelled"]

# 訂單品項狀態列舉
curl -s "${API_URL}/item/status" -H "Authorization: Bearer ${TOKEN}"
# ["open","scheduled","in_production","ready_to_ship","shipped","cancelled"]
```

---

## Customer Operations

### List Customers

客戶清單。`query` 過濾模式同 Order（`all` / `exact` / `fuzzy`），**必填、無預設**。

```bash
# 全部客戶（前 20 筆）
curl -s "${API_URL}/customer?query=all&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"

# 模糊過濾（依名稱），並取需要欄位
curl -s "${API_URL}/customer?query=fuzzy&name=Acme&limit=20" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.data[] | {uuid, name, number, address, isActive}'

# 只列啟用中的客戶
curl -s "${API_URL}/customer?query=exact&isActive=true&limit=50" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query 參數**:

| 參數 | 說明 | 適用模式 |
|------|------|----------|
| `query` | **必填**，過濾模式：`all` / `exact` / `fuzzy`（無預設，省略回 400） | 全部 |
| `name` | 客戶名稱 | exact / fuzzy |
| `number` | 客戶編號 | exact / fuzzy |
| `address` | 客戶地址 | exact / fuzzy |
| `isActive` | 是否啟用（`true` / `false`） | exact / fuzzy |
| `createTimeFrom` / `createTimeTo` | 建立時間起迄（含），RFC3339 | exact / fuzzy |
| `updateTimeFrom` / `updateTimeTo` | 更新時間起迄（含），RFC3339 | exact / fuzzy |
| `offset` | 分頁位移（預設 0） | 全部 |
| `limit` | 每頁筆數（預設 20） | 全部 |
| `orderBy` | 排序欄位，僅限 `name` / `number` / `createTime` / `updateTime`（預設 `createTime`，其他值回 400） | 全部 |
| `order` | 排序方向 `asc` / `desc`（預設 `desc`） | 全部 |

> - `query=all` 只能帶分頁 / 排序參數；帶任何過濾或區間參數會回 400。
> - `query=exact` / `fuzzy` 必須至少帶一個過濾條件，否則回 400。
> - 時間區間參數須為 RFC3339 格式（如 `2026-01-01T00:00:00Z`），否則回 400。

**回傳**: `{ "data": [...], "offset": N, "limit": N, "total": N }`。每筆客戶含 `uuid`、`name`、`number`、`address`、`isActive` 等欄位。

### Get Customer

取得單一客戶。**只接受 UUID**（不是客戶編號 `number`）。

```bash
CUSTOMER_UUID="<customer uuid>"
curl -s "${API_URL}/customer/${CUSTOMER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

**回傳**: 單筆客戶完整物件。

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List sales orders | GET | `/order?query=all\|exact\|fuzzy` |
| Get sales order | GET | `/order/{uuid}` |
| Order status enum | GET | `/order/status` |
| Order item status enum | GET | `/item/status` |
| List customers | GET | `/customer?query=all\|exact\|fuzzy` |
| Get customer | GET | `/customer/{uuid}` |

> 全部為唯讀查詢端點。訂單 / 客戶明細須以 UUID 取得，非業務編號。

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify UUID (order/{uuid}、customer/{uuid} 只接受 UUID，非業務編號) |
| 400 | Validation error | 檢查：query 模式（必填 all/exact/fuzzy）、query=all 不可帶過濾、exact/fuzzy 至少一個過濾條件、時間為 RFC3339、orderBy 白名單、limit/offset 為合法整數 |
