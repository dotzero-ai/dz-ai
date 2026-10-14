# DotZero AI Tools

讓 AI 助理直接查你公司在 [DotZero](https://dotzero.app) 的生產資料：工單、設備、OEE、SPC、庫存、銷售訂單、供應鏈、工程圖。
MCP servers and skills that connect AI assistants to DotZero MES.

需要：DotZero 帳號，以及貴公司的**租戶 ID**（不知道請問貴公司的 DotZero 管理員）。

## 雲端 MCP 還是 plugin？

兩種都讓 AI 呼叫 DotZero，差別在工具跑在哪裡：

| | 雲端 MCP | plugin（本機） |
|---|---|---|
| 工具跑在哪 | DotZero 的伺服器 | 你的電腦（用 `npx` 啟動） |
| 適用 | ChatGPT、Claude、Gemini App（網頁／桌面／手機）；Codex、Gemini CLI、Claude Code 也能用 | Claude Code、Codex、Gemini CLI、Cursor／VS Code |
| 安裝 | 不用裝，貼一個網址 | 一行指令，電腦要有 Node.js 18 以上 |
| 能做什麼 | **只能查詢**（9 個系統的唯讀工具） | 查詢，加上**寫入**（建工單、改產品、上傳量測值）、**畫圖表、匯出 Excel／CSV**，以及教 AI 看懂 DotZero 資料的 skill |
| 登入 | 第一次使用時跳出 DotZero 登入頁，30 天後重新登入 | 跟 AI 說「登入 DotZero」，瀏覽器開 DotZero 登入頁 |
| 登入憑證存在哪 | AI 服務商（每張 1 小時有效） | 只在你的電腦（`~/.dotzero/`） |
| 更新 | DotZero 更新，你不用動 | 下指令更新（見下方） |

**怎麼選**：只想在聊天時問資料 → 雲端 MCP。要在終端機工作、要寫入資料或產出圖表／報表檔 → plugin。
同一個 AI 工具只裝一種就好，兩種都裝，AI 會看到兩套重複的工具。

兩種都照你的帳號權限：你在 DotZero 看不到的資料，AI 也查不到。

## 雲端 MCP

網址：`https://dz-mcp-server.dotzero.app/mcp`

| AI 工具 | 誰能用 | 怎麼加 |
|---|---|---|
| ChatGPT（網頁、桌面版聊天模式） | Business／Enterprise／Edu（管理員或擁有者先開開發者模式）、Pro；Free 不行 | Settings → Apps → Advanced settings 打開 **Developer mode** → 到 [chatgpt.com/plugins](https://chatgpt.com/plugins) 按 ＋ → **Add custom MCP server** → 名稱填 DotZero、上傳[圖示](https://dz-mcp-server.dotzero.app/icon.png)、貼網址 → 驗證選 **OAuth** → 勾 I understand and want to continue → **Create as a plugin** |
| Claude（網頁、桌面、手機） | Free（限 1 個自訂 connector）、Pro、Max；Team／Enterprise 由 Owner 加 | **Customize → Connectors → Add custom connector** → 貼網址 → **Add**。Team／Enterprise：Owner 到 **Organization settings → Connectors → Add → Custom → Web** 加，成員再到 Customize → Connectors 按 **Connect** |
| Gemini App | 個人 Google 帳號（公司／學校帳號不行） | 在 gemini.google.com 的設定找「**Spark 適用的自訂應用程式**」→ 貼網址 → 繼續（官方文件寫只限美國，台灣已看得到這個選項） |
| Codex CLI | — | `codex mcp add dotzero --url https://dz-mcp-server.dotzero.app/mcp` |
| Gemini CLI | — | `gemini mcp add -s user -t http dotzero https://dz-mcp-server.dotzero.app/mcp`，再在 Gemini CLI 裡輸入 `/mcp auth dotzero` |
| Claude Code | — | `claude mcp add --transport http dotzero https://dz-mcp-server.dotzero.app/mcp`，再輸入 `/mcp` 選 dotzero 登入 |

第一次使用會跳出 DotZero 登入頁：填租戶 ID、帳號、密碼（密碼直接送到 DotZero，不經過 AI）。ChatGPT、Gemini 在對話中輸入 `@` 選它。

## plugin（本機）

| AI 工具 | 安裝 |
|---|---|
| Claude Code | `/plugin marketplace add dotzero-ai/dz-ai`，再 `/plugin install dotzero@dz-ai` |
| Codex CLI（ChatGPT 桌面版的 Work／Codex 模式也用這個） | `codex plugin marketplace add dotzero-ai/dz-ai`，再 `codex plugin add dotzero@dz-ai` |
| Gemini CLI | `gemini extensions install https://github.com/dotzero-ai/dz-ai` |
| Cursor／VS Code／Windsurf | `npx @dotzero.ai/setup` |

裝完**重開** AI 工具，跟它說「登入 DotZero」並告訴它租戶 ID，瀏覽器會打開 DotZero 登入頁（密碼不經過 AI）。

更新：Claude Code `/plugin update dotzero@dz-ai`；Codex `codex plugin marketplace upgrade dz-ai`；Gemini CLI `gemini extensions update dotzero`；Cursor 等重跑 `npx @dotzero.ai/setup`。

AI 不能跑 MCP？改裝只有 REST API 說明的 `dotzero-skills`（`/plugin install dotzero-skills@dz-ai`），或把 [skills-only/](skills-only/) 給它讀。

## 可以問什麼

- 目前有哪些進行中的工單？
- 這個月哪個料號產量最多？
- CNC-01 這週的 OEE？這週有哪些告警？
- 哪些物料低於安全庫存？客戶 A 有哪些訂單還沒交貨？
- （plugin）把本週完工的工單匯出成 Excel、畫這台機台的 OEE 分解圖

## 包含哪些系統

| 系統 | npm 套件 | 雲端 MCP |
|---|---|---|
| 工單、產品、途程、報工、倉儲 | `@dotzero.ai/work-order-mcp` | ✓ |
| SPC 量測 | `@dotzero.ai/spc-mcp` | ✓ |
| 設備狀態、告警 | `@dotzero.ai/equipment-mcp` | ✓ |
| 工廠／產線／設備架構 | `@dotzero.ai/device-topology-mcp` | ✓ |
| OEE | `@dotzero.ai/oee-mcp` | ✓ |
| 供應鏈（SCM） | `@dotzero.ai/scm-mcp` | ✓ |
| 工程圖（GDT） | `@dotzero.ai/gdt-mcp` | ✓ |
| 銷售訂單（SD） | `@dotzero.ai/sd-mcp` | ✓ |
| 倉儲（WMS） | `@dotzero.ai/wms-mcp` | ✓ |
| 圖表與匯出 | `@dotzero.ai/export-mcp` | — |
| 登入 | `@dotzero.ai/auth-mcp` | 用網頁登入 |

雲端 MCP 只開放各系統的唯讀工具。每支工具的參數見 [docs/mcp-reference](docs/mcp-reference/README.md)，skill 在 [skills/](skills/)；
手動註冊 MCP、切換環境、token 腳本見 [docs/advanced.md](docs/advanced.md)。

## 授權與支援

Proprietary，見 [LICENSE](LICENSE)。問題回報：[Issues](https://github.com/dotzero-ai/dz-ai/issues) 或 support@dotzero.app。
