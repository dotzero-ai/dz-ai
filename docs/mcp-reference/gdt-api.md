# GDT (Engineering Drawings) Skill

MCP skill for DotZero GDT (Engineering Drawings) — engineering drawing search, similarity retrieval, and feature extraction.

## Overview

This skill provides 3 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **gdt_drawing_list**: list engineering drawings (filter by q/customer/product/...)
- **gdt_drawing_similar**: find drawings similar to a given drawing id
- **gdt_feature_list**: dimensions / GD&T / hole-count features of a drawing

All tools are **read-only** (query/analysis; no writes).

`gdt_drawing_list` returns drawings newest first. Page with `offset` or the 1-based `page` (not both) plus `limit` (1-100, default 20); the tool converts the offset to the API's own page, and `has_more` / `next_offset` tell whether rows are left. `gdt_drawing_similar` takes `limit` 1-50 (default 8; above 50 the API silently returns only 8, so the tool refuses it) and `scope` `all` (default) / `type` / `subtype`.

## Prerequisites

Authenticate first (shared across all DotZero MCP servers). `tenant_id` is required; if unknown, ask the user.

```
auth_login(tenant_id: "your-tenant-id")   # opens browser login; password never passes through AI
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GDT_API_URL` | Yes | Base URL of the GDT (Engineering Drawings) API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Notes

- Numbers come straight from the API — do not fabricate.
- These tools mirror the DotZero GDT (Engineering Drawings) read endpoints (same data as the platform's gdt app).
- On a timeout or 5xx the tool answers that the server may still be computing and that the same call must not be resent; an identical request is refused for 2 minutes after a timeout or 504. Narrow the filters instead.

## Repository

https://github.com/dotzero-ai/dz-ai
