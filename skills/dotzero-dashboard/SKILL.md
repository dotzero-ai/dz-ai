---
name: dotzero-dashboard
description: DotZero 儀表板 panel 撰寫。用 viz_state(chartType+Cube.js query) 定義圖表，掛到看板；含 cube 欄位與範例。
compatibility: 需要先完成 dotzero-auth 認證；資料源在 dashboard-backend Cube.js
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero Dashboard Panel Authoring

Author DotZero dashboard panels — a panel is defined by a `viz_state` (a chart type plus a Cube.js query) and attached to a board. This skill teaches the exact `viz_state` shape, the Cube.js query rules, and the core cube fields so any AI Agent produces panels that actually render (not blank). Works with any AI Agent.

## Architecture

Two DIFFERENT services are involved — do not confuse them:

```
dashboard-api  (:5062, Go)      → stores the panel row. viz_state/custom_style/layout are opaque JSON STRINGS it never parses.
dashboard-backend (:5011, Node) → the Cube.js OLAP engine. The dashboard frontend runs your `query` against /cubejs-api/v1.
```

A panel is one row with fields `name`, `board_id`, `viz_state`, `custom_style`, `layout`. All three of `viz_state`/`custom_style`/`layout` are STRING columns holding JSON. The frontend `JSON.parse`s each, then renders. The Cube query inside `viz_state` is what pulls the numbers from dashboard-backend.

## viz_state schema

`viz_state` is a JSON string that decodes to EXACTLY two keys — nothing else is read:

```json
{ "chartType": "bar", "query": { /* Cube.js query object */ } }
```

- There is NO `spec` key. If you add one it is silently ignored.
- An EMPTY query `{}` renders an EMPTY panel. Always supply real `measures`/`dimensions`.
- `chartType` MUST be one of these (nothing else renders):
  `line`, `area`, `bar`, `pie`, `table`, `number`, `cards`, `gauge`, `timeline`, `statusmap`, `images`, `iframe`.
- `oee-breakdown` is NOT a panel chartType — it is only a PNG export tool (see `dotzero-export`). Using it renders BLANK.

### Companion fields (required to avoid a broken panel)

The frontend calls `JSON.parse(custom_style)` UNCONDITIONALLY. A null/empty/absent value THROWS and breaks the whole panel. Always store at least `"{}"`:

- `custom_style` (string): minimum `"{}"`; better `{"chartStyle":{"showLegend":true,"colors":[]}}`.
- `layout` (string): `{"website":{"x":0,"y":0,"w":4,"h":8}}` (react-grid-layout, minW/minH forced to 2).

## Cube.js query rules

The `query` is a standard Cube.js query:

```json
{
  "measures": ["Cube.member"],
  "dimensions": ["Cube.member"],
  "timeDimensions": [{"dimension": "Cube.timeMember", "granularity": "day", "dateRange": ["2026-07-16", "2026-07-23"]}],
  "filters": [{"member": "Cube.dim", "operator": "equals", "values": ["CNC-01"]}],
  "order": [["Cube.member", "asc"]],
  "limit": 100
}
```

- **Member naming is `CubeName.memberName`** (e.g. `OeeDaily.avgCalOee`). Never invent names.
- **Tenant is 100% server-side.** The agent sends ONLY `Authorization: Bearer <JWT>`. NEVER put `tenant_id` in the query.
- **Time members: use the PLAIN name** (`OeeDaily.startTime`, `MachineStatus.createTime`). When a `timeDimensions` entry exists the server auto-rewrites to the tz-adjusted `...Converted` column — do NOT send the `Converted` names yourself.
- **`granularity`**: `day` | `week` | `month` | `hour` | `15min`, or omit for a single total.
- **`dateRange`**: `["from","to"]` (ISO dates) or a named range like `"Today"`, `"This Week"`, `"This Month"`.
- **`MachineStatus` REQUIRES a `createTime` dateRange** (via `timeDimensions` or a filter); its base SQL is built from it or it returns empty.
- **Filter operators**: `equals`, `notEquals`, `contains`, `set`, `gt`, `lt`, `gte`, `lte`, `inDateRange`.
- **Filter a device** by `DeviceInfo.name` (device master); line/factory by `LineInfo.name` / `FactoryInfo.name`.
- The `query` is authored WITHOUT querying data first — you name measures/dimensions from the catalog below; the frontend runs the query live.

## Core cube field catalog

Addresses are `CubeName.member`. This is the common core; the AUTHORITATIVE, complete list is live at `GET http://localhost:5011/cubejs-api/v1/meta` (Bearer required). Many measures are dynamically generated (`sum`/`avg`/`count` × indicator, e.g. `OeeDaily.sumQty`, `OeeDaily.avgOee`) — consult `/meta` rather than hardcoding everything.

| Cube | Key measures | Key dimensions | Time member |
|------|-------------|----------------|-------------|
| `OeeDaily` (OEE 統計) | `avgCalOee`, `avgCalAvailability`, `avgCalPerformance`, `avgCalQuality`, `avgCalTeep`, `sumGood`, `sumDefect`, `sumQty`, `avgOee` | via `DeviceInfo.name`; `machineName` | `OeeDaily.startTime` |
| `MachineStatus` (設備狀態) | `runCountMin`, `idleCountMin`, `alarmCountMin`, `offCountMin`, `availability` | `state`, `stateType`, via `DeviceInfo.name` | `MachineStatus.createTime` (**required dateRange**) |
| `WorkOrder` | `sumGood`, `sumQty`, `sumWoohSumGood`, `sumWoohSumDefect`, `avgCalActWorkTime` | `workOrderId`, `status`, `statusType`, `productName`, `ratioOfActStd` (生產效率), `delayOrNot` | `WorkOrder.startTime` |
| `WorkOrderOpHistory` | `sumGood`, `sumDefect`, `sumQty`, `upph` (每人時良品數), `avgCalQuality` | `status`, product/worker fields | `WorkOrderOpHistory.startTime` |
| `DeviceInfo` (機台設定) | `count` | `name` (device master — filter device here) | — |
| `LineInfo` / `FactoryInfo` | `count` | `name` | — |
| `EMSHistory` (設備履歷) | `runDurationSum`, `idleDurationSum`, `alarmDurationSum`, `offDurationSum`, `availability` | `stateType`, via `DeviceInfo.name` | `EMSHistory.startTime` |
| `AlarmCodeHistory` | `count`, `sumCalDuration` | `code`, `category`, `messageTc` | `AlarmCodeHistory.startTime` |

## Worked viz_state examples

Each is the exact JSON string to store in the `viz_state` column.

### 1. Daily OEE per machine (line chart over time)

```json
{"chartType":"line","query":{"measures":["OeeDaily.avgCalOee"],"dimensions":["DeviceInfo.name"],"timeDimensions":[{"dimension":"OeeDaily.startTime","granularity":"day","dateRange":"This Month"}],"order":[["OeeDaily.startTime","asc"]]}}
```

### 2. Machine RUN/IDLE/ALARM minutes per device (bar chart, createTime required)

```json
{"chartType":"bar","query":{"measures":["MachineStatus.runCountMin","MachineStatus.idleCountMin","MachineStatus.alarmCountMin","MachineStatus.offCountMin"],"dimensions":["DeviceInfo.name"],"timeDimensions":[{"dimension":"MachineStatus.createTime","dateRange":"Today"}]}}
```

### 3. Time availability KPI (single-value gauge, measures only)

```json
{"chartType":"gauge","query":{"measures":["MachineStatus.availability"],"timeDimensions":[{"dimension":"MachineStatus.createTime","dateRange":"Today"}]}}
```

### 4. Good vs defect share by device (pie)

```json
{"chartType":"pie","query":{"measures":["OeeDaily.sumGood","OeeDaily.sumDefect"],"dimensions":["DeviceInfo.name"],"timeDimensions":[{"dimension":"OeeDaily.startTime","dateRange":"This Week"}]}}
```

Companion strings for any of the above: `custom_style` = `{"chartStyle":{"showLegend":true,"colors":[]}}`, `layout` = `{"website":{"x":0,"y":0,"w":4,"h":8}}`.

## Common mistakes

- Adding a `spec` key to `viz_state` — dead, never read.
- Empty `query {}` — renders an empty panel; always give measures/dimensions.
- `chartType: "oee-breakdown"` — not a panel type, renders blank. Use `bar`/`gauge`, or `dotzero-export`'s `chart_oee_breakdown` for a PNG.
- Sending `tenant_id` in the query — ignored; tenant is server-side from the Bearer.
- Sending `...Converted` time members — send the plain name; the server rewrites it.
- `MachineStatus` without a `createTime` dateRange — returns empty.
- Missing/`null` `custom_style` — frontend `JSON.parse` throws and breaks the panel; store at least `"{}"`.

## Authoritative member list

Do not hardcode the full schema. Fetch it live:

```
GET http://localhost:5011/cubejs-api/v1/meta
Authorization: Bearer <JWT>
```

This returns every cube's exact measures/dimensions (including all generated `sum`/`avg`/`count` measures) for the caller's tenant.

## Dashboard REST API (dashboard-api :5062)

The **dashboard-api** (Go/Echo/GORM) stores boards + panels — a *different* service from the Cube.js engine. All calls send `Authorization: Bearer <JWT>`; **tenant is server-side, never send `tenant_id`**. Base: local `http://localhost:5062`, prod `https://dashboard-api.dotzero.app`.

- **List boards** — `GET {base}/menu` → `{"tree_data":[{category, children:[{_id,name,menuType:"dashboard"}]}]}`. A board = a `menuType:"dashboard"` child; match `name` to get its `board_id`.
- **List panels** — `GET {base}/dashboard` (optional `?board_id=` / `?name=`) → JSON array of `{_id(=panel_id), board_id, name, viz_state, custom_style, layout}`. No server-side paging. `name` may be a multilingual JSON string; show `zh-TW`.
- **Create panel** — `POST {base}/dashboard`, body is a **JSON ARRAY** (batch, even for one). `viz_state`/`custom_style`/`layout` are JSON **strings**:
```
POST /dashboard
[ {"board_id":"<24-hex>","name":"本週各機台良品數",
   "viz_state":"{\"chartType\":\"bar\",\"query\":{\"measures\":[\"OeeDaily.sumGood\"],\"dimensions\":[\"DeviceInfo.name\"],\"timeDimensions\":[{\"dimension\":\"OeeDaily.startTime\",\"dateRange\":\"This week\"}]}}",
   "custom_style":"{\"chartStyle\":{\"showLegend\":true,\"colors\":[]}}",
   "layout":"{\"website\":{\"x\":0,\"y\":0,\"w\":4,\"h\":8}}"} ]
```
Returns created rows, each with a 24-hex `_id` (= panel_id). Errors are often a 500 with a plain-text body.
- **Create board** — no dedicated endpoint: `GET /menu` → append `{"_id":"<24-hex>","name":"...","menuType":"dashboard","viewPermission":["employee","manager","boss"]}` under a category → `PUT {base}/menu` (or `POST` if none yet).
- **Delete panel** — `DELETE {base}/dashboard/{panel_id}`.
- **User link** — `{dashboard_web}/dashboard/{boardName}` (local `http://localhost:3013`).

## Repository

https://gitlab.com/dotzero/dz-ai
