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
| `q` | 關鍵字（圖名 / 圖號 / 料號等的全文搜尋） |
| `customer` | 客戶過濾 |
| `product` | 產品過濾 |
| `category` | 類別過濾 |
| `material` | 材質過濾 |
| `drawing_type` | 圖面類型 |
| `drawing_subtype` | 圖面子類型 |
| `page` | 分頁頁碼 |
| `limit` | 每頁筆數 |

**回傳**：`{ "total": <int>, "items": [ ... ] }`。每筆 item 欄位：

```json
{
  "id": 123,
  "name": "Bracket Assembly",
  "drawing_no": "DWG-0001",
  "part_no": "P-0001",
  "revision": "A",
  "category": "sheet-metal",
  "material": "SUS304",
  "drawing_type": "part",
  "drawing_subtype": "machined",
  "ocr_status": "done",
  "has_feature": true
}
```

> `id` 為工程圖的整數 id，是 `/similar` 與 `/feature` 端點的路徑參數。
> `has_feature` 為 `true` 時，該圖才有可查的圖面特徵。

### List Similar Drawings

以指定工程圖為查詢基準，檢索相似的工程圖。`{id}` 為整數 id（來自 List Drawings）。

```bash
DRAWING_ID=123

# 預設相似圖
curl -s "${API_URL}/v1/drawing/${DRAWING_ID}/similar" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'

# 限制筆數 + 指定範圍
curl -s "${API_URL}/v1/drawing/${DRAWING_ID}/similar?limit=10&scope=customer" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{query_has_feature, count: (.items | length)}'
```

**Path 參數**：

| 參數 | 說明 |
|------|------|
| `{id}` | 查詢基準工程圖的整數 id（必填） |

**Query 參數**（全部選填；空值不送）：

| 參數 | 說明 |
|------|------|
| `limit` | 回傳相似圖的最大筆數 |
| `scope` | 相似檢索範圍 |

**回傳**：`{ "query_has_feature": <bool>, "items": [ ... ] }`。
`query_has_feature` 表示查詢基準圖本身是否有特徵資料（無特徵時相似結果可能受限）；`items` 為相似工程圖清單。

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

---

## Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List drawings | GET | `/v1/drawing` |
| List similar drawings | GET | `/v1/drawing/{id}/similar` |
| Get drawing feature | GET | `/v1/drawing/{id}/feature` |

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify drawing `id`（整數 id，取自 List Drawings） |
| 422 | Validation error | Check query parameters |
