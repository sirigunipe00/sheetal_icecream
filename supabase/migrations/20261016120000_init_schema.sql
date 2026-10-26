-- Sheetal Ice Cream: core schema for catalog, customers, carts, orders,
-- payments and inventory.
--
-- Security model
--   * Every table has Row Level Security enabled.
--   * Customers can only see and change their own profile, addresses, cart
--     and wishlist, and can only read their own orders and payments.
--   * Orders, payments and stock are never written directly by the app.
--     They change only through the functions below, which re-check prices,
--     stock and ownership on the server.
--   * Payment status is only changed by functions that require the
--     service_role key, which lives in Edge Functions and never in the app.
--   * Orders, payments and stock history cannot be deleted.

create schema if not exists private;
grant usage on schema private to anon, authenticated, service_role;

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

create type public.app_role as enum ('customer', 'admin');

create type public.account_status as enum ('active', 'blocked');

create type public.order_status as enum (
  'pending_payment',
  'confirmed',
  'packed',
  'out_for_delivery',
  'delivered',
  'cancelled',
  'payment_failed'
);

create type public.payment_method as enum ('razorpay', 'cod');

create type public.payment_status as enum (
  'pending',
  'paid',
  'failed',
  'refund_pending',
  'refunded',
  'partially_refunded'
);

create type public.inventory_change_kind as enum (
  'opening_stock',
  'stock_in',
  'reserve',
  'release',
  'sale',
  'cancel_restore',
  'return',
  'adjustment'
);

-------------------------------------------------------------------------------
-- Shared trigger functions
-------------------------------------------------------------------------------

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function private.prevent_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Rows in %.% cannot be deleted. Archive or cancel them instead.',
    tg_table_schema, tg_table_name
    using errcode = '42501';
end;
$$;

create or replace function private.prevent_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Rows in %.% are append-only.', tg_table_schema, tg_table_name
    using errcode = '42501';
end;
$$;

-------------------------------------------------------------------------------
-- Store settings (single row)
-------------------------------------------------------------------------------

create table public.store_settings (
  id boolean primary key default true check (id),
  delivery_fee numeric(10, 2) not null default 25 check (delivery_fee >= 0),
  free_delivery_threshold numeric(10, 2) not null default 199 check (free_delivery_threshold >= 0),
  handling_fee numeric(10, 2) not null default 5 check (handling_fee >= 0),
  payment_window_minutes integer not null default 15 check (payment_window_minutes between 5 and 60),
  max_quantity_per_line integer not null default 20 check (max_quantity_per_line between 1 and 100),
  updated_at timestamptz not null default now()
);

insert into public.store_settings default values;

-------------------------------------------------------------------------------
-- Profiles
-------------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text check (char_length(full_name) <= 100),
  phone text,
  email text,
  role public.app_role not null default 'customer',
  status public.account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
      and status = 'active'
  );
$$;

revoke execute on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated, service_role;

create or replace function private.guard_profile_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Requests without a user (SQL editor, service_role) are trusted.
  if (select auth.uid()) is null or private.is_admin() then
    return new;
  end if;

  if new.id is distinct from old.id
     or new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.phone is distinct from old.phone
     or new.email is distinct from old.email
     or new.created_at is distinct from old.created_at then
    raise exception 'Only your name can be changed here.' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger profiles_guard
  before update on public.profiles
  for each row execute function private.guard_profile_update();

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, phone, email, full_name)
  values (
    new.id,
    nullif(new.phone, ''),
    nullif(new.email, ''),
    nullif(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

create or replace function private.sync_user_contact()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set phone = nullif(new.phone, ''),
         email = nullif(new.email, '')
   where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_contact_changed
  after update of phone, email on auth.users
  for each row
  when (old.phone is distinct from new.phone or old.email is distinct from new.email)
  execute function private.sync_user_contact();

-------------------------------------------------------------------------------
-- Catalog
-------------------------------------------------------------------------------

create table public.segments (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  name text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  segment_id text references public.segments (id),
  name text not null unique,
  image_path text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index categories_segment_idx on public.categories (segment_id);

create table public.products (
  id bigint generated by default as identity primary key,
  legacy_key text unique,
  category_id text not null references public.categories (id),
  name text not null check (char_length(name) between 1 and 120),
  description text,
  image_path text,
  is_new boolean not null default false,
  best_seller_rank integer check (best_seller_rank > 0),
  is_active boolean not null default true,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_category_idx on public.products (category_id) where is_active;
create index products_name_search_idx on public.products using gin (to_tsvector('simple', name));

create table public.product_images (
  id bigint generated by default as identity primary key,
  product_id bigint not null references public.products (id),
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (product_id, storage_path)
);

create index product_images_product_idx on public.product_images (product_id, sort_order);

create table public.product_variants (
  id bigint generated by default as identity primary key,
  product_id bigint not null references public.products (id),
  sku text not null unique,
  label text not null check (char_length(label) between 1 and 60),
  units_per_pack integer not null default 1 check (units_per_pack between 1 and 100),
  price numeric(10, 2) not null check (price > 0),
  mrp numeric(10, 2) check (mrp is null or mrp >= price),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, label)
);

create index product_variants_product_idx on public.product_variants (product_id, sort_order);

-------------------------------------------------------------------------------
-- Inventory
--
-- Stock is counted in single units per product. A "Pack of 4" variant uses
-- four units. available = on_hand - reserved.
-------------------------------------------------------------------------------

create table public.inventory (
  product_id bigint primary key references public.products (id),
  on_hand integer not null default 0 check (on_hand >= 0),
  reserved integer not null default 0 check (reserved >= 0),
  updated_at timestamptz not null default now(),
  constraint inventory_reserved_within_stock check (reserved <= on_hand)
);

create or replace function private.create_inventory_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.inventory (product_id) values (new.id)
  on conflict (product_id) do nothing;
  return new;
end;
$$;

create trigger products_create_inventory
  after insert on public.products
  for each row execute function private.create_inventory_row();

create table public.inventory_ledger (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products (id),
  kind public.inventory_change_kind not null,
  on_hand_change integer not null default 0,
  reserved_change integer not null default 0,
  on_hand_after integer not null,
  reserved_after integer not null,
  order_id uuid,
  reason text,
  actor_id uuid,
  created_at timestamptz not null default now(),
  check (on_hand_change <> 0 or reserved_change <> 0)
);

create index inventory_ledger_product_idx on public.inventory_ledger (product_id, created_at desc);
create index inventory_ledger_order_idx on public.inventory_ledger (order_id) where order_id is not null;

-------------------------------------------------------------------------------
-- Addresses, cart, wishlist
-------------------------------------------------------------------------------

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  label text not null default 'Home' check (char_length(label) between 1 and 30),
  recipient_name text not null check (char_length(recipient_name) between 1 and 100),
  phone text not null check (phone ~ '^\+?[0-9]{10,15}$'),
  house text not null check (char_length(house) between 1 and 200),
  street text check (char_length(street) <= 200),
  locality text not null check (char_length(locality) between 1 and 200),
  landmark text check (char_length(landmark) <= 200),
  city text not null check (char_length(city) between 1 and 100),
  state text not null check (char_length(state) between 1 and 100),
  postal_code text not null check (postal_code ~ '^[1-9][0-9]{5}$'),
  instructions text check (char_length(instructions) <= 300),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index addresses_one_default_per_user on public.addresses (user_id) where is_default;
create index addresses_user_idx on public.addresses (user_id);

create or replace function private.manage_default_address()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and not exists (
    select 1 from public.addresses where user_id = new.user_id
  ) then
    new.is_default := true;
  end if;

  if new.is_default then
    update public.addresses
       set is_default = false
     where user_id = new.user_id
       and id <> new.id
       and is_default;
  end if;

  return new;
end;
$$;

create trigger addresses_default
  before insert or update of is_default on public.addresses
  for each row execute function private.manage_default_address();

create trigger addresses_updated_at
  before update on public.addresses
  for each row execute function private.set_updated_at();

create table public.cart_items (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  variant_id bigint not null references public.product_variants (id),
  quantity integer not null check (quantity between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);

create trigger cart_items_updated_at
  before update on public.cart_items
  for each row execute function private.set_updated_at();

create table public.wishlist_items (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id bigint not null references public.products (id),
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

-------------------------------------------------------------------------------
-- Orders and payments
-------------------------------------------------------------------------------

create sequence public.order_number_seq start with 100001;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('SHT' || nextval('public.order_number_seq')),
  user_id uuid references auth.users (id) on delete set null,
  idempotency_key uuid not null,
  status public.order_status not null,
  payment_method public.payment_method not null,
  payment_status public.payment_status not null default 'pending',
  subtotal numeric(10, 2) not null check (subtotal >= 0),
  delivery_fee numeric(10, 2) not null default 0 check (delivery_fee >= 0),
  handling_fee numeric(10, 2) not null default 0 check (handling_fee >= 0),
  discount numeric(10, 2) not null default 0 check (discount >= 0),
  total numeric(10, 2) not null check (total >= 0),
  currency text not null default 'INR',
  address_snapshot jsonb not null,
  payment_due_by timestamptz,
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create index orders_user_idx on public.orders (user_id, created_at desc);
create index orders_status_idx on public.orders (status, created_at desc);
create index orders_unpaid_idx on public.orders (payment_due_by) where status = 'pending_payment';

alter table public.inventory_ledger
  add constraint inventory_ledger_order_fk foreign key (order_id) references public.orders (id);

create table public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id),
  product_id bigint references public.products (id),
  variant_id bigint references public.product_variants (id),
  product_name text not null,
  variant_label text not null,
  image_path text,
  units_per_pack integer not null check (units_per_pack > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  line_total numeric(10, 2) not null check (line_total >= 0)
);

create index order_items_order_idx on public.order_items (order_id);

create table public.order_status_history (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id),
  from_status public.order_status,
  to_status public.order_status not null,
  note text,
  actor_id uuid,
  created_at timestamptz not null default now()
);

create index order_status_history_order_idx on public.order_status_history (order_id, created_at);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id),
  user_id uuid references auth.users (id) on delete set null,
  provider public.payment_method not null,
  provider_order_id text unique,
  provider_payment_id text unique,
  method text,
  amount numeric(10, 2) not null check (amount >= 0),
  currency text not null default 'INR',
  status public.payment_status not null default 'pending',
  refunded_amount numeric(10, 2) not null default 0 check (refunded_amount >= 0),
  provider_refund_id text,
  failure_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index payments_order_idx on public.payments (order_id);
create index payments_user_idx on public.payments (user_id, created_at desc);

create table public.payment_events (
  id bigint generated always as identity primary key,
  provider text not null,
  event_id text not null,
  event_type text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  unique (provider, event_id)
);

-------------------------------------------------------------------------------
-- updated_at and delete protection
-------------------------------------------------------------------------------

create trigger segments_updated_at before update on public.segments
  for each row execute function private.set_updated_at();
create trigger categories_updated_at before update on public.categories
  for each row execute function private.set_updated_at();
create trigger products_updated_at before update on public.products
  for each row execute function private.set_updated_at();
create trigger product_variants_updated_at before update on public.product_variants
  for each row execute function private.set_updated_at();
create trigger orders_updated_at before update on public.orders
  for each row execute function private.set_updated_at();
create trigger payments_updated_at before update on public.payments
  for each row execute function private.set_updated_at();
create trigger store_settings_updated_at before update on public.store_settings
  for each row execute function private.set_updated_at();

create trigger products_no_delete before delete on public.products
  for each row execute function private.prevent_delete();
create trigger product_variants_no_delete before delete on public.product_variants
  for each row execute function private.prevent_delete();
create trigger categories_no_delete before delete on public.categories
  for each row execute function private.prevent_delete();
create trigger orders_no_delete before delete on public.orders
  for each row execute function private.prevent_delete();
create trigger order_items_no_delete before delete on public.order_items
  for each row execute function private.prevent_delete();
create trigger payments_no_delete before delete on public.payments
  for each row execute function private.prevent_delete();
create trigger payment_events_no_delete before delete on public.payment_events
  for each row execute function private.prevent_delete();

create trigger order_items_append_only before update on public.order_items
  for each row execute function private.prevent_change();
create trigger order_status_history_append_only before update or delete on public.order_status_history
  for each row execute function private.prevent_change();
create trigger inventory_ledger_append_only before update or delete on public.inventory_ledger
  for each row execute function private.prevent_change();

-------------------------------------------------------------------------------
-- Row Level Security
-------------------------------------------------------------------------------

alter table public.store_settings enable row level security;
alter table public.profiles enable row level security;
alter table public.segments enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_variants enable row level security;
alter table public.inventory enable row level security;
alter table public.inventory_ledger enable row level security;
alter table public.addresses enable row level security;
alter table public.cart_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payments enable row level security;
alter table public.payment_events enable row level security;

-- Store settings
create policy "Anyone can read store settings"
  on public.store_settings for select to anon, authenticated
  using (true);
create policy "Admins update store settings"
  on public.store_settings for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

-- Profiles
create policy "Users read own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()));
create policy "Users update own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()))
  with check (id = (select auth.uid()) or (select private.is_admin()));

-- Catalog: public read of active rows, admin write
create policy "Anyone reads active segments"
  on public.segments for select to anon, authenticated
  using (is_active or (select private.is_admin()));
create policy "Admins insert segments"
  on public.segments for insert to authenticated
  with check ((select private.is_admin()));
create policy "Admins update segments"
  on public.segments for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Anyone reads active categories"
  on public.categories for select to anon, authenticated
  using (is_active or (select private.is_admin()));
create policy "Admins insert categories"
  on public.categories for insert to authenticated
  with check ((select private.is_admin()));
create policy "Admins update categories"
  on public.categories for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Anyone reads active products"
  on public.products for select to anon, authenticated
  using ((is_active and archived_at is null) or (select private.is_admin()));
create policy "Admins insert products"
  on public.products for insert to authenticated
  with check ((select private.is_admin()));
create policy "Admins update products"
  on public.products for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Anyone reads product images"
  on public.product_images for select to anon, authenticated
  using (true);
create policy "Admins insert product images"
  on public.product_images for insert to authenticated
  with check ((select private.is_admin()));
create policy "Admins update product images"
  on public.product_images for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "Admins delete product images"
  on public.product_images for delete to authenticated
  using ((select private.is_admin()));

create policy "Anyone reads active variants"
  on public.product_variants for select to anon, authenticated
  using (is_active or (select private.is_admin()));
create policy "Admins insert variants"
  on public.product_variants for insert to authenticated
  with check ((select private.is_admin()));
create policy "Admins update variants"
  on public.product_variants for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

-- Inventory: readable so the app can show "out of stock"; changed only by functions
create policy "Anyone reads inventory"
  on public.inventory for select to anon, authenticated
  using (true);

create policy "Admins read inventory ledger"
  on public.inventory_ledger for select to authenticated
  using ((select private.is_admin()));

-- Addresses, cart, wishlist: owner only
create policy "Users read own addresses"
  on public.addresses for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users add own addresses"
  on public.addresses for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users update own addresses"
  on public.addresses for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users delete own addresses"
  on public.addresses for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users read own cart"
  on public.cart_items for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users add to own cart"
  on public.cart_items for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users update own cart"
  on public.cart_items for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users remove from own cart"
  on public.cart_items for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users read own wishlist"
  on public.wishlist_items for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users add to own wishlist"
  on public.wishlist_items for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users remove from own wishlist"
  on public.wishlist_items for delete to authenticated
  using (user_id = (select auth.uid()));

-- Orders and payments: read own; no direct writes
create policy "Users read own orders"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

create policy "Users read own order items"
  on public.order_items for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (o.user_id = (select auth.uid()) or (select private.is_admin()))
    )
  );

create policy "Users read own order history"
  on public.order_status_history for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (o.user_id = (select auth.uid()) or (select private.is_admin()))
    )
  );

create policy "Users read own payments"
  on public.payments for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

-- payment_events has RLS enabled and no policies: only service_role can use it.

-------------------------------------------------------------------------------
-- Internal helpers (private schema, not exposed through the API)
-------------------------------------------------------------------------------

create or replace function private.apply_inventory_change(
  p_product_id bigint,
  p_kind public.inventory_change_kind,
  p_on_hand_change integer,
  p_reserved_change integer,
  p_order_id uuid,
  p_reason text,
  p_actor uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_on_hand integer;
  v_reserved integer;
begin
  update public.inventory
     set on_hand = on_hand + p_on_hand_change,
         reserved = reserved + p_reserved_change,
         updated_at = now()
   where product_id = p_product_id
  returning on_hand, reserved into v_on_hand, v_reserved;

  if not found then
    raise exception 'No stock record for product %', p_product_id;
  end if;

  insert into public.inventory_ledger (
    product_id, kind, on_hand_change, reserved_change,
    on_hand_after, reserved_after, order_id, reason, actor_id
  )
  values (
    p_product_id, p_kind, p_on_hand_change, p_reserved_change,
    v_on_hand, v_reserved, p_order_id, p_reason, p_actor
  );
end;
$$;

create or replace function private.order_units(p_order_id uuid)
returns table (product_id bigint, units integer)
language sql
stable
security definer
set search_path = ''
as $$
  select oi.product_id, sum(oi.quantity * oi.units_per_pack)::integer
  from public.order_items oi
  where oi.order_id = p_order_id
    and oi.product_id is not null
  group by oi.product_id
  order by oi.product_id;
$$;

create or replace function private.set_order_status(
  p_order public.orders,
  p_to public.order_status,
  p_note text,
  p_actor uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.orders set status = p_to where id = p_order.id;

  insert into public.order_status_history (order_id, from_status, to_status, note, actor_id)
  values (p_order.id, p_order.status, p_to, p_note, p_actor);
end;
$$;

-- Releases a reservation (unpaid order) or restores sold stock (paid/COD order).
create or replace function private.return_order_stock(
  p_order public.orders,
  p_reason text,
  p_actor uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_line record;
begin
  for v_line in select * from private.order_units(p_order.id) loop
    perform 1 from public.inventory where product_id = v_line.product_id for update;

    if p_order.status = 'pending_payment' then
      perform private.apply_inventory_change(
        v_line.product_id, 'release', 0, -v_line.units, p_order.id, p_reason, p_actor
      );
    elsif p_order.status in ('confirmed', 'packed', 'out_for_delivery') then
      perform private.apply_inventory_change(
        v_line.product_id, 'cancel_restore', v_line.units, 0, p_order.id, p_reason, p_actor
      );
    end if;
  end loop;
end;
$$;

revoke execute on all functions in schema private from public;
grant execute on function private.is_admin() to anon, authenticated, service_role;

-------------------------------------------------------------------------------
-- Customer functions (callable from the app with supabase.rpc)
-------------------------------------------------------------------------------

-- Creates an order from the signed-in user's cart.
-- Prices, fees and stock are always taken from the database, never from the app.
-- Calling again with the same idempotency key returns the same order.
create or replace function public.place_order(
  p_address_id uuid,
  p_payment_method public.payment_method,
  p_idempotency_key uuid
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_order public.orders;
  v_settings public.store_settings;
  v_address public.addresses;
  v_problem record;
  v_line record;
  v_subtotal numeric(10, 2);
  v_delivery numeric(10, 2);
  v_handling numeric(10, 2);
begin
  if v_uid is null then
    raise exception 'Please log in to place an order.' using errcode = '28000';
  end if;
  if p_idempotency_key is null or p_payment_method is null then
    raise exception 'Missing order details.' using errcode = '22023';
  end if;
  if exists (select 1 from public.profiles where id = v_uid and status <> 'active') then
    raise exception 'This account is blocked.' using errcode = '42501';
  end if;

  -- One checkout at a time per customer.
  perform pg_advisory_xact_lock(hashtextextended('place_order:' || v_uid::text, 0));

  select * into v_order
  from public.orders
  where user_id = v_uid and idempotency_key = p_idempotency_key;
  if found then
    return v_order;
  end if;

  select * into v_settings from public.store_settings where id;

  select * into v_address
  from public.addresses
  where id = p_address_id and user_id = v_uid;
  if not found then
    raise exception 'Please choose a delivery address.' using errcode = 'P0002';
  end if;

  if not exists (select 1 from public.cart_items where user_id = v_uid) then
    raise exception 'Your cart is empty.' using errcode = 'P0001';
  end if;

  select p.name into v_problem
  from public.cart_items c
  join public.product_variants v on v.id = c.variant_id
  join public.products p on p.id = v.product_id
  where c.user_id = v_uid
    and not (v.is_active and p.is_active and p.archived_at is null)
  limit 1;
  if found then
    raise exception '% is no longer available. Remove it from your cart.', v_problem.name
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.cart_items
    where user_id = v_uid and quantity > v_settings.max_quantity_per_line
  ) then
    raise exception 'You can order at most % of each item.', v_settings.max_quantity_per_line
      using errcode = 'P0001';
  end if;

  -- Lock stock rows in a fixed order so concurrent orders cannot oversell.
  perform 1
  from public.inventory i
  where i.product_id in (
    select v.product_id
    from public.cart_items c
    join public.product_variants v on v.id = c.variant_id
    where c.user_id = v_uid
  )
  order by i.product_id
  for update;

  select p.name, greatest(coalesce(i.on_hand - i.reserved, 0), 0) as available
    into v_problem
  from (
    select v.product_id, sum(c.quantity * v.units_per_pack) as needed
    from public.cart_items c
    join public.product_variants v on v.id = c.variant_id
    where c.user_id = v_uid
    group by v.product_id
  ) n
  join public.products p on p.id = n.product_id
  left join public.inventory i on i.product_id = n.product_id
  where coalesce(i.on_hand - i.reserved, 0) < n.needed
  limit 1;
  if found then
    raise exception 'Only % left of %. Please reduce the quantity.', v_problem.available, v_problem.name
      using errcode = 'P0001';
  end if;

  select sum(c.quantity * v.price) into v_subtotal
  from public.cart_items c
  join public.product_variants v on v.id = c.variant_id
  where c.user_id = v_uid;

  v_delivery := case when v_subtotal >= v_settings.free_delivery_threshold then 0 else v_settings.delivery_fee end;
  v_handling := v_settings.handling_fee;

  insert into public.orders (
    user_id, idempotency_key, status, payment_method, payment_status,
    subtotal, delivery_fee, handling_fee, discount, total,
    address_snapshot, payment_due_by
  )
  values (
    v_uid,
    p_idempotency_key,
    case when p_payment_method = 'cod' then 'confirmed' else 'pending_payment' end::public.order_status,
    p_payment_method,
    'pending',
    v_subtotal,
    v_delivery,
    v_handling,
    0,
    v_subtotal + v_delivery + v_handling,
    jsonb_build_object(
      'label', v_address.label,
      'recipient_name', v_address.recipient_name,
      'phone', v_address.phone,
      'house', v_address.house,
      'street', v_address.street,
      'locality', v_address.locality,
      'landmark', v_address.landmark,
      'city', v_address.city,
      'state', v_address.state,
      'postal_code', v_address.postal_code,
      'instructions', v_address.instructions,
      'latitude', v_address.latitude,
      'longitude', v_address.longitude
    ),
    case when p_payment_method = 'razorpay'
      then now() + make_interval(mins => v_settings.payment_window_minutes)
    end
  )
  returning * into v_order;

  insert into public.order_items (
    order_id, product_id, variant_id, product_name, variant_label,
    image_path, units_per_pack, unit_price, quantity, line_total
  )
  select
    v_order.id, p.id, v.id, p.name, v.label,
    p.image_path, v.units_per_pack, v.price, c.quantity, c.quantity * v.price
  from public.cart_items c
  join public.product_variants v on v.id = c.variant_id
  join public.products p on p.id = v.product_id
  where c.user_id = v_uid
  order by p.id, v.sort_order;

  for v_line in select * from private.order_units(v_order.id) loop
    if p_payment_method = 'cod' then
      perform private.apply_inventory_change(
        v_line.product_id, 'sale', -v_line.units, 0, v_order.id, 'Cash on delivery order', v_uid
      );
    else
      perform private.apply_inventory_change(
        v_line.product_id, 'reserve', 0, v_line.units, v_order.id, 'Waiting for online payment', v_uid
      );
    end if;
  end loop;

  insert into public.payments (order_id, user_id, provider, amount, status, method)
  values (
    v_order.id, v_uid, p_payment_method, v_order.total, 'pending',
    case when p_payment_method = 'cod' then 'cash' end
  );

  insert into public.order_status_history (order_id, from_status, to_status, note, actor_id)
  values (v_order.id, null, v_order.status, 'Order placed', v_uid);

  delete from public.cart_items where user_id = v_uid;

  return v_order;
end;
$$;

-- Cancels an order. Customers can cancel their own order until it is packed.
-- Admins can cancel any order that has not been delivered.
create or replace function public.cancel_order(p_order_id uuid, p_reason text default null)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_order public.orders;
begin
  if v_uid is null then
    raise exception 'Please log in.' using errcode = '28000';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found or (v_order.user_id is distinct from v_uid and not v_is_admin) then
    raise exception 'Order not found.' using errcode = 'P0002';
  end if;

  if v_order.status = 'cancelled' then
    return v_order;
  end if;

  if v_is_admin then
    if v_order.status in ('delivered', 'payment_failed') then
      raise exception 'This order can no longer be cancelled.' using errcode = 'P0001';
    end if;
  elsif v_order.status not in ('pending_payment', 'confirmed') then
    raise exception 'This order is already being prepared and cannot be cancelled in the app.'
      using errcode = 'P0001';
  end if;

  perform private.return_order_stock(v_order, coalesce(p_reason, 'Order cancelled'), v_uid);
  perform private.set_order_status(v_order, 'cancelled', p_reason, v_uid);

  update public.orders
     set cancel_reason = p_reason,
         payment_status = case
           when payment_status = 'paid' then 'refund_pending'::public.payment_status
           when payment_status = 'pending' then 'failed'::public.payment_status
           else payment_status
         end
   where id = v_order.id
  returning * into v_order;

  update public.payments
     set status = v_order.payment_status,
         failure_reason = case when status = 'pending' then 'Order cancelled' else failure_reason end
   where order_id = v_order.id
     and status in ('pending', 'paid');

  return v_order;
end;
$$;

-------------------------------------------------------------------------------
-- Admin functions
-------------------------------------------------------------------------------

create or replace function public.admin_adjust_stock(
  p_product_id bigint,
  p_change integer,
  p_kind public.inventory_change_kind,
  p_reason text
)
returns public.inventory
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.inventory;
begin
  if not private.is_admin() then
    raise exception 'Only admins can change stock.' using errcode = '42501';
  end if;
  if p_kind not in ('opening_stock', 'stock_in', 'return', 'adjustment') then
    raise exception 'Use opening_stock, stock_in, return or adjustment.' using errcode = '22023';
  end if;
  if p_change = 0 then
    raise exception 'Change cannot be zero.' using errcode = '22023';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'A reason is required for every stock change.' using errcode = '22023';
  end if;

  perform 1 from public.inventory where product_id = p_product_id for update;
  perform private.apply_inventory_change(p_product_id, p_kind, p_change, 0, null, p_reason, auth.uid());

  select * into v_row from public.inventory where product_id = p_product_id;
  return v_row;
end;
$$;

create or replace function public.admin_update_order_status(
  p_order_id uuid,
  p_status public.order_status,
  p_note text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_allowed boolean;
begin
  if not private.is_admin() then
    raise exception 'Only admins can update orders.' using errcode = '42501';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found.' using errcode = 'P0002';
  end if;

  v_allowed := (v_order.status, p_status) in (
    ('confirmed'::public.order_status, 'packed'::public.order_status),
    ('packed'::public.order_status, 'out_for_delivery'::public.order_status),
    ('out_for_delivery'::public.order_status, 'delivered'::public.order_status)
  );
  if not v_allowed then
    raise exception 'Cannot move an order from % to %. Use cancel_order to cancel.', v_order.status, p_status
      using errcode = 'P0001';
  end if;

  perform private.set_order_status(v_order, p_status, p_note, auth.uid());

  if p_status = 'delivered' and v_order.payment_method = 'cod' then
    update public.orders set payment_status = 'paid' where id = v_order.id;
    update public.payments set status = 'paid' where order_id = v_order.id and provider = 'cod';
  end if;

  select * into v_order from public.orders where id = p_order_id;
  return v_order;
end;
$$;

-------------------------------------------------------------------------------
-- Payment functions (service_role only: called by Edge Functions)
-------------------------------------------------------------------------------

create or replace function public.attach_provider_order(p_order_id uuid, p_provider_order_id text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.payments
     set provider_order_id = p_provider_order_id
   where order_id = p_order_id
     and provider = 'razorpay'
     and status = 'pending'
     and (provider_order_id is null or provider_order_id = p_provider_order_id);

  if not found then
    raise exception 'No pending Razorpay payment for order %', p_order_id;
  end if;
end;
$$;

-- Marks an online payment as captured. Safe to call more than once.
create or replace function public.mark_order_paid(
  p_order_id uuid,
  p_provider_payment_id text,
  p_amount numeric,
  p_method text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_line record;
  v_short boolean := false;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order % not found', p_order_id;
  end if;

  if v_order.payment_status in ('paid', 'refund_pending', 'refunded', 'partially_refunded') then
    return v_order;
  end if;

  if p_amount is distinct from v_order.total then
    raise exception 'Paid amount % does not match order total %', p_amount, v_order.total;
  end if;

  update public.payments
     set status = 'paid',
         provider_payment_id = p_provider_payment_id,
         method = coalesce(p_method, method),
         failure_reason = null
   where order_id = v_order.id
     and provider = 'razorpay';

  if v_order.status = 'pending_payment' then
    for v_line in select * from private.order_units(v_order.id) loop
      perform 1 from public.inventory where product_id = v_line.product_id for update;
      perform private.apply_inventory_change(
        v_line.product_id, 'sale', -v_line.units, -v_line.units, v_order.id, 'Online payment received', null
      );
    end loop;

    perform private.set_order_status(v_order, 'confirmed', 'Payment received', null);
    update public.orders set payment_status = 'paid', payment_due_by = null where id = v_order.id;

  elsif v_order.status in ('payment_failed', 'cancelled') then
    -- Paid after the order expired or was cancelled: take stock again if it is
    -- still available, otherwise flag the payment for a refund.
    for v_line in select * from private.order_units(v_order.id) loop
      perform 1 from public.inventory where product_id = v_line.product_id for update;
      if exists (
        select 1 from public.inventory
        where product_id = v_line.product_id and on_hand - reserved < v_line.units
      ) then
        v_short := true;
      end if;
    end loop;

    if v_order.status = 'payment_failed' and not v_short then
      for v_line in select * from private.order_units(v_order.id) loop
        perform private.apply_inventory_change(
          v_line.product_id, 'sale', -v_line.units, 0, v_order.id, 'Late online payment received', null
        );
      end loop;
      perform private.set_order_status(v_order, 'confirmed', 'Late payment received', null);
      update public.orders set payment_status = 'paid', payment_due_by = null where id = v_order.id;
    else
      update public.orders set payment_status = 'refund_pending' where id = v_order.id;
      update public.payments set status = 'refund_pending'
       where order_id = v_order.id and provider = 'razorpay';
    end if;
  end if;

  select * into v_order from public.orders where id = p_order_id;
  return v_order;
end;
$$;

create or replace function public.record_payment_failure(p_order_id uuid, p_reason text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.payments
     set failure_reason = left(p_reason, 500)
   where order_id = p_order_id
     and provider = 'razorpay'
     and status = 'pending';
$$;

create or replace function public.mark_order_refunded(
  p_order_id uuid,
  p_provider_refund_id text,
  p_amount numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_payment public.payments;
  v_status public.payment_status;
begin
  select * into v_payment
  from public.payments
  where order_id = p_order_id and provider = 'razorpay'
  for update;
  if not found then
    raise exception 'No Razorpay payment for order %', p_order_id;
  end if;

  if v_payment.provider_refund_id = p_provider_refund_id then
    return;
  end if;

  v_status := case
    when v_payment.refunded_amount + p_amount >= v_payment.amount then 'refunded'
    else 'partially_refunded'
  end;

  update public.payments
     set refunded_amount = least(amount, refunded_amount + p_amount),
         provider_refund_id = p_provider_refund_id,
         status = v_status
   where id = v_payment.id;

  update public.orders set payment_status = v_status where id = p_order_id;
end;
$$;

-- Releases stock held by online orders that were not paid in time.
create or replace function private.expire_unpaid_orders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_count integer := 0;
begin
  for v_order in
    select * from public.orders
    where status = 'pending_payment' and payment_due_by < now()
    order by payment_due_by
    for update skip locked
  loop
    perform private.return_order_stock(v_order, 'Payment window expired', null);
    perform private.set_order_status(v_order, 'payment_failed', 'Payment window expired', null);
    update public.orders set payment_status = 'failed' where id = v_order.id;
    update public.payments set status = 'failed'
     where order_id = v_order.id and status = 'pending';
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-------------------------------------------------------------------------------
-- Function permissions
-------------------------------------------------------------------------------

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.is_admin() to anon, authenticated, service_role;

revoke execute on function public.place_order(uuid, public.payment_method, uuid) from public, anon;
revoke execute on function public.cancel_order(uuid, text) from public, anon;
revoke execute on function public.admin_adjust_stock(bigint, integer, public.inventory_change_kind, text) from public, anon;
revoke execute on function public.admin_update_order_status(uuid, public.order_status, text) from public, anon;
grant execute on function public.place_order(uuid, public.payment_method, uuid) to authenticated;
grant execute on function public.cancel_order(uuid, text) to authenticated;
grant execute on function public.admin_adjust_stock(bigint, integer, public.inventory_change_kind, text) to authenticated;
grant execute on function public.admin_update_order_status(uuid, public.order_status, text) to authenticated;

revoke execute on function public.attach_provider_order(uuid, text) from public, anon, authenticated;
revoke execute on function public.mark_order_paid(uuid, text, numeric, text) from public, anon, authenticated;
revoke execute on function public.record_payment_failure(uuid, text) from public, anon, authenticated;
revoke execute on function public.mark_order_refunded(uuid, text, numeric) from public, anon, authenticated;
grant execute on function public.attach_provider_order(uuid, text) to service_role;
grant execute on function public.mark_order_paid(uuid, text, numeric, text) to service_role;
grant execute on function public.record_payment_failure(uuid, text) to service_role;
grant execute on function public.mark_order_refunded(uuid, text, numeric) to service_role;

-- The app never needs to bump the order number sequence or write these tables directly.
revoke insert, update, delete on public.orders, public.order_items, public.order_status_history,
  public.payments, public.payment_events, public.inventory, public.inventory_ledger
  from anon, authenticated;

-------------------------------------------------------------------------------
-- Realtime: customers receive live updates for their own orders (RLS applies)
-------------------------------------------------------------------------------

alter publication supabase_realtime add table public.orders, public.order_status_history;

-------------------------------------------------------------------------------
-- Storage: public product images, admin-only uploads
-------------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 1048576, array['image/webp', 'image/png', 'image/jpeg'])
on conflict (id) do nothing;

create policy "Admins upload product images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images' and (select private.is_admin()));

create policy "Admins replace product images"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and (select private.is_admin()))
  with check (bucket_id = 'product-images' and (select private.is_admin()));

create policy "Admins delete product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and (select private.is_admin()));

-------------------------------------------------------------------------------
-- Scheduled job: release unpaid reservations every 5 minutes
-------------------------------------------------------------------------------

do $cron$
begin
  create extension if not exists pg_cron with schema extensions;
  perform cron.schedule(
    'expire-unpaid-orders',
    '*/5 * * * *',
    'select private.expire_unpaid_orders();'
  );
exception
  when duplicate_object then
    null;
  when others then
    raise notice 'Unpaid-order schedule was not created: %', sqlerrm;
end
$cron$;
