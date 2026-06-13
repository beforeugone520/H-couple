# 双人时光盒 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an MVP for a private two-person memory album with a HarmonyOS main app, an iPhone-friendly PWA, and a Supabase backend.

**Architecture:** The backend is Supabase Auth, PostgreSQL, Row Level Security, and Storage. The PWA validates the complete cross-device user flow first: sign in, join a couple space, upload a moment, view the shared timeline, and respond. The HarmonyOS app uses ArkTS/ArkUI as the main native client and calls the same REST endpoints, then adds local-first UX and a desktop card.

**Tech Stack:** Supabase, PostgreSQL, React, TypeScript, Vite, Vitest, Playwright, pnpm, HarmonyOS ArkTS/ArkUI, Form Kit.

---

## 0. References And Assumptions

Official references to consult during implementation:

- HarmonyOS documentation center: `https://developer.huawei.com/consumer/cn/doc/`
- HarmonyOS application development: `https://developer.huawei.com/consumer/cn/harmonyos/develop/`
- AppGallery Connect: `https://developer.huawei.com/consumer/cn/agconnect/`
- Supabase documentation: `https://supabase.com/docs`

Project assumptions:

- The repository starts mostly empty.
- JavaScript commands use `pnpm`.
- Supabase project credentials are supplied through environment variables.
- HarmonyOS project creation is done in DevEco Studio if local CLI scaffolding is unavailable.
- The first executable slice is the PWA + Supabase backend. HarmonyOS implementation follows once the shared contract is stable.

Execution corrections applied during implementation:

- Couple space creation and joining use Supabase RPC functions, not direct table inserts/selects, so RLS does not block invite joining and the two-person limit is enforced server-side.
- Private media paths are stored in `moments.media_urls`; clients request signed URLs before rendering photos.

## 1. Target File Structure

Create this structure:

```text
apps/
  pwa/
    package.json
    index.html
    vite.config.ts
    tsconfig.json
    src/
      App.tsx
      main.tsx
      styles.css
      lib/
        env.ts
        supabase.ts
      features/
        auth/AuthGate.tsx
        couple/CoupleJoin.tsx
        moments/MomentComposer.tsx
        moments/Timeline.tsx
        moments/momentTypes.ts
        moments/momentService.ts
      tests/
        momentService.test.ts
  harmony/
    AppScope/app.json5
    entry/src/main/module.json5
    entry/src/main/ets/
      entryability/EntryAbility.ets
      pages/Index.ets
      shared/models/MemoryModels.ets
      shared/services/MemoryApi.ets
      shared/state/AppState.ets
      features/today/TodayPage.ets
      features/timeline/TimelinePage.ets
      features/album/AlbumPage.ets
      features/us/UsPage.ets
      features/moments/MomentComposer.ets
    entry/src/main/resources/base/profile/main_pages.json
docs/
  api/
    supabase-schema.sql
    storage-policies.md
  superpowers/
    specs/2026-06-08-twoperson-memory-box-design.md
    plans/2026-06-08-twoperson-memory-box.md
```

File responsibilities:

- `docs/api/supabase-schema.sql`: database tables, RLS policies, indexes, and storage bucket setup.
- `apps/pwa/src/lib/*`: environment and Supabase client setup.
- `apps/pwa/src/features/*`: PWA vertical slices.
- `apps/harmony/.../shared/*`: shared ArkTS models, network client, and app state.
- `apps/harmony/.../features/*`: HarmonyOS page-level UI.

## 2. Implementation Tasks

### Task 1: Supabase Schema And Security Rules

**Files:**

- Create: `docs/api/supabase-schema.sql`
- Create: `docs/api/storage-policies.md`

- [ ] **Step 1: Create the database schema**

Add this to `docs/api/supabase-schema.sql`:

```sql
create extension if not exists "pgcrypto";

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.couple_spaces (
  id uuid primary key default gen_random_uuid(),
  invite_code text not null unique,
  status text not null default 'active' check (status in ('active', 'closed')),
  created_at timestamptz not null default now()
);

create table public.couple_members (
  couple_space_id uuid not null references public.couple_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (couple_space_id, user_id)
);

create table public.moments (
  id uuid primary key default gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces(id) on delete cascade,
  creator_id uuid not null references auth.users(id) on delete cascade,
  media_urls text[] not null default '{}',
  text text not null default '',
  partner_text text not null default '',
  mood text not null default 'calm' check (mood in ('happy', 'miss', 'calm', 'sad', 'surprise')),
  response text not null default '' check (response in ('', 'like', 'hug', 'miss_you')),
  location_name text not null default '',
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_for_user_ids uuid[] not null default '{}',
  is_favorite boolean not null default false
);

create table public.anniversaries (
  id uuid primary key default gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces(id) on delete cascade,
  title text not null,
  date date not null,
  repeat_type text not null default 'yearly' check (repeat_type in ('none', 'yearly')),
  reminder_enabled boolean not null default true,
  cover_media_url text,
  created_at timestamptz not null default now()
);

create index moments_space_updated_idx on public.moments(couple_space_id, updated_at desc);
create index anniversaries_space_date_idx on public.anniversaries(couple_space_id, date);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger moments_touch_updated_at
before update on public.moments
for each row execute function public.touch_updated_at();

create or replace function public.is_space_member(space_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couple_members
    where couple_space_id = space_id
      and user_id = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.couple_spaces enable row level security;
alter table public.couple_members enable row level security;
alter table public.moments enable row level security;
alter table public.anniversaries enable row level security;

create policy "profile owner can read" on public.profiles
for select using (id = auth.uid());

create policy "profile owner can write" on public.profiles
for insert with check (id = auth.uid());

create policy "profile owner can update" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

create policy "members can read spaces" on public.couple_spaces
for select using (public.is_space_member(id));

create policy "authenticated users can create spaces" on public.couple_spaces
for insert with check (auth.uid() is not null);

create policy "members can read members" on public.couple_members
for select using (public.is_space_member(couple_space_id));

create policy "authenticated users can join spaces" on public.couple_members
for insert with check (auth.uid() = user_id);

create policy "members can read moments" on public.moments
for select using (
  public.is_space_member(couple_space_id)
  and not auth.uid() = any(deleted_for_user_ids)
);

create policy "members can create moments" on public.moments
for insert with check (
  public.is_space_member(couple_space_id)
  and creator_id = auth.uid()
);

create policy "members can update moments" on public.moments
for update using (public.is_space_member(couple_space_id))
with check (public.is_space_member(couple_space_id));

create policy "members can read anniversaries" on public.anniversaries
for select using (public.is_space_member(couple_space_id));

create policy "members can write anniversaries" on public.anniversaries
for all using (public.is_space_member(couple_space_id))
with check (public.is_space_member(couple_space_id));
```

- [ ] **Step 2: Add storage policy notes**

Add this to `docs/api/storage-policies.md`:

```markdown
# Supabase Storage Policies

Create a private bucket named `moments`.

Object path format:

```text
{coupleSpaceId}/{userId}/{uuid}.{extension}
```

Required policies:

- Authenticated users can upload to `moments` when the first path segment is a `couple_space_id` they belong to.
- Authenticated users can read objects when they belong to the `couple_space_id` in the first path segment.
- Authenticated users can delete only objects under their own `{userId}` path segment.

Keep the bucket private. Store object paths in `moments.media_urls`; clients request signed URLs for display.
```

- [ ] **Step 3: Apply schema in Supabase SQL editor**

Run the complete `docs/api/supabase-schema.sql` in the Supabase SQL editor.

Expected result: the editor reports success and the tables `profiles`, `couple_spaces`, `couple_members`, `moments`, and `anniversaries` exist.

- [ ] **Step 4: Commit**

```bash
git add docs/api/supabase-schema.sql docs/api/storage-policies.md
git commit -m "chore: define supabase schema"
```

### Task 2: PWA Project Scaffold

**Files:**

- Create: `apps/pwa/package.json`
- Create: `apps/pwa/index.html`
- Create: `apps/pwa/vite.config.ts`
- Create: `apps/pwa/tsconfig.json`
- Create: `apps/pwa/src/main.tsx`
- Create: `apps/pwa/src/App.tsx`
- Create: `apps/pwa/src/styles.css`
- Create: `apps/pwa/src/lib/env.ts`
- Create: `apps/pwa/src/lib/supabase.ts`

- [ ] **Step 1: Create package manifest**

Add `apps/pwa/package.json`:

```json
{
  "name": "twoperson-memory-box-pwa",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "tsc -b && vite build",
    "test": "vitest run",
    "preview": "vite preview --host 0.0.0.0"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.45.4",
    "@vitejs/plugin-react": "^4.3.1",
    "vite": "^5.4.8",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/react": "^16.0.1",
    "@testing-library/jest-dom": "^6.4.8",
    "@types/react": "^18.3.8",
    "@types/react-dom": "^18.3.0",
    "typescript": "^5.6.2",
    "vitest": "^2.1.1",
    "jsdom": "^25.0.1"
  }
}
```

- [ ] **Step 2: Create Vite config**

Add `apps/pwa/vite.config.ts`:

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true
  }
});
```

- [ ] **Step 3: Create TypeScript config**

Add `apps/pwa/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": ["src"],
  "references": []
}
```

- [ ] **Step 4: Create HTML entry**

Add `apps/pwa/index.html`:

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>双人时光盒</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 5: Create environment reader**

Add `apps/pwa/src/lib/env.ts`:

```ts
export type AppEnv = {
  supabaseUrl: string;
  supabaseAnonKey: string;
};

export function readEnv(): AppEnv {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY');
  }

  return { supabaseUrl, supabaseAnonKey };
}
```

- [ ] **Step 6: Create Supabase client**

Add `apps/pwa/src/lib/supabase.ts`:

```ts
import { createClient } from '@supabase/supabase-js';
import { readEnv } from './env';

const env = readEnv();

export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true
  }
});
```

- [ ] **Step 7: Create app shell**

Add `apps/pwa/src/App.tsx`:

```tsx
export function App() {
  return (
    <main className="app-shell">
      <header className="app-header">
        <p className="eyebrow">只属于两个人</p>
        <h1>双人时光盒</h1>
      </header>
      <section className="empty-state">
        <p>登录后开始记录共同生活瞬间。</p>
      </section>
    </main>
  );
}
```

Add `apps/pwa/src/main.tsx`:

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import './styles.css';

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

Add `apps/pwa/src/styles.css`:

```css
:root {
  color: #2b2926;
  background: #fbf8f3;
  font-family: Inter, "HarmonyOS Sans SC", system-ui, sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
}

.app-shell {
  width: min(100%, 720px);
  min-height: 100vh;
  margin: 0 auto;
  padding: 24px 18px 80px;
}

.app-header {
  padding: 8px 0 18px;
}

.eyebrow {
  margin: 0 0 8px;
  color: #7a6f65;
  font-size: 13px;
}

h1 {
  margin: 0;
  font-size: 30px;
  letter-spacing: 0;
}

.empty-state {
  border: 1px solid #e6ded3;
  border-radius: 8px;
  padding: 18px;
  background: #fffdfa;
}
```

- [ ] **Step 8: Install and verify scaffold**

Run:

```bash
cd apps/pwa
pnpm install
pnpm build
```

Expected: `pnpm build` exits with code 0 and creates `apps/pwa/dist`.

- [ ] **Step 9: Commit**

```bash
git add apps/pwa
git commit -m "feat: scaffold pwa"
```

### Task 3: PWA Auth And Couple Space Join

**Files:**

- Create: `apps/pwa/src/features/auth/AuthGate.tsx`
- Create: `apps/pwa/src/features/couple/CoupleJoin.tsx`
- Modify: `apps/pwa/src/App.tsx`

- [ ] **Step 1: Create auth gate**

Add `apps/pwa/src/features/auth/AuthGate.tsx`:

```tsx
import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';

type AuthGateProps = {
  children: (session: Session) => JSX.Element;
};

export function AuthGate({ children }: AuthGateProps) {
  const [session, setSession] = useState<Session | null>(null);
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState('请输入邮箱登录。');

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
    });
    return () => data.subscription.unsubscribe();
  }, []);

  async function requestMagicLink() {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: window.location.origin }
    });
    setStatus(error ? error.message : '登录链接已发送，请查看邮箱。');
  }

  if (session) {
    return children(session);
  }

  return (
    <section className="panel">
      <h2>登录</h2>
      <input
        aria-label="邮箱"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        placeholder="you@example.com"
      />
      <button onClick={requestMagicLink} disabled={!email.includes('@')}>
        发送登录链接
      </button>
      <p className="muted">{status}</p>
    </section>
  );
}
```

- [ ] **Step 2: Create couple join UI**

Add `apps/pwa/src/features/couple/CoupleJoin.tsx`:

```tsx
import { useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';

type CoupleJoinProps = {
  session: Session;
  onJoined: (coupleSpaceId: string) => void;
};

export function CoupleJoin({ session, onJoined }: CoupleJoinProps) {
  const [inviteCode, setInviteCode] = useState('');
  const [status, setStatus] = useState('');

  async function createSpace() {
    const code = Math.random().toString(36).slice(2, 8).toUpperCase();
    const { data: space, error: spaceError } = await supabase
      .from('couple_spaces')
      .insert({ invite_code: code })
      .select('id')
      .single();

    if (spaceError || !space) {
      setStatus(spaceError?.message ?? '创建失败');
      return;
    }

    const { error: memberError } = await supabase.from('couple_members').insert({
      couple_space_id: space.id,
      user_id: session.user.id,
      role: 'owner'
    });

    if (memberError) {
      setStatus(memberError.message);
      return;
    }

    setStatus(`邀请码：${code}`);
    onJoined(space.id);
  }

  async function joinSpace() {
    const { data: space, error: spaceError } = await supabase
      .from('couple_spaces')
      .select('id')
      .eq('invite_code', inviteCode.trim().toUpperCase())
      .single();

    if (spaceError || !space) {
      setStatus('邀请码无效。');
      return;
    }

    const { count } = await supabase
      .from('couple_members')
      .select('*', { count: 'exact', head: true })
      .eq('couple_space_id', space.id);

    if ((count ?? 0) >= 2) {
      setStatus('这个空间已经有两个人。');
      return;
    }

    const { error: memberError } = await supabase.from('couple_members').insert({
      couple_space_id: space.id,
      user_id: session.user.id,
      role: 'member'
    });

    if (memberError) {
      setStatus(memberError.message);
      return;
    }

    onJoined(space.id);
  }

  return (
    <section className="panel">
      <h2>我们的空间</h2>
      <button onClick={createSpace}>创建双人空间</button>
      <div className="join-row">
        <input
          aria-label="邀请码"
          value={inviteCode}
          onChange={(event) => setInviteCode(event.target.value)}
          placeholder="输入邀请码"
        />
        <button onClick={joinSpace} disabled={inviteCode.trim().length < 4}>
          加入
        </button>
      </div>
      <p className="muted">{status}</p>
    </section>
  );
}
```

- [ ] **Step 3: Wire auth into app**

Replace `apps/pwa/src/App.tsx` with:

```tsx
import { useState } from 'react';
import { AuthGate } from './features/auth/AuthGate';
import { CoupleJoin } from './features/couple/CoupleJoin';

export function App() {
  const [coupleSpaceId, setCoupleSpaceId] = useState('');

  return (
    <main className="app-shell">
      <header className="app-header">
        <p className="eyebrow">只属于两个人</p>
        <h1>双人时光盒</h1>
      </header>
      <AuthGate>
        {(session) =>
          coupleSpaceId ? (
            <section className="panel">
              <h2>已加入</h2>
              <p className="muted">空间 ID：{coupleSpaceId}</p>
            </section>
          ) : (
            <CoupleJoin session={session} onJoined={setCoupleSpaceId} />
          )
        }
      </AuthGate>
    </main>
  );
}
```

- [ ] **Step 4: Extend CSS**

Append to `apps/pwa/src/styles.css`:

```css
.panel {
  border: 1px solid #e6ded3;
  border-radius: 8px;
  padding: 18px;
  background: #fffdfa;
}

.panel + .panel {
  margin-top: 16px;
}

h2 {
  margin: 0 0 14px;
  font-size: 20px;
  letter-spacing: 0;
}

input {
  width: 100%;
  min-height: 44px;
  border: 1px solid #d7cec2;
  border-radius: 8px;
  padding: 0 12px;
  font: inherit;
  background: #fff;
}

button {
  min-height: 44px;
  border: 0;
  border-radius: 8px;
  padding: 0 14px;
  margin-top: 10px;
  color: #fff;
  background: #6f8f72;
  font: inherit;
}

button:disabled {
  opacity: 0.55;
}

.join-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
  align-items: start;
}

.join-row button {
  margin-top: 0;
}

.muted {
  color: #7a6f65;
  font-size: 14px;
}
```

- [ ] **Step 5: Verify**

Run:

```bash
cd apps/pwa
pnpm build
```

Expected: build passes. Manual test with Supabase env configured: a user can request a magic link, create a couple space, and see the space ID.

- [ ] **Step 6: Commit**

```bash
git add apps/pwa/src
git commit -m "feat: add pwa auth and pairing"
```

### Task 4: Moment Service With Tests

**Files:**

- Create: `apps/pwa/src/features/moments/momentTypes.ts`
- Create: `apps/pwa/src/features/moments/momentService.ts`
- Create: `apps/pwa/src/tests/momentService.test.ts`

- [ ] **Step 1: Write failing tests**

Add `apps/pwa/src/tests/momentService.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { buildMomentInsert, normalizeMoment } from '../features/moments/momentService';

describe('momentService', () => {
  it('builds a valid moment insert payload', () => {
    const payload = buildMomentInsert({
      coupleSpaceId: 'space-1',
      creatorId: 'user-1',
      mediaUrls: ['https://example.com/a.jpg'],
      text: '今天一起散步',
      mood: 'happy',
      locationName: '湖边',
      occurredAt: '2026-06-08T10:00:00.000Z'
    });

    expect(payload).toEqual({
      couple_space_id: 'space-1',
      creator_id: 'user-1',
      media_urls: ['https://example.com/a.jpg'],
      text: '今天一起散步',
      mood: 'happy',
      location_name: '湖边',
      occurred_at: '2026-06-08T10:00:00.000Z'
    });
  });

  it('normalizes database fields for UI usage', () => {
    const moment = normalizeMoment({
      id: 'moment-1',
      couple_space_id: 'space-1',
      creator_id: 'user-1',
      media_urls: ['a.jpg'],
      text: '晚饭很好吃',
      partner_text: '下次还去',
      mood: 'calm',
      response: 'like',
      location_name: '小店',
      occurred_at: '2026-06-08T11:00:00.000Z',
      created_at: '2026-06-08T11:01:00.000Z',
      updated_at: '2026-06-08T11:02:00.000Z',
      is_favorite: true
    });

    expect(moment).toEqual({
      id: 'moment-1',
      coupleSpaceId: 'space-1',
      creatorId: 'user-1',
      mediaUrls: ['a.jpg'],
      text: '晚饭很好吃',
      partnerText: '下次还去',
      mood: 'calm',
      response: 'like',
      locationName: '小店',
      occurredAt: '2026-06-08T11:00:00.000Z',
      createdAt: '2026-06-08T11:01:00.000Z',
      updatedAt: '2026-06-08T11:02:00.000Z',
      isFavorite: true
    });
  });
});
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
cd apps/pwa
pnpm test
```

Expected: FAIL because `momentService` does not exist.

- [ ] **Step 3: Add types**

Add `apps/pwa/src/features/moments/momentTypes.ts`:

```ts
export type Mood = 'happy' | 'miss' | 'calm' | 'sad' | 'surprise';
export type MomentResponse = '' | 'like' | 'hug' | 'miss_you';

export type Moment = {
  id: string;
  coupleSpaceId: string;
  creatorId: string;
  mediaUrls: string[];
  text: string;
  partnerText: string;
  mood: Mood;
  response: MomentResponse;
  locationName: string;
  occurredAt: string;
  createdAt: string;
  updatedAt: string;
  isFavorite: boolean;
};

export type MomentRow = {
  id: string;
  couple_space_id: string;
  creator_id: string;
  media_urls: string[];
  text: string;
  partner_text: string;
  mood: Mood;
  response: MomentResponse;
  location_name: string;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  is_favorite: boolean;
};

export type NewMomentInput = {
  coupleSpaceId: string;
  creatorId: string;
  mediaUrls: string[];
  text: string;
  mood: Mood;
  locationName: string;
  occurredAt: string;
};
```

- [ ] **Step 4: Add service functions**

Add `apps/pwa/src/features/moments/momentService.ts`:

```ts
import type { Moment, MomentRow, NewMomentInput } from './momentTypes';

export function buildMomentInsert(input: NewMomentInput) {
  return {
    couple_space_id: input.coupleSpaceId,
    creator_id: input.creatorId,
    media_urls: input.mediaUrls,
    text: input.text,
    mood: input.mood,
    location_name: input.locationName,
    occurred_at: input.occurredAt
  };
}

export function normalizeMoment(row: MomentRow): Moment {
  return {
    id: row.id,
    coupleSpaceId: row.couple_space_id,
    creatorId: row.creator_id,
    mediaUrls: row.media_urls,
    text: row.text,
    partnerText: row.partner_text,
    mood: row.mood,
    response: row.response,
    locationName: row.location_name,
    occurredAt: row.occurred_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    isFavorite: row.is_favorite
  };
}
```

- [ ] **Step 5: Run tests**

Run:

```bash
cd apps/pwa
pnpm test
```

Expected: PASS with 2 tests.

- [ ] **Step 6: Commit**

```bash
git add apps/pwa/src/features/moments apps/pwa/src/tests
git commit -m "test: cover moment mapping"
```

### Task 5: PWA Moment Composer And Timeline

**Files:**

- Create: `apps/pwa/src/features/moments/MomentComposer.tsx`
- Create: `apps/pwa/src/features/moments/Timeline.tsx`
- Modify: `apps/pwa/src/App.tsx`
- Modify: `apps/pwa/src/styles.css`

- [ ] **Step 1: Create moment composer**

Add `apps/pwa/src/features/moments/MomentComposer.tsx`:

```tsx
import { useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';
import { buildMomentInsert } from './momentService';
import type { Mood } from './momentTypes';

type MomentComposerProps = {
  session: Session;
  coupleSpaceId: string;
  onCreated: () => void;
};

const moods: Array<{ value: Mood; label: string }> = [
  { value: 'happy', label: '开心' },
  { value: 'miss', label: '想念' },
  { value: 'calm', label: '平静' },
  { value: 'sad', label: '委屈' },
  { value: 'surprise', label: '惊喜' }
];

export function MomentComposer({ session, coupleSpaceId, onCreated }: MomentComposerProps) {
  const [text, setText] = useState('');
  const [mood, setMood] = useState<Mood>('calm');
  const [locationName, setLocationName] = useState('');
  const [status, setStatus] = useState('');

  async function createMoment() {
    const payload = buildMomentInsert({
      coupleSpaceId,
      creatorId: session.user.id,
      mediaUrls: [],
      text,
      mood,
      locationName,
      occurredAt: new Date().toISOString()
    });

    const { error } = await supabase.from('moments').insert(payload);
    if (error) {
      setStatus(error.message);
      return;
    }

    setText('');
    setLocationName('');
    setMood('calm');
    setStatus('已保存。');
    onCreated();
  }

  return (
    <section className="panel">
      <h2>记录一个瞬间</h2>
      <textarea
        aria-label="一句话"
        value={text}
        onChange={(event) => setText(event.target.value)}
        placeholder="写一句今天想留下的话"
      />
      <select aria-label="心情" value={mood} onChange={(event) => setMood(event.target.value as Mood)}>
        {moods.map((item) => (
          <option key={item.value} value={item.value}>
            {item.label}
          </option>
        ))}
      </select>
      <input
        aria-label="地点"
        value={locationName}
        onChange={(event) => setLocationName(event.target.value)}
        placeholder="地点，可不填"
      />
      <button onClick={createMoment} disabled={!text.trim()}>
        保存
      </button>
      <p className="muted">{status}</p>
    </section>
  );
}
```

- [ ] **Step 2: Create timeline**

Add `apps/pwa/src/features/moments/Timeline.tsx`:

```tsx
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { normalizeMoment } from './momentService';
import type { Moment, MomentRow, MomentResponse } from './momentTypes';

type TimelineProps = {
  coupleSpaceId: string;
  refreshKey: number;
};

const responseLabels: Record<Exclude<MomentResponse, ''>, string> = {
  like: '喜欢',
  hug: '抱抱',
  miss_you: '想你'
};

export function Timeline({ coupleSpaceId, refreshKey }: TimelineProps) {
  const [moments, setMoments] = useState<Moment[]>([]);
  const [status, setStatus] = useState('');

  useEffect(() => {
    async function load() {
      const { data, error } = await supabase
        .from('moments')
        .select('*')
        .eq('couple_space_id', coupleSpaceId)
        .order('occurred_at', { ascending: false });

      if (error) {
        setStatus(error.message);
        return;
      }

      setMoments(((data ?? []) as MomentRow[]).map(normalizeMoment));
    }

    load();
  }, [coupleSpaceId, refreshKey]);

  async function respond(momentId: string, response: MomentResponse) {
    const { error } = await supabase.from('moments').update({ response }).eq('id', momentId);
    if (error) {
      setStatus(error.message);
      return;
    }
    setMoments((items) => items.map((item) => (item.id === momentId ? { ...item, response } : item)));
  }

  return (
    <section className="panel">
      <h2>时间线</h2>
      {status && <p className="muted">{status}</p>}
      {moments.length === 0 ? (
        <p className="muted">还没有共同瞬间。</p>
      ) : (
        <div className="timeline">
          {moments.map((moment) => (
            <article className="moment" key={moment.id}>
              <time>{new Date(moment.occurredAt).toLocaleDateString('zh-CN')}</time>
              <p>{moment.text}</p>
              {moment.partnerText && <p className="partner-text">{moment.partnerText}</p>}
              <p className="muted">{moment.locationName || '未记录地点'}</p>
              <div className="response-row">
                {(['like', 'hug', 'miss_you'] as const).map((value) => (
                  <button key={value} onClick={() => respond(moment.id, value)}>
                    {responseLabels[value]}
                  </button>
                ))}
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
```

- [ ] **Step 3: Wire into app**

Replace `apps/pwa/src/App.tsx` with:

```tsx
import { useState } from 'react';
import { AuthGate } from './features/auth/AuthGate';
import { CoupleJoin } from './features/couple/CoupleJoin';
import { MomentComposer } from './features/moments/MomentComposer';
import { Timeline } from './features/moments/Timeline';

export function App() {
  const [coupleSpaceId, setCoupleSpaceId] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  return (
    <main className="app-shell">
      <header className="app-header">
        <p className="eyebrow">只属于两个人</p>
        <h1>双人时光盒</h1>
      </header>
      <AuthGate>
        {(session) =>
          coupleSpaceId ? (
            <>
              <MomentComposer
                session={session}
                coupleSpaceId={coupleSpaceId}
                onCreated={() => setRefreshKey((value) => value + 1)}
              />
              <Timeline coupleSpaceId={coupleSpaceId} refreshKey={refreshKey} />
            </>
          ) : (
            <CoupleJoin session={session} onJoined={setCoupleSpaceId} />
          )
        }
      </AuthGate>
    </main>
  );
}
```

- [ ] **Step 4: Extend CSS**

Append to `apps/pwa/src/styles.css`:

```css
textarea,
select {
  width: 100%;
  min-height: 44px;
  border: 1px solid #d7cec2;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 10px;
  font: inherit;
  background: #fff;
}

textarea {
  min-height: 96px;
  resize: vertical;
}

.timeline {
  display: grid;
  gap: 12px;
}

.moment {
  border-top: 1px solid #eee5d8;
  padding-top: 12px;
}

.moment time {
  color: #7a6f65;
  font-size: 13px;
}

.partner-text {
  color: #6f8f72;
}

.response-row {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.response-row button {
  min-height: 36px;
  margin-top: 0;
  color: #3d4e3f;
  background: #e7efe3;
}
```

- [ ] **Step 5: Verify**

Run:

```bash
cd apps/pwa
pnpm test
pnpm build
```

Expected: tests pass and build succeeds. Manual test with Supabase env configured: create a text-only moment and see it in the timeline.

- [ ] **Step 6: Commit**

```bash
git add apps/pwa/src
git commit -m "feat: add pwa moment timeline"
```

### Task 6: PWA Media Upload

**Files:**

- Modify: `apps/pwa/src/features/moments/MomentComposer.tsx`

- [ ] **Step 1: Add selected file state and upload helper**

Replace `apps/pwa/src/features/moments/MomentComposer.tsx` with:

```tsx
import { useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';
import { buildMomentInsert } from './momentService';
import type { Mood } from './momentTypes';

type MomentComposerProps = {
  session: Session;
  coupleSpaceId: string;
  onCreated: () => void;
};

const moods: Array<{ value: Mood; label: string }> = [
  { value: 'happy', label: '开心' },
  { value: 'miss', label: '想念' },
  { value: 'calm', label: '平静' },
  { value: 'sad', label: '委屈' },
  { value: 'surprise', label: '惊喜' }
];

function getFileExtension(file: File): string {
  const fallback = file.type === 'image/png' ? 'png' : 'jpg';
  return file.name.split('.').pop() || fallback;
}

export function MomentComposer({ session, coupleSpaceId, onCreated }: MomentComposerProps) {
  const [text, setText] = useState('');
  const [mood, setMood] = useState<Mood>('calm');
  const [locationName, setLocationName] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [status, setStatus] = useState('');

  async function uploadSelectedFile(): Promise<string[]> {
    if (!file) {
      return [];
    }

    const extension = getFileExtension(file);
    const path = `${coupleSpaceId}/${session.user.id}/${crypto.randomUUID()}.${extension}`;
    const { error } = await supabase.storage.from('moments').upload(path, file, {
      cacheControl: '3600',
      upsert: false
    });

    if (error) {
      throw error;
    }

    return [path];
  }

  async function createMoment() {
    try {
      setStatus('正在保存...');
      const mediaUrls = await uploadSelectedFile();
      const payload = buildMomentInsert({
        coupleSpaceId,
        creatorId: session.user.id,
        mediaUrls,
        text,
        mood,
        locationName,
        occurredAt: new Date().toISOString()
      });

      const { error } = await supabase.from('moments').insert(payload);
      if (error) {
        throw error;
      }

      setText('');
      setLocationName('');
      setMood('calm');
      setFile(null);
      setStatus('已保存。');
      onCreated();
    } catch (error) {
      setStatus(error instanceof Error ? error.message : '保存失败');
    }
  }

  return (
    <section className="panel">
      <h2>记录一个瞬间</h2>
      <input
        aria-label="照片"
        type="file"
        accept="image/*"
        onChange={(event) => setFile(event.target.files?.[0] ?? null)}
      />
      <textarea
        aria-label="一句话"
        value={text}
        onChange={(event) => setText(event.target.value)}
        placeholder="写一句今天想留下的话"
      />
      <select aria-label="心情" value={mood} onChange={(event) => setMood(event.target.value as Mood)}>
        {moods.map((item) => (
          <option key={item.value} value={item.value}>
            {item.label}
          </option>
        ))}
      </select>
      <input
        aria-label="地点"
        value={locationName}
        onChange={(event) => setLocationName(event.target.value)}
        placeholder="地点，可不填"
      />
      <button onClick={createMoment} disabled={!text.trim() && !file}>
        保存
      </button>
      <p className="muted">{status}</p>
    </section>
  );
}
```

- [ ] **Step 2: Verify**

Run:

```bash
cd apps/pwa
pnpm build
```

Expected: build succeeds. Manual test on iPhone Safari: choose a photo, save it, and confirm the moment row contains one private storage path in `media_urls`.

- [ ] **Step 3: Commit**

```bash
git add apps/pwa/src/features/moments/MomentComposer.tsx
git commit -m "feat: support pwa photo upload"
```

### Task 7: HarmonyOS Project Shell

**Files:**

- Create or generate with DevEco Studio: `apps/harmony/`
- Create: `apps/harmony/entry/src/main/ets/shared/models/MemoryModels.ets`
- Create: `apps/harmony/entry/src/main/ets/shared/services/MemoryApi.ets`
- Create: `apps/harmony/entry/src/main/ets/shared/state/AppState.ets`
- Create: `apps/harmony/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Create HarmonyOS project**

Use DevEco Studio:

```text
File -> New -> Create Project -> Application -> Empty Ability
Project location: /mnt/linux_share/Harmony-work/apps/harmony
Language: ArkTS
UI: ArkUI declarative
Stage model: enabled
```

Expected: DevEco creates `oh-package.json5`, `build-profile.json5`, `hvigorfile.ts`, `AppScope/app.json5`, and `entry/src/main/module.json5`.

- [ ] **Step 2: Add network permission**

Modify `apps/harmony/entry/src/main/module.json5` to include:

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

Keep the rest of the generated module file intact.

- [ ] **Step 3: Add shared models**

Add `apps/harmony/entry/src/main/ets/shared/models/MemoryModels.ets`:

```ts
export type Mood = 'happy' | 'miss' | 'calm' | 'sad' | 'surprise'
export type MomentResponse = '' | 'like' | 'hug' | 'miss_you'

export class MomentModel {
  id: string = ''
  coupleSpaceId: string = ''
  creatorId: string = ''
  mediaUrls: string[] = []
  text: string = ''
  partnerText: string = ''
  mood: Mood = 'calm'
  response: MomentResponse = ''
  locationName: string = ''
  occurredAt: string = ''
  createdAt: string = ''
  updatedAt: string = ''
  isFavorite: boolean = false
}

export class AnniversaryModel {
  id: string = ''
  coupleSpaceId: string = ''
  title: string = ''
  date: string = ''
  repeatType: 'none' | 'yearly' = 'yearly'
  reminderEnabled: boolean = true
  coverMediaUrl: string = ''
}
```

- [ ] **Step 4: Add API skeleton**

Add `apps/harmony/entry/src/main/ets/shared/services/MemoryApi.ets`:

```ts
import { http } from '@kit.NetworkKit'
import { MomentModel } from '../models/MemoryModels'

export class MemoryApiConfig {
  supabaseUrl: string = ''
  anonKey: string = ''
  accessToken: string = ''
}

export class MemoryApi {
  private config: MemoryApiConfig

  constructor(config: MemoryApiConfig) {
    this.config = config
  }

  async listMoments(coupleSpaceId: string): Promise<MomentModel[]> {
    const request = http.createHttp()
    const url = `${this.config.supabaseUrl}/rest/v1/moments?couple_space_id=eq.${coupleSpaceId}&select=*&order=occurred_at.desc`
    const response = await request.request(url, {
      method: http.RequestMethod.GET,
      header: {
        apikey: this.config.anonKey,
        Authorization: `Bearer ${this.config.accessToken}`
      }
    })
    request.destroy()
    const raw = JSON.parse(response.result as string) as Array<Record<string, Object>>
    return raw.map((row) => this.toMoment(row))
  }

  private toMoment(row: Record<string, Object>): MomentModel {
    const moment = new MomentModel()
    moment.id = row['id'] as string
    moment.coupleSpaceId = row['couple_space_id'] as string
    moment.creatorId = row['creator_id'] as string
    moment.mediaUrls = row['media_urls'] as string[]
    moment.text = row['text'] as string
    moment.partnerText = row['partner_text'] as string
    moment.mood = row['mood'] as MomentModel['mood']
    moment.response = row['response'] as MomentModel['response']
    moment.locationName = row['location_name'] as string
    moment.occurredAt = row['occurred_at'] as string
    moment.createdAt = row['created_at'] as string
    moment.updatedAt = row['updated_at'] as string
    moment.isFavorite = row['is_favorite'] as boolean
    return moment
  }
}
```

- [ ] **Step 5: Add app state**

Add `apps/harmony/entry/src/main/ets/shared/state/AppState.ets`:

```ts
import { MomentModel } from '../models/MemoryModels'

@Observed
export class AppState {
  coupleSpaceId: string = ''
  moments: MomentModel[] = []
  selectedTab: number = 0
}
```

- [ ] **Step 6: Add index page shell**

Replace or add `apps/harmony/entry/src/main/ets/pages/Index.ets`:

```ts
import { AppState } from '../shared/state/AppState'

@Entry
@Component
struct Index {
  @State appState: AppState = new AppState()

  build() {
    Column() {
      Text('双人时光盒')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 6 })

      Text('只属于两个人的生活瞬间相册')
        .fontSize(14)
        .fontColor('#7a6f65')
        .margin({ bottom: 24 })

      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          Text('今天')
        }.tabBar('今天')

        TabContent() {
          Text('时间线')
        }.tabBar('时间线')

        TabContent() {
          Text('相册')
        }.tabBar('相册')

        TabContent() {
          Text('我们')
        }.tabBar('我们')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18 })
    .backgroundColor('#fbf8f3')
  }
}
```

- [ ] **Step 7: Verify HarmonyOS project**

Use DevEco Studio build action or run the generated hvigor build command available in the project.

Expected: the app compiles and the first page shows four tabs.

- [ ] **Step 8: Commit**

```bash
git add apps/harmony
git commit -m "feat: scaffold harmony app shell"
```

### Task 8: HarmonyOS Today, Timeline, Album, And Us Pages

**Files:**

- Create: `apps/harmony/entry/src/main/ets/features/today/TodayPage.ets`
- Create: `apps/harmony/entry/src/main/ets/features/timeline/TimelinePage.ets`
- Create: `apps/harmony/entry/src/main/ets/features/album/AlbumPage.ets`
- Create: `apps/harmony/entry/src/main/ets/features/us/UsPage.ets`
- Modify: `apps/harmony/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Create Today page**

Add `apps/harmony/entry/src/main/ets/features/today/TodayPage.ets`:

```ts
import { MomentModel } from '../../shared/models/MemoryModels'

@Component
export struct TodayPage {
  moments: MomentModel[] = []

  build() {
    Column({ space: 14 }) {
      Text('今天')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      if (this.moments.length === 0) {
        Text('还没有共同瞬间。')
          .fontSize(15)
          .fontColor('#7a6f65')
      } else {
        Text(this.moments[0].text)
          .fontSize(18)
          .fontColor('#2b2926')
        Text(this.moments[0].locationName)
          .fontSize(13)
          .fontColor('#7a6f65')
      }

      Button('记录一个瞬间')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#fffdfa')
    .borderRadius(8)
  }
}
```

- [ ] **Step 2: Create Timeline page**

Add `apps/harmony/entry/src/main/ets/features/timeline/TimelinePage.ets`:

```ts
import { MomentModel } from '../../shared/models/MemoryModels'

@Component
export struct TimelinePage {
  moments: MomentModel[] = []

  build() {
    List({ space: 12 }) {
      ForEach(this.moments, (moment: MomentModel) => {
        ListItem() {
          Column({ space: 8 }) {
            Text(moment.occurredAt.substring(0, 10))
              .fontSize(13)
              .fontColor('#7a6f65')
            Text(moment.text)
              .fontSize(17)
            if (moment.partnerText.length > 0) {
              Text(moment.partnerText)
                .fontSize(15)
                .fontColor('#6f8f72')
            }
            Text(moment.locationName.length > 0 ? moment.locationName : '未记录地点')
              .fontSize(13)
              .fontColor('#7a6f65')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor('#fffdfa')
          .borderRadius(8)
        }
      }, (moment: MomentModel) => moment.id)
    }
    .width('100%')
  }
}
```

- [ ] **Step 3: Create Album page**

Add `apps/harmony/entry/src/main/ets/features/album/AlbumPage.ets`:

```ts
import { MomentModel } from '../../shared/models/MemoryModels'

@Component
export struct AlbumPage {
  moments: MomentModel[] = []

  build() {
    Column({ space: 12 }) {
      Text('相册')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Text(`已记录 ${this.moments.length} 个瞬间`)
        .fontSize(15)
        .fontColor('#7a6f65')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#fffdfa')
    .borderRadius(8)
  }
}
```

- [ ] **Step 4: Create Us page**

Add `apps/harmony/entry/src/main/ets/features/us/UsPage.ets`:

```ts
@Component
export struct UsPage {
  coupleSpaceId: string = ''

  build() {
    Column({ space: 12 }) {
      Text('我们')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Text(this.coupleSpaceId.length > 0 ? `空间：${this.coupleSpaceId}` : '还没有加入双人空间')
        .fontSize(15)
        .fontColor('#7a6f65')

      Button('生成邀请码')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#fffdfa')
    .borderRadius(8)
  }
}
```

- [ ] **Step 5: Wire pages into Index**

Replace tab contents in `apps/harmony/entry/src/main/ets/pages/Index.ets` with:

```ts
import { AlbumPage } from '../features/album/AlbumPage'
import { TodayPage } from '../features/today/TodayPage'
import { TimelinePage } from '../features/timeline/TimelinePage'
import { UsPage } from '../features/us/UsPage'
import { AppState } from '../shared/state/AppState'

@Entry
@Component
struct Index {
  @State appState: AppState = new AppState()

  build() {
    Column() {
      Text('双人时光盒')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 6 })

      Text('只属于两个人的生活瞬间相册')
        .fontSize(14)
        .fontColor('#7a6f65')
        .margin({ bottom: 24 })

      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          TodayPage({ moments: this.appState.moments })
        }.tabBar('今天')

        TabContent() {
          TimelinePage({ moments: this.appState.moments })
        }.tabBar('时间线')

        TabContent() {
          AlbumPage({ moments: this.appState.moments })
        }.tabBar('相册')

        TabContent() {
          UsPage({ coupleSpaceId: this.appState.coupleSpaceId })
        }.tabBar('我们')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18 })
    .backgroundColor('#fbf8f3')
  }
}
```

- [ ] **Step 6: Verify**

Build and run in DevEco Studio.

Expected: all four tabs render without overlap on phone preview.

- [ ] **Step 7: Commit**

```bash
git add apps/harmony/entry/src/main/ets
git commit -m "feat: add harmony core pages"
```

### Task 9: HarmonyOS Moment Composer

**Files:**

- Create: `apps/harmony/entry/src/main/ets/features/moments/MomentComposer.ets`
- Modify: `apps/harmony/entry/src/main/ets/features/today/TodayPage.ets`

- [ ] **Step 1: Create composer component**

Add `apps/harmony/entry/src/main/ets/features/moments/MomentComposer.ets`:

```ts
import { Mood } from '../../shared/models/MemoryModels'

@Component
export struct MomentComposer {
  @State text: string = ''
  @State mood: Mood = 'calm'
  @State locationName: string = ''

  build() {
    Column({ space: 12 }) {
      Text('记录一个瞬间')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      TextArea({ placeholder: '写一句今天想留下的话', text: this.text })
        .height(96)
        .onChange((value: string) => {
          this.text = value
        })

      TextInput({ placeholder: '地点，可不填', text: this.locationName })
        .onChange((value: string) => {
          this.locationName = value
        })

      Row({ space: 8 }) {
        Button('开心').onClick(() => { this.mood = 'happy' })
        Button('平静').onClick(() => { this.mood = 'calm' })
        Button('想念').onClick(() => { this.mood = 'miss' })
      }

      Button('保存')
        .enabled(this.text.trim().length > 0)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#fffdfa')
    .borderRadius(8)
  }
}
```

- [ ] **Step 2: Add composer to Today page**

Replace `apps/harmony/entry/src/main/ets/features/today/TodayPage.ets` with:

```ts
import { MomentComposer } from '../moments/MomentComposer'
import { MomentModel } from '../../shared/models/MemoryModels'

@Component
export struct TodayPage {
  moments: MomentModel[] = []

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 14 }) {
          Text('今天')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)

          if (this.moments.length === 0) {
            Text('还没有共同瞬间。')
              .fontSize(15)
              .fontColor('#7a6f65')
          } else {
            Text(this.moments[0].text)
              .fontSize(18)
              .fontColor('#2b2926')
            Text(this.moments[0].locationName)
              .fontSize(13)
              .fontColor('#7a6f65')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#fffdfa')
        .borderRadius(8)

        MomentComposer()
      }
      .width('100%')
    }
  }
}
```

- [ ] **Step 3: Verify**

Build and run in DevEco Studio.

Expected: Today tab shows recent memory panel and composer panel.

- [ ] **Step 4: Commit**

```bash
git add apps/harmony/entry/src/main/ets/features
git commit -m "feat: add harmony moment composer"
```

### Task 10: HarmonyOS Desktop Card

**Files:**

- Modify: `apps/harmony/entry/src/main/module.json5`
- Create: `apps/harmony/entry/src/main/ets/widget/MemoryCardForm.ets`
- Create: `apps/harmony/entry/src/main/resources/base/profile/form_config.json`

- [ ] **Step 1: Register form ability in module config**

Modify `apps/harmony/entry/src/main/module.json5` by adding a form extension entry compatible with the DevEco generated structure:

```json5
{
  "name": "MemoryCardForm",
  "srcEntry": "./ets/widget/MemoryCardForm.ets",
  "description": "双人时光盒桌面卡片",
  "type": "form",
  "metadata": [
    {
      "name": "ohos.extension.form",
      "resource": "$profile:form_config"
    }
  ]
}
```

Keep existing abilities and extension abilities intact.

- [ ] **Step 2: Add card config**

Add `apps/harmony/entry/src/main/resources/base/profile/form_config.json`:

```json
{
  "forms": [
    {
      "name": "memory_card",
      "displayName": "双人时光盒",
      "description": "显示最近回忆和纪念日",
      "src": "./ets/widget/MemoryCardForm.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "colorMode": "auto",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30"
    }
  ]
}
```

- [ ] **Step 3: Add card UI**

Add `apps/harmony/entry/src/main/ets/widget/MemoryCardForm.ets`:

```ts
@Entry
@Component
struct MemoryCardForm {
  build() {
    Column({ space: 6 }) {
      Text('双人时光盒')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2b2926')

      Text('今天也留下一点共同回忆')
        .fontSize(13)
        .fontColor('#7a6f65')

      Text('打开记录')
        .fontSize(13)
        .fontColor('#6f8f72')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#fffdfa')
  }
}
```

- [ ] **Step 4: Verify**

Build in DevEco Studio and add the card in a simulator or device if available.

Expected: card renders the title, prompt, and action text without clipping.

- [ ] **Step 5: Commit**

```bash
git add apps/harmony/entry/src/main
git commit -m "feat: add harmony desktop card"
```

### Task 11: End-To-End Verification

**Files:**

- Modify only files needed to fix defects found during verification.

- [ ] **Step 1: Verify PWA commands**

Run:

```bash
cd apps/pwa
pnpm test
pnpm build
```

Expected: all tests pass and Vite build succeeds.

- [ ] **Step 2: Verify PWA on iPhone Safari**

Run:

```bash
cd apps/pwa
pnpm dev
```

Expected:

- iPhone Safari can open the dev server URL.
- User can log in.
- User can join with invite code.
- User can upload a photo or create a text-only moment.
- User can see the moment in timeline.
- User can send a light response.

- [ ] **Step 3: Verify Supabase permissions**

Manual checks in two browser sessions:

- User A creates a space.
- User B joins the same space.
- User C cannot query User A/User B moments.
- Third join attempt is blocked by the client and rejected by policy or a server-side guard if added.

Expected: only members can see space data.

- [ ] **Step 4: Verify HarmonyOS build**

Build with DevEco Studio or the generated hvigor task.

Expected: build succeeds and four tabs render.

- [ ] **Step 5: Commit fixes**

```bash
git add apps docs
git commit -m "fix: stabilize mvp verification"
```

## 3. Self-Review Checklist

- Spec coverage:
  - Account login: Tasks 1 and 3.
  - Couple space pairing: Tasks 1 and 3.
  - PWA participation: Tasks 3 through 6.
  - Shared timeline: Tasks 4 and 5.
  - Media storage: Tasks 1 and 6.
  - HarmonyOS main app: Tasks 7 through 9.
  - Desktop card: Task 10.
  - Privacy and permissions: Tasks 1 and 11.
- Exclusions remain excluded:
  - No public social feed.
  - No games.
  - No chat.
  - No iOS native app.
  - No Linux Agent or fusion development engine dependency.
- Verification:
  - PWA uses `pnpm test` and `pnpm build`.
  - HarmonyOS uses DevEco Studio or generated hvigor task.
  - Supabase security is manually verified with multiple users.
