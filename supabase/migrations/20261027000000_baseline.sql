-- ===== Baseline: الجداول الحالية للمخبز (messages, orders, admins, المنيو) =====
-- مجمّعة من messages.sql + schema.sql + admin.sql + menu.sql. كلها idempotent، فتشغيلها على مشروع فيه الجداول بالفعل مش بيغيّر بيانات.
-- الرد الآلي على الواتساب مش هنا عمداً: محتاج سر في الـ vault، وعلى الـ preview branches كان هيبعت واتساب حقيقي.

-- جدول رسائل فورم "تواصل معنا"
create table if not exists public.messages (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(btrim(name)) between 1 and 100),
  phone      text        not null check (phone ~ '^[0-9+ ]{8,20}$'),
  message    text        not null check (char_length(btrim(message)) between 1 and 2000),
  created_at timestamptz not null default now()
);

-- تشغيل Row Level Security
alter table public.messages enable row level security;

-- السياسة الوحيدة: الإضافة بس (مفيش سياسات select / update / delete = ممنوعين)
drop policy if exists "anyone can send a message" on public.messages;
create policy "anyone can send a message"
  on public.messages
  for insert
  to anon
  with check (true);

-- طبقة حماية زيادة: المفتاح الـ publishable (دور anon) يقدر يكتب الاسم والموبايل والرسالة بس
revoke all on public.messages from anon, authenticated;
grant insert (name, phone, message) on public.messages to anon;

-- جدول الطلبات: نسخة احتياطية من كل طلب بيتبعت من الموقع
create table if not exists public.orders (
  id          bigint generated always as identity primary key,
  order_no    text        not null,
  created_at  timestamptz not null default now(),
  items       jsonb       not null,           -- [{name, qty, price, total}]
  subtotal    integer     not null check (subtotal >= 0),
  delivery_fee integer    not null default 0 check (delivery_fee >= 0),
  total       integer     not null check (total >= 0),
  delivery    boolean     not null,
  payment     text        not null check (payment in ('cash', 'instapay', 'wallet')),
  customer_name  text     not null check (char_length(customer_name) between 1 and 100),
  customer_phone text     not null check (char_length(customer_phone) between 8 and 20),
  address     text        check (char_length(address) <= 500),
  notes       text        check (char_length(notes) <= 500),
  status      text        not null default 'new'
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);

-- الحماية: الموقع (anon) يقدر يضيف طلبات بس، ومحدش من الإنترنت يقدر يقرأ أو يعدّل أو يمسح
alter table public.orders enable row level security;

drop policy if exists "site can insert orders" on public.orders;
create policy "site can insert orders"
  on public.orders for insert
  to anon
  with check (status = 'new');

revoke all on public.orders from anon;
grant insert (order_no, items, subtotal, delivery_fee, total, delivery, payment,
              customer_name, customer_phone, address, notes) on public.orders to anon;

-- ===== لوحة الأدمن: مين يقدر يشوف الطلبات والرسائل =====

-- قائمة إيميلات الأدمن (مش متاحة من الموقع خالص)
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;

-- هل المستخدم اللي داخل أدمن؟ (security definer عشان يقدر يقرا جدول admins)
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- الأدمن يقرا الطلبات ويغيّر حالتها بس
drop policy if exists "admins read orders" on public.orders;
create policy "admins read orders" on public.orders
  for select to authenticated using (public.is_admin());

drop policy if exists "admins update order status" on public.orders;
create policy "admins update order status" on public.orders
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check
  check (status in ('new', 'preparing', 'delivered', 'cancelled'));

grant select on public.orders to authenticated;
grant update (status) on public.orders to authenticated;

-- الأدمن يقرا الرسائل بس
drop policy if exists "admins read messages" on public.messages;
create policy "admins read messages" on public.messages
  for select to authenticated using (public.is_admin());

grant select on public.messages to authenticated;

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
