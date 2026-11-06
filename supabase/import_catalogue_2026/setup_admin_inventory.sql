-- =============================================================================
-- Admin role + inventory for the FLAT products schema
-- Run once in Supabase SQL Editor.
-- Does NOT change existing product names or image_urls.
-- =============================================================================

begin;

-- 1) Stock quantity on products (inventory)
alter table public.products
  add column if not exists stock_qty integer not null default 0;

-- 2) Profiles (role per auth user)
do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('customer', 'admin');
  end if;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  role public.app_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile"
  on public.profiles for select to authenticated
  using (id = auth.uid());

drop policy if exists "Users update own profile (non-role)" on public.profiles;
create policy "Users update own profile (non-role)"
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles for existing users
insert into public.profiles (id, email, full_name)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'display_name', split_part(u.email, '@', 1))
from auth.users u
on conflict (id) do nothing;

-- 3) is_admin helper
create schema if not exists private;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated, anon, service_role;

-- 4) Admin: update ONLY price + stock_qty
create or replace function public.admin_update_inventory(
  p_product_id bigint,
  p_price numeric,
  p_stock_qty integer
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.products;
begin
  if not private.is_admin() then
    raise exception 'Only admins can update inventory' using errcode = '42501';
  end if;
  if p_price is null or p_price < 0 then
    raise exception 'Price must be >= 0';
  end if;
  if p_stock_qty is null or p_stock_qty < 0 then
    raise exception 'Stock qty must be >= 0';
  end if;

  update public.products
  set price = p_price,
      stock_qty = p_stock_qty
  where id = p_product_id
  returning * into v_row;

  if not found then
    raise exception 'Product % not found', p_product_id;
  end if;

  -- Catalogue UI uses product_variants.price — keep default pack in sync
  update public.product_variants v
  set price = p_price
  where v.product_id = p_product_id
    and v.is_active = true
    and v.id = (
      select v2.id
      from public.product_variants v2
      where v2.product_id = p_product_id
        and v2.is_active = true
      order by
        case
          when v_row.unit is not null
           and lower(trim(v2.label)) = lower(trim(v_row.unit)) then 0
          else 1
        end,
        v2.sort_order,
        v2.id
      limit 1
    );

  return v_row;
end;
$$;

revoke all on function public.admin_update_inventory(bigint, numeric, integer) from public;
grant execute on function public.admin_update_inventory(bigint, numeric, integer) to authenticated;

-- 5) Admin: add new product (name/image set only on create)
create or replace function public.admin_add_product(
  p_name text,
  p_category text,
  p_unit text,
  p_price numeric,
  p_stock_qty integer,
  p_image_url text default null,
  p_description text default null
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.products;
begin
  if not private.is_admin() then
    raise exception 'Only admins can add products' using errcode = '42501';
  end if;
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Name is required';
  end if;
  if p_category is null or length(trim(p_category)) = 0 then
    raise exception 'Category is required';
  end if;
  if p_image_url is null or length(trim(p_image_url)) = 0 then
    raise exception 'Product image is required';
  end if;
  if p_price is null or p_price < 0 then
    raise exception 'Price must be >= 0';
  end if;
  if p_stock_qty is null or p_stock_qty < 0 then
    raise exception 'Stock qty must be >= 0';
  end if;

  insert into public.products (
    name, category, unit, price, stock_qty, image_url, description, is_new, is_active
  ) values (
    trim(p_name),
    trim(p_category),
    coalesce(nullif(trim(p_unit), ''), 'Regular pack'),
    p_price,
    p_stock_qty,
    trim(p_image_url),
    nullif(trim(p_description), ''),
    true,
    true
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.admin_add_product(text, text, text, numeric, integer, text, text) from public;
grant execute on function public.admin_add_product(text, text, text, numeric, integer, text, text) to authenticated;

-- 6) Helper: am I admin? (for the app)
create or replace function public.am_i_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.is_admin();
$$;

revoke all on function public.am_i_admin() from public;
grant execute on function public.am_i_admin() to authenticated;

commit;

-- =============================================================================
-- ONE-TIME: promote your admin account (replace the email)
-- =============================================================================
-- update public.profiles
-- set role = 'admin'
-- where email = 'your-admin@email.com';
--
-- Or by user id:
-- update public.profiles set role = 'admin' where id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
