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
