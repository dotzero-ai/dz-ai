# SCM (Supply Chain) Skill

MCP skill for DotZero SCM (Supply Chain) — queries for deliveries, QA inspection, supplier performance, and billable invoices.

## Overview

This skill provides 4 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **scm_delivery_list**: deliverable / outstanding deliveries
- **scm_qa_inspectable**: items awaiting QA inspection
- **scm_supplier_performance**: supplier performance metrics (by period YYYY-MM)
- **scm_invoice_billable**: billable invoice items with amounts

All tools are **read-only** (query/analysis; no writes).

The SCM API has no paging: each list endpoint returns every row at once (`scm_delivery_list`, `scm_qa_inspectable` and `scm_invoice_billable` take no filters; `scm_supplier_performance` takes `period`). The tools page the result locally with `limit` (1-100, default 20) and `offset`; `has_more` / `next_offset` tell whether rows are left. Each page re-reads the whole list on the server, so only ask for the next page when you need it.

## Prerequisites

Authenticate first (shared across all DotZero MCP servers). `tenant_id` is required; if unknown, ask the user.

```
auth_login(tenant_id: "your-tenant-id")   # opens browser login; password never passes through AI
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SCM_API_URL` | Yes | Base URL of the SCM (Supply Chain) API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Notes

- Numbers come straight from the API — do not fabricate.
- These tools mirror the DotZero SCM (Supply Chain) read endpoints (same data as the platform's scm app).
- On a timeout or 5xx the tool answers that the server may still be computing and that the same call must not be resent; an identical request is refused for 2 minutes after a timeout or 504. Narrow the period or add filters instead.

## Repository

https://github.com/dotzero-ai/dz-ai
