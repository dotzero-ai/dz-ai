# GDT (Engineering Drawings) Skill

MCP skill for DotZero GDT (Engineering Drawings) — engineering drawing search, similarity retrieval, and feature extraction.

## Overview

This skill provides 3 read tools (+ auth):

- **auth_login / auth_status**: authenticate & check status
- **gdt_drawing_list**: list engineering drawings (filter by q/customer/product/...)
- **gdt_drawing_similar**: find drawings similar to a given drawing id
- **gdt_feature_list**: dimensions / GD&T / hole-count features of a drawing

All tools are **read-only** (query/analysis; no writes).

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
