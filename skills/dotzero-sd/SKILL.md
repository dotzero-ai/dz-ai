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

銷售訂單清單。`query` 決定過濾模式：`all`（全部，不帶其他過濾）、`exact`（精確比對）、`fuzzy`（模糊比對）。

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
| `query` | 過濾模式：`all` / `exact` / `fuzzy`（預設 `all`） | 全部 |
| `status` | 訂單狀態 | exact / fuzzy |
| `sdCustomerNumber` | 客戶編號 | exact / fuzzy |
| `sdCustomerName` | 客戶名稱 | exact / fuzzy |
| `number` | 訂單編號（業務編號） | exact / fuzzy |
| `customerOrderNumber` | 客戶方訂單編號 | exact / fuzzy |
| `deliveryDateFrom` | 交貨日起（含） | exact / fuzzy |
| `deliveryDateTo` | 交貨日迄（含） | exact / fuzzy |
| `createTimeFrom` | 建立時間起（含） | exact / fuzzy |
| `createTimeTo` | 建立時間迄（含） | exact / fuzzy |
| `offset` | 分頁位移 | 全部 |
| `limit` | 每頁筆數 | 全部 |
| `orderBy` | 排序欄位 | 全部 |
| `order` | 排序方向（`asc` / `desc`） | 全部 |

> `query=all` 時只送分頁 / 排序參數，其餘過濾欄位會被忽略。

**回傳**: `{ "data": [...], "total": N }`。每筆訂單含 `uuid`、`number`、`sdCustomerName`、`sdCustomerNumber`、`status`、`totalAmount`、`currency`、`deliveryDate`、`priority` 等欄位。

### Get Sales Order

取得單一訂單明細（含品項）。**只接受 UUID**（不是業務訂單編號 `number`）。

```bash
ORDER_UUID="<order uuid>"
curl -s "${API_URL}/order/${ORDER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

> 若手上只有訂單編號（`number`），先用 List Sales Orders 以 `query=exact&number=...` 查出對應的 `uuid`，再帶入此端點。

**回傳**: 單筆訂單完整物件，含明細品項。

---

## Customer Operations

### List Customers

客戶清單。`query` 過濾模式同 Order（`all` / `exact` / `fuzzy`）。

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
| `query` | 過濾模式：`all` / `exact` / `fuzzy`（預設 `all`） | 全部 |
| `name` | 客戶名稱 | exact / fuzzy |
| `number` | 客戶編號 | exact / fuzzy |
| `address` | 客戶地址 | exact / fuzzy |
| `isActive` | 是否啟用（`true` / `false`） | exact / fuzzy |
| `createTimeFrom` | 建立時間起（含） | exact / fuzzy |
| `createTimeTo` | 建立時間迄（含） | exact / fuzzy |
| `offset` | 分頁位移 | 全部 |
| `limit` | 每頁筆數 | 全部 |
| `orderBy` | 排序欄位 | 全部 |
| `order` | 排序方向（`asc` / `desc`） | 全部 |

> `query=all` 時只送分頁 / 排序參數，其餘過濾欄位會被忽略。

**回傳**: `{ "data": [...], "total": N }`。每筆客戶含 `uuid`、`name`、`number`、`address`、`isActive` 等欄位。

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List sales orders | GET | `/order?query=all\|exact\|fuzzy` |
| Get sales order | GET | `/order/{uuid}` |
| List customers | GET | `/customer?query=all\|exact\|fuzzy` |

> 全部為唯讀查詢端點。訂單明細須以 UUID 取得，非業務編號。

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify UUID (order/{uuid} 只接受 UUID，非業務編號) |
| 422 | Validation error | Check query mode and filter parameters |
