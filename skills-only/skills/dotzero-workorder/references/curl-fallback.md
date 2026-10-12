# Work Order — curl fallback plumbing

Only needed when the MCP tools are unavailable (see SKILL.md "Prefer MCP Tools").
With MCP, auth and token refresh are handled for you.

## Read Config and Token

每次 Bash 呼叫都是新的 shell：這三行要跟後面的 curl 放在**同一個指令**裡。

```bash
DZ=$([ -d .dotzero ] && echo .dotzero || echo "$HOME/.dotzero")   # same lookup as the MCP servers
API_URL=$(jq -r '.work_order_api_url // empty' "$DZ/config.json" 2>/dev/null); API_URL=${API_URL:-https://work-order-api.dotzero.app}
TOKEN=$(jq -r .token "$DZ/credentials.json")
```

`config.json` is optional — the default `https://work-order-api.dotzero.app` is correct for every cloud tenant (do not ask the user for it).

### On 401 Error

The token expired (1-hour lifetime). Refresh it with the **Manual Token Refresh** snippet in the
`dotzero-auth` skill (it writes the new token back to `credentials.json`), then re-run the block above.
If the refresh fails too, the user has to log in again.
