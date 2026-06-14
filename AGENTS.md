# Project Agent Instructions

本文件约束 `/mnt/linux_share/couple` 仓库内的后续 AI 协作。全局规则仍然适用；本文件只补充本项目特有事实和红线。

## Project Snapshot

- 项目名：双人时光盒。
- 产品定位：两个人共同记录和回看私密生活瞬间，不做公开社交、游戏、复杂聊天、排行榜或压力型打卡。
- 主端：HarmonyOS 6.1.0(23) 原生 ArkTS/ArkUI，根目录即 DevEco Studio 工程，模块为 `entry`。
- 轻量端：`apps/pwa` 是 React/Vite PWA，用来验证 iPhone 参与链路。
- 后端：Supabase Auth、PostgreSQL RLS 和 private Storage bucket `moments`。

## Package And Build Rules

- JavaScript/TypeScript 命令默认使用 `pnpm`。
- PWA 工作目录是 `apps/pwa`。
- pnpm 10+ 默认不跑依赖构建脚本；`apps/pwa/pnpm-workspace.yaml` 用 `allowBuilds` 放行 `esbuild`，否则 `pnpm test` / `pnpm build` 会因 `ERR_PNPM_IGNORED_BUILDS` 失败。不要删除该放行。
- PWA 常用验证命令：

```bash
cd apps/pwa
pnpm test
pnpm build
```

- HarmonyOS 工作流优先使用 DevEco Studio Sync/Build/Run。只有在本机确认 hvigor CLI 可用时才使用 CLI 构建。
- `local.properties`、`.hvigor/`、`oh_modules/`、`entry/build/`、`apps/pwa/node_modules/`、`apps/pwa/dist/` 都是本地或生成产物，不要提交。

## Source Of Truth

- 产品范围：`docs/superpowers/specs/2026-06-08-twoperson-memory-box-design.md`。
- Supabase schema/RLS/RPC：`docs/api/supabase-schema.sql`。
- Storage policy：`docs/api/storage-policies.md`。
- HarmonyOS 主题 token：`entry/src/main/ets/shared/theme/MemoryTheme.ets`。
- PWA Supabase env 读取：`apps/pwa/src/lib/env.ts`，必须通过 `VITE_SUPABASE_URL` 和 `VITE_SUPABASE_ANON_KEY`。

历史计划文件 `docs/superpowers/plans/2026-06-08-twoperson-memory-box.md` 不是当前完成度声明。实现状态必须以源码和 README 的“当前状态”为准。

## HarmonyOS Guidelines

- 保持 ArkTS/ArkUI Stage model 结构，不要把 HarmonyOS 端迁移到 WebView 或跨端壳。
- 新增页面优先复用 `MemoryTheme`，避免在组件里散落新的颜色、字号和半径。`MemoryTheme` 的现有 token 取值被 `entry/src/ohosTest/ets/test/VisualTheme.test.ets` 断言锁定，只能新增、不要改值。
- **ArkUI 编译红线（hvigor 已踩过的坑）**：
  - 组件的 `@State`/成员变量名**不能与 ArkUI 通用属性方法同名**（如 `tabIndex`、`width`、`height`、`position`、`id`、`key`、`enabled`、`zIndex`、`opacity`、`scale` 等），否则报 `Property ... not assignable to base type 'CustomComponent'`。本项目曾用 `tabIndex` 触发此错，已改名 `activeTab`。
  - `build()` 与 `@Builder` 内**只能是 UI 描述**：根容器前/之间不得写 `const/let` 等局部语句（否则报 `build method can have only one root node` 并连带 Rollup `Unexpected token`）。需要派生数据就放进普通方法或直接内联调用。
  - 组件级条件渲染只用 `if/else`，不要用返回组件的三元；`ForEach` 必须带第三个 key 生成器参数。
- **本地优先架构**：状态中枢是 `shared/state/AppState.ets`（`@Observed`），页面经 `@ObjectLink` 共享同一份实例。`@ObjectLink` 只观察一层属性，**所有变更必须整体替换数组/对象属性**（如 `this.moments = [...]`、克隆后 `this.space = ...`）才能触发刷新；克隆用 `shared/models/MemorySerde.ets` 的 `cloneX`。
- **持久化**：`shared/services/MemoryRepository.ets` 把整份快照 JSON 存入 `Preferences`（name `memorybox_state`，key `snapshot`）。`AppState` 每次变更后自动写入。新增可序列化字段时，必须同时在 `MemorySerde` 的 `*FromRecord` 映射里读取（ArkTS 名义类型：`JSON.parse` 的普通对象不能直接当 class 用）。
- **照片**：`shared/services/MemoryPhoto.ets` 用 `PhotoViewPicker` 选图并复制进沙箱 `filesDir/moments/`，存沙箱绝对路径；`Image()` 直接用该绝对路径，**不要加 `file://` 前缀**。
- `entry/src/main/module.json5` 中的 `ohos.permission.INTERNET` 是 Supabase 网络访问所需权限，不要删除。相册选图与沙箱读写走 picker 临时授权，无需额外权限。
- 桌面卡片：数据提供方是 `entry/src/main/ets/widget/MemoryCardFormProvider.ets`（`FormExtensionAbility`，读同一份 `Preferences` 快照），卡片 UI 是 `entry/src/main/ets/widget/MemoryCardForm.ets`（`@LocalStorageProp` 绑定，key 必须与 provider 的 `createFormBindingData` 字段一致）。module.json5 的 `extensionAbilities[].srcEntry` 指向 provider，form_config.json 的 `src` 指向卡片 UI。
- `MemoryApiConfig` 中的 Supabase URL、anon key、access token 只能从运行时配置或安全存储注入，不能硬编码真实值。云同步是可选增强，纯本地模式必须始终可用。

## PWA Guidelines

- PWA 是 iPhone 参与端和后端契约验证端，不要把它改成营销落地页。
- Auth 使用 Supabase Magic Link；创建/加入空间走 RPC：`create_couple_space` 和 `join_couple_space`。
- `moments.media_urls` 保存 private Storage path，不保存公开 URL。
- 显示媒体时通过 `supabase.storage.from('moments').createSignedUrl(...)` 获取短期 signed URL。
- 时间线已支持珍藏切换（写 `is_favorite`）、对方补一句话（写 `partner_text`，仅非记录者可补）、对自己隐藏（把当前用户追加进 `deleted_for_user_ids`，RLS select 会过滤掉本人已隐藏项）。这些都复用既有列，不改 schema。
- 纪念日为只读查看（`apps/pwa/src/features/anniversary/`），从 `anniversaries` 表按 `couple_space_id` 读取；新增/编辑纪念日在 HarmonyOS 端。
- 保留加载、空态、错误、禁用和 pending 状态；不要只实现 happy path。

## Data And Privacy Rules

- 所有业务数据必须挂到 `couple_space_id`。
- 一个空间 MVP 只允许两个成员，限制由 `join_couple_space` 服务端函数执行。
- 非成员不能读取空间数据；任何绕过 RLS 的改动都必须同步更新 schema 文档和 README。
- 删除共同记忆优先使用 `deleted_for_user_ids` 的“对自己隐藏”语义，不要默认物理删除。
- 不要提交 Supabase service role key、用户 access token、真实邮箱或本地签名材料。

## Documentation Rules

- 改动 schema、RPC、Storage path、环境变量或验证流程时，同时更新 `README.md` 和对应 `docs/api/*`。
- 改动 HarmonyOS 架构、页面入口、权限或桌面卡片时，同时更新 `README.md` 和本文件。
- 改动产品范围时，先更新 `docs/superpowers/specs/2026-06-08-twoperson-memory-box-design.md`，再改实现。
- 文档里用绝对日期，不写“今天”“最近”“刚刚”等相对时间。

## Verification Before Handoff

交付前至少运行与改动面相关的验证：

- PWA 代码变更：`cd apps/pwa && pnpm test && pnpm build`。
- HarmonyOS 代码变更：DevEco Studio 编译，或记录当前环境无法运行的具体原因。
- 文档变更：检查 README 命令、路径、环境变量与源码一致。
- Git 操作：提交前看 `git status --short` 和 `git diff --stat`，避免把生成物或本地配置提交进去。
