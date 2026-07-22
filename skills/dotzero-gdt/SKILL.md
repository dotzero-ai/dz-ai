---
name: dotzero-gdt
description: DotZero GDT 工程圖服務。查詢工程圖清單、相似圖檢索、圖面特徵（尺寸/GD&T/孔數）。全唯讀查詢。支援自動 token 刷新。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero GDT (Engineering Drawings)

Query engineering drawings, retrieve similar drawings, and inspect drawing features (dimensions, GD&T, hole counts). Works with any AI Agent that can execute curl commands or use WebFetch. **All operations are read-only queries.**

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `gdt_api_url` set

## Setup

Ensure config has the GDT API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "gdt_api_url": "https://gdt-backend.dotzero.app"
# }
```

## Get Valid Token

**重要**: Token 會在 1 小時後過期。使用 `dotzero-auth` skill 中的 `get_valid_token` 函數。

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.gdt_api_url // "https://gdt-backend.dotzero.app"')
TOKEN=$(get_valid_token)
```

---

## Drawing Operations (V1)

### List Drawings

查詢工程圖清單。支援關鍵字（`q`）與多欄位過濾，回傳 `{total, items}`。

```bash
# 全部（前 20 筆）
curl -s "${API_URL}/v1/drawing?limit=20" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# 關鍵字搜尋 + 客戶過濾
curl -s "${API_URL}/v1/drawing?q=bracket&customer=ACME&limit=20" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.items[] | {id, name, drawing_no, part_no}'
```

**Query 參數**（全部選填；空值不送）：

| 參數 | 說明 |
|------|------|
| `q` | 關鍵字（圖名 / 圖號 / 料號 / 客戶 / 產品關聯值的模糊搜尋） |
| `customer` | 客戶過濾 |
| `product` | 產品過濾 |
| `category` | 類別過濾 |
| `material` | 材質過濾 |
| `drawing_type` | 圖面類型：`customer_part`（客戶圖 A）或 `internal`（場內圖 B） |
| `drawing_subtype` | 圖面子類型：`mold` / `jig` / `machining` / `inspection` / `process` / `revision` |
| `page` | 分頁頁碼（1 起算；<1 視為 1） |
| `limit` | 每頁筆數（預設 20，上限 200，超過以 200 計） |

**回傳**：`{ "total": <int>, "items": [ ... ] }`。每筆 item 欄位：

```json
{
  "id": 123,
  "name": "Bracket Assembly",
  "mime_type": "image/png",
  "size_bytes": 204800,
  "ocr_status": "done",
  "owner_email": "user@example.com",
  "create_time": "2026-01-02T15:04:05Z",
  "update_time": "2026-01-02T15:04:05Z",
  "drawing_no": "DWG-0001",
  "part_no": "P-0001",
  "customer": "ACME",
  "revision": "A",
  "category": "sheet-metal",
  "material": "SUS304",
  "drawing_type": "customer_part",
  "drawing_subtype": null,
  "customers": ["ACME"],
  "products": ["Bracket"],
  "has_feature": true
}
```

> 時間欄位為 UTC，格式 `YYYY-MM-DDTHH:MM:SSZ`。歸類 metadata 欄位（`drawing_no`/`customer`/`drawing_type` 等）未填時為 `null`。

> `id` 為工程圖的整數 id，是 `/similar` 與 `/feature` 端點的路徑參數。
> `has_feature` 為 `true` 時，該圖才有可查的圖面特徵。

### List Similar Drawings

以指定工程圖為查詢基準，檢索相似的工程圖。`{id}` 為整數 id（來自 List Drawings）。

```bash
DRAWING_ID=123

# 預設相似圖
curl -s "${API_URL}/v1/drawing/${DRAWING_ID}/similar" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# 限制筆數 + 只比同大類
curl -s "${API_URL}/v1/drawing/${DRAWING_ID}/similar?limit=10&scope=type" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{query_has_feature, count: (.items | length)}'
```

**Path 參數**：

| 參數 | 說明 |
|------|------|
| `{id}` | 查詢基準工程圖的整數 id（必填） |

**Query 參數**（全部選填；空值不送）：

| 參數 | 說明 |
|------|------|
| `limit` | 回傳相似圖的最大筆數。預設 8；有效範圍 1–50，超出範圍會被重設回 8（不是截到 50） |
| `scope` | 相似檢索範圍。有效值：`all`（或空 = 全部）、`type`（同大類 customer_part/internal）、`subtype`（同六類細分）。**其他值不會報錯，會被靜默忽略、等同 `all`** |

**回傳**：`{ "query_has_feature": <bool>, "items": [ ... ] }`。
`query_has_feature` 表示查詢基準圖本身是否有特徵資料；為 `false` 時 `items` 為空。每筆 item 欄位：

| 欄位 | 說明 |
|------|------|
| `drawing_id` | 相似圖的整數 id |
| `similarity` | 相似度 0–100（Jaccard，主排序依據） |
| `hamming` | 漢明距離（參考用） |
| `drawing_type` | 相似圖大類（`customer_part` / `internal`；未歸類時省略） |
| `drawing_subtype` | 相似圖細分（未歸類時省略） |

> items 只有以上欄位，**不含**圖名 / 圖號等 metadata；要取得需再呼叫 `GET /v1/drawing/{drawing_id}`（見下方 Get Drawing）。

### Get Drawing Feature

取得單一工程圖的圖面特徵物件（尺寸 / GD&T / 孔數等）。`{id}` 為整數 id。

```bash
DRAWING_ID=123

curl -s "${API_URL}/v1/drawing/${DRAWING_ID}/feature" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

**Path 參數**：

| 參數 | 說明 |
|------|------|
| `{id}` | 工程圖的整數 id（必填） |

**回傳**：單一特徵物件（非清單），內含該圖擷取出的尺寸、GD&T 標註、孔數等圖面特徵。

> 僅 List Drawings 中 `has_feature: true` 的圖才有特徵可查；否則可能回空或 404。

### Get Drawing

取得單張工程圖完整資料（含 `ocr_result`、`annotations` JSONB 與客戶/產品關聯）。`/similar` 回傳的 `drawing_id` 用此端點換回圖名/圖號。

```bash
curl -s "${API_URL}/v1/drawing/123" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{id, name, drawing_no, part_no, customer, revision}'
```

**回傳**：單一物件，含 List Drawings 的所有欄位，另有 `ocr_result`、`annotations`、`remark`、`customers[]`、`products[]`。id 不存在回 404 `{"error": "drawing not found"}`。

### Get Facets

取得篩選欄位的 distinct 值（組 List Drawings filter 查詢前先查這裡）。

```bash
curl -s "${API_URL}/v1/drawing/facets" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

**回傳**：`{ "category": [...], "material": [...], "customer": [...], "product": [...] }`（各為排序後的字串陣列）。`drawing_type` / `drawing_subtype` 為固定 enum，不在 facets 內。

### Get Drawing Relations

查單張圖的衍生關聯（客戶圖 A ↔ 場內圖 B），雙向回傳、不需先知道該圖是 A 或 B。

```bash
curl -s "${API_URL}/v1/drawing/123/relations" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

**回傳**：`{ "derives": [...], "derived_from": [...] }`——`derives` 是此圖（A）衍生出的場內圖；`derived_from` 是此圖（B）的來源客戶圖。

### Get Drawing Tree

客戶視角樹：客戶圖為 root、其衍生的場內圖為 children；未掛任何客戶圖下的圖列在 `unlinked`。無參數。

```bash
curl -s "${API_URL}/v1/drawing/tree" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{customers: (.customers | length), unlinked: (.unlinked | length)}'
```

**回傳**：`{ "customers": [<node>], "unlinked": [<node>] }`。node 欄位：`id`、`name`、`drawing_no`、`revision`、`drawing_type`、`drawing_subtype`、`customers[]`、`products[]`、`children[]`（僅 customers root 有）。

---

## Stats

租戶級儀表板統計。無參數。

```bash
curl -s "${API_URL}/v1/stats" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

**回傳**：

```json
{
  "drawings": { "total": 0, "pending": 0, "done": 0, "failed": 0 },
  "dispatches": { "total": 0, "operations_total": 0, "inspection_sheets_total": 0, "measure_points_total": 0 }
}
```

> `drawings` 依 `ocr_status` 分（`pending` 含 running）；`dispatches` 為派工單與其工序/檢驗表/量測點總數。

---

## Dispatch (Read-only)

工單派工資料查詢（此 skill 只涵蓋唯讀端點）。

```bash
# 清單（不含 dispatch_data 內容）
curl -s "${API_URL}/v1/dispatch?page=1&limit=20" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# 單筆完整資料（含 dispatch_data JSONB）
curl -s "${API_URL}/v1/dispatch/45" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
```

**List Query 參數**：

| 參數 | 說明 |
|------|------|
| `page` | 分頁頁碼（預設 1） |
| `limit` | 每頁筆數（預設 20；**> 100 直接回 400**） |
| `drawing_id` | 依工程圖 id 過濾（選填；非正整數回 400） |

**List 回傳**：`{ "total": <int>, "items": [ ... ] }`，每筆 item 為 `{id, drawing_id, name, owner_email, create_time, update_time}`（不含 `dispatch_data`；需完整內容再查 `GET /v1/dispatch/{id}`）。

---

## Quote (Read-only, 需額外權限)

報價分析唯讀端點。**整個 `/v1/quote/*` 需 `apps.gdtQuote` 權限（中央權限微服務管理），無權限回 403**；project / item 的 `{id}` 為 **UUID**（非整數）。

| Operation | Method | Endpoint |
|-----------|--------|----------|
| 報價專案清單 | GET | `/v1/quote/project` |
| 專案分析（每品項單價/成本/利潤 + 專案總計） | GET | `/v1/quote/project/{id}/analysis` |
| 專案品項清單 | GET | `/v1/quote/project/{id}/item` |
| 品項估價 | GET | `/v1/quote/item/{id}/estimate` |
| 相似品項 | GET | `/v1/quote/item/{id}/similar` |
| 逆向回推費率 | GET | `/v1/quote/infer` |
| 價格規則清單 | GET | `/v1/quote/price-rule` |

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List drawings | GET | `/v1/drawing` |
| Get drawing facets | GET | `/v1/drawing/facets` |
| Get drawing (detail) | GET | `/v1/drawing/{id}` |
| List similar drawings | GET | `/v1/drawing/{id}/similar` |
| Get drawing feature | GET | `/v1/drawing/{id}/feature` |
| Get drawing relations | GET | `/v1/drawing/{id}/relations` |
| Get drawing tree | GET | `/v1/drawing/tree` |
| Get stats | GET | `/v1/stats` |
| List dispatches | GET | `/v1/dispatch` |
| Get dispatch | GET | `/v1/dispatch/{id}` |
| Quote (read) | GET | `/v1/quote/*`（需 gdtQuote 權限，id 為 UUID） |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify drawing `id`（整數 id，取自 List Drawings） |
| 400 | Bad request（invalid id / bind body 失敗 / limit 超限等） | Check path/query parameters |
