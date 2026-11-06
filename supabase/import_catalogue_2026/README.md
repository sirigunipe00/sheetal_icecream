# Upload Sheetal catalogue to Supabase

Source: `Sheetal_Product_Catalogue (2).xlsx`

## Steps

1. Open Supabase → **Storage → product-images**.
2. Open (or create) folder **products**, then folder **products** again  
   so the path is `product-images/products/`.
3. Upload **all files** from `images/` into that folder.
4. Open **SQL → SQL Editor → New query**.
5. Paste `replace_products.sql` and run it.
6. Restart the Flutter app.

## Notes

- Cart and wishlist are cleared. Orders are kept.
- Missing MRP values are stored as `0`.
- Image URLs use `.../product-images/products/<filename>.png`.
