// رد آلي على الواتساب لكل رسالة جديدة في جدول messages.
// الـ trigger اللي في supabase/whatsapp-auto-reply.sql بيندّه بعد كل insert.
// الإعدادات كلها secrets على Supabase (ممنوع تتكتب هنا):
//   WHATSAPP_TOKEN            توكن WhatsApp Cloud API من Meta
//   WHATSAPP_PHONE_NUMBER_ID  الـ Phone number ID من Meta
//   WHATSAPP_TEMPLATE         اسم القالب المتوافق عليه من Meta
//   WHATSAPP_TEMPLATE_LANG    لغة القالب، مثال: "ar"
//   WHATSAPP_API_VERSION      اختياري، الافتراضي "v22.0"
//   WEBHOOK_SECRET            نفس القيمة اللي في الـ vault باسم whatsapp_webhook_secret

const env = (k: string) => Deno.env.get(k) ?? "";

// 01xxxxxxxxx (مصري) -> 201xxxxxxxxx ، وأي رقم تاني بيتساب بأرقامه بس
function toWhatsApp(phone: string): string | null {
  let n = phone.replace(/[^0-9]/g, "");
  if (n.startsWith("00")) n = n.slice(2);
  if (/^01[0125][0-9]{8}$/.test(n)) n = "2" + n;
  return n.length >= 10 && n.length <= 15 ? n : null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  if (!env("WEBHOOK_SECRET") || req.headers.get("x-webhook-secret") !== env("WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }

  const { record } = await req.json().catch(() => ({}));
  const to = record?.phone ? toWhatsApp(String(record.phone)) : null;
  if (!to) return new Response("invalid phone", { status: 400 });

  const version = env("WHATSAPP_API_VERSION") || "v22.0";
  const res = await fetch(`https://graph.facebook.com/${version}/${env("WHATSAPP_PHONE_NUMBER_ID")}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${env("WHATSAPP_TOKEN")}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to,
      type: "template",
      template: {
        name: env("WHATSAPP_TEMPLATE"),
        language: { code: env("WHATSAPP_TEMPLATE_LANG") || "ar" },
        // القالب فيه متغيّر واحد {{1}} = اسم العميل
        components: [{ type: "body", parameters: [{ type: "text", text: String(record.name ?? "").slice(0, 60) }] }],
      },
    }),
  });

  const text = await res.text();
  if (!res.ok) console.error("WhatsApp API error", res.status, text);
  return new Response(text, { status: res.ok ? 200 : 502, headers: { "Content-Type": "application/json" } });
});
