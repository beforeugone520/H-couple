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
- 新增页面优先复用 `MemoryTheme`，避免在组件里散落新的颜色、字号和半径。
- `entry/src/main/module.json5` 中的 `ohos.permission.INTERNET` 是 Supabase 网络访问所需权限，不要删除。
- 桌面卡片入口是 `entry/src/main/ets/widget/MemoryCardForm.ets`，配置在 `entry/src/main/resources/base/profile/form_config.json`。
- `MemoryApiConfig` 中的 Supabase URL、anon key、access token 只能从运行时配置或安全存储注入，不能硬编码真实值。

## PWA Guidelines

- PWA 是 iPhone 参与端和后端契约验证端，不要把它改成营销落地页。
- Auth 使用 Supabase Magic Link；创建/加入空间走 RPC：`create_couple_space` 和 `join_couple_space`。
- `moments.media_urls` 保存 private Storage path，不保存公开 URL。
- 显示媒体时通过 `supabase.storage.from('moments').createSignedUrl(...)` 获取短期 signed URL。
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
