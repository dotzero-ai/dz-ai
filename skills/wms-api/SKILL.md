# WMS (Warehouse) Skill

MCP skill for DotZero WMS (Warehouse) — stock levels, low-stock alerts, and work-order picking progress.

## Overview

This skill provides 3 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **wms_stock_query**: query product storage / stock levels
- **wms_low_stock_list**: products below minimal stock level
- **wms_picking_progress**: work-order picking completion rate (date range)

All tools are **read-only** (query/analysis; no writes).

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
