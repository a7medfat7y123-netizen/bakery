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
