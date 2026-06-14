# 双人时光盒

双人时光盒是一款面向情侣或亲密伴侣的私密共同记忆应用。当前仓库包含 HarmonyOS 原生主端、iPhone 友好的 PWA 验证端，以及 Supabase 数据库/存储设计。

第一版产品目标很克制：两个人登录后创建或加入同一个双人空间，上传照片或写一句话，按时间线共同回看，并用轻回应补充情绪。不做公开社交、情侣游戏、复杂聊天或排行榜。

## 当前状态

- HarmonyOS 端：ArkTS/ArkUI 工程位于仓库根目录，入口模块是 `entry`，**本地优先（local-first）即开即用**。首次进入引导建立双人空间（两个称呼 + 在一起的日子，自动生成邀请码）；四个主入口「今天 / 时间线 / 相册 / 我们」全部绑定真实数据并持久化到设备 `Preferences`：今天页显示在一起天数 / 最近一条 / 某年今日 / 下一个纪念日倒数；记录支持相册选图（落地沙箱）、文字、心情、地点；时间线支持筛选（我的 / 对方 / 收藏 / 有地点）、珍藏、轻回应、对方补一句话、对自己隐藏；相册按月份 / 地点 / 纪念日聚合；我们页管理称呼、邀请码复制、纪念日增删与可选云同步。桌面卡片由 `FormExtensionAbility` 读取同一份本地快照显示最近回忆与纪念日倒数。可选的 Supabase REST 云同步用于跨设备。
- PWA 端：React + Vite 项目位于 `apps/pwa`；已覆盖邮箱 Magic Link 登录、创建/加入双人空间、上传照片、创建瞬间、读取时间线、轻回应、珍藏切换、对方补一句话、对自己隐藏，以及只读的纪念日查看。
- 后端：Supabase SQL schema 位于 `docs/api/supabase-schema.sql`；Storage bucket 策略说明位于 `docs/api/storage-policies.md`。
- 设计/规划：产品规格和历史实施计划位于 `docs/superpowers/`；视觉系统位于 `design-system/twoperson-memory-box/MASTER.md`。

## 技术栈

- HarmonyOS 6.1.0(23), ArkTS, ArkUI, Stage model, ArkData Preferences（本地持久化）, CoreFileKit（照片落地沙箱）, MediaLibraryKit（相册选图）, Form extension
- React 18, TypeScript, Vite, Vitest
- Supabase Auth, PostgreSQL RLS, Storage
- pnpm for JavaScript package management

## 目录结构

```text
.
├── AppScope/                         # HarmonyOS app scope 配置
├── entry/                            # HarmonyOS entry 模块
│   └── src/main/ets/
│       ├── entryability/             # Stage Ability
│       ├── features/                 # setup / today / timeline / album / us / moments(Composer)
│       ├── pages/                    # Index 应用外壳（引导 / 顶栏 / 四个 Tab）
│       ├── shared/                   # models / serde / services / state / util / theme
│       │   ├── models/               # 数据模型 + 序列化映射(MemorySerde)
│       │   ├── services/             # MemoryRepository(本地持久化) / MemoryPhoto(选图) / MemoryApi(可选云同步)
│       │   ├── state/                # AppState（@Observed 中枢状态）
│       │   └── util/                 # MemoryUtil（日期/ID/JSON 安全读取/文案）
│       └── widget/                   # MemoryCardFormProvider(数据) + MemoryCardForm(卡片 UI)
├── apps/pwa/                         # iPhone/PWA 验证端
├── docs/api/                         # Supabase schema 和 Storage policy
├── docs/superpowers/                 # 产品规格和历史实施计划
└── design-system/                    # 视觉系统
```

## 后端准备

1. 在 Supabase 创建项目。
2. 在 SQL Editor 执行 `docs/api/supabase-schema.sql`。
3. 创建私有 Storage bucket：`moments`。
4. 按 `docs/api/storage-policies.md` 配置 Storage policy。
5. 在 Supabase Auth 中启用邮箱 Magic Link，并把 PWA 开发/部署地址加入允许的 redirect URL。

媒体对象路径约定：

```text
{coupleSpaceId}/{userId}/{uuid}.{extension}
```

数据库只保存私有 Storage path，前端显示图片时申请 signed URL。

## 运行 PWA

```bash
cd apps/pwa
pnpm install
```

> pnpm 10+ 默认不执行依赖的构建脚本。`apps/pwa/pnpm-workspace.yaml` 已通过 `allowBuilds` 放行 `esbuild`，使 `pnpm test` / `pnpm build` 可非交互运行。

创建 `apps/pwa/.env.local`：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

常用命令：

```bash
pnpm dev
pnpm test
pnpm build
pnpm preview
```

`pnpm dev` 默认绑定 `0.0.0.0`，方便同一局域网内用 iPhone Safari 打开验证。

## 运行 HarmonyOS 端

推荐使用 DevEco Studio 打开仓库根目录：

1. 确认 SDK / Toolchains 与 `build-profile.json5` 中的 `6.1.0(23)` 匹配。
2. 让 DevEco Studio 执行 Sync。
3. 选择 `entry` 模块和 `default` product。
4. 首次真机运行或构建 HAP 时，按 DevEco Studio 提示配置本机调试签名。
5. 使用模拟器或真机运行，或通过 Build 菜单构建 HAP。

### 数据与同步模式

HarmonyOS 端是**本地优先**的：所有数据（双人空间、成员、瞬间、纪念日、云配置）以 JSON 快照存进应用 `Preferences`（名称 `memorybox_state`，键 `snapshot`），无需任何后端即可完整使用。照片通过相册选择后复制进应用沙箱 `filesDir/moments/`，时间线与相册直接用沙箱绝对路径渲染。

云同步为**可选增强**：在「我们」页填写 Supabase URL、anon key、登录邮箱/密码和云端 `couple_space_id` 后，可登录并拉取/推送瞬间，实现跨设备同步。Supabase URL、anon key、access token 只在运行时注入并存入本地配置，**不在源码中硬编码真实值**（见 `MemoryApiConfig` 与 AGENTS.md）。云同步当前同步瞬间的文本类字段，照片仍保存在本地设备。

桌面卡片由 `entry/src/main/ets/widget/MemoryCardFormProvider.ets`（`FormExtensionAbility`）读取同一份本地快照，绑定到 `MemoryCardForm.ets` 卡片 UI 显示在一起天数、最近一条瞬间和下一个纪念日倒数。

## 测试与验证

PWA 的自动化验证：

```bash
cd apps/pwa
pnpm test
pnpm build
```

> 本机若无 HarmonyOS 工具链（DevEco Studio / hvigor / SDK），无法在本机编译；HarmonyOS 端的验证需在装有 DevEco Studio 的环境进行。

HarmonyOS 验证以 DevEco Studio 编译和真机/模拟器预览为准。重点检查：

- 首次进入能创建空间，重启后数据仍在（`Preferences` 持久化）。
- 记录瞬间（照片 + 文字 + 心情 + 地点）保存后出现在「今天」和「时间线」。
- 时间线筛选、珍藏、轻回应、对方补一句话、对自己隐藏都生效且持久化。
- 顶栏「记录身份」切换后，「我的 / 对方记录的」筛选与补一句话入口随之变化。
- 四个主 tab 在手机、平板和 2in1 目标上不重叠。
- 空状态、加载失败状态和有数据状态都可读。
- 桌面卡片文本不裁切，能反映最近一条瞬间与纪念日倒数。
- 网络权限 `ohos.permission.INTERNET` 保留在 `entry/src/main/module.json5`。

Supabase 权限需要用多个账号手工验证：

- 用户 A 创建空间，用户 B 使用邀请码加入。
- 第三个用户不能加入已满空间。
- 非成员不能读取空间内 `moments`。
- 私有 bucket 中的媒体只能由空间成员通过 signed URL 查看。

## 参考文档

- `docs/superpowers/specs/2026-06-08-twoperson-memory-box-design.md`：产品定位、MVP 范围、页面结构和数据对象。
- `docs/api/supabase-schema.sql`：表结构、RLS policy、RPC 函数。
- `docs/api/storage-policies.md`：Supabase Storage bucket 和路径策略。
- `design-system/twoperson-memory-box/MASTER.md`：项目视觉 token 和组件风格。
- `docs/design/notion-DESIGN.md`：早期设计参考资料。
