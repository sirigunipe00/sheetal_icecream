-- Require image_url when admin adds a product.
-- Allow authenticated admins to upload into Storage bucket product-images.
-- Run once in Supabase SQL Editor.

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

-- Storage: admins can upload/update/delete in product-images bucket
-- (public read usually already exists for catalogue images)

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and private.is_admin()
  );

drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and private.is_admin())
  with check (bucket_id = 'product-images' and private.is_admin());

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and private.is_admin());
