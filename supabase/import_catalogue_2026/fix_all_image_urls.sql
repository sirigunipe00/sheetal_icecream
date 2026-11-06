-- Point every product image_url at:
--   product-images/products/<filename>.png
-- Run in SQL → SQL Editor (not Logs)

-- 1) Fix double products/products/ paths
update public.products
set image_url = replace(
  image_url,
  '/storage/v1/object/public/product-images/products/products/',
  '/storage/v1/object/public/product-images/products/'
)
where image_url like '%/product-images/products/products/%';

-- 2) If image_url is null/empty but we can derive from name+category slug,
--    leave those for the app fallback; optional check:
select id, name, category, image_url
from public.products
where image_url is null
   or image_url not like '%/product-images/products/%'
order by id
limit 30;

-- 3) Spot-check a known file
select id, name, image_url
from public.products
where image_url like '%750ml-tub-badam-rabdi.png%'
   or name ilike '%badam rabdi%';
