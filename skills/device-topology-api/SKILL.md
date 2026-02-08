# Device Topology API Skill

MCP skill for managing factory device topology — groups, factories, lines, devices, plant floors, alarms, and alarm codes in a hierarchical structure.

## Overview

This skill provides 37 tools for interacting with the Device Topology API:

- **Authentication** (2): Login and check auth status
- **Groups** (5): CRUD for organizational groups
- **Factories** (5): CRUD for factory entities
- **Lines** (5): CRUD for production lines
- **Devices** (5): CRUD for devices/machines
- **Plant Floors** (4): CRUD for plant floor layouts
- **Alarms** (5): CRUD for alarm records
- **Alarm Codes** (6): CRUD + batch operations for alarm code definitions
- **Topology** (2): Count and full topology tree

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
List factories.

**Parameters:**
- `group_uuid` (string, optional): Filter by group UUID
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
- `name` (string, required): Factory name
- `group_uuid` (string, optional): Parent group UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_update
Update an existing factory.

**Parameters:**
- `id` (string, required): Factory UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_factory_delete
Delete a factory.

**Parameters:**
- `id` (string, required): Factory UUID

---

### Line Tools

#### topo_line_list
List production lines.

**Parameters:**
- `factory_uuid` (string, optional): Filter by factory UUID
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
Update an existing line.

**Parameters:**
- `id` (string, required): Line UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_line_delete
Delete a line.

**Parameters:**
- `id` (string, required): Line UUID

---

### Device Tools

#### topo_device_list
List devices/machines.

**Parameters:**
- `line_uuid` (string, optional): Filter by line UUID
- `factory_uuid` (string, optional): Filter by factory UUID
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
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
- `name` (string, required): Floor name
- `factory_uuid` (string, required): Parent factory UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_plant_floor_update
Update an existing plant floor.

**Parameters:**
- `id` (string, required): Plant floor UUID
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_plant_floor_delete
Delete a plant floor.

**Parameters:**
- `id` (string, required): Plant floor UUID

---

### Alarm Tools

#### topo_alarm_list
List alarm records.

**Parameters:**
- `device_uuid` (string, optional): Filter by device UUID
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_get
Get a specific alarm record by UUID.

**Parameters:**
- `id` (string, required): Alarm UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_create
Create a new alarm record.

**Parameters:**
- `device_uuid` (string, required): Device UUID
- `alarm_code_uuid` (string, required): Alarm code UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_update
Update an existing alarm record.

**Parameters:**
- `id` (string, required): Alarm UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_delete
Delete an alarm record.

**Parameters:**
- `id` (string, required): Alarm UUID

---

### Alarm Code Tools

#### topo_alarm_code_list
List alarm code definitions.

**Parameters:**
- `limit` (number, default: 20): Max results (1-100)
- `offset` (number, default: 0): Pagination offset
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_get
Get a specific alarm code by UUID.

**Parameters:**
- `id` (string, required): Alarm code UUID
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_create
Create a new alarm code definition.

**Parameters:**
- `code` (string, required): Alarm code
- `name` (string, required): Alarm name/description
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_update
Update an existing alarm code.

**Parameters:**
- `id` (string, required): Alarm code UUID
- `code` (string, optional): Update code
- `name` (string, optional): Update name
- `response_format` ('markdown'|'json', default: 'markdown')

#### topo_alarm_code_delete
Delete an alarm code.

**Parameters:**
- `id` (string, required): Alarm code UUID

#### topo_alarm_code_batch
Batch create or update alarm codes.

**Parameters:**
- `items` (array, required): Array of alarm code objects

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

## Error Handling

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Call `auth_login` with tenant_id |
| 404 Not Found | Verify the UUID |
| 422 Validation | Check input parameters |

## MCP Server

- **Package**: `@dotzero.ai/device-topology-mcp`
- **Tools**: 37 (8 basic + 29 advanced, unlocked after auth)
- **Note**: This API uses PUT (not PATCH) for update operations

## Repository

https://gitlab.com/dotzero/dz-ai
