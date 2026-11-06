-- Allow cart lines to store which pack size was chosen.
-- Run once in Supabase SQL Editor after setup_product_variants.sql.
-- Does not change products.name or products.image_url.

begin;

alter table public.cart_items
  add column if not exists variant_id bigint not null default 0;

-- Drop old unique (user + product only)
alter table public.cart_items
  drop constraint if exists cart_user_product_unique;

-- One cart line per user + product + variant (0 = no / single-size product)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'cart_user_product_variant_unique'
  ) then
    alter table public.cart_items
      add constraint cart_user_product_variant_unique
      unique (user_id, product_id, variant_id);
  end if;
end $$;

commit;

-- Optional check
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'cart_items'
order by ordinal_position;
