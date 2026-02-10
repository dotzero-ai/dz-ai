#!/bin/bash
# DotZero Token Manager
# Usage:
#   ./dotzero-token.sh get          # Get valid token (auto-refresh if expired)
#   ./dotzero-token.sh check        # Check token status
#   ./dotzero-token.sh refresh      # Force refresh token
#
# This script automatically handles token refresh when the token is expired.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CREDS_FILE=".dotzero/credentials.json"
CONFIG_FILE=".dotzero/config.json"

# Check if credentials file exists
check_credentials() {
    if [ ! -f "$CREDS_FILE" ]; then
        echo -e "${RED}Error: Not logged in. Please run dotzero-login.sh first.${NC}" >&2
        exit 1
    fi
}

# Check if token is expired (with 5 minute buffer)
is_token_expired() {
    local expires_at=$(cat "$CREDS_FILE" | jq -r '.expires_at // empty')

    if [ -z "$expires_at" ]; then
        # No expiration time stored, assume expired
        return 0
    fi

    local expires_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${expires_at%%.*}" "+%s" 2>/dev/null || date -d "$expires_at" "+%s" 2>/dev/null || echo "0")
    local now_ts=$(date "+%s")
    local buffer=300  # 5 minutes buffer

    if [ $((expires_ts - buffer)) -lt $now_ts ]; then
        return 0  # Expired or about to expire
    else
        return 1  # Still valid
    fi
}

# Refresh the token
do_refresh() {
    check_credentials

    local refresh_token=$(cat "$CREDS_FILE" | jq -r '.refresh_token')
    local tenant_id=$(cat "$CREDS_FILE" | jq -r '.tenant_id')
    local user_api_url=$(cat "$CONFIG_FILE" 2>/dev/null | jq -r '.user_api_url // "https://dotzerotech-user-api.dotzero.app"')

    if [ -z "$refresh_token" ] || [ "$refresh_token" = "null" ]; then
        echo -e "${RED}Error: No refresh token available. Please login again.${NC}" >&2
        exit 1
    fi

    echo -e "${YELLOW}Refreshing token...${NC}" >&2

    local response=$(curl -s -X POST \
        "${user_api_url}/v2/auth/token?tenantID=${tenant_id}" \
        -H "Content-Type: application/json" \
        -d "{\"grant_type\":\"refresh_token\",\"refresh_token\":\"${refresh_token}\"}")

    # The /v2/auth/token endpoint returns a plain JWT string (not JSON object)
    # Check if response is a valid JWT (starts with "eyJ") or a quoted string
    local new_token=""
    if echo "$response" | jq -e 'type == "string"' > /dev/null 2>&1; then
        # Response is a JSON-encoded string
        new_token=$(echo "$response" | jq -r '.')
    elif [[ "$response" == eyJ* ]]; then
        # Response is a raw JWT string
        new_token="$response"
    fi

    if [ -n "$new_token" ]; then
        # Calculate new expiration time (1 hour from now)
        local expires_at=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

        # Update credentials file, preserving existing fields (refresh_token is not rotated)
        local current=$(cat "$CREDS_FILE")
        echo "$current" | jq --arg tok "$new_token" --arg exp "$expires_at" '
            .token = $tok |
            .expires_at = $exp
        ' > "$CREDS_FILE"
        chmod 600 "$CREDS_FILE"

        echo -e "${GREEN}Token refreshed successfully!${NC}" >&2
        return 0
    else
        local error=$(echo "$response" | jq -r '.message // .error // "Unknown error"' 2>/dev/null || echo "$response")
        echo -e "${RED}Refresh failed: ${error}${NC}" >&2
        echo -e "${YELLOW}Please login again using dotzero-login.sh${NC}" >&2
        exit 1
    fi
}

# Get a valid token (auto-refresh if needed)
get_token() {
    check_credentials

    if is_token_expired; then
        do_refresh
    fi

    cat "$CREDS_FILE" | jq -r '.token'
}

# Check token status
check_status() {
    check_credentials

    local email=$(cat "$CREDS_FILE" | jq -r '.email')
    local tenant_id=$(cat "$CREDS_FILE" | jq -r '.tenant_id')
    local expires_at=$(cat "$CREDS_FILE" | jq -r '.expires_at // "unknown"')

    echo -e "Email: ${GREEN}${email}${NC}"
    echo -e "Tenant: ${GREEN}${tenant_id}${NC}"
    echo -e "Expires: ${expires_at}"

    if is_token_expired; then
        echo -e "Status: ${YELLOW}Expired or expiring soon${NC}"
    else
        echo -e "Status: ${GREEN}Valid${NC}"
    fi
}

# Main
case "${1:-get}" in
    get)
        get_token
        ;;
    check)
        check_status
        ;;
    refresh)
        do_refresh
        ;;
    *)
        echo "Usage: $0 {get|check|refresh}"
        echo ""
        echo "Commands:"
        echo "  get     - Get valid token (auto-refresh if expired)"
        echo "  check   - Check token status"
        echo "  refresh - Force refresh token"
        exit 1
        ;;
esac
