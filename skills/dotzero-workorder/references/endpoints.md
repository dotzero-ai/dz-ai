# Work Order API — full endpoint reference

Complete endpoint table for the curl fallback path. The MCP tools cover the common
operations; consult this only when you need an endpoint the tools do not expose.

### Core MES

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List work orders | GET | `/v1/workOrders/` |
| Get work order | GET | `/v1/workOrders/{id}` |
| Get work order details | POST | `/v1/workOrders/details` (body: `{"work_order_id": ["..."]}` — string array) |
| Create work order | POST | `/v1/workOrders/` |
| Update work order | PATCH | `/v1/workOrders/{uuid}` |
| Delete work order | DELETE | `/v1/workOrders/{uuid}` |
| Work order count | GET | `/v1/count/workOrders` |
| List products | GET | `/v1/products/` |
| Get product | GET | `/v1/products/{uuid}` |
| Get product details | GET | `/v1/products/{uuid}/details` |
| Create product | POST | `/v1/products` |
| Update product | PATCH | `/v1/products/{uuid}` |
| Copy product | POST | `/v1/products/{uuid}/copyProduct` |
| List workers | GET | `/v1/worker/` |
| Get worker | GET | `/v1/worker/{uuid}` |
| Create worker | POST | `/v1/worker/` |
| Update worker | PATCH | `/v1/worker/{uuid}` |
| Delete worker | DELETE | `/v1/worker/{uuid}` |

### Routes & Operations

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List routes | GET | `/v1/routes/` |
| Get route | GET | `/v1/routes/{uuid}` |
| Create route | POST | `/v1/routes/` |
| Update route | PATCH | `/v1/routes/{uuid}` |
| Delete route | DELETE | `/v1/routes/{uuid}` |
| Routes by product | GET | `/v1/routes/{productUuid}/byProductUuid` |
| Copy route | POST | `/v1/routes/{uuid}/copyRoute` |
| List operations | GET | `/v1/operation/` |
| Get operation | GET | `/v1/operation/{uuid}` |
| Create operation | POST | `/v1/operation/` |
| Update operation | PATCH | `/v1/operation/{uuid}` |
| Delete operation | DELETE | `/v1/operation/{uuid}` |
| List route operations | GET | `/v1/routeOperation` |
| Get route operation | GET | `/v1/routeOperation/{uuid}` |
| Create route operation | POST | `/v1/routeOperation/` |
| Update route operation | PATCH | `/v1/routeOperation/{uuid}` |
| Delete route operation | DELETE | `/v1/routeOperation/{uuid}` |
| Route ops by route | GET | `/v1/routeOperation/{routeUuid}/byRouteUuid` |

### Operation History & Reports

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List op history | GET | `/v1/workOrderOpHistory/` |
| Get op history | GET | `/v1/workOrderOpHistory/{uuid}` |
| Create op history | POST | `/v1/workOrderOpHistory/` |
| Batch create op history | POST | `/v1/workOrderOpHistory/many` |
| Delete op history | DELETE | `/v1/workOrderOpHistory/{uuid}` |
| Op history by work order | GET | `/v1/workOrderOpHistory/{uuid}/byWorkOrderUuid` |
| Op history timeline | GET | `/v1/workOrderOpHistory/{uuid}/timeline` |
| Work order report | GET | `/v1/workOrderReport/` |
| Update report | PATCH | `/v1/workOrderReport/{uuid}` |
| Work order dashboard | MCP | `workorder_dashboard` (one-call composite; replaces weekly report, backend route removed) |
| Analytics operations | GET | `/v1/analytics/operations` |
| Analytics WO report | GET | `/v1/analytics/workOrderReport` |
| Worker efficiency ranking | MCP | `worker_efficiency_ranking` (MCP aggregation tool, no direct curl) |
| Device utilization ranking | MCP | `device_utilization_ranking` (MCP aggregation tool, no direct curl) |
| Production summary | MCP | `production_summary` (MCP aggregation tool, no direct curl) |
| Material production ranking | MCP | `material_production_ranking` (MCP, uses dateRange filter for accurate time scope) |

### Devices & Stations

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List devices | GET | `/v1/deviceInfo/` |
| Get device | GET | `/v1/deviceInfo/{uuid}` |
| Delete device | DELETE | `/v1/deviceInfo/{uuid}` |
| List stations | GET | `/v1/stationInfo/` |
| Get station | GET | `/v1/stationInfo/{uuid}` |
| Create station | POST | `/v1/stationInfo/` |
| Update station | PATCH | `/v1/stationInfo/{uuid}` |
| Delete station | DELETE | `/v1/stationInfo/{uuid}` |
| Station device list | GET | `/v1/stationInfo/{uuid}/deviceList` |

> Device create/update are removed on the backend (`POST`/`PATCH /v1/deviceInfo` disabled); devices are read-only (list/get/delete).

### Quality & Defects

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List defect reasons | GET | `/v1/defectReason/` |
| Create defect reason | POST | `/v1/defectReason/` |
| Update defect reason | PATCH | `/v1/defectReason/{uuid}` |
| Delete defect reason | DELETE | `/v1/defectReason/{uuid}` |
| List defect categories | GET | `/v1/defectReasonCategory/` |
| Get defect category | GET | `/v1/defectReasonCategory/{uuid}` |
| Create defect category | POST | `/v1/defectReasonCategory/` |
| Update defect category | PATCH | `/v1/defectReasonCategory/{uuid}` |
| List abnormal history | GET | `/v1/workHourAbnormalHistory/` |
| Get abnormal history | GET | `/v1/workHourAbnormalHistory/{uuid}` |
| Create abnormal history | POST | `/v1/workHourAbnormalHistory/` |
| Update abnormal history | PATCH | `/v1/workHourAbnormalHistory/{uuid}` |
| Abnormal by work order | GET | `/v1/workHourAbnormalHistory/{workOrderId}/byWorkOrderId` |
| List abnormal categories | GET | `/v1/workHourAbnormalCategory/` |
| Create abnormal category | POST | `/v1/workHourAbnormalCategory/` |
| List abnormal states | GET | `/v1/workHourAbnormalState/` |
| Create abnormal state | POST | `/v1/workHourAbnormalState/` |
| List op product BOMs | GET | `/v1/operationProductBom/` |
| Create op product BOM | POST | `/v1/operationProductBom/` |
| Update op product BOM | PATCH | `/v1/operationProductBom/{uuid}` |
| Delete op product BOM | DELETE | `/v1/operationProductBom/{uuid}` |

### Warehouse & Inventory

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List warehouses | GET | `/v1/warehouse/` |
| Get warehouse | GET | `/v1/warehouse/{uuid}` |
| Create warehouse | POST | `/v1/warehouse/` |
| Update warehouse | PATCH | `/v1/warehouse/{uuid}` |
| List storage locations | GET | `/v1/warehouseStorage/` |
| Get storage location | GET | `/v1/warehouseStorage/{uuid}` |
| Create storage location | POST | `/v1/warehouseStorage/` |
| Update storage location | PATCH | `/v1/warehouseStorage/{uuid}` |
| List product storage | GET | `/v1/productStorage/` |
| Get product storage | GET | `/v1/productStorage/{uuid}` |
| Product storage by product | GET | `/v1/productStorage/{productUuid}/byProductUuid` |
| WMS check inventory | PATCH | `/v1/wms/checkInventory` |
| WMS query storage | POST | `/v1/wms/queryProductStorage` |
| WMS storage history | GET | `/v1/wms/queryProductStorageHistory` |
| WMS minimal stock count | GET | `/v1/wms/minimalStockLevelProductCount` |
