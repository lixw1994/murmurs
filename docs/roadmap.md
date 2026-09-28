# Murmurs 路线图

> 最后更新：2026-09-28 · 目标架构的决策见 [`adr/`](../adr/)（ADR-0001 至 ADR-0013），当前系统见 [architecture.md](./architecture.md)
> 状态：⬜ 未开始 · 🟡 进行中 · ✅ 完成

## 总览

```
P0 骨架 ──► P1 同步 ──► P2 流水线 ──► P3 功能对齐 ──► P4 付费与合规 ──► 🚀 iOS + Web 上线
  │           ▲ 风险最高                    │                              │
  │           └ 越早验证越好                 └──► P6 桌面（可以和 P4 并行）    └──► P5 Android ──► 🚀 Play 上线
  │
  └ 每个阶段都有明确的完成标志，未达到不进入下一阶段
```

| 阶段 | 目标 | 完成标志 | 状态 |
|---|---|---|---|
| P0 | monorepo、服务端骨架、登录 | iOS 和 Web 都能用 Apple 或 Google 登录 | 🟡 |
| P1 | 同步引擎 | iPhone 上改一条 memo，Web 上实时看到 | ⬜ |
| P2 | 音频与转写流水线 | 离线录音，联网后自动完成转写和标题 | ⬜ |
| P3 | 功能对齐，Web 可用 | iOS 功能不少于 v0，Web 能完成主要流程 | ⬜ |
| P4 | 付费、配额、合规 | 可以提交 App Store 审核，Web 正式上线 | ⬜ |
| P5 | Android | 可以提交 Google Play 审核 | ⬜ |
| P6 | 桌面 | Electron 版签名、公证后发布 | ⬜ |

---

## P0 骨架

**目标**：把仓库和基础设施搭好，登录流程全部跑通。

- [x] iOS 最低版本提到 18.0，watchOS 提到 11.0（`project.yml`、CLAUDE.md）
- [x] 目标架构决策写成 ADR-0001 至 ADR-0013；`docs/architecture.md` 改为描述当前系统；写好路线图
- [x] 接入 paseo-agent-team 工作流：旧 spec 补齐结构、`CLAUDE.md` 引入 `AGENTS.md`、skill 链接到 `.claude/skills/`
- [x] 更新 `openspec/config.yaml`（当前与目标架构的上下文、分区验证命令、各 artifact 规则）、`CLAUDE.md`、`README.md`
- [ ] **仓库改成 monorepo**
  - [ ] 把现有 Swift 工程移到 `apple/`（project.yml、Sources、Shared、Watch、WatchWidget、Packages、Tests、SnapshotTests、Resources、fastlane）
  - [ ] 更新 CLAUDE.md 和 CI 里的路径与命令
  - [ ] 把 `Localizable.csv` 和 `scripts/l10n` 移到 `l10n/`，生成器新增输出 i18next JSON（Android 的 strings.xml 留到 P5）
- [ ] **初始化 `web/`**（从 `react-tanstarter` 复制，**不带** `.env*` 和 `.wrangler/`）
  - [ ] 改名为 murmurs，新建 D1，配置 dev、staging、prod 三套环境
  - [ ] 数据库迁移从 `db:push` 改为 `drizzle-kit generate` 加 `wrangler d1 migrations apply`
  - [ ] 新增 `routes/api/v1/$.ts`，挂载 Hono 加 zod-openapi 的骨架，先提供 `GET /api/v1/me`
  - [ ] 脚本导出 `contract/openapi.json`，CI 检查它和代码是否一致
- [ ] **登录**
  - [ ] Better Auth：加 Apple provider、`bearer()` 插件、邮箱 OTP；关掉 GitHub 和飞书
  - [ ] 原生登录流程：客户端拿到 idToken，服务端换成 bearer token
- [ ] **Apple 端接入**
  - [ ] 用 `swift-openapi-generator` 生成 `ApiClient`
  - [ ] 实现 `AuthService`：Sign in with Apple、Google，token 存在 Keychain
  - [ ] 做登录页，让 App 能进入“已登录”状态

**完成标志**：iOS 模拟器和 Web 都能完成 Apple 和 Google 登录；iOS 调用 `/api/v1/me` 返回当前用户。

---

## P1 同步 ⚠️ 风险最高

**目标**：自己写的同步协议在真实的多设备场景下可靠运行。

- [ ] 编写 `contract/sync-protocol.md`：push、pull、ws 的报文格式，LWW 规则，服务端专属字段
- [ ] 编写 `contract/sync-fixtures/`：冲突、删除、乱序、重复 push、大量数据分页等用例
- [ ] **UserSyncDO**
  - [ ] DO 内用 drizzle（durable-sqlite）定义 schema，写好迁移
  - [ ] 实现 push（LWW 合并、版本号递增、过滤服务端专属字段）
  - [ ] 实现 pull（游标加分页）
  - [ ] 实现可休眠 WebSocket，写入后广播版本号
  - [ ] 服务端跑通全部一致性用例
- [ ] **Apple 端 SyncEngine**
  - [ ] SwiftData 实体改造：UUIDv7 `id`、`updatedAt`、`deletedAt`、`version`、`dirty`
  - [ ] 触发同步的时机：push 在本地保存后、App 回到前台、网络恢复时；pull 在收到 WS 通知、启动时
  - [ ] Swift 端跑通一致性用例
  - [ ] 删除 `UsageEntity`，`Config` 里需要跨设备的项改为同步到 `settings`
- [ ] **Web 端**：只读的时间线页面，收到 WS 通知后刷新 Query 缓存

**完成标志**：两台 iOS 设备加 Web，离线修改后再联网，数据最终一致；一致性用例在服务端和 Swift 端全部通过。

**风险与对策**
- 客户端时钟偏差导致 LWW 判断错误 → 服务端把明显来自未来的 `updated_at` 截断到服务端当前时间；如果真出问题，再换成混合逻辑时钟（HLC）。
- SwiftData 做变更追踪不方便 → 用 `dirty` 标记加保存时的钩子；实在不行再评估换成 GRDB。

---

## P2 音频与转写流水线

**目标**：录音从本地到服务端再到转写结果，全流程可靠。

- [ ] 录音改成分段写文件，暂停和续录各产生一个新分段
- [ ] **R2**：`PUT /memos/:id/audio/:seg` 流式写入；`GET` 支持 Range 播放
- [ ] **Apple 端 UploadQueue**：后台 `URLSession` 加 `BGTaskScheduler`，失败后续传
- [ ] **MemoPipeline Workflow**：按分段转写 → 润色（可选）→ 生成标题 → 写回 DO → 在 D1 记录用量
- [ ] **AI Gateway**：接入 OpenAI 和 Workers AI，模型 ID 放在配置里；把 v0 里的 Whisper 幻觉过滤逻辑搬到服务端
- [ ] 失败处理：`status=failed`，客户端提供重试按钮，Cron 定期重试
- [ ] 保留 SpeechAnalyzer 实时转写，只用于录音时预览；新增隐私模式（`transcript_source=device`，不上传音频）
- [ ] **删除** iOS 里的 `OpenAIClient` 转写代码，以及“自定义服务器”“自带 API Key”这些设置
- [ ] Watch 录音经手机进入同一条流程，`source=watch`

**完成标志**：飞行模式下录 3 条（其中一条包含暂停和续录），联网后全部自动转写完成、生成标题，并同步到 Web。

---

## P3 功能对齐，Web 可用

**目标**：iOS 功能不少于 v0；Web 能完成主要流程。

- [ ] `POST /summaries/generate`：SSE 流式返回，完成后写入 DO
- [ ] prompt 改为同步数据，首次登录时写入默认 prompt
- [ ] iOS 总结流程改为调用服务端（界面不变）
- [ ] Readwise 移到服务端：`integrations` 表，token 加密存储，由 Cron 增量同步；删除客户端的 Readwise 代码
- [ ] **Web 页面**：时间线（按天、日历、搜索）、录音（MediaRecorder）、memo 编辑、总结流程、prompt 管理、设置
- [ ] 导出：CSV、Markdown 由服务端生成（各端都能用）；PDF 仍由客户端生成
- [ ] Widget、Live Activity、App Intents 改为读取 App Group 里的共享数据

**完成标志**：用 iOS 和 Web 连续使用一周，主要流程没有阻塞问题。

---

## P4 付费、配额与合规

**目标**：满足上架要求，商业模式跑通。

- [ ] **RevenueCat**：配置 App Store 订阅和 Web Billing（Stripe）；webhook 写入 `D1.entitlements`
- [ ] 配额检查：转写时长、总结次数、prompt 数量
- [ ] 确定免费额度、订阅额度和价格（根据 P2、P3 期间 `usage_daily` 的实际成本）
- [ ] iOS 付费墙：删除 StoreKit 1 的 `IAPManager`，改用 RevenueCat
- [ ] 账号删除（清空 DO、R2、D1）和全量数据导出
- [ ] 隐私清单、隐私政策、服务条款（更新 `html/`）
- [ ] 客户端接入 Sentry，服务端开启 Workers Logs 告警
- [ ] staging 环境配 TestFlight 内测，prod 环境做上线检查

**完成标志**：iOS 提交审核；Web 正式上线；订阅购买、恢复购买、跨端权益全部验证通过。

---

## P5 Android

**目标**：由 AI 对照 `apple/` 按模块移植，复用契约和一致性用例。

- [ ] 项目骨架：Kotlin、Compose、Room、Hilt、WorkManager
- [ ] 用 `openapi-generator` 生成 ApiClient；`l10n` 生成器新增输出 `strings.xml`
- [ ] 登录（Credential Manager）
- [ ] SyncEngine，跑通一致性用例
- [ ] 录音（前台服务、分段）加 UploadQueue（WorkManager）
- [ ] 时间线、总结、导出、设置
- [ ] RevenueCat（Play Billing）、Glance 小组件、快捷设置磁贴、App Shortcuts

**完成标志**：提交 Google Play 审核；三端数据互通。

---

## P6 桌面（Electron）

可以和 P4 或 P5 并行。

- [ ] Electron 外壳直接加载线上 Web
- [ ] 全局快捷键录音、托盘或菜单栏入口
- [ ] macOS 麦克风权限 entitlements、签名、公证；Windows 签名
- [ ] `electron-updater` 自动更新

**完成标志**：macOS 和 Windows 安装包发布；在任意应用里都能用全局快捷键开始录音。

---

## 以后再做（不排期）

- Android 设备端转写；桌面端本地转写（whisper.cpp）
- Watch 直接上传（不经过手机）
- 推送通知（转写完成时提醒）
- 原生 macOS 菜单栏 App（如果 Mac 用户占多数，可以替代 Electron）
- 自带 API Key 的高级模式

## 待决定事项

| 事项 | 需要在什么时候之前决定 | 说明 |
|---|---|---|
| 正式域名、品牌 | P0 | 影响 OAuth 回调地址、Apple Service ID |
| 总结使用的默认模型 | P3 | 要在成本和质量之间取舍 |
| 免费额度、订阅价格 | P4 | 依据 `usage_daily` 的实际数据 |
| Android 的优先级 | P4 结束时 | 根据 iOS 上线后的用户反馈 |
