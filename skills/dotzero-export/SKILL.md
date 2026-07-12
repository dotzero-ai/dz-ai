---
name: dotzero-export
description: DotZero 圖表生成與資料匯出。將製造數據視覺化為 PNG/JPG 圖表，匯出為 CSV/XLSX。
compatibility: 獨立運作，不需認證。搭配其他 DotZero skills 取得數據後使用。
metadata:
  author: dotzero
  version: "1.0.0"
---

# DotZero Export (Chart & Data Export)

Generate charts (PNG/JPG) and export data (CSV/XLSX) from DotZero manufacturing data. Works with any AI Agent. This is a pure rendering engine — no authentication required.

## Architecture

```
User → AI Agent → 1. Call DotZero MCP tool (json) → Get data
                → 2. Call export-mcp tool          → Generate chart/file
```

## Prerequisites

- `@dotzero.ai/export-mcp` MCP server running
- For data workflows: authenticate with DotZero services first via `auth_login`

## Tools Reference (14 tools)

### Generic Charts (5)

| Tool | Description | Key Inputs |
|------|-------------|------------|
| `chart_bar` | Bar chart (vertical/horizontal/stacked) | `title`, `labels[]`, `datasets[]`, `options?` |
| `chart_line` | Line chart (multi-series, area fill) | `title`, `labels[]`, `datasets[]`, `options?` |
| `chart_pie` | Pie or doughnut chart | `title`, `labels[]`, `values[]`, `chart_type?` |
| `chart_scatter` | Scatter plot | `title`, `datasets[]` (with {x,y} points) |
| `chart_gauge` | Gauge/dial for single KPI | `value`, `label?`, `min?`, `max?`, `thresholds?` |

### DotZero-Specific Charts (4)

| Tool | Description | Data Source |
|------|-------------|-------------|
| `chart_oee_breakdown` | OEE A/Q/P breakdown | `oee_device`, `oee_devices`, `oee_line`, `oee_factory` |
| `chart_control` | SPC control chart (UCL/CL/LCL) | `spc_statistics_capability`, `spc_measure_history_*` |
| `chart_timeline` | Device state timeline | `equip_machine_status_history` |
| `chart_multi` | Multi-chart dashboard (grid) | Multiple chart configs |

### Export Tools (2)

| Tool | Description | Key Inputs |
|------|-------------|------------|
| `export_csv` | Export to CSV file | `headers[]`, `rows[][]`, `filename?` |
| `export_xlsx` | Export to Excel XLSX | `sheets[]` (name/headers/rows), `filename?` |

### Smart Tools (2)

| Tool | Description |
|------|-------------|
| `chart_from_json` | Auto-detect DotZero JSON and pick best chart type |
| `export_table_from_json` | Auto-convert DotZero JSON to CSV or XLSX |

### Common Parameters (all chart tools)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `output_path` | auto | Custom file path |
| `width` | 800 | Image width (px) |
| `height` | 500 | Image height (px) |
| `format` | png | Image format (png/jpg) |

## Workflow Examples

### OEE Breakdown Chart

```
# 1. Get OEE data
oee_device(device_uuid: "uuid", start_time: "...", end_time: "...", response_format: "json")

# 2. Generate chart
chart_oee_breakdown(
  title: "CNC-01 OEE Breakdown",
  availability: 92.5,
  quality: 98.1,
  performance: 85.3
)
```

### SPC Control Chart

```
# 1. Get measurement data
spc_measure_history_manufacture(spc_config_parent_uuid: "uuid", response_format: "json")

# 2. Get capability stats
spc_statistics_capability(spc_measure_point_config_uuid: "uuid", response_format: "json")

# 3. Generate control chart
chart_control(
  title: "Diameter Control Chart",
  values: [10.01, 10.03, 9.98, ...],
  ucl: 10.15,
  cl: 10.00,
  lcl: 9.85,
  usl: 10.20,
  lsl: 9.80
)
```

### Production Summary CSV Export

```
# 1. Get production data
production_summary(start_time_start: "...", start_time_end: "...", response_format: "json")

# 2. Export to CSV
export_table_from_json(
  data: <json_result>,
  format: "csv",
  filename: "production-summary-feb"
)
```

### Worker Efficiency Bar Chart

```
# 1. Get ranking data
worker_efficiency_ranking(start_time_start: "...", start_time_end: "...", response_format: "json")

# 2. Auto-generate chart
chart_from_json(
  title: "Worker Efficiency Ranking",
  data: <json_result>
)
```

### Device State Pie Chart

```
# 1. Get state counts
equip_state_counts_line(line_uuid: "uuid", start_time: "...", end_time: "...", response_format: "json")

# 2. Generate pie chart
chart_pie(
  title: "Line A State Distribution",
  labels: ["Running", "Idle", "Down", "Off"],
  values: [480, 120, 30, 10],
  colors: ["#4CAF50", "#FFC107", "#F44336", "#9E9E9E"]
)
```

### Multi-Chart Dashboard

```
chart_multi(
  title: "Production Dashboard",
  layout: "grid",
  charts: [
    { type: "gauge", title: "OEE", value: 78.5 },
    { type: "bar", title: "Output by Line", labels: ["A", "B", "C"], datasets: [...] },
    { type: "pie", title: "Defect Distribution", labels: [...], values: [...] },
    { type: "line", title: "Weekly Trend", labels: [...], datasets: [...] }
  ]
)
```

## File Output

- Default directory: `.dotzero/exports/`
- Naming: `<type>-<name>-<timestamp>.<ext>`
- `.dotzero/` is in `.gitignore` — files won't be committed

## MCP Server

- **Package**: `@dotzero.ai/export-mcp`
- **Tools**: 13 (no authentication required)
- **No env vars needed**

## Repository

https://gitlab.com/dotzero/dz-ai
