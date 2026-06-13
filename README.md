# 双人时光盒

双人时光盒是一款面向情侣或亲密伴侣的私密共同记忆应用。当前仓库包含 HarmonyOS 原生主端、iPhone 友好的 PWA 验证端，以及 Supabase 数据库/存储设计。

第一版产品目标很克制：两个人登录后创建或加入同一个双人空间，上传照片或写一句话，按时间线共同回看，并用轻回应补充情绪。不做公开社交、情侣游戏、复杂聊天或排行榜。

## 当前状态

- HarmonyOS 端：ArkTS/ArkUI 工程位于仓库根目录，入口模块是 `entry`；已包含四个主入口「今天 / 时间线 / 相册 / 我们」、记录表单雏形、Supabase REST 读取模型和桌面卡片雏形。
- PWA 端：React + Vite 项目位于 `apps/pwa`；已覆盖邮箱 Magic Link 登录、创建/加入双人空间、上传照片、创建瞬间、读取时间线和轻回应。
- 后端：Supabase SQL schema 位于 `docs/api/supabase-schema.sql`；Storage bucket 策略说明位于 `docs/api/storage-policies.md`。
- 设计/规划：产品规格和历史实施计划位于 `docs/superpowers/`；视觉系统位于 `design-system/twoperson-memory-box/MASTER.md`。

## 技术栈

- HarmonyOS 6.1.0(23), ArkTS, ArkUI, Stage model, Form extension
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
│       ├── features/                 # Today / Timeline / Album / Us / Composer
│       ├── pages/                    # Index 页面
│       ├── shared/                   # 模型、API、状态、主题
│       └── widget/                   # 桌面卡片
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

HarmonyOS 端当前还没有完整登录和写入链路，`MemoryApi` 只保留了通过 Supabase REST 按 `couple_space_id` 读取 `moments` 的骨架。后续接入真实账号时需要把 Supabase URL、anon key 和用户 access token 注入 `MemoryApiConfig`，不要把密钥硬编码进源码。

## 测试与验证

PWA 的自动化验证：

```bash
cd apps/pwa
pnpm test
pnpm build
```

HarmonyOS 验证以 DevEco Studio 编译和真机/模拟器预览为准。重点检查：

- 四个主 tab 在手机、平板和 2in1 目标上不重叠。
- 空状态、加载失败状态和有数据状态都可读。
- 桌面卡片文本不裁切。
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
