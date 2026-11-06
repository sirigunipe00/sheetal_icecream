-- Fix: catalogue UI reads price from product_variants, not products.price.
-- Inventory updates must sync the default pack-size variant too.
-- Run once in Supabase SQL Editor.

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

  -- Sync default pack variant (same unit label, else lowest sort_order)
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

-- Repair Green Peas (and any product where products.price already differs from default variant)
update public.product_variants v
set price = p.price
from public.products p
where v.product_id = p.id
  and v.is_active = true
  and v.id = (
    select v2.id
    from public.product_variants v2
    where v2.product_id = p.id
      and v2.is_active = true
    order by
      case
        when p.unit is not null
         and lower(trim(v2.label)) = lower(trim(p.unit)) then 0
        else 1
      end,
      v2.sort_order,
      v2.id
    limit 1
  )
  and v.price is distinct from p.price;

-- Verify Green Peas
select p.id, p.name, p.price as product_price, v.label, v.price as variant_price
from public.products p
join public.product_variants v on v.product_id = p.id
where p.id = 309
order by v.sort_order;
