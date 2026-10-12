# DotZero

Tools for the DotZero MES (work orders, SPC, equipment, device topology, OEE, supply chain, sales, warehouse, engineering drawings).

- Before calling any DotZero tool, make sure the user is logged in: call `auth_status`; if not logged in, ask for their **tenant ID** and call `auth_login(tenant_id: "...")`. A browser login page opens — never ask for the password in chat.
- The REST fallback for each service is documented in `skills/dotzero-*/SKILL.md`.
