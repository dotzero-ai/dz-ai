# SPC API Skill

MCP skill for Statistical Process Control (SPC) — manage measurement configurations, record inspection data, calculate control charts, and monitor quality statistics.

## Overview

This skill provides 49 tools for interacting with the SPC API:

- **Authentication** (2): Login and check auth status
- **Products V2** (2): List manufacture and stock products
- **History V2** (4): Batch upsert/query/delete inspection history by group
- **Config Parent V2** (4): Parent config management with attachments
- **Measure Config V1** (9): Measurement point configuration CRUD with attachments, modes, and categories
- **Measure History V1** (11): Measurement history CRUD, batch operations, filtering, and counting
- **Instruments V1** (5): Measurement instrument management with batch delete
- **Rules V1** (1): List control chart rules
- **Dashboard V1** (6): Dashboard configuration and manufacture dashboard
- **Statistics V1** (1): Calculation results (recomputed on every call)
- **Inspection Sheets V3** (4): Inspection sheets (檢點表): list them, read one with its measure points, list recorded inspections, record inspections (量測值, e.g. 入料檢 / IQC)

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
List SPC inspection history records for a measure point config (GET /v2/history/). Returns the measure point's WHOLE history (no time filter, no pagination; can be tens of thousands of rows). Prefer `spc_measure_history_manufacture` with `start_time`/`end_time`; never call this in a loop over many measure points. The tool shows the leading records that fit the response size limit and says how many were left out.

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure point config UUID
- `work_order_op_history_uuid` (string, optional): Only measurements of this work order operation history
- `spc_measure_instrument_uuid` (string, optional): Only measurements taken with this measure instrument
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_history_batch_upsert
Batch upsert (create or update) SPC history records.

**Parameters:**
- `items` (array, required): Array of history records
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_history_batch_upsert_by_group
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
List one measure point config's measurements taken during manufacturing, filtered by when the work order operation started (GET /v1/history/manufacture/). Without `start_time`/`end_time` the last 30 days are used (the result says so), unless `work_order_op_history_uuid` is given. The API returns every matching record at once; `limit`/`offset` page through it client-side (`has_more` / `next_offset`), and each page re-runs the whole query, so prefer a shorter period over paging.

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure point config UUID
- `start_time` (string, optional): Work order operations started at or after this time, RFC3339 with an explicit offset (e.g. `2026-10-01T00:00:00+08:00`). Give both `start_time` and `end_time` or neither; `start_time` must be before `end_time`; at most 92 days
- `end_time` (string, optional): Work order operations started at or before this time, RFC3339 with an explicit offset
- `work_order_op_history_uuid` (string, optional): Work order operation history UUID filter; with it and no period, no default period applies
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_stock
List one measure point config's stock/inventory measurement history (GET /v1/history/stock/). No time filter: without `product_storage_history_uuid` every call reads the config's whole stock history. The API returns it at once; `limit`/`offset` page through it client-side.

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure point config UUID
- `product_storage_history_uuid` (string, optional): Product storage history UUID filter (one stock-in/out record)
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_measure_history_count
Get the count of measurement history records for a measure point config: total, manufacture and stock.

**Parameters:**
- `spc_measure_point_config_uuid` (string, **required**): Measure point config UUID
- `response_format` ('markdown'|'json', default: 'markdown')

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
List measurement instruments. The API has no offset, so the list is fetched once and paged client-side.

**Parameters:**
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
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
List SPC dashboards. The API has no paging and returns every dashboard at once; the list is paged client-side.

**Parameters:**
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
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



#### spc_statistics_calculate_result
Get SPC statistics per measure point config for a window of work order operation start times, highest metric value first (GET /v1/statisticCalculateResult/).

**Not read-only, and expensive:** every call recomputes the metric for every measure point config in the whole tenant over the window and saves the results before returning the top `limit`. Use the shortest range that answers the question and do not repeat the same call.

**Parameters:**
- `range` (enum, required): `day` | `week` | `month` | `custom` — `day` / `week` / `month` are the 1 / 7 / 30 days that end at 00:00 (+08:00) yesterday
- `metric_name` (enum, required): `Cpk` | `nelsonRule1`..`nelsonRule8` | `overSpecs`
- `work_order_op_history_start_time_from` (string, `range: custom` only, required there): Window start, RFC3339 with an explicit offset; the window may span at most 31 days
- `work_order_op_history_start_time_to` (string, `range: custom` only, required there): Window end, RFC3339 with an explicit offset
- `limit` (number, default: 20): How many results to return, highest metric value first (1-100)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Inspection Sheet Tools (V3, 檢點表)

Enter measurement values (量測值) on inspection sheets the way the SPC web app's sheet entry (輸入量測值 → 檢點表) and 量測歷史 pages do, e.g. incoming-inspection (入料檢 / IQC) rows from a spreadsheet: find the sheet, read its measure points, check what is recorded, then record.

#### spc_inspection_sheet_list
List the tenant's inspection sheets (GET /v3/spcInspectionSheets): uuid, name, inspection type and scope, product, number of measure points. The API returns every sheet at once; the filters and `limit`/`offset` apply client-side.

**Parameters:**
- `search` (string, optional): Sheets whose name, product number or product name contains this text (case-insensitive)
- `inspection_type` (enum, optional): `IQC` 進料檢驗 (入料檢) | `IPQC` 製程檢驗 | `PQC` 產品檢驗 | `FQC` 最終檢驗 | `OQC` 出貨檢驗 | `other` 其他
- `limit` (number, default: 20): Rows to return (1-100, client-side)
- `offset` (number, default: 0): Rows to skip (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_inspection_sheet_get
One sheet and its measure points in sheet order (GET /v3/spcInspectionSheets?full=true&uuid=, the web app's read of one sheet; `GET /v3/spcInspectionSheets/:uuid` answers 500, not 404, for a sheet it cannot find). Per point: `order`, `config_uuid` (the key `spc_inspection_history_create` takes), `name`, `category`, `unit`, `spec`, and the raw `std_value`, `usl`, `lsl`, `mode`. `usl` and `lsl` are tolerances around `std_value`, not limits; `spec` spells out the range. Capped at 25k characters; the note says how many points were left out.

**Parameters:**
- `inspection_sheet_uuid` (string, **required**): Sheet uuid from `spc_inspection_sheet_list`
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_inspection_history_list
The inspections recorded on one sheet in a period (GET /v3/spcInspectionSheets/measureHistory), one entry per inspection, grouped as the 量測歷史 page groups them: by `measure_object_id` and work-order operation, since measure points a sheet shares with work-order reporting bring inspections numbered on their own. Each entry: `measure_object_id`, work order (if any), `inspection_time`, `inspection_category`, `worker_id`, `create_time` and each point's value (goNogo → `boolean_value`, text → `text_value`, others → `decimal_value`, or `text_value` when only that was stored, e.g. `N.D`; empty points left out; in JSON keyed by `config_uuid`). `merged` marks a number two entries share (another writer, e.g. an entry page loaded earlier, used it too); its values may be mixed. One call reads at most 10000 values (one per point and inspection, in pages of 1000); a busier period is refused: narrow it. Lowest `measure_object_id` first.

**Parameters:**
- `inspection_sheet_uuid` (string, **required**)
- `start_time`, `end_time` (string, **required**): RFC3339 with an explicit offset, inclusive, at most 92 days apart
- `time_field` (enum, default: `inspection_time`): `inspection_time` (量測時間) or `create_time` (填寫時間; after an unknown outcome of `spc_inspection_history_create`, from just before that call)
- `limit` (number, default: 20), `offset` (number, default: 0): Page through the inspections (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### spc_inspection_history_create
**Writes quality records.** Record 1-50 inspections on one sheet as the web app's 送出 does: one `POST /v3/spcMeasurePointHistory/batch` with the rows `handleOnSubmit` builds for the sheet flow, i.e. one row per sheet point and inspection (empty for the points not given), `text_value` the value as text, `decimal_value` and `value` its `parseFloat`, `boolean_value` from 合格 / 不合格, `group_name` `"group 1"`, `work_order_op_history_uuid` null. The instrument is the sheet point's own, or none: the entry page would otherwise preselect an earlier row's or the config's default, and a config's default can name a deleted instrument, which the history row's foreign key refuses with a 500. Each inspection gets the next `measure_object_id`: max + 1 from `GET /v3/spcMeasurePointHistory/maxMeasureObjectIdByInspectionSheet`, in input order. Before calling, the AI must show the user every inspection exactly as it will be recorded and get their confirmation.

Checked before anything is sent; on any problem nothing is sent and the problems are listed (at most 20, then how many more): times are real dates, not in the future and not before 2000; every inspection has a value; every value's point is on the sheet (the batch endpoint itself accepts any config uuid, of any tenant); the value fits the point's category: `true`/`false` (合格/不合格) for `goNogo`, text for `text`, a number or text for `measure`, `geometricMeasure` and any other category. Text on a numeric point is recorded as the web app records it: `text_value` the text, `decimal_value` the number `parseFloat` finds at its start (`"1.2mm"` → 1.2, `"1,234"` → 1, so numbers go as numbers). Without one (`"N.D"`, `"<0.01"`) it is text only: in no statistic, and blank on the web app's 量測歷史 page. The result lists each such text with the number statistics use, or text only.

Repeats: the tool reads the sheet's values over the call's inspection times (up to 10000) and matches inspections with the same `inspection_time` (to the millisecond), `worker_id`, `inspection_category` and value on every point (a numeric point's text compared by its number when it has one), one recorded inspection for one given, so identical samples in one call are each recorded; inspections with a work-order operation never match. A match entered in the last 30 minutes is skipped as this call made before. A match entered earlier cannot be told from a new inspection that looks the same (a date-only time, all 合格): the call is refused with the matches listed, and after asking the user the AI calls again with `on_identical`. A call is also refused when the span holds more than 10000 values, or would after it, since a repeat of it could not be checked.

Errors: HTTP 400 passes the API's reason; any 4xx changed nothing. 5xx or no answer: whether the inspections were saved is unknown (the insert can still land after a timeout): wait 2 minutes, check with `spc_inspection_history_list`, `time_field` `create_time` from just before the call (the error names the `measure_object_id`s they would have), then the same call records only what was not saved. Through dz-mcp-server the gateway words that error itself, so the tool's description carries the procedure too. An identical POST within 2 minutes of one that got no answer is not sent (shared's resend block), and the error says so.

Returns: the `measure_object_id` and 檢查類別 each inspection got (by input index), the ones skipped, and the text given to numeric points with the number read from it; not the other values, which are the ones sent. If the sheet's entry page is open in the web app, it should be reloaded before submitting there, since it numbers inspections from when it loaded.

**Parameters:**
- `inspection_sheet_uuid` (string, **required**)
- `inspection_category` (enum, default: `首件`): `首件` | `自主` | `巡檢` | `末件`, for the inspections that give none of their own. Take it from the spreadsheet; when it says nothing, 首件 applies (as in the web app's Excel import; there is no IQC category) and the AI confirms that with the user
- `worker_id` (string, **required**, at most 20 characters, trimmed): The inspector's 工號 (worker_id in the SFR worker list)
- `inspections` (array, **required**, 1-50): `{ inspection_time, inspection_category?, values }` per inspection (one spreadsheet row)
  - `inspection_time`: RFC3339 with an explicit offset, not in the future, not before 2000; a spreadsheet time without an offset is the factory's local time (e.g. +08:00)
  - `inspection_category` (optional): this inspection's 檢查類別 when the spreadsheet gives one per row
  - `values`: `{ "<config_uuid>": value }`; leave out the points without a value
- `on_identical` (`'skip'`|`'record'`, optional): only after a refusal listing identical inspections entered more than 30 minutes ago, and after asking the user: `skip` when they are those inspections, `record` when they are new ones

---

## Usage Examples

### Workflow: Set up SPC inspection

```
# 1. List products
spc_product_manufacture_list()

# 2. Create a measure config
spc_measure_config_create(name: "Dimension A - Length", std_value: 10.0, measure_amount: 5)

# 3. Record measurements
spc_measure_history_create(spc_measure_point_config_uuid: "config-uuid", values: [10.02], measure_time: "2026-07-21T08:00:00Z")

# 4. Cpk for the last week (recomputes and saves results for the whole tenant: call once)
spc_statistics_calculate_result(range: "week", metric_name: "Cpk")
```

> `spc_statistics_capability` 與 `spc_statistics_nelson` 已於 2026-08-13 移除：它們轉發給
> spc-backend 的 `DZ_SPC_STATISTIC_API` 上游，該上游對 production 實測不可達
> （500 / 503，三次重打結果穩定）。上游恢復後可還原。
> `spc_statistics_capability_by_point` 打同一個上游，實測照範例參數一律 400（空 body），
> 也已移除。即時算 Cpk 目前沒有可用的端點，改用 `spc_statistics_calculate_result`（非唯讀：每次呼叫都重算整個租戶並寫回，見上方說明）。

### Workflow: Enter incoming-inspection (入料檢 / IQC) rows from a spreadsheet

```
# 1. Find the sheet
spc_inspection_sheet_list(inspection_type: "IQC", search: "P-001")

# 2. Its measure points: map the spreadsheet's columns to config_uuid
spc_inspection_sheet_get(inspection_sheet_uuid: "sheet-uuid")

# 3. Show the user the inspections exactly as they will be recorded; after they confirm:
spc_inspection_history_create(inspection_sheet_uuid: "sheet-uuid", worker_id: "PT-020", inspection_category: "首件",
  inspections: [{ inspection_time: "2026-11-03T09:00:00+08:00", values: { "config-uuid-1": 3.01, "config-uuid-2": true, "config-uuid-3": "LOT-001" } }])

# 4. What the sheet holds
spc_inspection_history_list(inspection_sheet_uuid: "sheet-uuid", start_time: "2026-11-03T00:00:00+08:00", end_time: "2026-11-04T00:00:00+08:00")
```

### Workflow: Check quality status

```
# 1. List configs
spc_measure_config_list()

# 2. Get measurement count
spc_measure_history_count(spc_measure_point_config_uuid: "config-uuid")

# 3. 判異法則：spc_statistics_nelson 已移除（後端上游不可達，見上一節說明）
#    目前可用的替代是 spc_rule_list（取規則定義）與 v3 的 outOfControl 統計端點
spc_rule_list()
```

## V3 HTTP Endpoints (2026, not yet MCP tools)

These read-only v3 queries are useful for monitoring/reporting but are not exposed as MCP tools yet — call them directly over HTTP with `Authorization: Bearer {token}` (v3 routes do **not** use trailing slashes):

- `GET /v3/count/spcMeasurePointHistory/outOfControl` — out-of-control count stats
- `GET /v3/dashboard/pastRecord`, `GET /v3/dashboard/trendRuns` — quality trend data
- `GET /v3/spcReport/search` — report search
- `GET /v3/spcInspectionSheets/withHistory` — the sheets with records in a period (the sheet list, one sheet and `/measureHistory` are the `spc_inspection_*` tools above)
- `GET /v3/instrument/dueReminders` — instrument calibration due reminders
- `GET /v3/instrumentCalibration` — calibration records
- `GET /v3/shippingReport` (+ `/measureHistory`) — shipping reports

## Error Handling

| Error | Solution |
|-------|----------|
| 400 Bad Request | Missing required param |
| 401 Unauthorized | Call `auth_login` with tenant_id |
| Token expired | Call `auth_refresh` or `auth_login` again |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |
| Timeout / 5xx | The server may still be computing: do not resend the same call; narrow the period or add filters. After a timeout or 504 the identical request is refused for 120 s (`Not sent: the same request timed out N s ago…`) |

## MCP Server

- **Package**: `@dotzero.ai/spc-mcp`
- **Tools**: 49 (6 basic + 43 advanced, unlocked after auth)

## Repository

https://github.com/dotzero-ai/dz-ai
