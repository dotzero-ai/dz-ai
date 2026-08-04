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
