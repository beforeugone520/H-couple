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

create or replace function public.create_couple_space()
returns table(couple_space_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  next_code text;
  next_space_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    next_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (
      select 1 from public.couple_spaces where couple_spaces.invite_code = next_code
    );
  end loop;

  insert into public.couple_spaces(invite_code)
  values (next_code)
  returning id into next_space_id;

  insert into public.couple_members(couple_space_id, user_id, role)
  values (next_space_id, auth.uid(), 'owner');

  return query select next_space_id, next_code;
end;
$$;

create or replace function public.join_couple_space(join_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_space_id uuid;
  member_count integer;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select id
    into target_space_id
    from public.couple_spaces
   where invite_code = upper(trim(join_code))
     and status = 'active'
   for update;

  if target_space_id is null then
    raise exception 'invalid_invite_code';
  end if;

  if public.is_space_member(target_space_id) then
    return target_space_id;
  end if;

  select count(*)
    into member_count
    from public.couple_members
   where couple_space_id = target_space_id;

  if member_count >= 2 then
    raise exception 'space_is_full';
  end if;

  insert into public.couple_members(couple_space_id, user_id, role)
  values (target_space_id, auth.uid(), 'member');

  return target_space_id;
end;
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

create policy "members can read members" on public.couple_members
for select using (public.is_space_member(couple_space_id));

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
