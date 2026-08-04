# SPC API Skill

MCP skill for Statistical Process Control (SPC) — manage measurement configurations, record inspection data, calculate control charts, and monitor quality statistics.

## Overview

This skill provides 49 tools for interacting with the SPC API:

- **Authentication** (2): Login and check auth status
- **Products V2** (2): List manufacture and stock products
- **History V2** (4): Batch upsert/query/delete inspection history by group
- **Config Parent V2** (5): Parent config management with attachments
- **Measure Config V1** (9): Measurement point configuration CRUD with attachments, modes, and categories
- **Measure History V1** (11): Measurement history CRUD, batch operations, filtering, and counting
- **Instruments V1** (5): Measurement instrument management with batch delete
- **Rules V1** (1): List control chart rules
- **Dashboard V1** (6): Dashboard configuration and manufacture dashboard
- **Statistics V1** (4): Nelson rules, capability analysis, and calculation results

## Prerequisites

### Authentication Required

Before using most tools, you need to authenticate. The `tenant_id` is required.

**IMPORTANT**: If you don't know the user's tenant_id, you must ask them for it.

```
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SPC_API_URL` | Yes | Base URL of the SPC API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Tools Reference

### Authentication Tools

#### auth_login
Authenticate with email, password, and tenant_id to obtain a JWT token.

**Parameters:**
- `email` (string, required): User email address
- `password` (string, required): User password
- `tenant_id` (string, required): Tenant ID (ask user if not known)

#### auth_status
Check if the client is authenticated.

**Parameters:** None

---

### Product Tools (V2)

#### spc_product_manufacture_list
List manufacture products for SPC inspection.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_product_stock_list
List stock products for SPC inspection.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

---

### History Tools (V2)

#### spc_history_list
List SPC inspection history records for a measure point config (GET /v2/history/). No server-side pagination — returns all matching records.

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure point config UUID
- `work_order_op_history_uuid` (string, optional): Filter by work order operation history UUID
- `spc_measure_instrument_uuid` (string, optional): Filter by measure instrument UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_history_batch_upsert
Batch upsert (create or update) SPC history records.

**Parameters:**
- `items` (array, required): Array of history records
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_history_batch_by_group
Ensure SPC history rows exist for the given (config, group name) pairs — creates empty rows if missing (PATCH /v2/history/batch/groupName/). There is no "get by group id" endpoint.

**Parameters:**
- `items` (array, required): Each item needs `spc_measure_point_config_uuid` and `group_name` (optional `work_order_op_history_uuid`, `product_storage_history_uuid`)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_history_delete_by_group
Delete SPC history rows for the given (config, group name) pairs (DELETE /v2/history/batch/groupName/).

**Parameters:**
- `items` (array, required): Each item needs `spc_measure_point_config_uuid` and `group_name` (optional `work_order_op_history_uuid`, `product_storage_history_uuid`)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Config Parent Tools (V2)

#### spc_config_parent_get
Get a parent config by UUID.

**Parameters:**
- `id` (string, required): Config parent UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_config_parent_create
Create a new parent config.

**Parameters:**
- `name` (string, required): Config name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_config_parent_update
Update an existing parent config.

**Parameters:**
- `id` (string, required): Config parent UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_config_parent_attachment_add
Add an attachment to a parent config via multipart upload (POST /v2/config/parent/{uuid}/attachment/, form field `attachment`).

**Parameters:**
- `parent_uuid` (string, required): Config parent UUID
- `file_path` (string, required): Local path to the file to upload (png/jpg/pdf)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_config_parent_attachment_delete
Delete an attachment from a parent config (DELETE /v2/config/parent/{uuid}/attachment/ with JSON body `{"path": ...}`).

**Parameters:**
- `parent_uuid` (string, required): Config parent UUID
- `path` (string, required): Attachment path/URL to remove

---

### Measure Config Tools (V1)

#### spc_measure_config_list
List measurement point configurations (GET /v1/config/). No pagination — returns all matching configs.

**Parameters:**
- `operation_uuid` (string, optional): Filter by operation UUID
- `product_uuid` (string, optional): Filter by product UUID
- `control_per` (string, optional): Filter by control-per (e.g. `manufacture` / `stock`)
- `product_storage_action` (string, optional): Filter by product storage action
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_config_get
Get a specific measure config by UUID.

**Parameters:**
- `id` (string, required): Measure config UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_config_create
Create a new measurement point configuration.

**Parameters:**
- `name` (string, required): Config name
- `parent_uuid` (string, optional): Parent config UUID
- `std_value` (number, optional): Standard value
- `measure_amount` (number, optional): Number of measurements per sample
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_config_update
Update an existing measure config.

**Parameters:**
- `id` (string, required): Measure config UUID
- `name` (string, optional): Update name
- `std_value` (number, optional): Update standard value
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_config_delete
Delete a measure config.

**Parameters:**
- `id` (string, required): Measure config UUID

#### spc_measure_config_attachment_add
Add an attachment to a measure config (multipart upload).

**Parameters:**
- `id` (string, required): Measure config UUID
- `file_path` (string, required): Path to the file to upload

#### spc_measure_config_attachment_delete
Delete an attachment from a measure config.

**Parameters:**
- `id` (string, required): Measure config UUID
- `attachment_uuid` (string, required): Attachment UUID

#### spc_measure_config_modes
List available measurement modes.

**Parameters:** None

#### spc_measure_config_categories
List available measurement categories.

**Parameters:** None

---

### Measure History Tools (V1)

#### spc_measure_history_create
Create a new measurement history record.

**Parameters:**
- `spc_measure_point_config_uuid` (string, required): Measure config UUID
- `value` (number, required): Measured value
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_upsert
Create or update a measurement history record.

**Parameters:**
- `spc_measure_point_config_uuid` (string, required): Measure config UUID
- `value` (number, required): Measured value
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_update
Update an existing measurement history record.

**Parameters:**
- `id` (string, required): History record UUID
- `value` (number, optional): Update measured value
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_delete
Delete a measurement history record.

**Parameters:**
- `id` (string, required): History record UUID

#### spc_measure_history_batch_upsert
Batch upsert measurement history records.

**Parameters:**
- `items` (array, required): Array of history records

#### spc_measure_history_batch_delete
Batch delete measurement history records.

**Parameters:**
- `ids` (array, required): Array of UUIDs to delete

#### spc_measure_history_manufacture
List measurement history for manufacture products.

**Parameters:**
- `spc_measure_point_config_uuid` (string, optional): Filter by config
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_stock
List measurement history for stock products.

**Parameters:**
- `spc_measure_point_config_uuid` (string, optional): Filter by config
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_count
Get count of measurement history records.

**Parameters:**
- `spc_measure_point_config_uuid` (string, optional): Filter by config

#### spc_measure_history_filter_list
List distinct filter values (work orders, workers, instruments, devices) for a manufacture measure point config (GET /v1/history/filter-list/{filterType}/).

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Config UUID
- `filter_type` (enum, **required**): One of `workOrderOpHistoryWorker`, `workOrderOpHistory`, `spcMeasureInstrument`, `device`, `spcMeasureWorker`
- `work_order_op_history_uuid` (string, optional): Work order op history UUID filter
- `work_order_op_history_start_time` (string, optional): Start time (RFC3339)
- `work_order_op_history_end_time` (string, optional): End time (RFC3339)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_filter_list_stock
List distinct stock filter values (warehouses, serial numbers, work order IDs, workers) for a measure point config (GET /v1/history/filter-list/{filterType}/stock/).

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Config UUID
- `filter_type` (enum, **required**): One of `warehouse`, `serialNumber`, `workOrderID`, `productStorageHistoryWorker`, `spcMeasureWorker`, `productStorageHistoryUUID`
- `product_storage_history_uuid` (string, optional): Product storage history UUID filter
- `product_storage_history_start_time` (string, optional): Start time (RFC3339)
- `product_storage_history_end_time` (string, optional): End time (RFC3339)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Instrument Tools (V1)

#### spc_instrument_list
List measurement instruments.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_instrument_create
Create a new instrument.

**Parameters:**
- `name` (string, required): Instrument name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_instrument_update
Update an existing instrument.

**Parameters:**
- `id` (string, required): Instrument UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_instrument_delete
Delete an instrument.

**Parameters:**
- `id` (string, required): Instrument UUID

#### spc_instrument_batch_delete
Batch delete instruments.

**Parameters:**
- `ids` (array, required): Array of UUIDs to delete

---

### Rule Tools (V1)

#### spc_rule_list
List available control chart rules (e.g., Nelson rules).

**Parameters:** None

---

### Dashboard Tools (V1)

#### spc_dashboard_list
List SPC dashboards.

**Parameters:**
- `limit` (number, default: 20): Max results
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_dashboard_create
Create a new SPC dashboard.

**Parameters:**
- `name` (string, required): Dashboard name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_dashboard_update
Update an existing dashboard.

**Parameters:**
- `id` (string, required): Dashboard UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_dashboard_delete
Delete a dashboard.

**Parameters:**
- `id` (string, required): Dashboard UUID

#### spc_dashboard_manufacture_create
Create a manufacture dashboard entry.

**Parameters:**
- `dashboard_uuid` (string, required): Dashboard UUID
- `spc_measure_point_config_uuid` (string, required): Measure config UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_dashboard_manufacture_update
Update a manufacture dashboard entry.

**Parameters:**
- `id` (string, required): Dashboard entry UUID
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Statistics Tools (V1)

#### spc_statistics_nelson
Run Nelson rule analysis on measurement data. All four filter params are **required** by the backend (400 if any is missing).

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure config UUID
- `work_order_op_history_uuid` (string, **required**): Work order operation history UUID
- `start_time` (string, **required**): Start time (ISO 8601 / RFC3339)
- `end_time` (string, **required**): End time (ISO 8601 / RFC3339)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_statistics_capability
Calculate process capability indices (Cp, Cpk, Pp, Ppk). All four filter params are **required** by the backend (400 if any is missing).

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure config UUID
- `work_order_op_history_uuid` (string, **required**): Work order operation history UUID
- `start_time` (string, **required**): Start time (ISO 8601 / RFC3339)
- `end_time` (string, **required**): End time (ISO 8601 / RFC3339)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_statistics_capability_by_point
Calculate process capability from raw data points and spec limits (no config needed).

**Parameters:**
- `points` (number[], required): Measurement data points
- `usl` (number, required): Upper specification limit
- `lsl` (number, required): Lower specification limit
- `std_value` (number, required): Standard/target value
- `measure_amount` (number, required): Measurements per sample
- `good` (number, required): Count of good parts
- `defect` (number, required): Count of defective parts
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_statistics_calculate_result
Get pre-calculated SPC statistics for a time range and metric (GET /v1/statisticCalculateResult/).

**Parameters:**
- `range` (enum, required): `day` | `week` | `month` | `custom`
- `metric_name` (enum, required): `Cpk` | `nelsonRule1`..`nelsonRule8` | `overSpecs`
- `work_order_op_history_start_time_from` (string, optional): Start time (ISO 8601, for `custom` range)
- `work_order_op_history_start_time_to` (string, optional): End time (ISO 8601, for `custom` range)
- `limit` (number, optional, default: 20): Max results
- `response_format` ('markdown'|'json', default: 'markdown')

---

## Usage Examples

### Workflow: Set up SPC inspection

```
# 1. List products
spc_product_manufacture_list()

# 2. Create a measure config
spc_measure_config_create(name: "Dimension A - Length", std_value: 10.0, measure_amount: 5)

# 3. Record measurements
spc_measure_history_create(spc_measure_point_config_uuid: "config-uuid", value: 10.02)

# 4. Run capability analysis (all four params required)
spc_statistics_capability(spc_measure_point_config_uuid: "config-uuid", work_order_op_history_uuid: "wo-uuid", start_time: "2026-07-01T00:00:00Z", end_time: "2026-07-21T23:59:59Z")
```

### Workflow: Check quality status

```
# 1. List configs
spc_measure_config_list()

# 2. Get measurement count
spc_measure_history_count(spc_measure_point_config_uuid: "config-uuid")

# 3. Run Nelson rules (all four params required)
spc_statistics_nelson(spc_measure_point_config_uuid: "config-uuid", work_order_op_history_uuid: "wo-uuid", start_time: "2026-07-01T00:00:00Z", end_time: "2026-07-21T23:59:59Z")
```

## V3 HTTP Endpoints (2026, not yet MCP tools)

These read-only v3 queries are useful for monitoring/reporting but are not exposed as MCP tools yet — call them directly over HTTP with `Authorization: Bearer {token}` (v3 routes do **not** use trailing slashes):

- `GET /v3/count/spcMeasurePointHistory/outOfControl` — out-of-control count stats
- `GET /v3/dashboard/pastRecord`, `GET /v3/dashboard/trendRuns` — quality trend data
- `GET /v3/spcReport/search` — report search
- `GET /v3/spcInspectionSheets` (+ `/withHistory`, `/measureHistory`) — inspection sheets
- `GET /v3/instrument/dueReminders` — instrument calibration due reminders
- `GET /v3/instrumentCalibration` — calibration records
- `GET /v3/shippingReport` (+ `/measureHistory`) — shipping reports

## Error Handling

| Error | Solution |
|-------|----------|
| 400 Bad Request | Missing required param (e.g. statistics need start/end time + work order uuid) |
| 401 Unauthorized | Call `auth_login` with tenant_id |
| Token expired | Call `auth_refresh` or `auth_login` again |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |

## MCP Server

- **Package**: `@dotzero.ai/spc-mcp`
- **Tools**: 49 (6 basic + 43 advanced, unlocked after auth)

## Repository

https://github.com/dotzero-ai/dz-ai
