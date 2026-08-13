# DotZero Authentication Skill

Centralized authentication for DotZero services.

## Overview

This skill provides authentication tools for all DotZero services. Use this skill before using other DotZero services that require authentication.

## Required Information

Before authenticating, you only need:

| Field | Description |
|-------|-------------|
| `tenant_id` | Tenant ID - **Ask the user if not known** |

> **DO NOT ask for email or password.** Calling `auth_login` with only `tenant_id` automatically opens a browser login form where the user enters credentials directly and securely — the password never passes through the AI.

## Tools

### auth_login

Authenticate with DotZero. **Always call with `tenant_id` only** — this opens a secure browser login form.

**Parameters:**
- `tenant_id` (string, required): Tenant ID for authentication
- `email` (string, optional): Only provide if user explicitly pastes it
- `password` (string, optional): **Never ask for this** — browser login handles it securely

**Returns:**
- `token`: JWT token for API calls
- `refresh_token`: Token for refreshing the session
- `email`: User's email
- `name`: User's name
- `tenant_id`: Confirmed tenant ID

**Example:**
```
auth_login(tenant_id: "your-tenant-id")
```
This opens a browser window where the user signs in. No email or password needed from the AI side.

### auth_refresh

Refresh an expired JWT token using a refresh token.

**Parameters:**
- `refresh_token` (string, required): Refresh token from a previous login
- `tenant_id` (string, required): Tenant ID for authentication

**Returns:**
- `token`: New JWT token
- `refresh_token`: New refresh token (may be the same)

**Example:**
```
auth_refresh(
  refresh_token: "your-refresh-token",
  tenant_id: "your-tenant-id"
)
```

### auth_status

Check the authentication configuration status.

**Parameters:** None

**Returns:** Current User API URL and available tools

> Note: `auth_status` only reports **local** state (in-memory token present, configured URLs) — it does not contact the backend. To actually verify a token against the server, call `GET {USER_API_URL}/v2/auth/userInfo` with `Authorization: Bearer {token}`; 200 returns `{email, name, tenantId}`, 401 means the token is invalid/expired.

## Authentication Flow

```
┌─────────────────┐
│  User Request   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      No      ┌─────────────────┐
│  Have Token?    │─────────────►│  auth_login     │
└────────┬────────┘              │  (ask for       │
         │ Yes                   │  tenant_id)     │
         ▼                       └────────┬────────┘
┌─────────────────┐                       │
│  Use Token      │◄──────────────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐      Yes     ┌─────────────────┐
│  Token Expired? │─────────────►│  auth_refresh   │
└────────┬────────┘              └────────┬────────┘
         │ No                             │
         ▼                                │
┌─────────────────┐                       │
│  Make API Call  │◄──────────────────────┘
└─────────────────┘
```

## Workflow Examples

### First-time Authentication

```
# 1. Ask user only for their Tenant ID
AI: "請問你的 Tenant ID 是什麼？"

# 2. User provides tenant_id
User: "my-company"

# 3. Call auth_login with tenant_id only → browser opens automatically
auth_login(tenant_id: "my-company")

# Browser opens at http://127.0.0.1:<port>/
# User enters email + password in the browser form
# On success, token is returned to Claude Code automatically
```

### Token Refresh

```
# When a 401 error occurs:
# 1. Try to refresh the token
auth_refresh(refresh_token: "stored-refresh-token", tenant_id: "my-company")

# 2. If refresh fails, open browser login again
auth_login(tenant_id: "my-company")
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `USER_API_URL` | No | https://dotzerotech-user-api.dotzero.app | DotZero User API URL |

## MCP Server

- **Package**: `@dotzero.ai/auth-mcp`
- **Tools**: 3 (auth_login, auth_refresh, auth_status)

### Add to Claude Code

```bash
claude mcp add dotzero-auth \
  -e USER_API_URL=https://user-api.dotzero.app \
  -- npx -y @dotzero.ai/auth-mcp
```

> The form is `claude mcp add <name> [-e K=V ...] -- <command> [args...]`; the `--`
> separator is required. There is no `--command` / `--args` — passing them fails with
> `error: unknown option '--command'`. (`--env` does exist, as the long form of
> `-e`; what breaks the old snippets is `--command` / `--args`, and the command
> itself must follow `--`.)
>
> Verify with `claude mcp list`, then restart Claude Code.

## Error Handling

Backend errors come as JSON `{"errorType": "...", "errorMsg": "..."}`; login failures return **HTTP 500** (not 400/401) — match on `errorType`, not on HTTP status or message text.

| HTTP | errorType | Cause | Solution |
|------|-----------|-------|----------|
| 500 | `INVALID_AUTH_INFO` | Wrong credentials (`Please check tenantId, email and password.`) | Verify email and password |
| 401 | `INVALID_AUTH_INFO` | Invalid tenant_id (`No such tenant.`) | Ask user for correct tenant_id |
| 500 | `INVALID_DATA` | Missing parameters (`Email / Password is not given.`) | Ensure all required fields are provided |
| 500 | `TOO_MANY_ATTEMPTS_TRY_LATER` | Rate limited | Wait before retrying |

## Repository

https://github.com/dotzero-ai/dz-ai
