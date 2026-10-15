# WMS (Warehouse) Skill

MCP skill for DotZero WMS (Warehouse) — stock levels, low-stock alerts, and work-order picking progress.

## Overview

This skill provides 3 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **wms_stock_query**: query product storage / stock levels by work-order IDs or by serial numbers — one list per call, at most 50 values
- **wms_low_stock_list**: products below minimal stock level, largest shortage first (`limit` 1-100, default 50, plus `offset`)
- **wms_picking_progress**: work-order picking completion rate (planned-date range, at most 92 days)

All tools are **read-only** (query/analysis; no writes).

Notes on tool coverage:

- `wms_stock_query` takes `work_order_id_list` or `serial_number_list`, not both (the API mishandles both lists in one request): to look up both, make two calls. An empty call is refused.
- `wms_low_stock_list`: the API returns every alerted product at once; the tool pages through it locally and `has_more` / `next_offset` tell whether products are left. Each page re-reads the whole list on the server.
- `wms_picking_progress` requires `planned_date_start`/`planned_date_end` (YYYY-MM-DD, at most 92 days, both ends included). The underlying API also accepts a `pickedDateStart`/`pickedDateEnd` (actual issue date) range, but filtering by picked date alone is deliberately not offered: without a planned range the API loads every active picking plan of the tenant. To also filter by actual picked date, call the HTTP endpoint with both ranges (see the `dotzero-wms` skill).
- `wms_stock_query` and `wms_picking_progress` cap their output at the response size limit: the leading rows that fit are shown with a note of how many were left out (picking-progress counts and rates still cover every plan of the period). Query fewer IDs or a shorter range to see the rest.
- Additional read-only WMS endpoints not yet wrapped as MCP tools (storage change history `queryProductStorageHistory`, batch history `groupQueryProductStorageHistory`, per-work-order picking history `workOrderPickingHistory`) are documented in the `dotzero-wms` skill.
- work-order-mcp no longer carries its own `wms_*` tools: use `wms_stock_query` instead of `wms_query_product_storage` and `wms_low_stock_list` instead of `wms_minimal_stock_count`. `wms_query_storage_history` has no MCP replacement, and `wms_check_inventory` was removed.

## Prerequisites

Authenticate first (shared across all DotZero MCP servers). `tenant_id` is required; if unknown, ask the user.

```
auth_login(tenant_id: "your-tenant-id")   # opens browser login; password never passes through AI
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WMS_API_URL` | Yes | Base URL of the WMS (Warehouse) API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Notes

- Numbers come straight from the API — do not fabricate.
- These tools mirror the DotZero WMS (Warehouse) read endpoints (same data as the platform's wms app).
- On a timeout or 5xx the tool answers that the server may still be computing and that the same call must not be resent; an identical request is refused for 2 minutes after a timeout or 504. Narrow the period or add filters instead.

## Repository

https://github.com/dotzero-ai/dz-ai
