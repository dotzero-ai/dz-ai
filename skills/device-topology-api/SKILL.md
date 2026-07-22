# Device Topology API Skill

MCP skill for managing factory device topology — groups, factories, lines, devices, plant floors, alarms, and alarm codes in a hierarchical structure.

## Overview

This skill provides 39 tools for interacting with the Device Topology API:

- **Authentication** (2): Login and check auth status
- **Groups** (5): CRUD for organizational groups
- **Factories** (5): CRUD for factory entities
- **Lines** (5): CRUD for production lines
- **Devices** (5): CRUD for devices/machines
- **Plant Floors** (4): CRUD for plant floor layouts
- **Alarms** (5): CRUD for alarm **groups** (an alarm group is a named container; alarm codes belong to it)
- **Alarm Codes** (6): CRUD + batch operations for alarm code definitions
- **Topology** (2): Count and full topology tree

> **Pagination**: `limit`/`offset` are applied **client-side** by the MCP server — the backend list endpoints return all rows for the tenant/filter and ignore these params.

## Prerequisites

### Authentication Required

Before using most tools, you need to authenticate. The `tenant_id` is required.

**IMPORTANT**: If you don't know the user's tenant_id, you must ask them for it.

```
auth_login(email: "user@example.com", password: "password", tenant_id: "tenant-id")
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEVICE_TOPOLOGY_API_URL` | Yes | Base URL of the Device Topology API |
| `USER_API_URL` | No | Auth API URL (default: https://dotzerotech-user-api.dotzero.app) |

## Hierarchy

```
Group
  └── Factory
        └── Line
              └── Device
```

## Tools Reference

### Authentication Tools

#### auth_login
Authenticate with email, password, and tenant_id.

**Parameters:**
- `email` (string, required): User email address
- `password` (string, required): User password
- `tenant_id` (string, required): Tenant ID

#### auth_status
Check if the client is authenticated.

---

### Group Tools

#### topo_group_list
List organizational groups.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_group_get
Get a specific group by UUID.

**Parameters:**
- `id` (string, required): Group UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_group_create
Create a new group.

**Parameters:**
- `name` (string, required): Group name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_group_update
Update an existing group.

**Parameters:**
- `id` (string, required): Group UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_group_delete
Delete a group.

**Parameters:**
- `id` (string, required): Group UUID

---

### Factory Tools

#### topo_factory_list
List factories under a group.

**Parameters:**
- `group_uuid` (string, **required**): Group UUID — backend errors ("The groupUUID is not given.") without it. To list all factories regardless of group, use `GET /v1/factories/all` (see Additional Query Endpoints).
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_get
Get a specific factory by UUID.

**Parameters:**
- `id` (string, required): Factory UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_create
Create a new factory.

**Parameters:**
- `name` (string, required): Factory name (1-48 chars)
- `group_uuid` (string, **required**): Parent group UUID (must reference an existing group)
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_update
Update an existing factory. Backend `PUT` is a **full replace** (`name` and `groupUuid` are required server-side); the tool fetches the current record and merges your changes, preserving `groupUuid`.

**Parameters:**
- `id` (string, required): Factory UUID
- `name` (string, optional): Update name
- `longitude` (number, optional): Update longitude
- `latitude` (number, optional): Update latitude
- `imgUrl` (string, optional): Update image URL
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_delete
Delete a factory.

**Parameters:**
- `id` (string, required): Factory UUID

---

### Line Tools

#### topo_line_list
List production lines under a factory.

**Parameters:**
- `factory_uuid` (string, **required**): Factory UUID — backend errors ("The factoryUUID is not given.") without it. To list all lines, use `GET /v1/lines/all`.
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_line_get
Get a specific line by UUID.

**Parameters:**
- `id` (string, required): Line UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_line_create
Create a new production line.

**Parameters:**
- `name` (string, required): Line name
- `factory_uuid` (string, required): Parent factory UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_line_update
Update an existing line. Backend `PUT` is a **full replace**: `name` and `factory_uuid` are both required server-side, so always pass `factory_uuid` (a name-only update fails validation).

**Parameters:**
- `id` (string, required): Line UUID
- `name` (string, optional): Update name
- `factory_uuid` (string, required for update): Parent factory UUID
- `longitude` (number, optional), `latitude` (number, optional), `imgUrl` (string, optional)
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_line_delete
Delete a line.

**Parameters:**
- `id` (string, required): Line UUID

---

### Device Tools

#### topo_device_list
List devices/machines under a line.

**Parameters:**
- `line_uuid` (string, **required**): Line UUID — backend errors ("The lineUUID is not given.") without it. There is no factory-level filter on this endpoint; to list all devices use `GET /v1/devices/all`.
- `limit` (number, default: 20): Max results (1-100, client-side)
- `offset` (number, default: 0): Pagination offset (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_device_get
Get a specific device by UUID.

**Parameters:**
- `id` (string, required): Device UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_device_create
Create a new device.

**Parameters:**
- `name` (string, required): Device name
- `line_uuid` (string, required): Parent line UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_device_update
Update an existing device.

**Parameters:**
- `id` (string, required): Device UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_device_delete
Delete a device.

**Parameters:**
- `id` (string, required): Device UUID

---

### Plant Floor Tools

#### topo_plant_floor_get
Get a plant floor layout by UUID.

**Parameters:**
- `id` (string, required): Plant floor UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_plant_floor_create
Create a new plant floor layout.

**Parameters:**
- `canvas` (string, **required**): Canvas layout data (JSON string / layout definition) — the only required field server-side
- `interval_time` (number, optional): Refresh interval in seconds
- `response_format` ('markdown'|'json', default: 'markdown')

> There is no `factory_uuid` / `name` on create. `name` is nullable and set separately via `PATCH /v1/plantFloors/{uuid}/name` with body `{"name": "..."}`.

#### topo_plant_floor_update
Update an existing plant floor.

**Parameters:**
- `id` (string, required): Plant floor UUID
- `canvas` (string, optional): Update canvas layout
- `interval_time` (number, optional): Update interval
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_plant_floor_delete
Delete a plant floor.

**Parameters:**
- `id` (string, required): Plant floor UUID

---

### Alarm Tools

An **alarm** is a named **group** (container) that holds alarm codes. It is tenant-wide — it is not bound to a device. (Devices reference an alarm group via `alarm_uuid` on the device record.)

#### topo_alarm_list
List all alarm groups for the tenant.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100, client-side)
- `offset` (number, default: 0): Pagination offset (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

> No `device_uuid` filter exists — listing is tenant-wide only.

#### topo_alarm_get
Get a specific alarm group by UUID.

**Parameters:**
- `id` (string, required): Alarm group UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_create
Create a new alarm group. Duplicate names are rejected server-side.

**Parameters:**
- `name` (string, **required**, 1-20 chars): Alarm group name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_update
Update an existing alarm group (rename).

**Parameters:**
- `id` (string, required): Alarm group UUID
- `name` (string, required): New name (1-20 chars)
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_delete
Delete an alarm group.

**Parameters:**
- `id` (string, required): Alarm group UUID

---

### Alarm Code Tools

An **alarm code** is a numeric code belonging to one alarm group (`alarm_uuid`).

#### topo_alarm_code_list
List alarm codes for a given alarm group.

**Parameters:**
- `alarm_uuid` (string, **required**): Parent alarm group UUID — backend errors ("The alarmUUID is not given.") without it
- `limit` (number, default: 20): Max results (1-100, client-side)
- `offset` (number, default: 0): Pagination offset (client-side)
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_get
Get a specific alarm code by UUID.

**Parameters:**
- `id` (string, required): Alarm code UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_create
Create a new alarm code under an alarm group.

**Parameters:**
- `code` (number, **required**): Alarm code (integer)
- `alarm_uuid` (string, **required**, uuid4): Parent alarm group UUID (must exist)
- `category` (string, optional): Category (e.g. "Controller")
- `level` (number, optional): Severity level (integer)
- `messageEn` (string, optional): English message
- `messageTc` (string, optional): Traditional Chinese message
- `response_format` ('markdown'|'json', default: 'markdown')

> There is no `name` field on alarm codes.

#### topo_alarm_code_update
Update an existing alarm code.

**Parameters:**
- `id` (string, required): Alarm code UUID
- `code` (number, optional): Update code (integer)
- `category` / `level` / `messageEn` / `messageTc` (optional): as in create
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_delete
Delete an alarm code.

**Parameters:**
- `id` (string, required): Alarm code UUID

#### topo_alarm_code_batch
Batch **add and/or remove** alarm codes in one call (this is add + delete, **not** update). Maps to `POST /v1/alarmCodes/batch` with body `{add:[...], remove:[...]}`.

**Parameters:**
- `add` (array, optional): Alarm codes to create — each `{code:int, alarm_uuid:uuid4 (required per item), category?, level?, messageEn?, messageTc?}`
- `remove` (array, optional): Alarm codes to delete (identified by `uuid`)
- `response_format` ('markdown'|'json', default: 'markdown')

---

### Topology Tools

#### topo_topology_count
Get count of entities in the topology (groups, factories, lines, devices).

**Parameters:** None

#### topo_topology_all
Get the full topology tree (all groups, factories, lines, devices).

**Parameters:**
- `response_format` ('markdown'|'json', default: 'markdown')

---

## Usage Examples

### Workflow: Explore factory topology

```
# 1. Get full tree
topo_topology_all()

# 2. List factories
topo_factory_list()

# 3. Get lines in a factory
topo_line_list(factory_uuid: "factory-uuid")

# 4. Get devices on a line
topo_device_list(line_uuid: "line-uuid")
```

### Workflow: Set up a new production line

```
# 1. Create line under factory
topo_line_create(name: "Line A3", factory_uuid: "factory-uuid")

# 2. Add devices
topo_device_create(name: "CNC-001", line_uuid: "line-uuid")
topo_device_create(name: "CNC-002", line_uuid: "line-uuid")
```

## Additional Query Endpoints

These backend endpoints have no dedicated MCP tool but are useful and callable directly:

| Purpose | Endpoint |
|---------|----------|
| Search devices by name (returns topology subtree) | `GET /v1/topology/search/device?name=` |
| List all factories / lines / devices (no parent UUID needed) | `GET /v1/factories/all`, `/v1/lines/all`, `/v1/devices/all` |
| Device count under a topology node | `GET /v1/devices/count?type=group\|factory\|line&uuid=` (both required; `uuid=null` = unassigned line) |
| List plant floors | `GET /v1/plantFloors/` (optionally `?topologyType=&topologyUuid=`) |
| Create alarm group + its codes in one call | `POST /v1/alarms/withAlarmCodes` body `{name, alarmCodes:[...]}` |
| Set plant floor name | `PATCH /v1/plantFloors/{uuid}/name` body `{"name":"..."}` |

## Error Handling

This API signals **almost all errors as HTTP 500** with a plain-text message body (both "not found" and validation failures). Only auth returns 401.

| Error | Meaning / Solution |
|-------|--------------------|
| 401 Unauthorized | Not authenticated — call `auth_login` with tenant_id |
| 500 + text message | Validation failure, missing required query param, or resource not found — read the message body (e.g. "The groupUUID is not given.", "invalid groupUuid") |

## MCP Server

- **Package**: `@dotzero.ai/device-topology-mcp`
- **Tools**: 39 (8 basic + 31 advanced, unlocked after auth)
- **Note**: Updates use `PUT` (full replace). The one exception is the plant-floor name, which is set via `PATCH /v1/plantFloors/{uuid}/name`.

## Repository

https://github.com/dotzero-ai/dz-ai
