---
name: dotzero-auth
description: DotZero 認證（登入取 token、查狀態、自動刷新）。Use when 使用者要登入 DotZero、token 過期、其他 DotZero 服務回 401（login, auth token expired, 401）。MCP 工具可用時直接叫工具（auth_login / auth_status）；本 skill 只給路由與已知陷阱。
compatibility: 需要網路存取和執行 curl 的能力
metadata:
  author: dotzero
  version: "1.1.0"
---

# DotZero Authentication

Centralized authentication for DotZero services. Works with any AI Agent that can execute curl commands or use WebFetch.

## Token Expiration

- **Token 有效期限**: 1 小時
- **自動刷新**: 使用 refresh_token 可以取得新的 token
- **credentials.json** 會儲存 `expires_at` 時間來追蹤過期

## Token Storage

Credentials are stored in `.dotzero/` directory (project-level if exists, otherwise `~/.dotzero/`):

| File | Purpose |
|------|---------|
| `.dotzero/config.json` | API URL overrides — **optional**; without it every skill uses the production URLs |
| `.dotzero/credentials.json` | Token, refresh_token, and expiration time |

**credentials.json 格式**:
```json
{
  "tenant_id": "my-company",
  "email": "user@example.com",
  "name": "User Name",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2024-01-15T11:30:00Z"
}
```

**Important**: Add `.dotzero/` to `.gitignore` to avoid committing credentials.

## Initial Setup

**Optional** — only needed to point at non-default URLs (e.g. an on-prem deployment). Without this file every `dotzero-*` skill falls back to the production URLs below:

```bash
# 建立 .dotzero 設定目錄（預設用家目錄，專案隔離用 .dotzero/）
mkdir -p ~/.dotzero
cat > ~/.dotzero/config.json << 'EOF'
{
  "user_api_url": "https://dotzerotech-user-api.dotzero.app",
  "work_order_api_url": "https://work-order-api.dotzero.app",
  "spc_api_url": "https://dotzerotech-spc-backend.dotzero.app",
  "equipment_api_url": "https://dotzerotech-equipment-api.dotzero.app",
  "device_topology_api_url": "https://dotzerotech-device-topology.dotzero.app",
  "oee_api_url": "https://dotzerotech-oee-api.dotzero.app",
  "scm_api_url": "https://dotzerotech-scm-backend.dotzero.app",
  "gdt_api_url": "https://gdt-backend.dotzero.app",
  "sd_api_url": "https://sales-distribution-api.dotzero.app",
  "wms_api_url": "https://dotzerotech-wms-backend.dotzero.app"
}
EOF
```

> 這份範本要涵蓋**每一個** `dotzero-*` skill 會讀的 key。少一個就會靜默退回
> 該 skill 自己 hardcode 的 fallback（例如 `dotzero-wms` 讀不到 `wms_api_url`），
> 換了環境才會炸。新增 skill 時記得回來補這裡。

> All URLs above are standard DotZero endpoints — no changes needed.
> For project-level isolation, create `.dotzero/` in the project directory instead.
> Add `.dotzero/` to `.gitignore` to avoid committing credentials.

## Login

**Step 1 — Ask user for Tenant ID** (only this, never ask for email or password):

```
AI: "請問你的 Tenant ID 是什麼？"
```

**Step 2 — Call `auth_login` MCP tool** (opens browser login automatically):

```
auth_login(tenant_id: "your-tenant-id")
```

> Browser opens at `http://127.0.0.1:<port>/` — user enters email + password in the browser form.
> Password **never** passes through the AI. Token is returned automatically on success.

### If `auth_login` MCP tool is not available

The DotZero auth MCP server is not registered with this agent. Register it (user-level), restart the agent, then call `auth_login(tenant_id: "your-tenant-id")` again:

```bash
# Claude Code
claude mcp add dotzero-auth -e USER_API_URL=https://user-api.dotzero.app -- npx -y @dotzero.ai/auth-mcp
# Codex CLI (writes ~/.codex/config.toml)
codex mcp add dotzero-auth --env USER_API_URL=https://user-api.dotzero.app -- npx -y @dotzero.ai/auth-mcp
# Gemini CLI
gemini mcp add -s user -e USER_API_URL=https://user-api.dotzero.app dotzero-auth npx -y @dotzero.ai/auth-mcp
```

All three run the server locally via `npx`, so the browser login opens on the user's machine. Web-only
clients (ChatGPT, the Gemini app) accept only remote HTTPS MCP servers and cannot run this one.

### Fallback — terminal login (only if MCP cannot be set up)

密碼**不可以**經過 AI：不要在對話裡要密碼，也不要把密碼放進你執行的指令。請使用者在**自己的終端機**執行（密碼隱藏輸入）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dotzero-ai/dz-ai/main/scripts/dotzero-login.sh) <email> <tenant_id>
```

成功後 token 寫進 `.dotzero/credentials.json`（目前目錄有 `.dotzero/` 就寫那裡，否則 `~/.dotzero/`），所有 `dotzero-*` skill 與 MCP server 都讀同一份。

## Get Valid Token (Auto-Refresh)

**在每次 API 呼叫前，先檢查 token 是否過期，如過期則自動刷新。** 每次 Bash 呼叫都是新的 shell——函數要跟使用它的 curl 放在同一個指令裡：

```bash
# Function to get valid token (auto-refresh if expired)
get_valid_token() {
  # Find .dotzero directory: project-level first, then user home
  if [ -d ".dotzero" ]; then
    _DOTZERO_DIR=".dotzero"
  elif [ -d "${HOME}/.dotzero" ]; then
    _DOTZERO_DIR="${HOME}/.dotzero"
  else
    _DOTZERO_DIR="${HOME}/.dotzero"
  fi
  CREDS_FILE="${_DOTZERO_DIR}/credentials.json"
  CONFIG_FILE="${_DOTZERO_DIR}/config.json"

  if [ ! -f "$CREDS_FILE" ]; then
    echo "ERROR: Not logged in" >&2
    return 1
  fi

  # Read current credentials
  CREDS=$(cat "$CREDS_FILE")
  EXPIRES_AT=$(echo "$CREDS" | jq -r '.expires_at // empty')

  # Check if token is expired (with 5 minute buffer)
  if [ -n "$EXPIRES_AT" ]; then
    EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" "+%s" 2>/dev/null || date -d "$EXPIRES_AT" "+%s" 2>/dev/null || echo "0")
    NOW_TS=$(date "+%s")
    BUFFER=300  # 5 minutes

    if [ $((EXPIRES_TS - BUFFER)) -gt $NOW_TS ]; then
      # Token still valid
      echo "$CREDS" | jq -r '.token'
      return 0
    fi
  fi

  # Token expired or no expiration time, refresh it
  echo "Token expired, refreshing..." >&2

  REFRESH_TOKEN=$(echo "$CREDS" | jq -r '.refresh_token')
  TENANT_ID=$(echo "$CREDS" | jq -r '.tenant_id')
  USER_API_URL=$(jq -r '.user_api_url // empty' "$CONFIG_FILE" 2>/dev/null)
  USER_API_URL=${USER_API_URL:-https://dotzerotech-user-api.dotzero.app}

  RESPONSE=$(curl -s -X POST \
    "${USER_API_URL}/v2/auth/token?tenantID=${TENANT_ID}" \
    -H "Content-Type: application/json" \
    -d "{\"grant_type\":\"refresh_token\",\"refresh_token\":\"${REFRESH_TOKEN}\"}")

  # /v2/auth/token returns a plain JWT string, not a JSON object
  NEW_TOKEN=""
  if echo "$RESPONSE" | jq -e 'type == "string"' > /dev/null 2>&1; then
    NEW_TOKEN=$(echo "$RESPONSE" | jq -r '.')
  elif [[ "$RESPONSE" == eyJ* ]]; then
    NEW_TOKEN="$RESPONSE"
  fi

  if [ -n "$NEW_TOKEN" ]; then
    NEW_EXPIRES=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

    # Update token and expiration (refresh_token is not rotated)
    echo "$CREDS" | jq --arg tok "$NEW_TOKEN" --arg exp "$NEW_EXPIRES" '
      .token = $tok |
      .expires_at = $exp
    ' > "$CREDS_FILE"

    echo "$NEW_TOKEN"
    echo "Token refreshed!" >&2
    return 0
  else
    echo "ERROR: Refresh failed, please login again" >&2
    return 1
  fi
}

# Usage: Get valid token for API calls
TOKEN=$(get_valid_token)
```

## Quick Token Access (Without Auto-Refresh)

If you just want to read the current token:

```bash
_DZ_DIR=$([ -d ".dotzero" ] && echo ".dotzero" || echo "${HOME}/.dotzero")
TOKEN=$(cat "${_DZ_DIR}/credentials.json" | jq -r '.token')
```

## Check Token Status

```bash
_DZ_DIR=$([ -d ".dotzero" ] && echo ".dotzero" || echo "${HOME}/.dotzero")
if [ -f "${_DZ_DIR}/credentials.json" ]; then
  CREDS=$(cat "${_DZ_DIR}/credentials.json")
  echo "Email: $(echo "$CREDS" | jq -r '.email')"
  echo "Tenant: $(echo "$CREDS" | jq -r '.tenant_id')"
  echo "Expires: $(echo "$CREDS" | jq -r '.expires_at')"

  # Check if expired
  EXPIRES_AT=$(echo "$CREDS" | jq -r '.expires_at // empty')
  if [ -n "$EXPIRES_AT" ]; then
    EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" "+%s" 2>/dev/null || date -d "$EXPIRES_AT" "+%s" 2>/dev/null || echo "0")
    NOW_TS=$(date "+%s")
    if [ $EXPIRES_TS -lt $NOW_TS ]; then
      echo "Status: EXPIRED"
    else
      echo "Status: Valid"
    fi
  fi
else
  echo "Not logged in"
fi
```

## Manual Token Refresh

```bash
_DZ_DIR=$([ -d ".dotzero" ] && echo ".dotzero" || echo "${HOME}/.dotzero")
CREDS=$(cat "${_DZ_DIR}/credentials.json")
REFRESH_TOKEN=$(echo "$CREDS" | jq -r '.refresh_token')
TENANT_ID=$(echo "$CREDS" | jq -r '.tenant_id')
USER_API_URL=$(jq -r '.user_api_url // empty' "${_DZ_DIR}/config.json" 2>/dev/null)
USER_API_URL=${USER_API_URL:-https://dotzerotech-user-api.dotzero.app}

RESPONSE=$(curl -s -X POST \
  "${USER_API_URL}/v2/auth/token?tenantID=${TENANT_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"grant_type\":\"refresh_token\",\"refresh_token\":\"${REFRESH_TOKEN}\"}")

# /v2/auth/token returns a plain JWT string
NEW_TOKEN=""
if echo "$RESPONSE" | jq -e 'type == "string"' > /dev/null 2>&1; then
  NEW_TOKEN=$(echo "$RESPONSE" | jq -r '.')
elif [[ "$RESPONSE" == eyJ* ]]; then
  NEW_TOKEN="$RESPONSE"
fi

if [ -n "$NEW_TOKEN" ]; then
  NEW_EXPIRES=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

  echo "$CREDS" | jq --arg tok "$NEW_TOKEN" --arg exp "$NEW_EXPIRES" '
    .token = $tok |
    .expires_at = $exp
  ' > "${_DZ_DIR}/credentials.json"
  echo "Token refreshed! New expiration: $NEW_EXPIRES"
else
  echo "Refresh failed: $RESPONSE"
fi
```

## Token Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│  1. First Use - Login                                       │
│     Execute: curl POST /v2/auth/login                       │
│     → Receive token, refresh_token                          │
│     → Calculate expires_at (now + 1 hour)                   │
│     → Save to .dotzero/credentials.json                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Before Each API Call - Check & Auto-Refresh             │
│     Read expires_at from credentials.json                   │
│     → If valid: use current token                           │
│     → If expired: call refresh endpoint                     │
│        → Update token and expires_at                        │
│        → If refresh fails: prompt re-login                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Make API Call with Valid Token                          │
│     Use token in Authorization header                       │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling

Errors are returned as JSON `{"errorType": "...", "errorMsg": "..."}`. Note: login failures return **HTTP 500** (not 400/401) — match on `errorType`, not on HTTP status or message text.

| HTTP | errorType | errorMsg (actual) | Solution |
|------|-----------|-------------------|----------|
| 500 | `INVALID_AUTH_INFO` | `Please check tenantId, email and password.` | Verify email and password |
| 500 | `INVALID_AUTH_INFO` | `No such tenant.` | Ask user for correct tenant_id |
| 500 | `INVALID_AUTH_INFO` | `User is not existed.` | Email is not a member of this tenant — check tenant_id or ask the tenant admin |
| 500 | `USER_DISABLED` | `This account is disabled.` | User was removed from / disabled in the tenant — ask the tenant admin |
| 500 | `INVALID_DATA` | `Email / Password is not given.` | Ensure all required fields are provided |
| 500 | `TOO_MANY_ATTEMPTS_TRY_LATER` | `Attemps too many times, please try later.` | Wait before retrying |
| 500 | `TOKEN_EXPIRED` | `RefreshToken is expired.` | (refresh) Log in again |
| 500 | `USER_NOT_FOUND` | `User was been deleted.` | (refresh) Account deleted — log in with another account |
| 500 | `ERROR_NOT_EXPECTED` | (varies — on refresh e.g. `RefreshToken is not for the tenant specified by parameter.`) | Retry once; if refresh keeps failing, log in again |
| 401 | (no body) | Token expired/invalid on protected endpoints | Auto-refresh or re-login |

## API Reference

### POST /v2/auth/login

**URL**: `{USER_API_URL}/v2/auth/login?tenantID={tenant_id}`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "<your-password>"
}
```

**Response**:
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "token": "eyJhbG...",
  "refresh_token": "eyJhbG...",
  "tenant_id": "my-company"
}
```

### POST /v2/auth/token (Refresh)

**URL**: `{USER_API_URL}/v2/auth/token?tenantID={tenant_id}`

**Request Body**:
```json
{
  "grant_type": "refresh_token",
  "refresh_token": "eyJhbG..."
}
```

**Response**: the raw JWT as `text/plain` — not JSON, no surrounding quotes
```
eyJhbG...
```

Notes:
- **Rotation (cloud)**: In the cloud environment the refresh_token is not rotated — keep using the original refresh_token from login. (Edge/keycloak deployments do rotate, but the default response discards the new refresh_token; pass `?new_refresh_token=true` — edge only — to get JSON `{"token", "refresh_token"}` instead of a plain string. Cloud rejects `new_refresh_token=true` with `INVALID_DATA`.)
- `grant_type=password` is also supported (body: `email` + `password`), returning a plain token string — normally prefer `/v2/auth/login` which also returns a refresh_token.

### GET /v2/auth/userInfo

The most direct way to verify a token is still valid and confirm the current identity.

**URL**: `{USER_API_URL}/v2/auth/userInfo`

**Headers**: `Authorization: Bearer {token}` (tenant is derived from the token — no query param)

**Response** (200):
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "tenantId": "my-company"
}
```

401 (empty body) means the token is invalid/expired — refresh or re-login.

## Helper Scripts

From a clone of the `dotzero-ai/dz-ai` repository (run in **your own terminal** — the login script prompts for the password):

```bash
# Login
./scripts/dotzero-login.sh user@example.com my-tenant
# Password will be prompted securely (not visible in shell history)

# Get valid token (auto-refresh)
TOKEN=$(./scripts/dotzero-token.sh get)

# Check token status
./scripts/dotzero-token.sh check

# Force refresh
./scripts/dotzero-token.sh refresh
```

## Environment

**Default User API URL**: `https://dotzerotech-user-api.dotzero.app`

You can override this in `.dotzero/config.json`.
