-- ===== messages (الجدول موجود بالفعل: id, name, phone, message, created_at) =====
alter table public.messages alter column name set not null;
alter table public.messages alter column phone set not null;
alter table public.messages alter column message set not null;
alter table public.messages alter column created_at set default now();

alter table public.messages enable row level security;

-- نشيل أي سياسات قديمة ونسيب سياسة واحدة: إضافة بس
do $$
declare p record;
begin
  for p in select policyname from pg_policies where schemaname = 'public' and tablename = 'messages' loop
    execute format('drop policy %I on public.messages', p.policyname);
  end loop;
end $$;

create policy "anyone can send a message"
  on public.messages for insert to anon
  with check (true);

revoke all on public.messages from anon, authenticated;
grant insert (name, phone, message) on public.messages to anon;

-- ===== orders: نسخة احتياطية من الطلبات =====
create table if not exists public.orders (
  id            bigint generated always as identity primary key,
  order_no      text        not null,
  created_at    timestamptz not null default now(),
  items         jsonb       not null,
  subtotal      integer     not null check (subtotal >= 0),
  delivery_fee  integer     not null default 0 check (delivery_fee >= 0),
  total         integer     not null check (total >= 0),
  delivery      boolean     not null,
  payment       text        not null check (payment in ('cash', 'instapay', 'wallet')),
  customer_name  text       not null check (char_length(customer_name) between 1 and 100),
  customer_phone text       not null check (char_length(customer_phone) between 8 and 20),
  address       text        check (char_length(address) <= 500),
  notes         text        check (char_length(notes) <= 500),
  status        text        not null default 'new'
);

alter table public.orders enable row level security;

drop policy if exists "site can insert orders" on public.orders;
create policy "site can insert orders"
  on public.orders for insert to anon
  with check (status = 'new');

revoke all on public.orders from anon, authenticated;
grant insert (order_no, items, subtotal, delivery_fee, total, delivery, payment,
              customer_name, customer_phone, address, notes) on public.orders to anon;
