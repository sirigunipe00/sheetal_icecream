-- ============================================================================
-- ORDERS TABLE SCHEMA
-- Sheetal Ice Cream App
-- Note: The orders table in your Supabase project is already created with:
-- columns: id, order_number, user_id, customer_name, customer_phone,
--          delivery_address, payment_method, payment_status, subtotal,
--          delivery_fee, handling_fee, total, status, items (jsonb),
--          created_at, updated_at
-- ============================================================================

begin;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id text not null,
  customer_name text not null default '',
  customer_phone text not null default '',
  delivery_address text not null default '',
  payment_method text not null default 'cod',
  payment_status text not null default 'pending',
  subtotal numeric(10, 2) not null default 0,
  delivery_fee numeric(10, 2) not null default 0,
  handling_fee numeric(10, 2) not null default 0,
  total numeric(10, 2) not null default 0,
  status text not null default 'placed',
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Performance indexes
create index if not exists orders_user_created_idx
  on public.orders (user_id, created_at desc);

create index if not exists orders_status_created_idx
  on public.orders (status, created_at desc);

create index if not exists orders_created_at_idx
  on public.orders (created_at desc);

-- RLS policies
alter table public.orders enable row level security;

drop policy if exists "Enable all for authenticated users" on public.orders;
create policy "Enable all for authenticated users"
  on public.orders for all to authenticated
  using (true)
  with check (true);

drop policy if exists "Enable all for anon users" on public.orders;
create policy "Enable all for anon users"
  on public.orders for all to anon
  using (true)
  with check (true);

commit;
