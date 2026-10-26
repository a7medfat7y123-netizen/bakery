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
