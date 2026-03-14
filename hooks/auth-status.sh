#!/bin/bash
# DotZero SessionStart Hook — display auth status
# Shows login state, email, tenant, and token expiry at session start

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Find .dotzero directory: project-level first, then user home
if [ -d ".dotzero" ]; then
  _DZ_DIR=".dotzero"
elif [ -d "${HOME}/.dotzero" ]; then
  _DZ_DIR="${HOME}/.dotzero"
else
  _DZ_DIR=""
fi

echo ""
printf "${BOLD}Plugin:dotzero${NC} · DotZero MCP Servers\n"
echo ""

CREDS_FILE="${_DZ_DIR}/credentials.json"

if [ -z "$_DZ_DIR" ] || [ ! -f "$CREDS_FILE" ]; then
  printf "  ${BOLD}Auth:${NC}   ${RED}✗ not authenticated${NC}\n"
  printf "  ${DIM}→ Call auth_login(tenant_id: \"your-tenant\") to log in${NC}\n"
else
  # Check if jq is available
  if ! command -v jq &>/dev/null; then
    printf "  ${BOLD}Auth:${NC}   ${YELLOW}⚠ credentials found (jq not installed for details)${NC}\n"
    echo ""
    exit 0
  fi

  CREDS=$(cat "$CREDS_FILE" 2>/dev/null || echo "{}")
  TOKEN=$(echo "$CREDS" | jq -r '.token // ""' 2>/dev/null || echo "")

  if [ -z "$TOKEN" ]; then
    printf "  ${BOLD}Auth:${NC}   ${RED}✗ credentials invalid${NC}\n"
    printf "  ${DIM}→ Call auth_login(tenant_id: \"your-tenant\") to re-login${NC}\n"
  else
    EMAIL=$(echo "$CREDS" | jq -r '.email // "unknown"' 2>/dev/null || echo "unknown")
    TENANT=$(echo "$CREDS" | jq -r '.tenant_id // "unknown"' 2>/dev/null || echo "unknown")
    EXPIRES_AT=$(echo "$CREDS" | jq -r '.expires_at // ""' 2>/dev/null || echo "")

    # Calculate expiry info
    EXPIRES_INFO=""
    if [ -n "$EXPIRES_AT" ]; then
      EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" "+%s" 2>/dev/null || \
                   date -d "$EXPIRES_AT" "+%s" 2>/dev/null || echo "0")
      NOW_TS=$(date "+%s")

      if [ "$EXPIRES_TS" -le "$NOW_TS" ]; then
        EXPIRES_INFO=" ${YELLOW}(expired — will auto-refresh on next API call)${NC}"
      else
        DIFF_MIN=$(( (EXPIRES_TS - NOW_TS) / 60 ))
        if [ "$DIFF_MIN" -gt 60 ]; then
          DIFF_HR=$(( DIFF_MIN / 60 ))
          EXPIRES_INFO=" ${DIM}(${DIFF_HR}h remaining)${NC}"
        else
          EXPIRES_INFO=" ${DIM}(${DIFF_MIN}m remaining)${NC}"
        fi
      fi
    fi

    printf "  ${BOLD}Auth:${NC}   ${GREEN}✓ ${EMAIL}${NC}${EXPIRES_INFO}\n"
    printf "  ${BOLD}Tenant:${NC} ${TENANT}\n"
  fi
fi

echo ""
