# Work Order API Skill

MCP skill for managing work orders, products, workers, and operation history in manufacturing execution systems (MES).

## Overview

This skill provides 100 tools for interacting with the Work Order API:

- **Authentication** (2): Login and check auth status
- **Work Orders** (7): Full CRUD operations with filtering, pagination, and count
- **Products** (6): Manage product catalog with details and copy
- **Workers** (5): Full CRUD for worker directory
- **Operation History** (7): Track operation history, create/delete records, view timeline
- **Reports & Analytics** (8): Work order reports, weekly reports, operation analytics, worker efficiency ranking, device utilization ranking, production summary
- **Routes** (7): Production route management with copy
- **Operations** (5): Operation (工序) CRUD
- **Route Operations** (6): Route-operation mapping management
- **Devices** (5): Device/machine management
- **Defect Reasons** (4): Defect reason management
- **Defect Reason Categories** (4): Defect category management
- **Stations** (6): Station management with device lists
- **Abnormal History** (5): Work hour abnormal tracking
- **Abnormal Config** (4): Abnormal category and state management
- **Operation Product BOM** (4): Manufacturing BOM management
- **Warehouses** (4): Warehouse management
- **Warehouse Storage** (4): Storage location management
- **Product Storage** (3): Product storage tracking
- **WMS** (4): Warehouse management system operations

## Prerequisites

### Authentication Required

Before using most tools, you need to authenticate. The `tenant_id` is required for authentication.

**IMPORTANT**: If you don't know the user's tenant_id, you must ask them for it.

### Method 1: Use Auth Skill (Recommended)

Use the centralized auth skill first:
```
# See skills/auth/SKILL.md for details
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

### Method 2: Direct Login

Use the `auth_login` tool in this skill:
```
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

### Method 3: Environment Token (Automation)

Set the `WORK_ORDER_API_TOKEN` environment variable with a valid JWT token.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WORK_ORDER_API_URL` | No | `https://work-order-api.dotzero.app` | Work Order API base URL |
| `WORK_ORDER_API_TOKEN` | No | — | JWT token (or use auth_login) |
| `USER_API_URL` | No | `https://dotzerotech-user-api.dotzero.app` | Auth API URL |

## Work Order Status Values

| Value | Status | Description |
|-------|--------|-------------|
| 1 | Not Started | Work order created but not yet started |
| 2 | In Progress | Work order currently being processed |
| 3 | Completed | Work order finished successfully |
| 4 | Incomplete | Work order stopped before completion |

## Tools Reference

### Authentication Tools

#### auth_login
Authenticate with email, password, and tenant_id to obtain a JWT token.

**Parameters:**
- `email` (string, required): User email address
- `password` (string, required): User password
- `tenant_id` (string, required): Tenant ID (ask user if not known)

**Returns:** Authentication status and user info

#### auth_status
Check if the client is authenticated.

**Parameters:** None

**Returns:** Current authentication status and API URL

---

### Work Order Tools

#### workorder_list
List work orders with optional filters.

**Parameters:**
- `status` (number, optional): Filter by status (1-4)
- `start_time_start` (string, optional): Filter by start time (ISO 8601, range start)
- `start_time_end` (string, optional): Filter by start time (ISO 8601, range end)
- `end_time_start` (string, optional): Filter by end time (ISO 8601, range start)
- `end_time_end` (string, optional): Filter by end time (ISO 8601, range end)
- `deadline_start` (string, optional): Filter by deadline (ISO 8601, range start)
- `deadline_end` (string, optional): Filter by deadline (ISO 8601, range end)
- `work_order_id` (string, optional): Filter by work order ID (partial match)
- `is_asap` (boolean, optional): Filter for rush orders only
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Skip results for pagination
- `response_format` ('markdown'|'json', default: 'markdown'): Output format

**Returns:** List of work orders with pagination info

**Example:**
```
workorder_list(status: 2, is_asap: true, limit: 10)
```

#### workorder_get
Get a specific work order by UUID or work_order_id.

**Parameters:**
- `id` (string, required): Work order UUID or work_order_id
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Work order details

#### workorder_create
Create a new work order.

**Parameters:**
- `work_order_id` (string, required): Unique work order identifier
- `qty` (number, required): Quantity to produce
- `route_uuid` (string, optional): Production route UUID
- `status` (number, default: 1): Initial status
- `deadline` (string, optional): Deadline (ISO 8601)
- `order_due_date` (string, optional): Customer due date (ISO 8601)
- `is_asap` (boolean, default: false): Mark as rush order
- `work_order_priority_ranking` (number, optional): Priority (0=unset, 1=highest)
- `memo` (string, optional): Notes
- `default_warehouse_uuid` (string, optional): Warehouse UUID
- `default_warehouse_storage_uuid` (string, optional): Storage location UUID
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Created work order

**Example:**
```
workorder_create(
  work_order_id: "WO-2024-001",
  qty: 100,
  deadline: "2024-12-31T23:59:59Z",
  is_asap: true
)
```

#### workorder_update
Update an existing work order.

**Parameters:**
- `id` (string, required): Work order UUID
- `work_order_id` (string, optional): Update identifier
- `qty` (number, optional): Update quantity
- `good` (number, optional): Update good parts count
- `status` (number, optional): Update status (1-4)
- `deadline` (string, optional): Update deadline (ISO 8601)
- `order_due_date` (string, optional): Update due date (ISO 8601)
- `is_asap` (boolean, optional): Update rush flag
- `work_order_priority_ranking` (number, optional): Update priority
- `memo` (string, optional): Update notes
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Updated work order

#### workorder_delete
Delete a work order by UUID.

**Parameters:**
- `id` (string, required): Work order UUID to delete

**Returns:** Confirmation message

**Warning:** This is a destructive operation.

#### workorder_details
Get work order with full details including product info and operations.

**Parameters:**
- `work_order_id` (string, required): Work order ID
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Work order with product, route, and operation details

---

### Product Tools

#### product_list
List products with optional filters.

**Parameters:**
- `name` (string, optional): Filter by name (partial match)
- `number` (string, optional): Filter by product number (partial match)
- `category` (string, optional): Filter by category
- `is_active` (boolean, optional): Filter by active status
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Skip results for pagination
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** List of products with pagination info

#### product_get
Get a specific product by UUID.

**Parameters:**
- `id` (string, required): Product UUID
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Product details

#### product_create
Create a new product.

**Parameters:**
- `number` (string, required): Product number (material number)
- `name` (string, required): Product name
- `category` (string, optional): Category
- `specification` (string, optional): Specification
- `memo` (string, optional): Notes
- `remarks` (string, optional): Remarks
- `product_type` (number, default: 1): Type (1=in-house, 2=outsourced)
- `is_active` (boolean, default: true): Active status
- `minimum_stock_level` (number, optional): Min stock level
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Created product

#### product_update
Update an existing product.

**Parameters:**
- `id` (string, required): Product UUID
- `number` (string, optional): Update product number
- `name` (string, optional): Update name
- `category` (string, optional): Update category
- `specification` (string, optional): Update specification
- `memo` (string, optional): Update notes
- `remarks` (string, optional): Update remarks
- `is_active` (boolean, optional): Update active status
- `minimum_stock_level` (number, optional): Update min stock
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Updated product

---

### Worker Tools

#### worker_list
List workers with optional filters.

**Parameters:**
- `worker_id` (string, optional): Filter by worker ID (badge number)
- `worker_name` (string, optional): Filter by name (partial match)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Skip results for pagination
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** List of workers with pagination info

#### worker_get
Get a specific worker by UUID.

**Parameters:**
- `id` (string, required): Worker UUID
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Worker details

---

### Operation History Tools

#### operation_history_list
List work order operation history with optional filters.

**Parameters:**
- `work_order_uuid` (string, optional): Filter by work order UUID
- `work_order_id` (string, optional): Filter by work order ID
- `worker_uuid` (string, optional): Filter by worker UUID
- `device_uuid` (string, optional): Filter by device UUID
- `status` (number, optional): Filter by status
- `start_time_start` (string, optional): Filter by time range (ISO 8601, start)
- `start_time_end` (string, optional): Filter by time range (ISO 8601, end)
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Skip results for pagination
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** List of operation history records

#### operation_history_by_workorder
Get all operation history for a specific work order.

**Parameters:**
- `work_order_uuid` (string, required): Work order UUID
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** All operations for the work order

---

### Report Tools

#### workorder_report
Get work order operation report with filters.

**Parameters:**
- `start_time_start` (string, optional): Report period start (ISO 8601)
- `start_time_end` (string, optional): Report period end (ISO 8601)
- `work_order_id` (string, optional): Filter by work order ID
- `worker_uuid` (string, optional): Filter by worker UUID
- `device_uuid` (string, optional): Filter by device UUID
- `limit` (number, default: 50): Max results (1-100)
- `offset` (number, default: 0): Skip results for pagination
- `response_format` ('markdown'|'json', default: 'markdown')

**Returns:** Operation report data

**Example:**
```
workorder_report(
  start_time_start: "2024-01-01T00:00:00Z",
  start_time_end: "2024-01-31T23:59:59Z"
)
```

#### report_update
Update an existing work order report.

**Parameters:**
- `id` (string, required): Report UUID
- `memo` (string, optional): Update notes

**Returns:** Updated report

#### weekly_report
Get weekly production report summary.

**Parameters:** None

**Returns:** Weekly report data

#### analytics_operations
Get operation analytics data.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** Operation analytics

#### analytics_workorder_report
Get work order report analytics.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** Work order report analytics

#### worker_efficiency_ranking
Rank workers by production efficiency (good parts per hour). Returns a compact ranked table.

**Parameters:**
- `start_time_start` (string, required): Period start (ISO 8601)
- `start_time_end` (string, required): Period end (ISO 8601)
- `work_order_id` (string, optional): Filter to specific work order
- `top_n` (number, default: 10): Number of workers to show (1-50)

**Returns:** Markdown table with columns: Rank, Worker, ID, Ops, Qty, Good, Defect, Good Rate, Hours, Good/Hr

**Example:**
```
worker_efficiency_ranking(
  start_time_start: "2024-01-01T00:00:00Z",
  start_time_end: "2024-01-14T23:59:59Z",
  top_n: 5
)
```

#### device_utilization_ranking
Rank devices/machines by utilization (total hours used). Returns a compact ranked table.

**Parameters:**
- `start_time_start` (string, required): Period start (ISO 8601)
- `start_time_end` (string, required): Period end (ISO 8601)
- `work_order_id` (string, optional): Filter to specific work order
- `top_n` (number, default: 10): Number of devices to show (1-50)

**Returns:** Markdown table with columns: Rank, Device, Ops, Qty, Good, Defect, Good Rate, Hours, Good/Hr

**Example:**
```
device_utilization_ranking(
  start_time_start: "2024-01-01T00:00:00Z",
  start_time_end: "2024-01-14T23:59:59Z"
)
```

#### production_summary
Summarize production output with aggregated metrics. Returns a compact summary table.

**Parameters:**
- `start_time_start` (string, required): Period start (ISO 8601)
- `start_time_end` (string, required): Period end (ISO 8601)
- `work_order_id` (string, optional): Filter to specific work order
- `group_by` (string, default: "overall"): Group by "overall", "work_order", or "operation"

**Returns:** Markdown table with columns: [Group], Ops, Qty, Good, Defect, Defect Rate, Hours, Good/Hr

**Example:**
```
production_summary(
  start_time_start: "2024-01-01T00:00:00Z",
  start_time_end: "2024-01-07T23:59:59Z",
  group_by: "work_order"
)
```

---

### Route Tools

#### route_list
List production routes with optional filters.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset

**Returns:** List of routes

#### route_get
Get a specific route by UUID.

**Parameters:**
- `id` (string, required): Route UUID

**Returns:** Route details

#### route_create
Create a new production route.

**Parameters:**
- `name` (string, required): Route name
- `memo` (string, optional): Notes

**Returns:** Created route

#### route_update
Update an existing route.

**Parameters:**
- `id` (string, required): Route UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated route

#### route_delete
Delete a route by UUID.

**Parameters:**
- `id` (string, required): Route UUID

**Returns:** Confirmation message

#### route_by_product
Get routes associated with a product.

**Parameters:**
- `product_uuid` (string, required): Product UUID

**Returns:** List of routes for the product

#### route_copy
Copy/duplicate an existing route.

**Parameters:**
- `id` (string, required): Route UUID to copy

**Returns:** Newly created route copy

---

### Operation Tools (工序)

#### operation_list
List operations.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset

**Returns:** List of operations

#### operation_get
Get a specific operation by UUID.

**Parameters:**
- `id` (string, required): Operation UUID

**Returns:** Operation details

#### operation_create
Create a new operation.

**Parameters:**
- `name` (string, required): Operation name
- `op_category_uuid` (string, optional): Category UUID
- `memo` (string, optional): Notes

**Returns:** Created operation

#### operation_update
Update an existing operation.

**Parameters:**
- `id` (string, required): Operation UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated operation

#### operation_delete
Delete an operation by UUID.

**Parameters:**
- `id` (string, required): Operation UUID

**Returns:** Confirmation message

---

### Route Operation Tools

#### route_operation_list
List route operations.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of route operations

#### route_operation_get
Get a specific route operation by UUID.

**Parameters:**
- `id` (string, required): Route operation UUID

**Returns:** Route operation details

#### route_operation_create
Create a new route operation.

**Parameters:**
- `route_uuid` (string, required): Route UUID
- `operation_uuid` (string, required): Operation UUID
- `sequence` (number, optional): Order in route

**Returns:** Created route operation

#### route_operation_update
Update an existing route operation.

**Parameters:**
- `id` (string, required): Route operation UUID
- `sequence` (number, optional): Update order

**Returns:** Updated route operation

#### route_operation_delete
Delete a route operation.

**Parameters:**
- `id` (string, required): Route operation UUID

**Returns:** Confirmation message

#### route_operation_by_route
Get all operations for a specific route.

**Parameters:**
- `route_uuid` (string, required): Route UUID

**Returns:** List of operations in the route

---

### Device Tools

#### device_list
List devices/machines.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of devices

#### device_get
Get a specific device by UUID.

**Parameters:**
- `id` (string, required): Device UUID

**Returns:** Device details

#### device_create
Create a new device.

**Parameters:**
- `name` (string, required): Device name
- `memo` (string, optional): Notes

**Returns:** Created device

#### device_update
Update an existing device.

**Parameters:**
- `id` (string, required): Device UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated device

#### device_delete
Delete a device by UUID.

**Parameters:**
- `id` (string, required): Device UUID

**Returns:** Confirmation message

---

### Defect Reason Tools

#### defect_reason_list
List defect reasons.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of defect reasons

#### defect_reason_create
Create a new defect reason.

**Parameters:**
- `name` (string, required): Reason name
- `category_uuid` (string, optional): Category UUID

**Returns:** Created defect reason

#### defect_reason_update
Update an existing defect reason.

**Parameters:**
- `id` (string, required): Defect reason UUID
- `name` (string, optional): Update name

**Returns:** Updated defect reason

#### defect_reason_delete
Delete a defect reason.

**Parameters:**
- `id` (string, required): Defect reason UUID

**Returns:** Confirmation message

---

### Defect Reason Category Tools

#### defect_reason_category_list
List defect reason categories.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of categories

#### defect_reason_category_get
Get a specific category by UUID.

**Parameters:**
- `id` (string, required): Category UUID

**Returns:** Category details

#### defect_reason_category_create
Create a new defect reason category.

**Parameters:**
- `name` (string, required): Category name

**Returns:** Created category

#### defect_reason_category_update
Update an existing category.

**Parameters:**
- `id` (string, required): Category UUID
- `name` (string, optional): Update name

**Returns:** Updated category

---

### Station Tools

#### station_list
List stations.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of stations

#### station_get
Get a specific station by UUID.

**Parameters:**
- `id` (string, required): Station UUID

**Returns:** Station details

#### station_create
Create a new station.

**Parameters:**
- `name` (string, required): Station name
- `memo` (string, optional): Notes

**Returns:** Created station

#### station_update
Update an existing station.

**Parameters:**
- `id` (string, required): Station UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated station

#### station_delete
Delete a station.

**Parameters:**
- `id` (string, required): Station UUID

**Returns:** Confirmation message

#### station_device_list
List devices at a specific station.

**Parameters:**
- `id` (string, required): Station UUID

**Returns:** List of devices at the station

---

### Abnormal History Tools

#### abnormal_history_list
List work hour abnormal records.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of abnormal records

#### abnormal_history_get
Get a specific abnormal record by UUID.

**Parameters:**
- `id` (string, required): Abnormal record UUID

**Returns:** Abnormal record details

#### abnormal_history_create
Create a new abnormal record.

**Parameters:**
- `work_order_id` (string, required): Work order ID
- `category_uuid` (string, optional): Category UUID
- `state_uuid` (string, optional): State UUID
- `memo` (string, optional): Notes

**Returns:** Created abnormal record

#### abnormal_history_update
Update an existing abnormal record.

**Parameters:**
- `id` (string, required): Abnormal record UUID
- `state_uuid` (string, optional): Update state
- `memo` (string, optional): Update notes

**Returns:** Updated abnormal record

#### abnormal_history_by_workorder
Get abnormal records for a specific work order.

**Parameters:**
- `work_order_id` (string, required): Work order ID

**Returns:** List of abnormal records for the work order

---

### Abnormal Config Tools

#### abnormal_category_list
List abnormal categories.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of abnormal categories

#### abnormal_category_create
Create a new abnormal category.

**Parameters:**
- `name` (string, required): Category name

**Returns:** Created category

#### abnormal_state_list
List abnormal states.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of abnormal states

#### abnormal_state_create
Create a new abnormal state.

**Parameters:**
- `name` (string, required): State name

**Returns:** Created state

---

### Operation Product BOM Tools

#### op_product_bom_list
List operation product BOMs.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of operation product BOMs

#### op_product_bom_create
Create a new operation product BOM.

**Parameters:**
- `operation_uuid` (string, required): Operation UUID
- `product_uuid` (string, required): Product UUID
- `qty` (number, required): Quantity

**Returns:** Created BOM record

#### op_product_bom_update
Update an existing operation product BOM.

**Parameters:**
- `id` (string, required): BOM UUID
- `qty` (number, optional): Update quantity

**Returns:** Updated BOM record

#### op_product_bom_delete
Delete an operation product BOM.

**Parameters:**
- `id` (string, required): BOM UUID

**Returns:** Confirmation message

---

### Warehouse Tools

#### warehouse_list
List warehouses.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of warehouses

#### warehouse_get
Get a specific warehouse by UUID.

**Parameters:**
- `id` (string, required): Warehouse UUID

**Returns:** Warehouse details

#### warehouse_create
Create a new warehouse.

**Parameters:**
- `name` (string, required): Warehouse name
- `memo` (string, optional): Notes

**Returns:** Created warehouse

#### warehouse_update
Update an existing warehouse.

**Parameters:**
- `id` (string, required): Warehouse UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated warehouse

---

### Warehouse Storage Tools

#### warehouse_storage_list
List warehouse storage locations.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of storage locations

#### warehouse_storage_get
Get a specific storage location by UUID.

**Parameters:**
- `id` (string, required): Storage location UUID

**Returns:** Storage location details

#### warehouse_storage_create
Create a new storage location.

**Parameters:**
- `warehouse_uuid` (string, required): Parent warehouse UUID
- `name` (string, required): Storage location name
- `memo` (string, optional): Notes

**Returns:** Created storage location

#### warehouse_storage_update
Update an existing storage location.

**Parameters:**
- `id` (string, required): Storage location UUID
- `name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated storage location

---

### Product Storage Tools

#### product_storage_list
List product storage records.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** List of product storage records

#### product_storage_get
Get a specific product storage record by UUID.

**Parameters:**
- `id` (string, required): Product storage UUID

**Returns:** Product storage details

#### product_storage_by_product
Get storage records for a specific product.

**Parameters:**
- `product_uuid` (string, required): Product UUID

**Returns:** List of storage records for the product

---

### WMS Tools

#### wms_check_inventory
Check and reconcile inventory via WMS.

**Parameters:**
- `product_uuid` (string, optional): Product UUID
- `warehouse_uuid` (string, optional): Warehouse UUID
- `warehouse_storage_uuid` (string, optional): Storage location UUID

**Returns:** Inventory check results

#### wms_query_product_storage
Query product storage data via WMS.

**Parameters:**
- `product_uuid` (string, optional): Product UUID
- `warehouse_uuid` (string, optional): Warehouse UUID
- `warehouse_storage_uuid` (string, optional): Storage location UUID

**Returns:** Product storage query results

#### wms_query_storage_history
Query product storage history via WMS.

**Parameters:**
- `product_uuid` (string, optional): Product UUID
- `warehouse_uuid` (string, optional): Warehouse UUID
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset

**Returns:** Storage history records

#### wms_minimal_stock_count
Get count of products at or below minimum stock levels.

**Parameters:** None

**Returns:** Count of products below minimum stock

---

### Extended Work Order Tools

#### workorder_count
Get total count of work orders.

**Parameters:** None

**Returns:** Work order count

### Extended Product Tools

#### product_details
Get product with full details.

**Parameters:**
- `id` (string, required): Product UUID

**Returns:** Product with full details

#### product_copy
Copy/duplicate a product.

**Parameters:**
- `id` (string, required): Product UUID to copy

**Returns:** Newly created product copy

### Extended Worker Tools

#### worker_create
Create a new worker.

**Parameters:**
- `worker_id` (string, required): Worker ID (badge number)
- `worker_name` (string, required): Worker name
- `memo` (string, optional): Notes

**Returns:** Created worker

#### worker_update
Update an existing worker.

**Parameters:**
- `id` (string, required): Worker UUID
- `worker_name` (string, optional): Update name
- `memo` (string, optional): Update notes

**Returns:** Updated worker

#### worker_delete
Delete a worker.

**Parameters:**
- `id` (string, required): Worker UUID

**Returns:** Confirmation message

### Extended Operation History Tools

#### operation_history_get
Get a specific operation history record by UUID.

**Parameters:**
- `id` (string, required): Operation history UUID

**Returns:** Operation history details

#### operation_history_create
Create a new operation history record.

**Parameters:**
- `work_order_uuid` (string, required): Work order UUID
- `operation_uuid` (string, optional): Operation UUID
- `worker_uuid` (string, optional): Worker UUID
- `device_uuid` (string, optional): Device UUID
- `good` (number, optional): Good quantity
- `defective` (number, optional): Defective quantity
- `memo` (string, optional): Notes

**Returns:** Created operation history

#### operation_history_create_many
Batch create operation history records.

**Parameters:**
- `items` (array, required): Array of operation history records

**Returns:** Created records

#### operation_history_delete
Delete an operation history record.

**Parameters:**
- `id` (string, required): Operation history UUID

**Returns:** Confirmation message

#### operation_history_timeline
Get the timeline for a specific operation history.

**Parameters:**
- `id` (string, required): Operation history UUID

**Returns:** Timeline data

## Usage Examples

### Workflow: First-time Setup

```
# 1. Ask user for tenant_id if not known
AI: "What is your DotZero tenant ID?"
User: "my-company"

# 2. Authenticate
auth_login(email: "operator@example.com", password: "<ask-user>", tenant_id: "my-company")

# 3. Now you can use other tools
workorder_list(limit: 5)
```

### Workflow: Check rush orders and update status

```
# 1. List rush orders in progress
workorder_list(status: 2, is_asap: true)

# 2. Get details for a specific order
workorder_details(work_order_id: "WO-2024-001")

# 3. Mark as completed
workorder_update(id: "uuid-here", status: 3)
```

### Workflow: Production report for a date range

```
# Get operations for this week
workorder_report(
  start_time_start: "2024-01-15T00:00:00Z",
  start_time_end: "2024-01-21T23:59:59Z",
  response_format: "json"
)
```

### Workflow: Create work order with product

```
# 1. Find or create product
product_list(name: "Widget A")

# 2. Create work order
workorder_create(
  work_order_id: "WO-2024-002",
  qty: 500,
  deadline: "2024-02-15T17:00:00Z",
  memo: "Urgent customer order"
)
```

## Error Handling

All tools return descriptive error messages:

- **401**: Authentication required - use `auth_login` with tenant_id
- **403**: Permission denied - check user permissions
- **404**: Resource not found - verify the ID
- **422**: Validation error - check input parameters
- **429**: Rate limited - wait before retrying

## Response Formats

### Markdown (default)
Human-readable format with headers and bullet points. Best for interactive use.

### JSON
Machine-readable format with full data structure. Best for programmatic processing.

Set `response_format: "json"` on any tool to get JSON output.

## Repository

https://gitlab.com/dotzero/dz-ai
