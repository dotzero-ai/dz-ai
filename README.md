# DotZero AI Tools

MCP servers and Claude Code skills for [DotZero](https://dotzero.app) manufacturing execution systems (MES).

## Quick Install

```bash
npx @dotzero.ai/setup
```

This registers all MCP servers, creates `.dotzero/config.json`, and updates `.gitignore`.
After setup, restart Claude Code and run `auth_login` to authenticate.

## What's Included

### MCP Servers (217 tools)

| Server | Package | Tools | Description |
|--------|---------|-------|-------------|
| dotzero-auth | `@dotzero.ai/auth-mcp` | 3 | Authentication (login, refresh, status) |
| dotzero-workorder | `@dotzero.ai/work-order-mcp` | 98 | Work orders, products, routes, operations, devices, quality, warehouse, WMS |
| dotzero-spc | `@dotzero.ai/spc-mcp` | 41 | SPC measurement configs, inspection data, control charts, statistics |
| dotzero-equipment | `@dotzero.ai/equipment-mcp` | 12 | Real-time machine status, alarms, idle time, part counts |
| dotzero-device-topology | `@dotzero.ai/device-topology-mcp` | 37 | Factory/line/device hierarchy, plant floors, alarm codes |
| dotzero-oee | `@dotzero.ai/oee-mcp` | 20 | Availability, quality, performance, OEE at device/line/factory |

### Cross-Platform Skills (REST API)

Works with any AI Agent that supports curl/WebFetch, no MCP required:

| Skill | Description |
|-------|-------------|
| `dotzero-auth` | Authentication and token management |
| `dotzero-workorder` | Work order and production management |
| `dotzero-spc` | SPC quality control and measurement |
| `dotzero-equipment` | Equipment monitoring |
| `dotzero-device-topology` | Device topology management |
| `dotzero-oee` | OEE analysis |

## Installation Options

### Option 1: Full Plugin (MCP + Skills)

Install the complete plugin with MCP servers and skills:

```bash
npx @dotzero.ai/setup
```

### Option 2: Manual MCP Setup

```bash
# Auth
claude mcp add dotzero-auth \
  --command "npx" \
  --args "-y" "@dotzero.ai/auth-mcp" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Work Order
claude mcp add dotzero-workorder \
  --command "npx" \
  --args "-y" "@dotzero.ai/work-order-mcp" \
  --env "WORK_ORDER_API_URL=https://work-order-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# SPC
claude mcp add dotzero-spc \
  --command "npx" \
  --args "-y" "@dotzero.ai/spc-mcp" \
  --env "SPC_API_URL=https://dotzerotech-spc-backend.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Equipment
claude mcp add dotzero-equipment \
  --command "npx" \
  --args "-y" "@dotzero.ai/equipment-mcp" \
  --env "EQUIPMENT_API_URL=https://dotzerotech-equipment-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# Device Topology
claude mcp add dotzero-device-topology \
  --command "npx" \
  --args "-y" "@dotzero.ai/device-topology-mcp" \
  --env "DEVICE_TOPOLOGY_API_URL=https://dotzerotech-device-topology.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"

# OEE
claude mcp add dotzero-oee \
  --command "npx" \
  --args "-y" "@dotzero.ai/oee-mcp" \
  --env "OEE_API_URL=https://dotzerotech-oee-api.dotzero.app" \
  --env "USER_API_URL=https://user-api.dotzero.app"
```

### Option 3: Skills Only (No MCP)

For AI Agents that don't support MCP, use the REST API skills in `skills-only/`.

## Authentication

All DotZero services require authentication with a **tenant_id**.

### Using MCP Tools

```
auth_login(email: "user@example.com", password: "password", tenant_id: "your-tenant")
```

### Using Scripts

```bash
./scripts/dotzero-login.sh user@example.com password your-tenant-id
```

### Token Management

Credentials are stored in `.dotzero/credentials.json` (auto-created on login).

```bash
# Get valid token (auto-refresh if expired)
./scripts/dotzero-token.sh get

# Check token status
./scripts/dotzero-token.sh check
```

**Important**: Add `.dotzero/` to your `.gitignore`.

## 使用範例 (Best Practices)

以下是常見的使用情境，展示如何用自然語言讓 AI 幫你操作 DotZero 系統。

### 工單管理 (Work Orders)

#### 1. 查詢進行中的工單

> **你可以這樣問：** 「目前有哪些正在進行中的工單？」
>
> **AI 會做的事：** 呼叫 `workorder_list`，以狀態 = 進行中篩選
>
> **回覆範例：**
> 目前有 3 張進行中的工單：
> | 工單編號 | 產品 | 數量 | 開始時間 |
> |---------|------|------|---------|
> | WO-2026-001 | 齒輪 A | 500 | 2026-02-06 |
> | WO-2026-003 | 軸承 B | 200 | 2026-02-07 |
> | WO-2026-005 | 外殼 C | 1000 | 2026-02-08 |

#### 2. 建立新工單

> **你可以這樣問：** 「幫我建一張工單，產品編號 GEAR-A，數量 500，交期 2/28」
>
> **AI 會做的事：** 呼叫 `workorder_create` 建立工單，設定數量和交期
>
> **回覆範例：**
> 已建立工單 WO-2026-012：
> - 產品：GEAR-A（齒輪 A）
> - 數量：500
> - 交期：2026-02-28
> - 狀態：未開始

#### 3. 查看工單完整資訊

> **你可以這樣問：** 「WO-2026-001 的詳細資訊，包含產品和工序」
>
> **AI 會做的事：** 呼叫 `workorder_details` 取得工單、產品、途程和工序明細
>
> **回覆範例：**
> **工單 WO-2026-001**
> - 產品：齒輪 A（GEAR-A）
> - 數量：500（已完成 320）
> - 途程：齒輪標準流程（4 道工序）
>   1. 切削 → 已完成
>   2. 熱處理 → 進行中（機台 CNC-03）
>   3. 研磨 → 未開始
>   4. 品檢 → 未開始

#### 4. 本週生產進度報告

> **你可以這樣問：** 「這週的生產進度報告」
>
> **AI 會做的事：** 呼叫 `weekly_report` 或 `production_summary` 取得本週彙總
>
> **回覆範例：**
> **本週生產報告（2/3 – 2/8）**
> - 完成工單：12 張
> - 進行中：5 張
> - 總產量：8,500 件
> - 良率：97.2%
> - 較上週 +5.3%

#### 5. 作業員效率排名

> **你可以這樣問：** 「哪位作業員效率最高？」
>
> **AI 會做的事：** 呼叫 `worker_efficiency_ranking` 取得效率排名
>
> **回覆範例：**
> **本月作業員效率排名：**
> | 排名 | 姓名 | 完成數量 | 效率 |
> |------|------|---------|------|
> | 1 | 王大明 | 1,250 件 | 105% |
> | 2 | 李小華 | 1,180 件 | 98% |
> | 3 | 張志豪 | 1,050 件 | 92% |

---

### SPC 品質管控 (Statistical Process Control)

#### 6. 查看量測設定

> **你可以這樣問：** 「目前有哪些 SPC 量測項目？」
>
> **AI 會做的事：** 呼叫 `spc_measure_config_list` 列出量測設定
>
> **回覆範例：**
> 目前有 8 個量測項目：
> | 名稱 | 規格 | 上限 | 下限 | 量測方式 |
> |------|------|------|------|---------|
> | 外徑 | 50.00mm | 50.05 | 49.95 | 自動 |
> | 內徑 | 30.00mm | 30.03 | 29.97 | 手動 |
> | 表面粗度 | Ra 1.6 | 1.8 | — | 手動 |

#### 7. 製程能力分析 (Cpk)

> **你可以這樣問：** 「齒輪 A 的外徑 Cpk 分析結果」
>
> **AI 會做的事：** 呼叫 `spc_statistics_capability` 計算 Cpk 及相關指標
>
> **回覆範例：**
> **齒輪 A — 外徑 Cpk 分析**
> - Cp：1.85（製程能力充足）
> - Cpk：1.52（製程穩定偏中）
> - 平均值：50.01mm
> - 標準差：0.009mm
> - 判定：✅ Cpk ≥ 1.33，製程能力合格

#### 8. 批次上傳量測數據

> **你可以這樣問：** 「幫我上傳這批量測數據：外徑 50.02, 50.01, 49.98, 50.03, 50.00」
>
> **AI 會做的事：** 呼叫 `spc_history_batch_upsert` 批次寫入量測紀錄
>
> **回覆範例：**
> 已成功上傳 5 筆量測數據：
> - 量測項目：外徑
> - 數據：50.02, 50.01, 49.98, 50.03, 50.00
> - 平均值：50.008mm（規格內 ✅）
> - 全部在管制範圍內，無異常警報

---

### 設備監控 (Equipment Monitoring)

#### 9. 即時機台狀態

> **你可以這樣問：** 「目前所有機台的狀態」
>
> **AI 會做的事：** 呼叫 `equip_machine_status_realtime_batch` 取得即時狀態
>
> **回覆範例：**
> **機台即時狀態：**
> | 機台 | 狀態 | 運行時間 | 目前工單 |
> |------|------|---------|---------|
> | CNC-01 | 🟢 運轉中 | 4h 32m | WO-2026-001 |
> | CNC-02 | 🟡 閒置 | — | — |
> | CNC-03 | 🟢 運轉中 | 2h 15m | WO-2026-003 |
> | CNC-04 | 🔴 告警 | — | WO-2026-005 |

#### 10. 設備告警紀錄

> **你可以這樣問：** 「今天有哪些設備告警？」
>
> **AI 會做的事：** 呼叫 `equip_alarm_list` 以今天日期範圍篩選
>
> **回覆範例：**
> **今日告警紀錄（2 筆）：**
> | 時間 | 機台 | 告警代碼 | 說明 | 狀態 |
> |------|------|---------|------|------|
> | 09:15 | CNC-04 | ALM-012 | 主軸過熱 | 處理中 |
> | 14:30 | CNC-02 | ALM-007 | 油壓異常 | 已復歸 |

#### 11. 機台產量統計

> **你可以這樣問：** 「CNC-01 今天的產量多少？」
>
> **AI 會做的事：** 呼叫 `equip_machine_status_part_counts` 取得產量資料
>
> **回覆範例：**
> **CNC-01 今日產量：**
> - 總產量：285 件
> - 良品：278 件
> - 不良品：7 件
> - 良率：97.5%
> - 預計完成時間：17:30

---

### 設備拓撲 (Device Topology)

#### 12. 工廠完整設備架構

> **你可以這樣問：** 「列出工廠的完整設備架構」
>
> **AI 會做的事：** 呼叫 `topo_topology_all` 取得完整階層樹
>
> **回覆範例：**
> **設備拓撲架構：**
> ```
> 📍 台中廠
>   ├── 加工產線 A
>   │   ├── CNC-01（CNC 車床）
>   │   ├── CNC-02（CNC 銑床）
>   │   └── CNC-03（CNC 車床）
>   ├── 加工產線 B
>   │   ├── CNC-04（CNC 車床）
>   │   └── CNC-05（CNC 銑床）
>   └── 組裝產線
>       ├── ASM-01（自動組裝機）
>       └── ASM-02（自動組裝機）
> ```

#### 13. 新增產線

> **你可以這樣問：** 「在台中廠新增一條 '品檢產線'」
>
> **AI 會做的事：** 呼叫 `topo_line_create`，指定工廠和產線名稱
>
> **回覆範例：**
> 已成功新增產線：
> - 名稱：品檢產線
> - 所屬工廠：台中廠
> - 狀態：啟用
> - 目前設備數：0（可開始新增設備）

#### 14. 告警代碼清單

> **你可以這樣問：** 「列出所有告警代碼」
>
> **AI 會做的事：** 呼叫 `topo_alarm_code_list` 取得告警代碼
>
> **回覆範例：**
> | 代碼 | 名稱 | 等級 | 說明 |
> |------|------|------|------|
> | ALM-001 | 急停 | 嚴重 | 操作員按下急停按鈕 |
> | ALM-007 | 油壓異常 | 警告 | 油壓系統壓力超出範圍 |
> | ALM-012 | 主軸過熱 | 嚴重 | 主軸溫度超過 85°C |

---

### OEE 綜合效率 (Overall Equipment Effectiveness)

#### 15. 單機 OEE 查詢

> **你可以這樣問：** 「CNC-01 的 OEE 是多少？」
>
> **AI 會做的事：** 呼叫 `oee_device` 取得該設備的 OEE 三大指標
>
> **回覆範例：**
> **CNC-01 OEE 分析：**
> - 稼動率（Availability）：92.5%
> - 良率（Quality）：97.8%
> - 效能（Performance）：88.3%
> - **OEE：79.9%**
> - 判定：⚠️ 略低於目標 85%，主要瓶頸在效能

#### 16. 產線稼動率

> **你可以這樣問：** 「加工產線 A 的稼動率」
>
> **AI 會做的事：** 呼叫 `oee_availability_line` 取得產線稼動率
>
> **回覆範例：**
> **加工產線 A 稼動率：90.1%**
> | 機台 | 稼動率 | 計畫停機 | 非計畫停機 |
> |------|--------|---------|-----------|
> | CNC-01 | 92.5% | 30 min | 15 min |
> | CNC-02 | 85.3% | 30 min | 58 min |
> | CNC-03 | 92.6% | 30 min | 12 min |

#### 17. 多設備良率比較

> **你可以這樣問：** 「比較所有 CNC 機台的良率」
>
> **AI 會做的事：** 呼叫 `oee_quality_devices` 取得多設備良率
>
> **回覆範例：**
> **CNC 機台良率比較：**
> | 機台 | 良率 | 良品 | 不良品 |
> |------|------|------|--------|
> | CNC-01 | 97.8% | 278 | 6 |
> | CNC-02 | 99.1% | 215 | 2 |
> | CNC-03 | 95.2% | 198 | 10 |
> | CNC-04 | 98.5% | 302 | 5 |
>
> ⚠️ CNC-03 良率偏低，建議檢查刀具狀態

---

### 跨服務綜合查詢 (Cross-Service Analysis)

#### 18. 產線日報

> **你可以這樣問：** 「幫我做今天加工產線 A 的日報」
>
> **AI 會做的事：** 綜合呼叫多個服務 — `workorder_list` 取得工單進度、`equip_machine_status_realtime_batch` 取得機台狀態、`oee_line` 取得 OEE、`equip_alarm_list` 取得告警
>
> **回覆範例：**
> **加工產線 A 日報（2026-02-08）**
>
> 📊 **生產概況**
> - 完成工單：3 張 / 進行中：2 張
> - 今日產量：856 件（目標 900）— 達成率 95.1%
>
> 🏭 **OEE：82.3%**
> - 稼動率 90.1% / 良率 97.2% / 效能 94.1%
>
> ⚠️ **異常紀錄**
> - CNC-04 主軸過熱（09:15，已處理）
> - CNC-02 閒置超過 1 小時（待排工單）

#### 19. 設備效率低落分析

> **你可以這樣問：** 「為什麼 CNC-03 效率這麼低？」
>
> **AI 會做的事：** 綜合呼叫 `oee_device` 查 OEE、`equip_alarm_list` 查告警、`equip_idle_list` 查閒置、`equip_machine_status_history` 查歷史狀態
>
> **回覆範例：**
> **CNC-03 效率分析：**
>
> 🔍 **OEE：71.2%**（目標 85%）
> - 稼動率 85.3%（⚠️ 低）
> - 良率 95.2%（⚠️ 偏低）
> - 效能 87.5%
>
> 📋 **原因分析：**
> 1. 今日 3 次告警（ALM-012 主軸過熱 ×2、ALM-015 刀具磨損 ×1）
> 2. 非計畫停機共 58 分鐘
> 3. 不良品偏高（10 件），集中在 10:00-11:00
>
> 💡 **建議：** 檢查主軸冷卻系統、更換刀具

#### 20. 異常狀況總覽

> **你可以這樣問：** 「列出所有需要注意的異常狀況」
>
> **AI 會做的事：** 綜合查詢 `equip_alarm_list` 設備告警、`oee_devices` 找出 OEE 偏低的機台、`workorder_list` 找出逾期工單、`abnormal_history_list` 異常歷史紀錄
>
> **回覆範例：**
> **⚠️ 需要注意的異常狀況：**
>
> 🔴 **設備告警（2 件）**
> - CNC-04 主軸過熱 — 處理中
> - CNC-02 油壓異常 — 已復歸，建議追蹤
>
> 🟡 **OEE 偏低（1 台）**
> - CNC-03 OEE 71.2%（低於目標 85%）
>
> 🟠 **工單逾期風險（1 張）**
> - WO-2026-005 交期 2/10，目前進度 62%
>
> ✅ 其餘設備和工單運作正常

---

## MCP Tool Categories

### Work Order API (98 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Work Orders | 7 | CRUD + details + count |
| Products | 6 | CRUD + details + copy |
| Workers | 5 | CRUD + delete |
| Operation History | 7 | CRUD + batch + timeline |
| Reports & Analytics | 8 | Reports, weekly, analytics, rankings, summary |
| Routes | 7 | CRUD + by product + copy |
| Operations | 5 | CRUD + delete |
| Route Operations | 6 | CRUD + by route |
| Devices | 5 | CRUD + delete |
| Stations | 6 | CRUD + device list |
| Defect Reasons | 4 | CRUD |
| Defect Categories | 4 | CRUD |
| Abnormal History | 5 | CRUD + by work order |
| Abnormal Config | 4 | Categories + states |
| Op Product BOM | 4 | CRUD |
| Warehouses | 4 | CRUD |
| Warehouse Storage | 4 | CRUD |
| Product Storage | 3 | List + get + by product |
| WMS | 4 | Inventory, storage, history, stock |

### SPC API (41 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Products V2 | 2 | Manufacture + stock product lists |
| History V2 | 4 | Batch upsert/query/delete by group |
| Config Parent V2 | 5 | Parent config CRUD + attachments |
| Measure Config V1 | 9 | Measure point config CRUD + modes + categories |
| Measure History V1 | 11 | History CRUD + batch + filtering + counting |
| Instruments V1 | 5 | Instrument CRUD + batch delete |
| Rules V1 | 1 | Control chart rules |
| Dashboard V1 | 6 | Dashboard CRUD + manufacture entries |
| Statistics V1 | 4 | Nelson rules, capability, calculation |

### Equipment API (12 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Alarms | 1 | Alarm records |
| Idles | 1 | Idle time records |
| Machine Status | 5 | History, part counts, real-time (single + batch) |
| Off Time | 1 | Off-time records |
| State Counts | 2 | Factory + line aggregations |

### Device Topology API (37 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Groups | 5 | Organizational group CRUD |
| Factories | 5 | Factory CRUD |
| Lines | 5 | Production line CRUD |
| Devices | 5 | Device/machine CRUD |
| Plant Floors | 4 | Plant floor layout CRUD |
| Alarms | 5 | Alarm record CRUD |
| Alarm Codes | 6 | Alarm code CRUD + batch |
| Topology | 2 | Count + full tree |

### OEE API (20 tools)

| Category | Tools | Description |
|----------|-------|-------------|
| Authentication | 2 | Login and status |
| Availability | 4 | Device, multi-device, line, factory |
| Quality | 4 | Device, multi-device, line, factory |
| Performance | 5 | Device, multi-device, line, factory, device range |
| OEE (Combined) | 4 | Device, multi-device, line, factory |
| Status | 1 | Device OEE status |
| Alarm History | 1 | OEE-related alarms |

## Work Order Status Values

| Value | Status | Description |
|-------|--------|-------------|
| 1 | Not Started | Work order created but not yet started |
| 2 | In Progress | Work order currently being processed |
| 3 | Completed | Work order finished successfully |
| 4 | Incomplete | Work order stopped before completion |

## Manufacturing Terminology

| Common Name | Formal Name | API Resource |
|-------------|-------------|-------------|
| Big WO | Parent Work Order | `/v1/workOrders/` |
| Small WO | Sub/Child Work Order | `/v1/workOrderOpHistory/` |

## Requirements

- Node.js >= 18
- Claude Code >= 1.0.0
- A DotZero account with tenant_id

## License

Proprietary. See [LICENSE](LICENSE) for details.

## Support

- [Documentation](https://github.com/dotzero-ai/dz-ai/blob/main/README.md)
- [Issues](https://github.com/dotzero-ai/dz-ai/issues)
- Email: support@dotzero.app
