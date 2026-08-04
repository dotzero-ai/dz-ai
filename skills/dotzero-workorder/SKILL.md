---
name: dotzero-workorder
description: DotZero 工單管理。建立、查詢、更新工單，查看產品、作業員、作業紀錄和報表。支援自動 token 刷新。
compatibility: 需要先完成 dotzero-auth 認證
metadata:
  author: dotzero
  version: "1.1.0"
---

# DotZero Work Order Management

Manage work orders, products, workers, routes, operations, devices, quality, warehouse, and WMS in DotZero manufacturing systems (MES).

## IMPORTANT: Prefer MCP Tools

**If MCP tools are available** (e.g. `workorder_list`, `workorder_get`, `workorder_create`), use them directly — do NOT use curl. MCP tools handle auth and API calls automatically.

```
# Use MCP tool directly:
workorder_list(status: 2, limit: 20)
```

**Only use the curl-based approach below if MCP tools are NOT available.**

## 查詢路由指引（避免大型回應）

| 用戶問題類型 | 正確工具 | 不要用 |
|-------------|---------|---------|
| 本週/本月工單狀況、儀表板 | `workorder_dashboard(start_time_start, start_time_end)` | ~~workorder_list~~ |
| 各狀態工單統計 | `analytics_workorder_report` | ~~workorder_list~~ |
| 工單週報 | `workorder_dashboard(start_time_start, start_time_end)` | ~~weekly_report（後端已停用）~~ |
| 純計數（有幾張） | `workorder_count(status?)` | ~~workorder_list~~ |
| 查看特定工單清單 | `workorder_list(limit≤10, fields=[...], format=markdown)` | ~~format=json, limit>10~~ |
| 單筆工單詳細 | `workorder_get(uuid)` | — |

**黃金法則**：JSON format 只用於 limit ≤ 10 的少量精確查詢。彙總問題用專屬彙總工具。

## Prerequisites (curl fallback only)

1. **Authentication required first** — call `auth_login` MCP tool:
   ```
   auth_login(tenant_id: "your-tenant-id")
   ```
   This opens a browser login form. Token is saved automatically.
   If `auth_login` is not available, run: `claude mcp add dotzero-auth -- npx -y @dotzero.ai/auth-mcp` (the `--` separator is required)
2. `.dotzero/credentials.json` must exist with valid token

## 名詞對照 (Terminology)

| 常用名稱 | 正式名稱 | API 端點 | 說明 |
|----------|---------|----------|------|
| 大工單 | 母工單 / 母製令單 | `/v1/workOrders/` | 生產工單主體，包含產品、數量、截止日等 |
| 小工單 | 子工單 / 子製令單 / 工序工單 | `/v1/workOrderOpHistory/` | 工單下的個別工序作業紀錄，含作業員、機台、良品數等 |

## Token and config (curl fallback only)

With the MCP tools you do not handle tokens at all. For the curl path, the
`get_valid_token` helper (auto-refresh, 5-minute expiry buffer) and the config loading
snippet are in **[references/curl-fallback.md](references/curl-fallback.md)**.
Every `curl` example below assumes `$API_URL` and `$TOKEN` come from there.

## Work Order Status Values

| Value | Status | Description |
|-------|--------|-------------|
| 1 | Not Started | Work order created but not yet started |
| 2 | In Progress | Work order currently being processed |
| 3 | Completed | Work order finished successfully |
| 4 | Incomplete | Work order stopped before completion |

## Time Range Filter Rules

**重要**: 所有時間範圍篩選參數必須**成對提供**，只提供其中一個會回傳 0 筆結果。

| 篩選範圍 | 必須同時提供 | 適用端點 |
|----------|-------------|---------|
| Start Time | `startTimeStart` + `startTimeEnd` | workOrders, workOrderReport |
| End Time | `endTimeStart` + `endTimeEnd` | workOrders |
| Deadline | `deadlineTimeStart` + `deadlineTimeEnd` | workOrders |
| Date Range | `action=dateRange` + `startTime` + `endTime` | workOrderOpHistory |

所有時間參數格式為 ISO 8601，例如：`2026-01-24T00:00:00Z`

**正確用法**:
```bash
# 查最近 14 天的工單（必須同時給 start 和 end）
curl -s "${API_URL}/v1/workOrders/?startTimeStart=2026-01-24T00:00:00Z&startTimeEnd=2026-02-07T23:59:59Z&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**錯誤用法**（會回傳 0 筆）:
```bash
# 只給 startTimeStart，沒給 startTimeEnd → 回傳 0
curl -s "${API_URL}/v1/workOrders/?startTimeStart=2026-01-24T00:00:00Z&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Work Order Operations

### List Work Orders

```bash
curl -s "${API_URL}/v1/workOrders/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Query Parameters**:
- `limit` (number, default: 20): Max results (1-100)
- `start` (number, default: 0): Skip results for pagination
- `status` (number): Filter by status (1-4)
- `workOrderID` (string): Filter by work order ID (partial match)
- `startTimeStart` / `startTimeEnd` (ISO 8601, must pair): Filter by start time range
- `endTimeStart` / `endTimeEnd` (ISO 8601, must pair): Filter by end time range
- `deadlineTimeStart` / `deadlineTimeEnd` (ISO 8601, must pair): Filter by deadline range

(No `is_asap` query filter — the backend query struct has no such field and silently ignores it.)

**Example - List in-progress work orders**:
```bash
curl -s "${API_URL}/v1/workOrders/?status=2&limit=10" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Work Order

```bash
curl -s "${API_URL}/v1/workOrders/${WORK_ORDER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

Or by work_order_id:
```bash
curl -s "${API_URL}/v1/workOrders/${WORK_ORDER_ID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Work Order Details

Get work order with product info, route, and operations:

```bash
curl -s -X POST "${API_URL}/v1/workOrders/details" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"work_order_id\": [\"${WORK_ORDER_ID}\"]}"
```

`work_order_id` must be a **string array** — the backend binds `WorkOrderIdList{ WorkOrderId []string }`; sending a bare string returns 400.

### Create Work Order

```bash
curl -s -X POST "${API_URL}/v1/workOrders/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "work_order_id": "WO-2024-001",
    "qty": 100,
    "status": 1,
    "deadline": "2024-12-31T23:59:59Z",
    "is_asap": false,
    "memo": "Customer order #12345"
  }'
```

**Required Fields**:
- `work_order_id` (string): Unique identifier
- `qty` (number): Quantity to produce

**Optional Fields**:
- `route_uuid` (string): Production route UUID
- `status` (number, default: 1): Initial status
- `deadline` (ISO 8601): Deadline
- `order_due_date` (ISO 8601): Customer due date
- `is_asap` (boolean, default: false): Rush order flag
- `work_order_priority_ranking` (number): Priority (0=unset, 1=highest)
- `memo` (string): Notes
- `default_warehouse_uuid` (string): Warehouse UUID
- `default_warehouse_storage_uuid` (string): Storage location UUID

### Update Work Order

```bash
curl -s -X PATCH "${API_URL}/v1/workOrders/${WORK_ORDER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": 2,
    "memo": "Started production"
  }'
```

**Updatable Fields**:
- `work_order_id`, `qty`, `good`, `status`
- `deadline`, `order_due_date`
- `is_asap`, `work_order_priority_ranking`, `memo`

### Delete Work Order

```bash
curl -s -X DELETE "${API_URL}/v1/workOrders/${WORK_ORDER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Warning**: This is a destructive operation.

---

## Product Operations

### List Products

```bash
curl -s "${API_URL}/v1/products/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**:
- `limit`, `start`: Pagination
- `name` (string): Filter by name (partial match)
- `number` (string): Filter by product number (partial match)
- `category` (string): Filter by category
- `isActive` (boolean): Filter by active status

### Get Product

```bash
curl -s "${API_URL}/v1/products/${PRODUCT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Create Product

```bash
curl -s -X POST "${API_URL}/v1/products/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "PROD-001",
    "name": "Widget A",
    "category": "Components",
    "specification": "Size: 10x10x5cm",
    "is_active": true
  }'
```

**Required Fields**:
- `number` (string): Product number (material number)
- `name` (string): Product name

**Optional Fields**:
- `category`, `specification`, `memo`, `remarks`
- `product_type` (number, default: 1): 1=in-house, 2=outsourced
- `is_active` (boolean, default: true)
- `minimum_stock_level` (number)

### Update Product

```bash
curl -s -X PATCH "${API_URL}/v1/products/${PRODUCT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Widget A - Updated",
    "is_active": false
  }'
```

---

## Worker Operations

### List Workers

```bash
curl -s "${API_URL}/v1/worker/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**:
- `limit`, `start`: Pagination
- `workerID` (string): Filter by worker ID (badge number)
- `workerName` (string): Filter by name (partial match)

### Get Worker

```bash
curl -s "${API_URL}/v1/worker/${WORKER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Operation History

### List Operation History

```bash
curl -s "${API_URL}/v1/workOrderOpHistory/?limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters** — this endpoint supports ONLY two modes:
- **Date range**: `action=dateRange` + `startTime` / `endTime` (ISO 8601, must pair). Returns ALL records in the range (no pagination — `limit`/`start` are ignored in this mode).
- **Plain pagination**: `limit`, `start` (only when `action` is not `dateRange`).

The endpoint does **not** support `workOrderID` / `deviceUUID` / `status` filters — the handler never reads them, so they are silently ignored (you get unfiltered results).
- To filter by a work order, use `GET /v1/workOrderOpHistory/{uuid}/byWorkOrderUuid`.
- To filter by device/status, use `GET /v1/workOrderReport/` (supports `workOrderID`/`deviceUUID`/`status`).

**Note**: This endpoint uses `startTime`/`endTime` (not `startTimeStart`/`startTimeEnd` like workOrders).

**Example - Filter by date range**:
```bash
curl -s "${API_URL}/v1/workOrderOpHistory/?action=dateRange&startTime=2026-01-24T00:00:00Z&endTime=2026-02-07T23:59:59Z&limit=20" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get Operations for Work Order

```bash
curl -s "${API_URL}/v1/workOrderOpHistory/${WORK_ORDER_UUID}/byWorkOrderUuid" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Reports

### 生產分析工具選擇指南 (MCP Tool Selection for Analytics)

**IMPORTANT**: 依查詢意圖選擇正確工具。錯誤的工具會返回不準確的時間範圍資料。

#### 問法 → 工具對應

| 問法模式 | 關鍵概念 | 正確工具 | 時間參數的意義 |
|---------|---------|---------|--------------|
| 最近一週「做了」多少/什麼物料 | 實際產出 | `material_production_ranking` | 實際作業時間 |
| 本月「產量」最高的料號 | 實際產出聚合 | `material_production_ranking` | 實際作業時間 |
| 今天/本週「有哪些工單」在生產 | 工單排程狀態 | `workorder_list` | 工單計劃開工時間 |
| 工單「什麼時候開工/完工」 | 工單計劃時間 | `workorder_list` / `workorder_get` | 計劃開工/完工時間 |
| 某工單的「生產記錄」/工序 | 子工單明細 | `operation_history_by_workorder` | 不需要時間，直接用 uuid |
| 「整體」這週做了多少（良品/不良率）| 產出統計 | `production_summary` | 實際作業時間 |
| 「哪個作業員」最有效率 | 人員效率 | `worker_efficiency_ranking` | 實際作業時間 |
| 「哪台機台」使用率最高 | 設備稼動 | `device_utilization_ranking` | 實際作業時間 |
| 完整週報（生產+人員+設備） | 全面報告 | `workorder_dashboard` | 實際作業時間 |

**時間概念辨別（核心知識）：**
- 「做了」「產出」「生產了多少」「哪個物料最多」→ **實際作業時間** → 用 `material_production_ranking` / `production_summary`
- 「工單」「排程」「計劃」「今天/本週的工單」→ **工單計劃時間** → 用 `workorder_list` 的 `start_time_start/end`

**時間過濾說明**:
- `material_production_ranking` 使用 `/v1/workOrderOpHistory/` 的 `action=dateRange`，過濾**實際作業時間**與指定範圍重疊的紀錄（包含「進行中→完工」的工單）
- `workorder_list` / `workorder_report` 的 `start_time_start/end` 篩選的是工單**計劃開工時間**，非實際作業時間
- **不要**用 `workorder_report` 或 `operation_history_list` 做物料產量聚合 — 前者時間過濾不可靠，後者資料量太大

### Material Production Ranking (MCP Only)

```
# MCP tool (preferred):
material_production_ranking(
  start_time_start: "2026-02-25T00:00:00+08:00",
  start_time_end: "2026-03-04T23:59:59+08:00",
  top_n: 10
)
```

> No curl equivalent — this tool paginates and aggregates server-side via /v1/workOrderOpHistory/.

### Work Order Report (curl fallback — raw records only)

> **WARNING**: `/v1/workOrderReport/` time filter (`startTimeStart/End`) filters by **scheduled start time of the work order**, not actual operation time. Results may include records outside the intended period. Use `material_production_ranking` MCP tool for accurate material production queries.

```bash
curl -s "${API_URL}/v1/workOrderReport/?startTimeStart=2024-01-01T00:00:00Z&startTimeEnd=2024-01-31T23:59:59Z&limit=50" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**:
- `startTimeStart` / `startTimeEnd` (ISO 8601, must pair): Work order scheduled start time range (not operation time)
- `workOrderID` (string): Filter by work order
- `deviceUUID` (string): Filter by device
- `status` (number): Filter by status

**No pagination**: this endpoint ignores `limit`/`start` and returns ALL matching records (grouped by status). Always pass a `startTimeStart`/`startTimeEnd` range to bound the response. (The `workorder_report` MCP tool truncates client-side; raw curl has no such guard.)

### Operation History with Date Range (actual operation time filter)

```bash
# Fetch operations that overlapped with the specified time range (includes in-progress → completed)
curl -s "${API_URL}/v1/workOrderOpHistory/?action=dateRange&startTime=2026-02-25T00:00:00%2B08:00&endTime=2026-03-04T23:59:59%2B08:00&limit=100" \
  -H "Authorization: Bearer ${TOKEN}"
```

This is the correct endpoint for "production during this week" — uses actual operation time overlap.

---

## Usage Examples

### Workflow: Check and Update Rush Orders

```bash
# 1. List in-progress work orders
curl -s "${API_URL}/v1/workOrders/?status=2" \
  -H "Authorization: Bearer ${TOKEN}"

# 2. Get details for specific order (work_order_id must be a string array)
curl -s -X POST "${API_URL}/v1/workOrders/details" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"work_order_id": ["WO-2024-001"]}'

# 3. Mark as completed
curl -s -X PATCH "${API_URL}/v1/workOrders/${UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status": 3}'
```

### Workflow: Create Work Order with Product

```bash
# 1. Find product
curl -s "${API_URL}/v1/products/?name=Widget" \
  -H "Authorization: Bearer ${TOKEN}"

# 2. Create work order
curl -s -X POST "${API_URL}/v1/workOrders/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "work_order_id": "WO-2024-002",
    "qty": 500,
    "deadline": "2024-02-15T17:00:00Z",
    "is_asap": true,
    "memo": "Urgent customer order"
  }'
```

### Workflow: Weekly Production Report

```bash
# Get operations for this week
curl -s "${API_URL}/v1/workOrderReport/?startTimeStart=2024-01-15T00:00:00Z&startTimeEnd=2024-01-21T23:59:59Z&limit=100" \
  -H "Authorization: Bearer ${TOKEN}"
```

---

## Error Handling

| HTTP Code | Cause | Solution |
|-----------|-------|----------|
| 401 | Token expired/invalid | Refresh token or re-login |
| 403 | Permission denied | Check user permissions |
| 404 | Resource not found | Verify UUID or ID |
| 422 | Validation error | Check input parameters |
| 429 | Rate limited | Wait before retrying |

On 401 the token has expired — refresh and retry; see
**[references/curl-fallback.md](references/curl-fallback.md)**.

---

## Quick Reference

The MCP tools cover the common operations. The **complete endpoint table** (core MES,
routes, operation history, devices/stations, quality/defects, warehouse) lives in
**[references/endpoints.md](references/endpoints.md)** — consult it when you need an
endpoint the MCP tools do not expose.
