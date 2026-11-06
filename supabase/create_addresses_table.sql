-- ============================================================================
-- CREATE TABLE: public.addresses
-- For Sheetal Ice Cream Customer App
-- ============================================================================

-- 1. Create table
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  label text not null default 'Home',
  recipient_name text not null,
  phone text not null,
  house text not null,
  street text,
  locality text not null,
  landmark text,
  city text not null default 'Bengaluru',
  state text not null default 'Karnataka',
  postal_code text not null,
  instructions text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Performance & default index
create index if not exists addresses_user_idx on public.addresses (user_id);
create unique index if not exists addresses_one_default_per_user on public.addresses (user_id) where is_default;

-- 3. Automatic Default Address Manager Trigger
-- Automatically sets first address as default, and unsets other defaults if is_default is true
create or replace function public.manage_default_address()
returns trigger
language plpgsql
security definer
as $$
begin
  -- If this is the user's first address, force is_default = true
  if tg_op = 'INSERT' and not exists (
    select 1 from public.addresses where user_id = new.user_id
  ) then
    new.is_default := true;
  end if;

  -- If this address is set as default, remove default from all other addresses of this user
  if new.is_default then
    update public.addresses
       set is_default = false
     where user_id = new.user_id
       and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
       and is_default;
  end if;

  return new;
end;
$$;

drop trigger if exists addresses_default on public.addresses;
create trigger addresses_default
  before insert or update of is_default on public.addresses
  for each row execute function public.manage_default_address();

-- 4. Enable Row Level Security (RLS)
alter table public.addresses enable row level security;

-- 5. Policies: Users can only see, add, edit, and delete their own addresses
drop policy if exists "Users read own addresses" on public.addresses;
create policy "Users read own addresses"
  on public.addresses for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users add own addresses" on public.addresses;
create policy "Users add own addresses"
  on public.addresses for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users update own addresses" on public.addresses;
create policy "Users update own addresses"
  on public.addresses for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users delete own addresses" on public.addresses;
create policy "Users delete own addresses"
  on public.addresses for delete to authenticated
  using (auth.uid() = user_id);

-- 6. Enable Realtime Replication
alter table public.addresses replica identity full;
do $$
begin
  alter publication supabase_realtime add table public.addresses;
exception
  when duplicate_object then null;
end $$;

