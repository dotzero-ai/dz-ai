#!/bin/bash
# DotZero Login Script
# Usage: ./dotzero-login.sh <email> <tenant_id>
#
# This script authenticates with DotZero and saves the credentials
# to .dotzero/credentials.json for use by other tools — the project's
# .dotzero/ if it exists, otherwise ~/.dotzero/ (same lookup as the MCP servers).

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments — password is always prompted interactively
if [ $# -ne 2 ]; then
    echo -e "${YELLOW}Usage: $0 <email> <tenant_id>${NC}"
    echo ""
    echo "Arguments:"
    echo "  email      - Your DotZero email address"
    echo "  tenant_id  - Your company tenant ID"
    echo ""
    echo "Password will be prompted securely (not visible)."
    echo ""
    echo "Example:"
    echo "  $0 user@example.com my-company"
    exit 1
fi

EMAIL="$1"
TENANT_ID="$2"
echo -n "Password: "
read -s PASSWORD
echo ""

DZ_DIR=$([ -d .dotzero ] && echo .dotzero || echo "$HOME/.dotzero")
mkdir -p -m 700 "$DZ_DIR"

# config.json is optional (only for non-default URLs, e.g. on-prem)
USER_API_URL=$(jq -r '.user_api_url // empty' "$DZ_DIR/config.json" 2>/dev/null || true)  # set -e: missing file is fine
USER_API_URL=${USER_API_URL:-https://dotzerotech-user-api.dotzero.app}

echo -e "${YELLOW}Authenticating with DotZero...${NC}"
echo "  API URL: ${USER_API_URL}"
echo "  Email: ${EMAIL}"
echo "  Tenant ID: ${TENANT_ID}"

# Make login request
RESPONSE=$(curl -s -X POST \
    "${USER_API_URL}/v2/auth/login?tenantID=${TENANT_ID}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg e "$EMAIL" --arg p "$PASSWORD" '{email: $e, password: $p}')")

# Check if login was successful
if echo "$RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
    # Calculate expiration time (1 hour from now)
    EXPIRES_AT=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

    # Save credentials with expiration time
    (umask 077; echo "$RESPONSE" | jq --arg tenant "$TENANT_ID" --arg exp "$EXPIRES_AT" '{
        tenant_id: $tenant,
        email: .email,
        name: .name,
        token: .token,
        refresh_token: .refresh_token,
        expires_at: $exp
    }' > "$DZ_DIR/credentials.json")
    chmod 600 "$DZ_DIR/credentials.json"

    NAME=$(echo "$RESPONSE" | jq -r '.name // .email')
    echo ""
    echo -e "${GREEN}Login successful!${NC}"
    echo "  Logged in as: ${NAME}"
    echo "  Token expires: ${EXPIRES_AT}"
    echo "  Credentials saved to: $DZ_DIR/credentials.json"
    echo ""
    echo -e "${YELLOW}Tip: Use ./scripts/dotzero-token.sh get to auto-refresh expired tokens${NC}"
    echo -e "${YELLOW}Remember to add .dotzero/ to your .gitignore${NC}"
else
    # Login failed
    # user-api errors are {"errorType", "errorMsg"} with HTTP 500
    ERROR=$(echo "$RESPONSE" | jq -r '.errorMsg // .message // .error // "Unknown error"' 2>/dev/null || echo "$RESPONSE")
    echo ""
    echo -e "${RED}Login failed: ${ERROR}${NC}"
    echo ""
    echo "Full response:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
