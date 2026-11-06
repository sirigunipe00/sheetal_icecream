-- Split multi-size catalogue products into one DB row per pack size.
-- - Existing row is updated to the first (smallest) size.
-- - Extra sizes are inserted as new rows.
-- - image_url is NEVER changed on existing rows; new rows COPY the same image_url.
-- - Safe to re-run? NO — run once. Check verification query at the bottom first/after.
-- Source: Sheetal_Product_Catalogue (3).xlsx

begin;

-- Gold Milk (500 ml - 6 Ltr)  ->  2 sizes  [Milk]
update public.products
set name = 'Gold Milk (500 ml)',
    unit = '500 ml',
    price = 36
where id = 125;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Gold Milk (6 Ltr)', 420, image_url, category, '6 Ltr', description, is_new
from public.products
where id = 125
  and not exists (
    select 1 from public.products x
    where x.name = 'Gold Milk (6 Ltr)' and x.category = public.products.category
  );

-- Taza Milk (160 ml - 200 ml - 330 ml - 400 ml)  ->  2 sizes  [Milk]
update public.products
set name = 'Taza Milk (330 ml)',
    unit = '330 ml',
    price = 20
where id = 126;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Taza Milk (400 ml)', 25, image_url, category, '400 ml', description, is_new
from public.products
where id = 126
  and not exists (
    select 1 from public.products x
    where x.name = 'Taza Milk (400 ml)' and x.category = public.products.category
  );

-- Anytime Tea Milk (1 Ltr - 6 Ltr)  ->  2 sizes  [Milk]
update public.products
set name = 'Anytime Tea Milk (1 Ltr)',
    unit = '1 Ltr',
    price = 57
where id = 130;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Anytime Tea Milk (6 Ltr)', 340, image_url, category, '6 Ltr', description, is_new
from public.products
where id = 130
  and not exists (
    select 1 from public.products x
    where x.name = 'Anytime Tea Milk (6 Ltr)' and x.category = public.products.category
  );

-- Chhash (Buttermilk) (300 ml - 400 ml - 600 ml - 6 Ltr)  ->  2 sizes  [Buttermilk]
update public.products
set name = 'Chhash (Buttermilk) (600 ml)',
    unit = '600 ml',
    price = 20
where id = 133;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Chhash (Buttermilk) (6 Ltr)', 175, image_url, category, '6 Ltr', description, is_new
from public.products
where id = 133
  and not exists (
    select 1 from public.products x
    where x.name = 'Chhash (Buttermilk) (6 Ltr)' and x.category = public.products.category
  );

-- Shital Dahi (80 gm - 180 gm - 5 Kg)  ->  2 sizes  [Dahi]
update public.products
set name = 'Shital Dahi (180 g)',
    unit = '180 g',
    price = 20
where id = 136;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Shital Dahi (5 kg)', 450, image_url, category, '5 kg', description, is_new
from public.products
where id = 136
  and not exists (
    select 1 from public.products x
    where x.name = 'Shital Dahi (5 kg)' and x.category = public.products.category
  );

-- Ghee (500 ml - 1 Ltr - 15 Kg)  ->  3 sizes  [Ghee]
update public.products
set name = 'Ghee (500 ml)',
    unit = '500 ml',
    price = 360
where id = 139;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Ghee (1 Ltr)', 700, image_url, category, '1 Ltr', description, is_new
from public.products
where id = 139
  and not exists (
    select 1 from public.products x
    where x.name = 'Ghee (1 Ltr)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Ghee (15 kg)', 11500, image_url, category, '15 kg', description, is_new
from public.products
where id = 139
  and not exists (
    select 1 from public.products x
    where x.name = 'Ghee (15 kg)' and x.category = public.products.category
  );

-- Cow Ghee (Gaay nu Ghee) (200 ml - 500 ml - 1 Ltr - 15 Kg)  ->  4 sizes  [Ghee]
update public.products
set name = 'Cow Ghee (Gaay nu Ghee) (200 ml)',
    unit = '200 ml',
    price = 160
where id = 140;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Cow Ghee (Gaay nu Ghee) (500 ml)', 370, image_url, category, '500 ml', description, is_new
from public.products
where id = 140
  and not exists (
    select 1 from public.products x
    where x.name = 'Cow Ghee (Gaay nu Ghee) (500 ml)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Cow Ghee (Gaay nu Ghee) (1 Ltr)', 720, image_url, category, '1 Ltr', description, is_new
from public.products
where id = 140
  and not exists (
    select 1 from public.products x
    where x.name = 'Cow Ghee (Gaay nu Ghee) (1 Ltr)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Cow Ghee (Gaay nu Ghee) (15 kg)', 11900, image_url, category, '15 kg', description, is_new
from public.products
where id = 140
  and not exists (
    select 1 from public.products x
    where x.name = 'Cow Ghee (Gaay nu Ghee) (15 kg)' and x.category = public.products.category
  );

-- Elaichi Shrikhand (200 gm - 500 gm - 1 Kg)  ->  5 sizes  [Shrikhand]
update public.products
set name = 'Elaichi Shrikhand (200 g)',
    unit = '200 g',
    price = 50
where id = 161;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Elaichi Shrikhand (500 g)', 110, image_url, category, '500 g', description, is_new
from public.products
where id = 161
  and not exists (
    select 1 from public.products x
    where x.name = 'Elaichi Shrikhand (500 g)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Elaichi Shrikhand (1 kg)', 210, image_url, category, '1 kg', description, is_new
from public.products
where id = 161
  and not exists (
    select 1 from public.products x
    where x.name = 'Elaichi Shrikhand (1 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Elaichi Shrikhand (6 kg)', 1250, image_url, category, '6 kg', description, is_new
from public.products
where id = 161
  and not exists (
    select 1 from public.products x
    where x.name = 'Elaichi Shrikhand (6 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Elaichi Shrikhand (20 kg)', 4100, image_url, category, '20 kg', description, is_new
from public.products
where id = 161
  and not exists (
    select 1 from public.products x
    where x.name = 'Elaichi Shrikhand (20 kg)' and x.category = public.products.category
  );

-- Rajbhog Shrikhand (200 gm - 500 gm - 1 Kg)  ->  5 sizes  [Shrikhand]
update public.products
set name = 'Rajbhog Shrikhand (200 g)',
    unit = '200 g',
    price = 75
where id = 162;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Rajbhog Shrikhand (500 g)', 150, image_url, category, '500 g', description, is_new
from public.products
where id = 162
  and not exists (
    select 1 from public.products x
    where x.name = 'Rajbhog Shrikhand (500 g)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Rajbhog Shrikhand (1 kg)', 290, image_url, category, '1 kg', description, is_new
from public.products
where id = 162
  and not exists (
    select 1 from public.products x
    where x.name = 'Rajbhog Shrikhand (1 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Rajbhog Shrikhand (6 kg)', 1740, image_url, category, '6 kg', description, is_new
from public.products
where id = 162
  and not exists (
    select 1 from public.products x
    where x.name = 'Rajbhog Shrikhand (6 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Rajbhog Shrikhand (20 kg)', 5700, image_url, category, '20 kg', description, is_new
from public.products
where id = 162
  and not exists (
    select 1 from public.products x
    where x.name = 'Rajbhog Shrikhand (20 kg)' and x.category = public.products.category
  );

-- Mixed Fruit Shrikhand (200 gm - 500 gm - 1 Kg)  ->  5 sizes  [Shrikhand]
update public.products
set name = 'Mixed Fruit Shrikhand (200 g)',
    unit = '200 g',
    price = 60
where id = 163;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mixed Fruit Shrikhand (500 g)', 120, image_url, category, '500 g', description, is_new
from public.products
where id = 163
  and not exists (
    select 1 from public.products x
    where x.name = 'Mixed Fruit Shrikhand (500 g)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mixed Fruit Shrikhand (1 kg)', 230, image_url, category, '1 kg', description, is_new
from public.products
where id = 163
  and not exists (
    select 1 from public.products x
    where x.name = 'Mixed Fruit Shrikhand (1 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mixed Fruit Shrikhand (6 kg)', 1380, image_url, category, '6 kg', description, is_new
from public.products
where id = 163
  and not exists (
    select 1 from public.products x
    where x.name = 'Mixed Fruit Shrikhand (6 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mixed Fruit Shrikhand (20 kg)', 4500, image_url, category, '20 kg', description, is_new
from public.products
where id = 163
  and not exists (
    select 1 from public.products x
    where x.name = 'Mixed Fruit Shrikhand (20 kg)' and x.category = public.products.category
  );

-- Mango Shrikhand (200 gm - 500 gm - 1 Kg)  ->  5 sizes  [Shrikhand]
update public.products
set name = 'Mango Shrikhand (200 g)',
    unit = '200 g',
    price = 60
where id = 164;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Shrikhand (500 g)', 120, image_url, category, '500 g', description, is_new
from public.products
where id = 164
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Shrikhand (500 g)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Shrikhand (1 kg)', 230, image_url, category, '1 kg', description, is_new
from public.products
where id = 164
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Shrikhand (1 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Shrikhand (6 kg)', 1380, image_url, category, '6 kg', description, is_new
from public.products
where id = 164
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Shrikhand (6 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Shrikhand (20 kg)', 4500, image_url, category, '20 kg', description, is_new
from public.products
where id = 164
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Shrikhand (20 kg)' and x.category = public.products.category
  );

-- Tikha Mitha Mix  ->  2 sizes  [Namkeen]
update public.products
set name = 'Tikha Mitha Mix (150 g)',
    unit = '150 g',
    price = 30
where id = 186;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Tikha Mitha Mix (500 g)', 70, image_url, category, '500 g', description, is_new
from public.products
where id = 186
  and not exists (
    select 1 from public.products x
    where x.name = 'Tikha Mitha Mix (500 g)' and x.category = public.products.category
  );

-- Khatta Meetha  ->  2 sizes  [Namkeen]
update public.products
set name = 'Khatta Meetha (150 g)',
    unit = '150 g',
    price = 25
where id = 187;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Khatta Meetha (500 g)', 70, image_url, category, '500 g', description, is_new
from public.products
where id = 187
  and not exists (
    select 1 from public.products x
    where x.name = 'Khatta Meetha (500 g)' and x.category = public.products.category
  );

-- Bhavnagari Gathiya  ->  2 sizes  [Namkeen]
update public.products
set name = 'Bhavnagari Gathiya (150 g)',
    unit = '150 g',
    price = 25
where id = 189;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Bhavnagari Gathiya (500 g)', 75, image_url, category, '500 g', description, is_new
from public.products
where id = 189
  and not exists (
    select 1 from public.products x
    where x.name = 'Bhavnagari Gathiya (500 g)' and x.category = public.products.category
  );

-- French Fries (200 g - 2.5 Kg)  ->  2 sizes  [Frozen French Fries]
update public.products
set name = 'French Fries (200 g)',
    unit = '200 g',
    price = 45
where id = 274;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'French Fries (2.5 Kg)', 400, image_url, category, '2.5 Kg', description, is_new
from public.products
where id = 274
  and not exists (
    select 1 from public.products x
    where x.name = 'French Fries (2.5 Kg)' and x.category = public.products.category
  );

-- Handmade Punjabi Samosa  ->  2 sizes  [Samosa]
update public.products
set name = 'Handmade Punjabi Samosa (50 g)',
    unit = '50 g',
    price = 100
where id = 275;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Handmade Punjabi Samosa (80 g)', 160, image_url, category, '80 g', description, is_new
from public.products
where id = 275
  and not exists (
    select 1 from public.products x
    where x.name = 'Handmade Punjabi Samosa (80 g)' and x.category = public.products.category
  );

-- Handmade Mix Veg Samosa  ->  2 sizes  [Samosa]
update public.products
set name = 'Handmade Mix Veg Samosa (50 g)',
    unit = '50 g',
    price = 100
where id = 276;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Handmade Mix Veg Samosa (80 g)', 180, image_url, category, '80 g', description, is_new
from public.products
where id = 276
  and not exists (
    select 1 from public.products x
    where x.name = 'Handmade Mix Veg Samosa (80 g)' and x.category = public.products.category
  );

-- Kesar Dryfruit Basundi (1 Kg - 5 Kg)  ->  2 sizes  [Frozen Sweets]
update public.products
set name = 'Kesar Dryfruit Basundi (1 kg)',
    unit = '1 kg',
    price = 400
where id = 292;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Kesar Dryfruit Basundi (5 kg)', 1890, image_url, category, '5 kg', description, is_new
from public.products
where id = 292
  and not exists (
    select 1 from public.products x
    where x.name = 'Kesar Dryfruit Basundi (5 kg)' and x.category = public.products.category
  );

-- Mango Milk Shake (Aam Ras) (500 gm - 1 Kg - 5 Kg)  ->  3 sizes  [Frozen Sweets]
update public.products
set name = 'Mango Milk Shake (Aam Ras) (500 g)',
    unit = '500 g',
    price = 145
where id = 293;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Milk Shake (Aam Ras) (1 kg)', 280, image_url, category, '1 kg', description, is_new
from public.products
where id = 293
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Milk Shake (Aam Ras) (1 kg)' and x.category = public.products.category
  );
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Mango Milk Shake (Aam Ras) (5 kg)', 1350, image_url, category, '5 kg', description, is_new
from public.products
where id = 293
  and not exists (
    select 1 from public.products x
    where x.name = 'Mango Milk Shake (Aam Ras) (5 kg)' and x.category = public.products.category
  );

-- Green Peas  ->  2 sizes  [Vegetables]
update public.products
set name = 'Green Peas (200 g)',
    unit = '200 g',
    price = 40
where id = 309;
insert into public.products (name, price, image_url, category, unit, description, is_new)
select 'Green Peas (1 kg)', 120, image_url, category, '1 kg', description, is_new
from public.products
where id = 309
  and not exists (
    select 1 from public.products x
    where x.name = 'Green Peas (1 kg)' and x.category = public.products.category
  );

commit;

-- Verification: multi-size families should now appear as separate rows
select id, name, unit, price, category,
       left(image_url, 80) as image_url_prefix
from public.products
where name ~* '(Green Peas|Gold Milk|Taza Milk|Anytime Tea Milk|Chhash \(Buttermilk\)|Shital Dahi|^Ghee \(|Cow Ghee \(Gaay|Elaichi Shrikhand|Rajbhog Shrikhand|Mixed Fruit Shrikhand|Mango Shrikhand|Tikha Mitha Mix|Khatta Meetha|Bhavnagari Gathiya|French Fries \(|Handmade Punjabi Samosa|Handmade Mix Veg Samosa|Kesar Dryfruit Basundi|Mango Milk Shake)'
order by name, price;

-- Skipped (ambiguous size/price in Excel — not split):
--   Classic Chocobar (60 ml) prices ₹15 / ₹20
--   Farali Chevdo (Sweet) (500gm) prices ₹25 / ₹70
--   Noodles prices ₹5 / ₹10
