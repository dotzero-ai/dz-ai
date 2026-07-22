# DotZero All Systems Skill

Aggregate skill for accessing all DotZero MCP servers and tools.

## Overview

This skill provides access to all DotZero system integrations through MCP servers.

## Getting Started

### 1. Authentication First

All DotZero services share one authentication. You only need the user's **tenant_id**.

**IMPORTANT**: If you don't know the user's tenant_id, ask them for it. **DO NOT ask for email or password** — calling `auth_login` with only `tenant_id` opens a secure browser login form where the user enters credentials directly; the password never passes through the AI.

```
# Use the auth skill or any service's auth_login tool.
# Opens a browser login form; email/password are entered there, not by the AI.
auth_login(tenant_id: "your-tenant-id")
```

### 2. Use Service Tools

After authentication, you can use the service-specific tools.

---

## Available Systems

### Authentication API

Centralized authentication for all DotZero services.

- **MCP Server**: `@dotzero.ai/auth-mcp`
- **Skill**: [auth](../auth/SKILL.md)
- **Tools**: 3

| Tool | Description |
|------|-------------|
| `auth_login` | Authenticate with `tenant_id` (opens secure browser login; no password from AI) |
| `auth_refresh` | Refresh an expired token |
| `auth_status` | Check authentication configuration |

---

### Work Order API

Manage work orders, products, workers, routes, operations, devices, quality, warehouse, and WMS in manufacturing execution systems (MES).

- **MCP Server**: `@dotzero.ai/work-order-mcp`
- **Skill**: [work-order-api](../work-order-api/SKILL.md)
- **Tools**: 101

| Category | Count | Tools |
|----------|-------|-------|
| Authentication | 2 | `auth_login`, `auth_status` |
| Work Orders | 7 | `workorder_list`, `workorder_get`, `workorder_create`, `workorder_update`, `workorder_delete`, `workorder_details`, `workorder_count` |
| Products | 6 | `product_list`, `product_get`, `product_create`, `product_update`, `product_details`, `product_copy` |
| Workers | 5 | `worker_list`, `worker_get`, `worker_create`, `worker_update`, `worker_delete` |
| Operation History | 7 | `operation_history_list`, `operation_history_by_workorder`, `operation_history_get`, `operation_history_create`, `operation_history_create_many`, `operation_history_delete`, `operation_history_timeline` |
| Reports & Analytics | 9 | `workorder_report`, `report_update`, `analytics_operations`, `analytics_workorder_report`, `worker_efficiency_ranking`, `device_utilization_ranking`, `production_summary`, `workorder_dashboard`, `material_production_ranking` — **物料產量排名用 `material_production_ranking`（正確時間過濾）；週報端點後端已停用，改用 `workorder_dashboard`** |
| Routes | 7 | `route_list`, `route_get`, `route_create`, `route_update`, `route_delete`, `route_by_product`, `route_copy` |
| Operations | 5 | `operation_list`, `operation_get`, `operation_create`, `operation_update`, `operation_delete` |
| Route Operations | 6 | `route_operation_list`, `route_operation_get`, `route_operation_create`, `route_operation_update`, `route_operation_delete`, `route_operation_by_route` |
| Devices | 3 | `device_list`, `device_get`, `device_delete` — **後端 device 建立/更新已停用，僅唯讀 + 刪除** |
| Defect Reasons | 4 | `defect_reason_list`, `defect_reason_create`, `defect_reason_update`, `defect_reason_delete` |
| Defect Reason Categories | 4 | `defect_reason_category_list`, `defect_reason_category_get`, `defect_reason_category_create`, `defect_reason_category_update` |
| Stations | 6 | `station_list`, `station_get`, `station_create`, `station_update`, `station_delete`, `station_device_list` |
| Abnormal History | 5 | `abnormal_history_list`, `abnormal_history_get`, `abnormal_history_create`, `abnormal_history_update`, `abnormal_history_by_workorder` |
| Abnormal Config | 4 | `abnormal_category_list`, `abnormal_category_create`, `abnormal_state_list`, `abnormal_state_create` |
| Op Product BOM | 4 | `op_product_bom_list`, `op_product_bom_create`, `op_product_bom_update`, `op_product_bom_delete` |
| Warehouses | 4 | `warehouse_list`, `warehouse_get`, `warehouse_create`, `warehouse_update` |
| Warehouse Storage | 4 | `warehouse_storage_list`, `warehouse_storage_get`, `warehouse_storage_create`, `warehouse_storage_update` |
| Product Storage | 3 | `product_storage_list`, `product_storage_get`, `product_storage_by_product` |
| WMS | 4 | `wms_check_inventory`, `wms_query_product_storage`, `wms_query_storage_history`, `wms_minimal_stock_count` |

---

### SPC API (Statistical Process Control)

Manage measurement configurations, record inspection data, calculate control charts, and monitor quality statistics.

- **MCP Server**: `@dotzero.ai/spc-mcp`
- **Skill**: [spc-api](../spc-api/SKILL.md)
- **Tools**: 49

| Category | Count | Tools |
|----------|-------|-------|
| Authentication | 2 | `auth_login`, `auth_status` |
| Products V2 | 2 | `spc_product_manufacture_list`, `spc_product_stock_list` |
| History V2 | 4 | `spc_history_list`, `spc_history_batch_upsert`, `spc_history_batch_by_group`, `spc_history_delete_by_group` |
| Config Parent V2 | 5 | `spc_config_parent_get`, `spc_config_parent_create`, `spc_config_parent_update`, `spc_config_parent_attachment_add`, `spc_config_parent_attachment_delete` |
| Measure Config V1 | 9 | `spc_measure_config_list`, `spc_measure_config_get`, `spc_measure_config_create`, `spc_measure_config_update`, `spc_measure_config_delete`, `spc_measure_config_attachment_add`, `spc_measure_config_attachment_delete`, `spc_measure_config_modes`, `spc_measure_config_categories` |
| Measure History V1 | 11 | `spc_measure_history_create`, `spc_measure_history_upsert`, `spc_measure_history_update`, `spc_measure_history_delete`, `spc_measure_history_batch_upsert`, `spc_measure_history_batch_delete`, `spc_measure_history_manufacture`, `spc_measure_history_stock`, `spc_measure_history_count`, `spc_measure_history_filter_list`, `spc_measure_history_filter_list_stock` |
| Instruments V1 | 5 | `spc_instrument_list`, `spc_instrument_create`, `spc_instrument_update`, `spc_instrument_delete`, `spc_instrument_batch_delete` |
| Rules V1 | 1 | `spc_rule_list` |
| Dashboard V1 | 6 | `spc_dashboard_list`, `spc_dashboard_create`, `spc_dashboard_update`, `spc_dashboard_delete`, `spc_dashboard_manufacture_create`, `spc_dashboard_manufacture_update` |
| Statistics V1 | 4 | `spc_statistics_nelson`, `spc_statistics_capability`, `spc_statistics_capability_by_point`, `spc_statistics_calculate_result` |

---

### Equipment API

Monitor real-time machine status, alarms, idle time, part counts, and equipment state aggregations.

- **MCP Server**: `@dotzero.ai/equipment-mcp`
- **Skill**: [equipment-api](../equipment-api/SKILL.md)
- **Tools**: 12

| Category | Count | Tools |
|----------|-------|-------|
| Authentication | 2 | `auth_login`, `auth_status` |
| Alarms | 1 | `equip_alarm_list` |
| Idles | 1 | `equip_idle_list` |
| Machine Status | 5 | `equip_machine_status_history`, `equip_machine_status_part_counts`, `equip_machine_status_part_counts_batch`, `equip_machine_status_realtime`, `equip_machine_status_realtime_batch` |
| Off Time | 1 | `equip_off_time_list` |
| State Counts | 2 | `equip_state_counts_factory`, `equip_state_counts_line` |

---

### Device Topology API

Manage factory device topology — groups, factories, lines, devices, plant floors, alarms, and alarm codes.

- **MCP Server**: `@dotzero.ai/device-topology-mcp`
- **Skill**: [device-topology-api](../device-topology-api/SKILL.md)
- **Tools**: 39

| Category | Count | Tools |
|----------|-------|-------|
| Authentication | 2 | `auth_login`, `auth_status` |
| Groups | 5 | `topo_group_list`, `topo_group_get`, `topo_group_create`, `topo_group_update`, `topo_group_delete` |
| Factories | 5 | `topo_factory_list`, `topo_factory_get`, `topo_factory_create`, `topo_factory_update`, `topo_factory_delete` |
| Lines | 5 | `topo_line_list`, `topo_line_get`, `topo_line_create`, `topo_line_update`, `topo_line_delete` |
| Devices | 5 | `topo_device_list`, `topo_device_get`, `topo_device_create`, `topo_device_update`, `topo_device_delete` |
| Plant Floors | 4 | `topo_plant_floor_get`, `topo_plant_floor_create`, `topo_plant_floor_update`, `topo_plant_floor_delete` |
| Alarms | 5 | `topo_alarm_list`, `topo_alarm_get`, `topo_alarm_create`, `topo_alarm_update`, `topo_alarm_delete` |
| Alarm Codes | 6 | `topo_alarm_code_list`, `topo_alarm_code_get`, `topo_alarm_code_create`, `topo_alarm_code_update`, `topo_alarm_code_delete`, `topo_alarm_code_batch` |
| Topology | 2 | `topo_topology_count`, `topo_topology_all` |

---

### OEE API (Overall Equipment Effectiveness)

Calculate and analyze OEE metrics — availability, quality, performance — at device, line, and factory levels.

- **MCP Server**: `@dotzero.ai/oee-mcp`
- **Skill**: [oee-api](../oee-api/SKILL.md)
- **Tools**: 21

| Category | Count | Tools |
|----------|-------|-------|
| Authentication | 2 | `auth_login`, `auth_status` |
| Availability | 4 | `oee_availability_device`, `oee_availability_devices`, `oee_availability_line`, `oee_availability_factory` |
| Quality | 4 | `oee_quality_device`, `oee_quality_devices`, `oee_quality_line`, `oee_quality_factory` |
| Performance | 5 | `oee_performance_device`, `oee_performance_devices`, `oee_performance_line`, `oee_performance_factory`, `oee_performance_device_range` |
| OEE (Combined) | 4 | `oee_device`, `oee_devices`, `oee_line`, `oee_factory` |
| Status | 1 | `oee_device_status` |
| Alarm History | 1 | `oee_alarm_history` |

---

### Export API (Chart & Data Export)

Generate charts (PNG/JPG) and export data (CSV/XLSX) from DotZero manufacturing data. No authentication required.

- **MCP Server**: `@dotzero.ai/export-mcp`
- **Skill**: [export-api](../export-api/SKILL.md)
- **Tools**: 13

| Category | Count | Tools |
|----------|-------|-------|
| Generic Charts | 5 | `chart_bar`, `chart_line`, `chart_pie`, `chart_scatter`, `chart_gauge` |
| DotZero Charts | 4 | `chart_oee_breakdown`, `chart_control`, `chart_timeline`, `chart_multi` |
| Export | 2 | `export_csv`, `export_xlsx` |
| Smart | 2 | `chart_from_json`, `export_table_from_json` |

---

### GDT API (Engineering Drawings)

Engineering drawing search, similarity retrieval, and drawing feature extraction (dimensions / GD&T / hole counts). Read-only.

- **MCP Server**: `@dotzero.ai/gdt-mcp`
- **Skill**: [gdt-api](../gdt-api/SKILL.md)
- **Tools**: 5 (2 auth + 3 read)

| Tool | Description |
|------|-------------|
| `auth_login`, `auth_status` | Authenticate & check status |
| `gdt_drawing_list` | List engineering drawings (filter by q / customer / product) |
| `gdt_drawing_similar` | Find drawings similar to a given drawing id |
| `gdt_feature_list` | Dimensions / GD&T / hole-count features of a drawing |

---

### SCM API (Supply Chain)

Queries for deliveries, QA inspection, supplier performance, and billable invoices. Read-only.

- **MCP Server**: `@dotzero.ai/scm-mcp`
- **Skill**: [scm-api](../scm-api/SKILL.md)
- **Tools**: 6 (2 auth + 4 read)

| Tool | Description |
|------|-------------|
| `auth_login`, `auth_status` | Authenticate & check status |
| `scm_delivery_list` | Deliverable / outstanding deliveries |
| `scm_qa_inspectable` | Items awaiting QA inspection |
| `scm_supplier_performance` | Supplier performance metrics (by period YYYY-MM) |
| `scm_invoice_billable` | Billable invoice items with amounts |

---

### SD API (Sales & Distribution)

Customer sales orders and customer master queries. Read-only.

- **MCP Server**: `@dotzero.ai/sd-mcp`
- **Skill**: [sd-api](../sd-api/SKILL.md)
- **Tools**: 5 (2 auth + 3 read)

| Tool | Description |
|------|-------------|
| `auth_login`, `auth_status` | Authenticate & check status |
| `sd_order_list` | List customer sales orders (filters + pagination) |
| `sd_order_get` | Get one sales order by UUID (not business number) |
| `sd_customer_list` | List customers |

---

### WMS API (Warehouse)

Stock levels, low-stock alerts, and work-order picking progress. Read-only.

- **MCP Server**: `@dotzero.ai/wms-mcp`
- **Skill**: [wms-api](../wms-api/SKILL.md)
- **Tools**: 5 (2 auth + 3 read)

| Tool | Description |
|------|-------------|
| `auth_login`, `auth_status` | Authenticate & check status |
| `wms_stock_query` | Query product storage / stock levels |
| `wms_low_stock_list` | Products below minimal stock level |
| `wms_picking_progress` | Work-order picking completion rate (planned-date range) |

---

### Gateway MCP (Unified Entry Point)

Single MCP server that dynamically loads tools from all DotZero services on demand.

- **MCP Server**: `@dotzero.ai/dotzero-mcp`
- **Startup Tools**: 6

| Tool | Description |
|------|-------------|
| `auth_login` | Unified login (one JWT works for all services) |
| `auth_status` | Check auth + show configured services |
| `auth_refresh` | Refresh expired token |
| `find_tools` | Search tools by keyword across the gateway tool catalog |
| `list_services` | Show available/loaded services |
| `load_service` | Load a service's tools on demand |

> **Note**: The gateway tool-catalog (`packages/dotzero-mcp/src/tool-catalog.ts`) now indexes all 10 services — work-order, spc, equipment, device-topology, oee, export, **gdt, scm, sd, wms** — so `find_tools` / `load_service` can reach every service through the gateway (`auth_login` / `auth_status` are handled by `loadService` and intentionally excluded from the catalog). You may still use each service's dedicated MCP server (`dotzero-gdt`, `dotzero-scm`, `dotzero-sd`, `dotzero-wms`) directly.

---

## Tool Count Summary

| MCP Server | Tools |
|------------|-------|
| auth-mcp | 3 |
| work-order-mcp | 103 |
| spc-mcp | 49 |
| equipment-mcp | 12 |
| device-topology-mcp | 39 |
| oee-mcp | 21 |
| export-mcp | 13 |
| gdt-mcp | 5 |
| scm-mcp | 6 |
| sd-mcp | 5 |
| wms-mcp | 5 |
| dotzero-mcp (gateway) | 6 + dynamic |
| **Total** | **~267** |

---

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Request                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Do you have the user's tenant_id?                          │
│                                                              │
│  NO ──────► Ask user: "What is your DotZero tenant ID?"     │
│                                                              │
│  YES ─────► Continue to authentication                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  auth_login(tenant_id) → opens browser login                 │
│                                                              │
│  Returns: token, refresh_token, user info                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Use service tools (workorder_list, oee_device, etc.)        │
│                                                              │
│  If 401 error: Use auth_refresh or auth_login again          │
└─────────────────────────────────────────────────────────────┘
```

---

## Environment Variables

### Required (per service)

| Variable | Service |
|----------|---------|
| `WORK_ORDER_API_URL` | Work Order API |
| `SPC_API_URL` | SPC API |
| `EQUIPMENT_API_URL` | Equipment API |
| `DEVICE_TOPOLOGY_API_URL` | Device Topology API |
| `OEE_API_URL` | OEE API |
| `GDT_API_URL` | GDT API |
| `SCM_API_URL` | SCM API |
| `SD_API_URL` | SD API |
| `WMS_API_URL` | WMS API |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `USER_API_URL` | https://dotzerotech-user-api.dotzero.app | Auth API URL |

---

## MCP Server Configuration

### Quick Setup (Recommended)

```bash
npx @dotzero.ai/setup
```

### Manual Setup

```bash
# Auth
claude mcp add dotzero-auth --command "node" --args "packages/auth-mcp/dist/index.js"

# Work Order
claude mcp add dotzero-workorder --command "node" --args "packages/work-order-mcp/dist/index.js" --env "WORK_ORDER_API_URL=https://work-order-api.dotzero.app"

# SPC
claude mcp add dotzero-spc --command "node" --args "packages/spc-mcp/dist/index.js" --env "SPC_API_URL=https://dotzerotech-spc-backend.dotzero.app"

# Equipment
claude mcp add dotzero-equipment --command "node" --args "packages/equipment-mcp/dist/index.js" --env "EQUIPMENT_API_URL=https://dotzerotech-equipment-api.dotzero.app"

# Device Topology
claude mcp add dotzero-device-topology --command "node" --args "packages/device-topology-mcp/dist/index.js" --env "DEVICE_TOPOLOGY_API_URL=https://dotzerotech-device-topology.dotzero.app"

# OEE
claude mcp add dotzero-oee --command "node" --args "packages/oee-mcp/dist/index.js" --env "OEE_API_URL=https://dotzerotech-oee-api.dotzero.app"

# GDT (Engineering Drawings)
claude mcp add dotzero-gdt --command "node" --args "packages/gdt-mcp/dist/index.js" --env "GDT_API_URL=https://gdt-backend.dotzero.app"

# SCM (Supply Chain)
claude mcp add dotzero-scm --command "node" --args "packages/scm-mcp/dist/index.js" --env "SCM_API_URL=https://dotzerotech-scm-backend.dotzero.app"

# SD (Sales & Distribution)
claude mcp add dotzero-sd --command "node" --args "packages/sd-mcp/dist/index.js" --env "SD_API_URL=https://sales-distribution-api.dotzero.app"

# WMS (Warehouse)
claude mcp add dotzero-wms --command "node" --args "packages/wms-mcp/dist/index.js" --env "WMS_API_URL=https://dotzerotech-wms-backend.dotzero.app"
```

---

## Quick Reference

### Common Workflows

**Check work order status:**
```
workorder_list(status: 2)  # In progress
workorder_details(work_order_id: "WO-001")
```

**Check factory OEE:**
```
oee_factory(factory_uuid: "uuid", start_time: "2026-02-01T00:00:00Z", end_time: "2026-02-07T23:59:59Z")
```

**Monitor equipment:**
```
equip_state_counts_factory(factory_uuid: "uuid")
equip_realtime_batch(device_uuids: ["dev-1", "dev-2"])
```

**Analyze SPC quality:**
```
spc_measure_config_list()
spc_statistics_capability(spc_measure_point_config_uuid: "config-uuid")
```

**Explore topology:**
```
topo_topology_all()
topo_device_list(line_uuid: "line-uuid")
```

### Error Recovery

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| Token expired | Call `auth_refresh` with refresh_token |
| Tenant not found | Verify tenant_id with user |

---

## Repository

https://github.com/dotzero-ai/dz-ai
