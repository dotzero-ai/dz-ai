# Work Order — curl fallback plumbing

Only needed when the MCP tools are unavailable (see SKILL.md "Prefer MCP Tools").
With MCP, auth and token refresh are handled for you.

## Get Valid Token (Auto-Refresh)

**重要**: Token 會在 1 小時後過期。在每次 API 呼叫前，使用以下函數自動刷新過期的 token：

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

  CREDS=$(cat "$CREDS_FILE")
  EXPIRES_AT=$(echo "$CREDS" | jq -r '.expires_at // empty')

  # Check if token is expired (with 5 minute buffer)
  if [ -n "$EXPIRES_AT" ]; then
    EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" "+%s" 2>/dev/null || date -d "$EXPIRES_AT" "+%s" 2>/dev/null || echo "0")
    NOW_TS=$(date "+%s")
    BUFFER=300

    if [ $((EXPIRES_TS - BUFFER)) -gt $NOW_TS ]; then
      echo "$CREDS" | jq -r '.token'
      return 0
    fi
  fi

  # Token expired, refresh it
  echo "Token expired, refreshing..." >&2
  REFRESH_TOKEN=$(echo "$CREDS" | jq -r '.refresh_token')
  TENANT_ID=$(echo "$CREDS" | jq -r '.tenant_id')
  USER_API_URL=$(cat "$CONFIG_FILE" | jq -r '.user_api_url')

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
      .token = $tok | .expires_at = $exp
    ' > "$CREDS_FILE"
    echo "$NEW_TOKEN"
    return 0
  else
    echo "ERROR: Refresh failed, please login again" >&2
    return 1
  fi
}
```

## Read Config and Token

Before any API call, get a valid token:

```bash
# Load configuration
CONFIG=$(cat .dotzero/config.json)
API_URL=$(echo "$CONFIG" | jq -r '.work_order_api_url // "https://work-order-api.dotzero.app"')
# Default: https://work-order-api.dotzero.app (do not ask user for this)

# Get valid token (auto-refresh if expired)
TOKEN=$(get_valid_token)
```

### On 401 Error

When you get a 401 error, the token has expired. Use `get_valid_token` function which auto-refreshes:

```bash
# Automatically refresh and get new token
TOKEN=$(get_valid_token)

# If using helper scripts:
TOKEN=$(./scripts/dotzero-token.sh get)

# Retry the failed request with new token
curl -s "${API_URL}/v1/workOrders/" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Tip**: Always use `get_valid_token` before making API calls to avoid 401 errors.
