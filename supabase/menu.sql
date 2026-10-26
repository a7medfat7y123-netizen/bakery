-- ===== المنيو في قاعدة البيانات: الأقسام والأصناف =====
create table if not exists public.categories (
  id      bigint generated always as identity primary key,
  name    text    not null unique check (char_length(btrim(name)) between 1 and 60),
  sort    integer not null default 0,
  hidden  boolean not null default false,          -- قسم مقفول يتفتح بالضغط (زي المعجنات الدايت)
  note    text    check (char_length(note) <= 200)
);

create table if not exists public.products (
  id          bigint generated always as identity primary key,
  category_id bigint  not null references public.categories (id) on delete cascade,
  name        text    not null check (char_length(btrim(name)) between 1 and 100),
  price       integer not null check (price >= 0),
  image       text    check (char_length(image) <= 500),   -- مسار صورة أو رابط أو إيموجي
  sort        integer not null default 0,
  available   boolean not null default true,               -- false = مخفي من الموقع
  created_at  timestamptz not null default now()
);
create index if not exists products_category_idx on public.products (category_id, sort);

alter table public.categories enable row level security;
alter table public.products   enable row level security;

-- الكل يقرا المنيو (الأصناف المتاحة بس)، والأدمن يشوف كله
drop policy if exists "anyone reads categories" on public.categories;
create policy "anyone reads categories" on public.categories for select to anon, authenticated using (true);

drop policy if exists "anyone reads available products" on public.products;
create policy "anyone reads available products" on public.products for select to anon, authenticated
  using (available or public.is_admin());

-- الأدمن بس يضيف ويعدّل ويمسح
drop policy if exists "admins manage categories" on public.categories;
create policy "admins manage categories" on public.categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins manage products" on public.products;
create policy "admins manage products" on public.products for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

revoke all on public.categories, public.products from anon, authenticated;
grant select on public.categories, public.products to anon, authenticated;
grant insert, update, delete on public.categories, public.products to authenticated;

-- ===== البيانات الحالية (مرة واحدة بس لو الجداول فاضية) =====
do $$
declare c bigint;
begin
  if exists (select 1 from public.categories) then return; end if;

  insert into public.categories (name, sort) values ('المخبوزات', 1) returning id into c;
  insert into public.products (category_id, name, price, image, sort) values
    (c, 'عيش بلدي (الرغيف)', 1, 'images/aish-baladi.jpg', 1),
    (c, 'عيش فينو (الرغيف)', 2, 'images/fino.jpg', 2),
    (c, 'عيش شامي (الكيس)', 15, 'images/shami.jpg', 3),
    (c, 'توست (الكيس)', 35, 'images/toast.jpg', 4),
    (c, 'كرواسون سادة', 15, 'images/croissant.jpg', 5),
    (c, 'كرواسون شوكولاتة', 20, 'images/choco-croissant.jpg', 6);

  insert into public.categories (name, sort) values ('المعجنات', 2) returning id into c;
  insert into public.products (category_id, name, price, image, sort) values
    (c, 'فطيرة جبنة', 25, 'images/cheese-pie.jpg', 1),
    (c, 'فطيرة لحمة مفرومة', 40, 'images/meat-pie.jpg', 2),
    (c, 'بيتزا صغيرة', 45, 'images/pizza.jpg', 3),
    (c, 'سينابون', 30, 'images/cinnabon.jpg', 4);

  insert into public.categories (name, sort) values ('الحلويات', 3) returning id into c;
  insert into public.products (category_id, name, price, image, sort) values
    (c, 'كيك شوكولاتة (القطعة)', 25, 'images/choco-cake-slice.jpg', 1),
    (c, 'بسبوسة (الكيلو)', 120, 'images/basbousa.jpg', 2),
    (c, 'كحك العيد (الكيلو)', 200, 'images/kahk.jpg', 3),
    (c, 'بسكويت بالسمن (الكيلو)', 150, 'images/butter-cookies.jpg', 4);

  insert into public.categories (name, sort) values ('التورت', 4) returning id into c;
  insert into public.products (category_id, name, price, image, sort) values
    (c, 'تورتة شوكولاتة (صغيرة)', 250, 'images/choco-cake.jpg', 1),
    (c, 'تورتة فانيليا بالفواكه (صغيرة)', 280, 'images/fruit-cake.jpg', 2),
    (c, 'تورتة بلاك فورست (كبيرة)', 450, 'images/black-forest.jpg', 3);

  insert into public.categories (name, sort, hidden, note)
    values ('المعجنات الدايت', 5, true, '🥗 قليلة السعرات، بالقمح الكامل والشوفان') returning id into c;
  insert into public.products (category_id, name, price, image, sort) values
    (c, 'فطيرة جبنة لايت بالشوفان', 35, 'images/diet-cheese-pie.jpg', 1),
    (c, 'بيتزا دايت بعجينة القمح الكامل', 55, 'images/diet-pizza.jpg', 2),
    (c, 'كرواسون قمح كامل', 25, '🥐', 3),
    (c, 'عيش شوفان (الكيس)', 30, 'images/oat-bread.jpg', 4),
    (c, 'بسكويت شوفان بدون سكر (الكيلو)', 120, 'images/oat-cookies.jpg', 5);
end $$;

-- ===== صور الأصناف: مكان رفع الصور من لوحة الأدمن =====
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('products', 'products', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 3145728,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "admins upload product images" on storage.objects;
create policy "admins upload product images" on storage.objects for insert to authenticated
  with check (bucket_id = 'products' and public.is_admin());

drop policy if exists "admins change product images" on storage.objects;
create policy "admins change product images" on storage.objects for update to authenticated
  using (bucket_id = 'products' and public.is_admin());

drop policy if exists "admins delete product images" on storage.objects;
create policy "admins delete product images" on storage.objects for delete to authenticated
  using (bucket_id = 'products' and public.is_admin());
