# Export API Skill

MCP skill for chart generation and data export — PNG/JPG charts, CSV/XLSX files. No authentication required.

## Overview

This skill provides 13 tools for generating charts and exporting data:

- **Generic Charts** (5): Bar, line, pie, scatter, gauge
- **DotZero Charts** (4): OEE breakdown, SPC control chart, device timeline, multi-chart dashboard
- **Export** (2): CSV, XLSX
- **Smart** (2): Auto-detect chart type, auto-convert JSON to table

## Prerequisites

No authentication required. This is a pure rendering engine.

For data workflows, authenticate with DotZero services first (opens a secure browser login; password never passes through the AI):

```
auth_login(tenant_id: "your-tenant-id")
```

## Tools Reference

### Generic Chart Tools

#### chart_bar
Generate a bar chart (vertical, horizontal, or stacked).

**Parameters:**
- `title` (string, required): Chart title
- `labels` (string[], required): Category labels
- `datasets` (array, required): Data series with `label`, `data[]`, `color?`
- `options` (object, optional): `stacked`, `horizontal`, `show_legend`, `show_grid`, `x_label`, `y_label`, `min_y`, `max_y`
- `width` (number, default: 800): Image width
- `height` (number, default: 500): Image height
- `format` ('png'|'jpg', default: 'png'): Image format
- `output_path` (string, optional): Custom output path

#### chart_line
Generate a line chart with one or more series.

**Parameters:**
- `title` (string, required): Chart title
- `labels` (string[], required): X-axis labels
- `datasets` (array, required): Data series with `label`, `data[]`, `color?`, `fill?`
- `options` (object, optional): Same as chart_bar
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_pie
Generate a pie or doughnut chart.

**Parameters:**
- `title` (string, required): Chart title
- `labels` (string[], required): Slice labels
- `values` (number[], required): Slice values
- `colors` (string[], optional): Slice colors (hex)
- `chart_type` ('pie'|'doughnut', default: 'pie')
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_scatter
Generate a scatter plot.

**Parameters:**
- `title` (string, required): Chart title
- `datasets` (array, required): Series with `label`, `data[]` ({x, y} points), `color?`
- `options` (object, optional): Same as chart_bar
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_gauge
Generate a gauge chart for a single KPI.

**Parameters:**
- `value` (number, required): Value to display
- `label` (string, optional): Metric label
- `min` (number, default: 0): Minimum
- `max` (number, default: 100): Maximum
- `thresholds` (array, optional): Color breakpoints `{value, color}`
- `width`, `height`, `format`, `output_path`: Same as chart_bar

---

### DotZero-Specific Chart Tools

#### chart_oee_breakdown
Generate an OEE breakdown chart (A/Q/P bars).

**Parameters:**
- `title` (string, default: "OEE Breakdown"): Chart title
- `availability` (number, required): Availability %
- `quality` (number, required): Quality %
- `performance` (number, required): Performance %
- `oee` (number, optional): Combined OEE (auto-calculated if omitted)
- `devices` (array, optional): Multi-device comparison `{name, availability, quality, performance}`
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_control
Generate an SPC control chart with UCL/CL/LCL.

**Parameters:**
- `title` (string, default: "Control Chart"): Chart title
- `values` (number[], required): Measurement values
- `labels` (string[], optional): X-axis labels
- `ucl` (number, required): Upper Control Limit
- `cl` (number, required): Center Line
- `lcl` (number, required): Lower Control Limit
- `usl` (number, optional): Upper Specification Limit
- `lsl` (number, optional): Lower Specification Limit
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_timeline
Generate a device state timeline chart.

**Parameters:**
- `title` (string, default: "Device Timeline"): Chart title
- `device_name` (string, optional): Device name
- `segments` (array, required): Timeline segments `{start, end, state, color?}`
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### chart_multi
Generate multiple charts in a single dashboard image.

**Parameters:**
- `title` (string, default: "Dashboard"): Overall title
- `charts` (array, required, max 9): Sub-chart configs (bar/line/pie/gauge)
- `layout` ('grid'|'vertical'|'horizontal', default: 'grid')
- `width`, `height`, `format`, `output_path`: Same as chart_bar

---

### Export Tools

#### export_csv
Export data to CSV file.

**Parameters:**
- `headers` (string[], required): Column headers
- `rows` (array, required): Row data (arrays of string/number/boolean/null)
- `filename` (string, optional): Output filename
- `output_path` (string, optional): Custom output path

#### export_xlsx
Export data to Excel XLSX file.

**Parameters:**
- `sheets` (array, required): Sheets with `name`, `headers[]`, `rows[][]`
- `filename` (string, optional): Output filename
- `output_path` (string, optional): Custom output path

---

### Smart Tools

#### chart_from_json
Auto-detect JSON data format and generate appropriate chart.

**Parameters:**
- `title` (string, default: "Auto Chart"): Chart title
- `data` (any, required): JSON from any DotZero tool
- `chart_type` ('auto'|'bar'|'line'|'pie'|'gauge'|'oee', default: 'auto')
- `width`, `height`, `format`, `output_path`: Same as chart_bar

#### export_table_from_json
Auto-convert JSON data to CSV or XLSX.

**Parameters:**
- `data` (any, required): JSON from any DotZero tool
- `format` ('csv'|'xlsx', default: 'csv')
- `filename` (string, optional): Output filename
- `output_path` (string, optional): Custom output path
- `sheet_name` (string, default: "Data"): Sheet name for XLSX

---

## Usage Examples

### Workflow: OEE Chart

```
# 1. Get OEE data (JSON format)
oee_device(device_uuid: "uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z", response_format: "json")

# 2. Generate breakdown chart
chart_oee_breakdown(title: "CNC-01 OEE", availability: 92.5, quality: 98.1, performance: 85.3)
```

### Workflow: Export work orders to Excel

```
# 1. Get work order data
workorder_list(status: 2, response_format: "json")

# 2. Auto-export to XLSX
export_table_from_json(data: <result>, format: "xlsx", filename: "active-work-orders")
```

## File Output

- Default: `.dotzero/exports/<type>-<name>-<timestamp>.<ext>`
- `.dotzero/` is already in `.gitignore`

## Error Handling

| Error | Solution |
|-------|----------|
| Canvas init failure | Ensure `@napi-rs/canvas` is installed |
| File write error | Check write permissions for output directory |

## MCP Server

- **Package**: `@dotzero.ai/export-mcp`
- **Tools**: 13 (all public, no auth required)

## Repository

https://github.com/dotzero-ai/dz-ai
