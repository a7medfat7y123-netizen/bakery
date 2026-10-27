-- ===== رد آلي على الواتساب لكل رسالة جديدة في messages =====
-- شغّله مرة واحدة في SQL Editor، بعد ما الـ Edge Function "whatsapp-auto-reply" تتنشر.
-- قبل ما تشغّله: حط نفس قيمة WEBHOOK_SECRET بتاعة الـ function مكان <WEBHOOK_SECRET> تحت.

create extension if not exists pg_net;

-- السر بيتحفظ في الـ vault، مش في الكود
select vault.create_secret('<WEBHOOK_SECRET>', 'whatsapp_webhook_secret')
where not exists (select 1 from vault.secrets where name = 'whatsapp_webhook_secret');

create or replace function public.whatsapp_auto_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := 'https://hidjlsdcwnsgmrqnlphy.supabase.co/functions/v1/whatsapp-auto-reply',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'whatsapp_webhook_secret')
    ),
    body := jsonb_build_object('record', jsonb_build_object('name', new.name, 'phone', new.phone))
  );
  return new;
end;
$$;

drop trigger if exists whatsapp_auto_reply on public.messages;
create trigger whatsapp_auto_reply
after insert on public.messages
for each row execute function public.whatsapp_auto_reply();
