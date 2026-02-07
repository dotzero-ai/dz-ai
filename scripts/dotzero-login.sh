#!/bin/bash
# DotZero Login Script
# Usage: ./dotzero-login.sh <email> <password> <tenant_id>
#
# This script authenticates with DotZero and saves the credentials
# to .dotzero/credentials.json for use by other tools.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 3 ]; then
    echo -e "${YELLOW}Usage: $0 <email> <password> <tenant_id>${NC}"
    echo ""
    echo "Arguments:"
    echo "  email      - Your DotZero email address"
    echo "  password   - Your DotZero password"
    echo "  tenant_id  - Your company tenant ID"
    echo ""
    echo "Example:"
    echo "  $0 user@example.com password123 my-company"
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"
TENANT_ID="$3"

# Create .dotzero directory if it doesn't exist
mkdir -p .dotzero

# Check for config file, create default if not exists
if [ ! -f .dotzero/config.json ]; then
    echo -e "${YELLOW}Creating default config file...${NC}"
    cat > .dotzero/config.json << 'EOF'
{
  "user_api_url": "https://dotzerotech-user-api.dotzero.app",
  "work_order_api_url": "https://YOUR-COMPANY.dotzero.app"
}
EOF
    echo -e "${YELLOW}Please update .dotzero/config.json with your Work Order API URL${NC}"
fi

# Read User API URL from config
USER_API_URL=$(cat .dotzero/config.json 2>/dev/null | jq -r '.user_api_url // "https://dotzerotech-user-api.dotzero.app"')

echo -e "${YELLOW}Authenticating with DotZero...${NC}"
echo "  API URL: ${USER_API_URL}"
echo "  Email: ${EMAIL}"
echo "  Tenant ID: ${TENANT_ID}"

# Make login request
RESPONSE=$(curl -s -X POST \
    "${USER_API_URL}/v2/auth/login?tenantID=${TENANT_ID}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")

# Check if login was successful
if echo "$RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
    # Calculate expiration time (1 hour from now)
    EXPIRES_AT=$(date -u -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ")

    # Save credentials with expiration time
    echo "$RESPONSE" | jq --arg tenant "$TENANT_ID" --arg exp "$EXPIRES_AT" '{
        tenant_id: $tenant,
        email: .email,
        name: .name,
        token: .token,
        refresh_token: .refresh_token,
        expires_at: $exp
    }' > .dotzero/credentials.json

    NAME=$(echo "$RESPONSE" | jq -r '.name // .email')
    echo ""
    echo -e "${GREEN}Login successful!${NC}"
    echo "  Logged in as: ${NAME}"
    echo "  Token expires: ${EXPIRES_AT}"
    echo "  Credentials saved to: .dotzero/credentials.json"
    echo ""
    echo -e "${YELLOW}Tip: Use ./scripts/dotzero-token.sh get to auto-refresh expired tokens${NC}"
    echo -e "${YELLOW}Remember to add .dotzero/ to your .gitignore${NC}"
else
    # Login failed
    ERROR=$(echo "$RESPONSE" | jq -r '.message // .error // "Unknown error"')
    echo ""
    echo -e "${RED}Login failed: ${ERROR}${NC}"
    echo ""
    echo "Full response:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
