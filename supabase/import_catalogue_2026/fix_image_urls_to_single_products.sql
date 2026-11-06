-- Fix image URLs to match Storage path:
-- product-images/products/<filename>.png
-- Run in SQL → SQL Editor

update public.products
set image_url = replace(
  image_url,
  '/storage/v1/object/public/product-images/products/products/',
  '/storage/v1/object/public/product-images/products/'
)
where image_url like '%/product-images/products/products/%';

-- If any rows still point at the bucket root, move them under products/
update public.products
set image_url = replace(
  image_url,
  '/storage/v1/object/public/product-images/',
  '/storage/v1/object/public/product-images/products/'
)
where image_url like '%/product-images/%'
  and image_url not like '%/product-images/products/%';

select id, name, image_url
from public.products
where name ilike '%badam rabdi%'
limit 5;
