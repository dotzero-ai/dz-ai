---
name: dotzero-auth
description: DotZero 認證服務。登入取得 token，管理認證狀態，自動刷新過期 token。適用於任何 AI Agent。
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

Credentials are stored in the project's `.dotzero/` directory:

| File | Purpose |
|------|---------|
| `.dotzero/config.json` | API URLs configuration |
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

Before first use, create the config file:

```bash
mkdir -p .dotzero
cat > .dotzero/config.json << 'EOF'
{
  "user_api_url": "https://dotzerotech-user-api.dotzero.app",
  "work_order_api_url": "https://YOUR-COMPANY.dotzero.app"
}
EOF
```

Replace `YOUR-COMPANY` with the actual API hostname.

## Login

**Required information** (ask user if not known):
- `email`: User's email address
- `password`: User's password
- `tenant_id`: Company tenant ID

### Login Command

```bash
# Read config
USER_API_URL=$(cat .dotzero/config.json | jq -r '.user_api_url')

# Set credentials (replace with actual values)
EMAIL="user@example.com"
PASSWORD="password123"
TENANT_ID="my-company"

# Login
RESPONSE=$(curl -s -X POST \
  "${USER_API_URL}/v2/auth/login?tenantID=${TENANT_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")

# Check for success and save with expiration time
if echo "$RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
  # Calculate expiration (1 hour from now)
  EXPIRES_AT=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

  # Save credentials
  echo "$RESPONSE" | jq --arg tenant "$TENANT_ID" --arg exp "$EXPIRES_AT" '{
    tenant_id: $tenant,
    email: .email,
    name: .name,
    token: .token,
    refresh_token: .refresh_token,
    expires_at: $exp
  }' > .dotzero/credentials.json
  echo "Login successful! Token expires at: $EXPIRES_AT"
else
  echo "Login failed: $RESPONSE"
fi
```

## Get Valid Token (Auto-Refresh)

**在每次 API 呼叫前，先檢查 token 是否過期，如過期則自動刷新：**

```bash
# Function to get valid token (auto-refresh if expired)
get_valid_token() {
  CREDS_FILE=".dotzero/credentials.json"
  CONFIG_FILE=".dotzero/config.json"

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
  USER_API_URL=$(cat "$CONFIG_FILE" | jq -r '.user_api_url')

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
TOKEN=$(cat .dotzero/credentials.json | jq -r '.token')
```

## Check Token Status

```bash
if [ -f .dotzero/credentials.json ]; then
  CREDS=$(cat .dotzero/credentials.json)
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
CREDS=$(cat .dotzero/credentials.json)
REFRESH_TOKEN=$(echo "$CREDS" | jq -r '.refresh_token')
TENANT_ID=$(echo "$CREDS" | jq -r '.tenant_id')
USER_API_URL=$(cat .dotzero/config.json | jq -r '.user_api_url')

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
  ' > .dotzero/credentials.json
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

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid email or password` | Wrong credentials | Verify email and password |
| `Tenant not found` | Invalid tenant_id | Ask user for correct tenant_id |
| `Bad request` | Missing parameters | Ensure all required fields are provided |
| `Too many login attempts` | Rate limited | Wait before retrying |
| `401 Unauthorized` | Token expired | Auto-refresh or re-login |
| `Refresh token expired` | Refresh token also expired | Must re-login |

## API Reference

### POST /v2/auth/login

**URL**: `{USER_API_URL}/v2/auth/login?tenantID={tenant_id}`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**:
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "token": "eyJhbG...",
  "refresh_token": "eyJhbG..."
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

**Response**: Plain JWT string (not a JSON object)
```
"eyJhbG..."
```

Note: The refresh_token is not rotated. Keep using the original refresh_token from login.

## Helper Scripts

If using the dz-ai repository, helper scripts are available:

```bash
# Login
./scripts/dotzero-login.sh user@example.com password123 my-tenant

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
