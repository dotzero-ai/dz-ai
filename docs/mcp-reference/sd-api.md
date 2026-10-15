# SD (Sales & Distribution) Skill

MCP skill for DotZero SD (Sales & Distribution) — customer sales orders and customer master queries.

## Overview

This skill provides 3 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **sd_order_list**: list customer sales orders (filters + pagination)
- **sd_order_get**: get one sales order by UUID (not business number)
- **sd_customer_list**: list customers

All tools are **read-only** (query/analysis; no writes).

`query` is required on both list tools (no default). `exact` / `fuzzy` apply the filters (dates included) and need at least one; for period questions use `delivery_date_from/to` or `create_time_from/to` (`sd_customer_list`: `create_time_from/to`). `all` takes no filters and only pages: a filter together with `all` is refused. `limit` is 1-100.

## Prerequisites

Authenticate first (shared across all DotZero MCP servers). `tenant_id` is required; if unknown, ask the user.

```
auth_login(tenant_id: "your-tenant-id")   # opens browser login; password never passes through AI
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SD_API_URL` | Yes | Base URL of the SD (Sales & Distribution) API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Notes

- Numbers come straight from the API — do not fabricate.
- These tools mirror the DotZero SD (Sales & Distribution) read endpoints (same data as the platform's sd app).
- On a timeout or 5xx the tool answers that the server may still be computing and that the same call must not be resent; an identical request is refused for 2 minutes after a timeout or 504. Narrow the period or add filters instead.

## Repository

https://github.com/dotzero-ai/dz-ai
