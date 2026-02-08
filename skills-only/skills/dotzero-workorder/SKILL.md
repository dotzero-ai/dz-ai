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

## Prerequisites

1. Complete `dotzero-auth` authentication first
2. `.dotzero/credentials.json` must exist with valid token
3. `.dotzero/config.json` must have `work_order_api_url` set

## Setup

Ensure config has the Work Order API URL:

```bash
cat .dotzero/config.json
# Should contain:
# {
#   "user_api_url": "https://dotzerotech-user-api.dotzero.app",
#   "work_order_api_url": "https://YOUR-COMPANY.dotzero.app"
# }
```

## 名詞對照 (Terminology)

| 常用名稱 | 正式名稱 | API 端點 | 說明 |
|----------|---------|----------|------|
| 大工單 | 母工單 / 母製令單 | `/v1/workOrders/` | 生產工單主體，包含產品、數量、截止日等 |
| 小工單 | 子工單 / 子製令單 / 工序工單 | `/v1/workOrderOpHistory/` | 工單下的個別工序作業紀錄，含作業員、機台、良品數等 |

## Get Valid Token (Auto-Refresh)

**重要**: Token 會在 1 小時後過期。在每次 API 呼叫前，使用以下函數自動刷新過期的 token：

```bash
# Function to get valid token (auto-refresh if expired)
get_valid_token() {
  CREDS_FILE=".dotzero/credentials.json"
  CONFIG_FILE=".dotzero/config.json"

  if [ ! -f "$CREDS_FILE" ]; then
    echo "ERROR: Not logged in" >&2
    return 1
  fi

  CREDS=$(cat "$CREDS_FILE")
  EXPIRES_AT=$(echo "$CREDS" | jq -r '.expires_at // empty')

  # Check if token is expired (with 5 minute buffer)
  if [ -n "$EXPIRES_AT" ]; then
    EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" "+%s" 2>/dev/null || date -d "$EXPIRES_AT" "+%s" 2>/dev/null || echo "0")
    NOW_TS=$(date "+%s")
    BUFFER=300

    if [ $((EXPIRES_TS - BUFFER)) -gt $NOW_TS ]; then
      echo "$CREDS" | jq -r '.token'
      return 0
    fi
  fi

  # Token expired, refresh it
  echo "Token expired, refreshing..." >&2
  REFRESH_TOKEN=$(echo "$CREDS" | jq -r '.refresh_token')
  TENANT_ID=$(echo "$CREDS" | jq -r '.tenant_id')
  USER_API_URL=$(cat "$CONFIG_FILE" | jq -r '.user_api_url')

  RESPONSE=$(curl -s -X POST \
    "${USER_API_URL}/v2/auth/token?tenantID=${TENANT_ID}" \
    -H "Content-Type: application/json" \
    -d "{\"grant_type\":\"refresh_token\",\"refresh_token\":\"${REFRESH_TOKEN}\"}")

  # /v2/auth/token returns a plain JWT string
  NEW_TOKEN=""
  if echo "$RESPONSE" | jq -e 'type == "string"' > /dev/null 2>&1; then
    NEW_TOKEN=$(echo "$RESPONSE" | jq -r '.')
  elif [[ "$RESPONSE" == eyJ* ]]; then
    NEW_TOKEN="$RESPONSE"
  fi

  if [ -n "$NEW_TOKEN" ]; then
    NEW_EXPIRES=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")
    echo "$CREDS" | jq --arg tok "$NEW_TOKEN" --arg exp "$NEW_EXPIRES" '
      .token = $tok | .expires_at = $exp
    ' > "$CREDS_FILE"
    echo "$NEW_TOKEN"
    return 0
  else
    echo "ERROR: Refresh failed, please login again" >&2
    return 1
  fi
}
```

## Read Config and Token

Before any API call, get a valid token:

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.work_order_api_url')

# Get valid token (auto-refresh if expired)
TOKEN=$(get_valid_token)
```

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
curl -s "${API_URL}/v1/workOrders?limit=20" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Query Parameters**:
- `limit` (number, default: 20): Max results (1-100)
- `start` (number, default: 0): Skip results for pagination
- `status` (number): Filter by status (1-4)
- `workOrderID` (string): Filter by work order ID (partial match)
- `is_asap` (boolean): Filter for rush orders only
- `startTimeStart` / `startTimeEnd` (ISO 8601, must pair): Filter by start time range
- `endTimeStart` / `endTimeEnd` (ISO 8601, must pair): Filter by end time range
- `deadlineTimeStart` / `deadlineTimeEnd` (ISO 8601, must pair): Filter by deadline range

**Example - List in-progress rush orders**:
```bash
curl -s "${API_URL}/v1/workOrders/?status=2&is_asap=true&limit=10" \
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
  -d "{\"work_order_id\": \"${WORK_ORDER_ID}\"}"
```

### Create Work Order

```bash
curl -s -X POST "${API_URL}/v1/workOrders" \
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
curl -s "${API_URL}/v1/products?limit=20" \
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
curl -s -X POST "${API_URL}/v1/products" \
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

**Query Parameters**:
- `limit`, `start`: Pagination
- `workOrderID` (string): Filter by work order ID
- `deviceUUID` (string): Filter by device
- `status` (number): Filter by status
- `action=dateRange` (required when using time filters)
- `startTime` / `endTime` (ISO 8601, must pair): Filter by time range

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

### Work Order Report

```bash
curl -s "${API_URL}/v1/workOrderReport/?startTimeStart=2024-01-01T00:00:00Z&startTimeEnd=2024-01-31T23:59:59Z&limit=50" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Query Parameters**:
- `startTimeStart` / `startTimeEnd` (ISO 8601, must pair): Report period
- `workOrderID` (string): Filter by work order
- `deviceUUID` (string): Filter by device
- `limit`, `start`: Pagination

---

## Usage Examples

### Workflow: Check and Update Rush Orders

```bash
# 1. List rush orders in progress
curl -s "${API_URL}/v1/workOrders?status=2&is_asap=true" \
  -H "Authorization: Bearer ${TOKEN}"

# 2. Get details for specific order
curl -s -X POST "${API_URL}/v1/workOrders/details" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"work_order_id": "WO-2024-001"}'

# 3. Mark as completed
curl -s -X PATCH "${API_URL}/v1/workOrders/${UUID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status": 3}'
```

### Workflow: Create Work Order with Product

```bash
# 1. Find product
curl -s "${API_URL}/v1/products?name=Widget" \
  -H "Authorization: Bearer ${TOKEN}"

# 2. Create work order
curl -s -X POST "${API_URL}/v1/workOrders" \
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

### On 401 Error

When you get a 401 error, the token has expired. Use `get_valid_token` function which auto-refreshes:

```bash
# Automatically refresh and get new token
TOKEN=$(get_valid_token)

# If using helper scripts:
TOKEN=$(./scripts/dotzero-token.sh get)

# Retry the failed request with new token
curl -s "${API_URL}/v1/workOrders" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Tip**: Always use `get_valid_token` before making API calls to avoid 401 errors.

---

## Quick Reference

### Core MES

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List work orders | GET | `/v1/workOrders/` |
| Get work order | GET | `/v1/workOrders/{id}` |
| Get work order details | POST | `/v1/workOrders/details` (body: work_order_id) |
| Create work order | POST | `/v1/workOrders` |
| Update work order | PATCH | `/v1/workOrders/{uuid}` |
| Delete work order | DELETE | `/v1/workOrders/{uuid}` |
| Work order count | GET | `/v1/count/workOrders` |
| List products | GET | `/v1/products/` |
| Get product | GET | `/v1/products/{uuid}` |
| Get product details | GET | `/v1/products/{uuid}/details` |
| Create product | POST | `/v1/products` |
| Update product | PATCH | `/v1/products/{uuid}` |
| Copy product | POST | `/v1/products/{uuid}/copyProduct` |
| List workers | GET | `/v1/worker/` |
| Get worker | GET | `/v1/worker/{uuid}` |
| Create worker | POST | `/v1/worker/` |
| Update worker | PATCH | `/v1/worker/{uuid}` |
| Delete worker | DELETE | `/v1/worker/{uuid}` |

### Routes & Operations

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List routes | GET | `/v1/routes/` |
| Get route | GET | `/v1/routes/{uuid}` |
| Create route | POST | `/v1/routes/` |
| Update route | PATCH | `/v1/routes/{uuid}` |
| Delete route | DELETE | `/v1/routes/{uuid}` |
| Routes by product | GET | `/v1/routes/{productUuid}/byProductUuid` |
| Copy route | POST | `/v1/routes/{uuid}/copyRoute` |
| List operations | GET | `/v1/operation/` |
| Get operation | GET | `/v1/operation/{uuid}` |
| Create operation | POST | `/v1/operation/` |
| Update operation | PATCH | `/v1/operation/{uuid}` |
| Delete operation | DELETE | `/v1/operation/{uuid}` |
| List route operations | GET | `/v1/routeOperation` |
| Get route operation | GET | `/v1/routeOperation/{uuid}` |
| Create route operation | POST | `/v1/routeOperation/` |
| Update route operation | PATCH | `/v1/routeOperation/{uuid}` |
| Delete route operation | DELETE | `/v1/routeOperation/{uuid}` |
| Route ops by route | GET | `/v1/routeOperation/{routeUuid}/byRouteUuid` |

### Operation History & Reports

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List op history | GET | `/v1/workOrderOpHistory/` |
| Get op history | GET | `/v1/workOrderOpHistory/{uuid}` |
| Create op history | POST | `/v1/workOrderOpHistory/` |
| Batch create op history | POST | `/v1/workOrderOpHistory/many` |
| Delete op history | DELETE | `/v1/workOrderOpHistory/{uuid}` |
| Op history by work order | GET | `/v1/workOrderOpHistory/{uuid}/byWorkOrderUuid` |
| Op history timeline | GET | `/v1/workOrderOpHistory/{uuid}/timeline` |
| Work order report | GET | `/v1/workOrderReport/` |
| Update report | PATCH | `/v1/workOrderReport/{uuid}` |
| Weekly report | GET | `/v1/report/weeklyReport` |
| Analytics operations | GET | `/v1/analytics/operations` |
| Analytics WO report | GET | `/v1/analytics/workOrderReport` |
| Worker efficiency ranking | MCP | `worker_efficiency_ranking` (MCP aggregation tool, no direct curl) |
| Device utilization ranking | MCP | `device_utilization_ranking` (MCP aggregation tool, no direct curl) |
| Production summary | MCP | `production_summary` (MCP aggregation tool, no direct curl) |

### Devices & Stations

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List devices | GET | `/v1/deviceInfo/` |
| Get device | GET | `/v1/deviceInfo/{uuid}` |
| Create device | POST | `/v1/deviceInfo/` |
| Update device | PATCH | `/v1/deviceInfo/{uuid}` |
| Delete device | DELETE | `/v1/deviceInfo/{uuid}` |
| List stations | GET | `/v1/stationInfo/` |
| Get station | GET | `/v1/stationInfo/{uuid}` |
| Create station | POST | `/v1/stationInfo/` |
| Update station | PATCH | `/v1/stationInfo/{uuid}` |
| Delete station | DELETE | `/v1/stationInfo/{uuid}` |
| Station device list | GET | `/v1/stationInfo/{uuid}/deviceList` |

### Quality & Defects

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List defect reasons | GET | `/v1/defectReason/` |
| Create defect reason | POST | `/v1/defectReason/` |
| Update defect reason | PATCH | `/v1/defectReason/{uuid}` |
| Delete defect reason | DELETE | `/v1/defectReason/{uuid}` |
| List defect categories | GET | `/v1/defectReasonCategory/` |
| Get defect category | GET | `/v1/defectReasonCategory/{uuid}` |
| Create defect category | POST | `/v1/defectReasonCategory/` |
| Update defect category | PATCH | `/v1/defectReasonCategory/{uuid}` |
| List abnormal history | GET | `/v1/workHourAbnormalHistory/` |
| Get abnormal history | GET | `/v1/workHourAbnormalHistory/{uuid}` |
| Create abnormal history | POST | `/v1/workHourAbnormalHistory/` |
| Update abnormal history | PATCH | `/v1/workHourAbnormalHistory/{uuid}` |
| Abnormal by work order | GET | `/v1/workHourAbnormalHistory/{workOrderId}/byWorkOrderId` |
| List abnormal categories | GET | `/v1/workHourAbnormalCategory/` |
| Create abnormal category | POST | `/v1/workHourAbnormalCategory/` |
| List abnormal states | GET | `/v1/workHourAbnormalState/` |
| Create abnormal state | POST | `/v1/workHourAbnormalState/` |
| List op product BOMs | GET | `/v1/operationProductBom/` |
| Create op product BOM | POST | `/v1/operationProductBom/` |
| Update op product BOM | PATCH | `/v1/operationProductBom/{uuid}` |
| Delete op product BOM | DELETE | `/v1/operationProductBom/{uuid}` |

### Warehouse & Inventory

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List warehouses | GET | `/v1/warehouse/` |
| Get warehouse | GET | `/v1/warehouse/{uuid}` |
| Create warehouse | POST | `/v1/warehouse/` |
| Update warehouse | PATCH | `/v1/warehouse/{uuid}` |
| List storage locations | GET | `/v1/warehouseStorage/` |
| Get storage location | GET | `/v1/warehouseStorage/{uuid}` |
| Create storage location | POST | `/v1/warehouseStorage/` |
| Update storage location | PATCH | `/v1/warehouseStorage/{uuid}` |
| List product storage | GET | `/v1/productStorage/` |
| Get product storage | GET | `/v1/productStorage/{uuid}` |
| Product storage by product | GET | `/v1/productStorage/{productUuid}/byProductUuid` |
| WMS check inventory | PATCH | `/v1/wms/checkInventory` |
| WMS query storage | POST | `/v1/wms/queryProductStorage` |
| WMS storage history | GET | `/v1/wms/queryProductStorageHistory` |
| WMS minimal stock count | GET | `/v1/wms/minimalStockLevelProductCount` |
