-- Fill MISSING price / unit only from Sheetal_Product_Catalogue (3).xlsx
-- Does NOT change image_url, name, category, id, created_at, is_new
-- Multi-size (e.g. 150gm-500gm with ₹30/₹70):
--   unit = first/matched size, price = that size MRP,
--   description = all options like "150gm: ₹30 · 500gm: ₹70"
begin;
update public.products set unit = '80 ml' where id = 0; -- Tender Coconut (80 ml)
update public.products set unit = '80 ml' where id = 1; -- Alphonso Mango (80 ml)
update public.products set unit = '80 ml' where id = 2; -- Mixed Fruits (80 ml)
update public.products set unit = '80 ml' where id = 3; -- Guava (80 ml)
update public.products set unit = '80 ml' where id = 4; -- Jamun (80 ml)
update public.products set unit = '80 ml' where id = 5; -- Custard Apple (80 ml)
update public.products set unit = '120 ml' where id = 6; -- Almond Carnival (120 ml)
update public.products set unit = '120 ml' where id = 7; -- Chocolate Chips (120 ml)
update public.products set unit = '120 ml' where id = 8; -- American Nuts (120 ml)
update public.products set unit = '110 ml' where id = 9; -- Vanilla (110 ml)
update public.products set unit = '100 ml' where id = 10; -- Authentic Kulfi (100 ml)
update public.products set unit = '100 ml' where id = 11; -- Triple Chocolate (100 ml)
update public.products set unit = '100 ml' where id = 12; -- Creamy Bastani (100 ml)
update public.products set unit = '100 ml' where id = 13; -- Sugar Free Kesar Pista (100 ml)
update public.products set unit = '80 ml' where id = 14; -- Kaju Draksh (80 ml)
update public.products set unit = '80 ml' where id = 15; -- Butterscotch (80 ml)
update public.products set unit = '80 ml' where id = 16; -- American Dry Fruits (80 ml)
update public.products set unit = '100 ml' where id = 17; -- Sugar Free Vanilla (100 ml)
update public.products set unit = '100 ml' where id = 18; -- Kesar Pista (100 ml)
update public.products set unit = '80 ml' where id = 19; -- Rajbhog (80 ml)
update public.products set unit = '80 ml' where id = 20; -- Mawa Badam (80 ml)
update public.products set unit = '80 ml' where id = 21; -- Cookies ''N'' Cream (80 ml)
update public.products set unit = '110 ml' where id = 22; -- Vanilla (50 ml)
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 23; -- Strawberry (50 ml)
update public.products set unit = '100 ml' where id = 25; -- Chocolate Cyclone Funday (100 ml)
update public.products set unit = '100 ml' where id = 26; -- Fruit Rocking Funday (100 ml)
update public.products set unit = '120 ml' where id = 27; -- Sadi Lassi (120 ml)
update public.products set unit = '120 ml' where id = 28; -- Mango Lassi (120 ml)
update public.products set unit = '120 ml' where id = 29; -- Dry Fruit Lassi (120 ml)
update public.products set unit = '70 ml' where id = 30; -- Shahi Kulfi (70 ml)
update public.products set unit = '60 ml' where id = 31; -- Anjeer Kulfi (60 ml)
update public.products set unit = '60 ml' where id = 32; -- Traditional Kulfi (60 ml)
update public.products set unit = '60 ml' where id = 33; -- Sugar Free Kulfi (60 ml)
update public.products set unit = '50 ml' where id = 34; -- Kadai Kulfi (50 ml)
update public.products set unit = '50 ml' where id = 35; -- Punjab Di Kulfi (50 ml)
update public.products set unit = '60 ml' where id = 36; -- Jamun Kulfi (60 ml)
update public.products set unit = '60 ml' where id = 37; -- Royal Rabdi Kulfi (60 ml)
update public.products set unit = '45 ml' where id = 38; -- Malai Kulfi (45 ml)
update public.products set unit = '45 ml' where id = 39; -- Shahi Pista Kulfi (45 ml)
update public.products set unit = '60 ml' where id = 40; -- Bombay Chowpaty Kulfi (60 ml)
update public.products set unit = '70 ml' where id = 42; -- Gloria Almond (70 ml)
update public.products set unit = '60 ml' where id = 43; -- Hazelnut Filter Coffee (60 ml)
update public.products set unit = '60 ml' where id = 44; -- Baklava Pistachio (60 ml)
update public.products set unit = '60 ml' where id = 45; -- Hazelnut Chocolate Swirl (60 ml)
update public.products set unit = '60 ml' where id = 46; -- Tender Coconut Salted Caramel (60 ml)
update public.products set unit = '70 ml' where id = 47; -- Frostick (70 ml)
update public.products set unit = '60 ml' where id = 48; -- Rajbhog Candy (60 ml)
update public.products set unit = '60 ml' where id = 49; -- Almond Chocobar (60 ml)
update public.products set unit = '50 ml' where id = 50; -- Alphonso Mango (50 ml)
update public.products set unit = '40 ml' where id = 51; -- Mini Mega Bite (40 ml)
update public.products set unit = '55 ml' where id = 52; -- Choco Sparkle (55 ml)
update public.products set unit = '60 ml' where id = 53; -- Premium Mawa Malai (60 ml)
update public.products set unit = '60 ml', price = 15, description = 'Prices: ₹15 / ₹20' where id = 57; -- Classic Chocobar (60 ml)
update public.products set unit = '135 ml' where id = 66; -- Black Forest (135 ml)
update public.products set unit = '135 ml' where id = 67; -- Bolltop (135 ml)
update public.products set unit = '135 ml' where id = 68; -- American Nuts (135 ml)
update public.products set unit = '135 ml' where id = 69; -- Dark Choco Fantasy (135 ml)
update public.products set unit = '110 ml' where id = 70; -- Disc Cone (110 ml)
update public.products set unit = '100 ml' where id = 71; -- Biscotti (100 ml)
update public.products set unit = '110 ml' where id = 72; -- Chocolate Delight (110 ml)
update public.products set unit = '110 ml' where id = 73; -- Kaju Draksh (110 ml)
update public.products set unit = '100 ml' where id = 74; -- 2 in One (100 ml)
update public.products set unit = '100 ml' where id = 75; -- Cappuccino (100 ml)
update public.products set unit = '100 ml' where id = 76; -- Kesar (100 ml)
update public.products set unit = '110 ml' where id = 77; -- Nutty Butter Scotch (110 ml)
update public.products set unit = '110 ml' where id = 78; -- Kesar Pista (110 ml)
update public.products set unit = '100 ml' where id = 79; -- Salted Caramel (100 ml)
update public.products set unit = '100 ml' where id = 80; -- Choco Daddy Cone (100 ml)
update public.products set unit = 'Box' where id = 81; -- Gully Gola (Box)
update public.products set unit = '120 ml' where id = 82; -- Tripple Sundae (120 ml)
update public.products set unit = '100 ml' where id = 83; -- Single Sundae (100 ml)
update public.products set unit = '80 ml' where id = 84; -- Double Sundae (80 ml)
update public.products set unit = '80 ml' where id = 85; -- Matka Kulfi (80 ml)
update public.products set unit = '100 ml' where id = 86; -- Ras Malai Matka (100 ml)
update public.products set unit = '100 ml' where id = 87; -- Pista Malai Matka (100 ml)
update public.products set unit = '100 ml' where id = 88; -- Slice Cassata (100 ml)
update public.products set unit = '120 ml' where id = 89; -- Classic Cassata (120 ml)
update public.products set unit = '120 ml' where id = 90; -- Traditional Cassata (120 ml)
update public.products set unit = '80 ml' where id = 91; -- Nutty Roll Cut (80 ml)
update public.products set unit = '125 ml' where id = 92; -- Cookies Sandwich (125 ml)
update public.products set unit = '100 ml' where id = 93; -- Sandwich Ice Cream (100 ml)
update public.products set unit = '1 Ltr' where id = 94; -- Golden Fantasy Cake (1 Ltr)
update public.products set unit = '1 Ltr' where id = 95; -- Black Forest Cake (1 Ltr)
update public.products set unit = '400 g' where id = 96; -- Chocolate Cake (400 g)
update public.products set unit = '500 g' where id = 97; -- Red Velvet Cake (500 g)
update public.products set unit = '500 g' where id = 98; -- Cookie Chocolate Cake (500 g)
update public.products set unit = '100 ml' where id = 99; -- Golden Fantasy Pastry (100 ml)
update public.products set unit = '100 ml' where id = 100; -- Black Forest Pastry (100 ml)
update public.products set unit = '1 Ltr' where id = 101; -- Tender Coconut (1 Ltr)
update public.products set unit = '1 Ltr' where id = 102; -- Classical Kulfi (1 Ltr)
update public.products set unit = '1 Ltr' where id = 103; -- Rajbhog (1 Ltr)
update public.products set unit = '1 Ltr' where id = 104; -- Kesar Kaju Katli (1 Ltr)
update public.products set unit = '1 Ltr' where id = 105; -- Almond Carnival (1 Ltr)
update public.products set unit = '1 Ltr' where id = 106; -- Alphonso Mango (1 Ltr)
update public.products set unit = '1 Ltr' where id = 107; -- Malai Kulfi (1 Ltr)
update public.products set unit = '1 Ltr' where id = 108; -- Sitafal (1 Ltr)
update public.products set unit = '750 ml' where id = 109; -- Kesar Pista (750 ml)
update public.products set unit = '750 ml' where id = 110; -- Badam Rabdi (750 ml)
update public.products set unit = '750 ml' where id = 111; -- Butterscotch (750 ml)
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 112; -- Rajbhog (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 113; -- Kesar Pista (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 114; -- Mawa Badam (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 115; -- Almond Carnival (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 116; -- American Bits (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 117; -- Black Current (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 118; -- Kaju Draksh (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 119; -- Chocolate Chips (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 120; -- Cookies ''N'' Cream (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 121; -- Butter Scotch (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 122; -- Alphonso Mango (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 123; -- Strawberry (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set unit = '700 ml + 700 ml (Buy 1 Get 1 Free)' where id = 124; -- Vanilla (700 ml + 700 ml (Buy 1 Get 1 Free))
update public.products set price = 36.0, unit = '500 ml - 6 Ltr' where id = 125; -- Gold Milk (500 ml - 6 Ltr)
update public.products set price = 20.0, unit = '330 ml - 400 ml' where id = 126; -- Taza Milk (160 ml - 200 ml - 330 ml - 400 ml)
update public.products set price = 28.0, unit = '500 ml' where id = 127; -- Cow Milk (500 ml)
update public.products set price = 300.0, unit = '6 Ltr' where id = 128; -- Silver Milk (180 ml - 6 Ltr)
update public.products set price = 65.0, unit = '1 Ltr' where id = 129; -- Tea Special Milk (1 Ltr)
update public.products set price = 57.0, unit = '1 Ltr - 6 Ltr' where id = 130; -- Anytime Tea Milk (1 Ltr - 6 Ltr)
update public.products set price = 20.0, unit = '600 ml' where id = 132; -- Khati Chhash (Sour Buttermilk) (200 ml - 400 ml - 600 ml)
update public.products set price = 20.0, unit = '600 ml - 6 Ltr' where id = 133; -- Chhash (Buttermilk) (300 ml - 400 ml - 600 ml - 6 Ltr)
update public.products set price = 55.0, unit = '800 gm' where id = 135; -- Silver Dahi (Pouch) (150 gm - 800 gm)
update public.products set price = 20.0, unit = '180 gm - 5 Kg' where id = 136; -- Shital Dahi (80 gm - 180 gm - 5 Kg)
update public.products set price = 330.0, unit = '5 Kg' where id = 137; -- Silver Dahi (5 Kg)
update public.products set price = 115.0, unit = '1 Kg' where id = 138; -- Probiotic Dahi (1 Kg)
update public.products set price = 360.0, unit = '500 ml - 1 Ltr - 15 Kg' where id = 139; -- Ghee (500 ml - 1 Ltr - 15 Kg)
update public.products set price = 160.0, unit = '200 ml - 500 ml - 1 Ltr - 15 Kg' where id = 140; -- Cow Ghee (Gaay nu Ghee) (200 ml - 500 ml - 1 Ltr - 15 Kg)
update public.products set price = 160.0, unit = '200 ml - 500 ml - 1 Ltr - 15 Kg' where id = 141; -- Cow Ghee (Tin) (1 Ltr)
update public.products set unit = '100 g' where id = 142; -- Malai Paneer (100 g)
update public.products set unit = '200 g' where id = 143; -- Malai Paneer (200 g)
update public.products set unit = '500 g' where id = 144; -- Malai Paneer (500 g)
update public.products set unit = '1 Kg' where id = 145; -- Malai Paneer (1 Kg)
update public.products set unit = '100 gm' where id = 146; -- Butter (100 gm)
update public.products set price = 120.0, unit = '170gram' where id = 147; -- Badam Pista Cookies
update public.products set price = 100.0, unit = '170gram' where id = 148; -- Chocolate Chips Cookies
update public.products set price = 130.0, unit = '170gram' where id = 149; -- Brownie Walnut Cookies
update public.products set price = 100.0, unit = '170gram' where id = 150; -- Honey Oats Cookies
update public.products set price = 30.0, unit = '200 ml' where id = 151; -- Kulfi Flavoured Milk (200 ml)
update public.products set price = 30.0, unit = '200 ml' where id = 152; -- Elaichi Flavoured Milk (200 ml)
update public.products set price = 30.0, unit = '200 ml' where id = 153; -- Kesar Flavoured Milk (200 ml)
update public.products set price = 30.0, unit = '200 ml' where id = 154; -- Rose Flavoured Milk (200 ml)
update public.products set price = 40.0, unit = '200 ml' where id = 155; -- Cold Coffee (200 ml)
update public.products set price = 40.0, unit = '200 ml' where id = 156; -- Cold Coco (200 ml)
update public.products set price = 30.0, unit = '200 ml' where id = 157; -- Rose Lassi (200 ml)
update public.products set price = 20.0 where id = 158; -- Masala Chhash
update public.products set price = 200.0, unit = '1 Kg' where id = 159; -- Gulab Jamun (1 Kg)
update public.products set price = 200.0, unit = '1 Kg' where id = 160; -- Rasgulla (1 Kg)
update public.products set price = 50.0, unit = '200 gm - 500 gm - 1 Kg - 6 Kg - 20 Kg' where id = 161; -- Elaichi Shrikhand (200 gm - 500 gm - 1 Kg)
update public.products set price = 75.0, unit = '200 gm - 500 gm - 1 Kg 6 Kg - 20 Kg' where id = 162; -- Rajbhog Shrikhand (200 gm - 500 gm - 1 Kg)
update public.products set price = 60.0, unit = '200 gm - 500 gm - 1 Kg 6 Kg - 20 Kg' where id = 163; -- Mixed Fruit Shrikhand (200 gm - 500 gm - 1 Kg)
update public.products set price = 60.0, unit = '200 gm - 500 gm - 1 Kg 6 Kg - 20 Kg' where id = 164; -- Mango Shrikhand (200 gm - 500 gm - 1 Kg)
update public.products set unit = 'Bulk Tub) (6 Kg - 20 Kg' where id = 165; -- Shrikhand (Bulk Tub) (6 Kg - 20 Kg)
update public.products set price = 40.0, unit = '150' where id = 171; -- Butter Khari
update public.products set price = 40.0, unit = '150' where id = 172; -- Jeera Khari
update public.products set price = 40.0, unit = '150' where id = 173; -- Masala Khari
update public.products set price = 50.0, unit = '150' where id = 174; -- Palak Khari
update public.products set price = 40.0, unit = '150' where id = 175; -- Methi Khari
update public.products set price = 45.0, unit = '200Gram' where id = 176; -- Milk Rusk
update public.products set price = 50.0, unit = '200Gram' where id = 177; -- Kaju Rusk
update public.products set price = 40.0, unit = '200Gram' where id = 178; -- Jeera Rusk
update public.products set price = 40.0, unit = '200Gram' where id = 179; -- Fruta Rusk
update public.products set price = 20.0, unit = '70Gm' where id = 180; -- Chocolate Cream Roll
update public.products set price = 20.0, unit = '70Gm' where id = 181; -- Vanilla Cream Roll
update public.products set price = 20.0, unit = '70Gm' where id = 182; -- Strawberry Cream Roll
update public.products set price = 40.0, unit = '400gm' where id = 183; -- Pav
update public.products set price = 60.0, unit = '700gm' where id = 184; -- Premium Bread (Big)
update public.products set price = 60.0, unit = '700gm' where id = 185; -- Premium Bread (Small)
update public.products set unit = '150gm', price = 30, description = '150gm: ₹30 · 500gm: ₹70' where id = 186; -- Tikha Mitha Mix
update public.products set unit = '150gm', price = 25, description = '150gm: ₹25 · 500gm: ₹70' where id = 187; -- Khatta Meetha
update public.products set unit = '500gm', price = 25, description = 'Prices: ₹25 / ₹70' where id = 188; -- Farali Chevdo (Sweet)
update public.products set unit = '150gm', price = 25, description = '150gm: ₹25 · 500gm: ₹75' where id = 189; -- Bhavnagari Gathiya
update public.products set unit = '200gm' where id = 190; -- Sev Mamra
update public.products set unit = '150gm' where id = 191; -- Chana Jor Garam
update public.products set unit = '150gm' where id = 192; -- Ratlami Sev
update public.products set unit = '120gm' where id = 193; -- Shing Bhujiya
update public.products set unit = '500gm', description = 'Prices: ₹25 / ₹70' where id = 194; -- Farali Chevdo (Spicy)
update public.products set unit = '400 g' where id = 195; -- Chana Dal
update public.products set unit = '100gm' where id = 205; -- Bombay Bhel
update public.products set unit = '160gm' where id = 208; -- Papad Chavana
update public.products set unit = '150gm' where id = 209; -- Sev Bundi
update public.products set unit = '500gm' where id = 210; -- Subji Sev
update public.products set unit = '150gm' where id = 211; -- Salted Potato Wafers
update public.products set unit = '150gm' where id = 212; -- Masala Potato Wafers
update public.products set price = 45.0, unit = '200 g - 2.5 Kg' where id = 218; -- French Fries (Crispy & Salty)
update public.products set unit = 'Regular pack', price = 5, description = 'Prices: ₹5 / ₹10' where id = 219; -- Noodles
update public.products set unit = 'Cup' where id = 242; -- Masala Popcorn (Cup)
update public.products set unit = 'Cup' where id = 243; -- Manchurian Popcorn (Cup)
update public.products set unit = 'Cup' where id = 244; -- Cheese Popcorn (Cup)
update public.products set unit = 'Pouch' where id = 245; -- Popcorn (Pouch)
update public.products set unit = 'Pouch, bada' where id = 246; -- Popcorn (Pouch, bada)
update public.products set unit = 'Box' where id = 247; -- Choco Stix
update public.products set unit = 'Box' where id = 248; -- Strawberry Stix
update public.products set price = 80.0, unit = '400 g' where id = 249; -- Aloo Bhujiya (400 g)
update public.products set price = 75.0, unit = '400 g' where id = 250; -- Bhavnagari Gathiya (400 g)
update public.products set price = 85.0, unit = '400 g' where id = 251; -- Chana Dal (400 g)
update public.products set price = 80.0, unit = '400 g' where id = 252; -- Chana Jor Garam (400 g)
update public.products set price = 105.0, unit = '400 g' where id = 253; -- Farali Chiwda (Sweet) (400 g)
update public.products set price = 80.0, unit = '400 g' where id = 254; -- Khatta Meetha (400 g)
update public.products set price = 85.0, unit = '400 g' where id = 255; -- Ratlami Sev (400 g)
update public.products set price = 70.0, unit = '250 g' where id = 256; -- Dry Samosa (250 g)
update public.products set price = 80.0, unit = '250 g' where id = 257; -- Chakri (250 g)
update public.products set price = 70.0, unit = '250 g' where id = 258; -- Big Bhakharwadi (250 g)
update public.products set price = 85.0, unit = '250 g' where id = 259; -- Dry Kachori (250 g)
update public.products set price = 50.0 where id = 260; -- Fafda Gathiya
update public.products set price = 150.0, unit = 'Box' where id = 261; -- Pani Puri Kit
update public.products set price = 50.0, unit = '100gm' where id = 262; -- Bombay Bhel (Kit)
update public.products set unit = '80 g' where id = 263; -- Laccha Paratha (400 g)
update public.products set unit = '100 g' where id = 264; -- Mix Veg Paratha (400 g)
update public.products set unit = '80 g' where id = 265; -- Aloo Paratha 
update public.products set unit = '80 g' where id = 266; -- Malabar Paratha 
update public.products set unit = '80 g' where id = 267; -- Onion Paratha (400 g)
update public.products set unit = '400 g' where id = 268; -- Methi Paratha (400 g)
update public.products set unit = '40 g' where id = 271; -- Chapati
update public.products set price = 45.0, unit = '200 g - 2.5 Kg' where id = 274; -- French Fries (200 g - 2.5 Kg)
update public.products set unit = '50 g - 80 g' where id = 275; -- Handmade Punjabi Samosa
update public.products set price = 100.0, unit = '50 g - 80 g' where id = 276; -- Handmade Mix Veg Samosa
update public.products set unit = '1 Kg - 5 Kg' where id = 292; -- Kesar Dryfruit Basundi (1 Kg - 5 Kg)
update public.products set unit = '500 gm - 1 Kg - 5 Kg' where id = 293; -- Mango Milk Shake (Aam Ras) (500 gm - 1 Kg - 5 Kg)
commit;

-- Still missing price after update:
select id, name, category, unit, price from public.products where coalesce(price,0)=0 order by id;