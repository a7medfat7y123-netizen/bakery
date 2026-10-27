---
name: test-form
description: يختبر فورم "تواصل معنا" على الموقع المنشور بعد أي تعديل أو push على main. استخدمه بعد كل push، أو لما حد يقول "اختبر الفورم" أو "اتأكد إن الرسايل بتوصل".
---

# اختبار الفورم بعد التعديل

كل push على main بيتنشر على Cloudflare Pages لوحده على `https://bakery-68n.pages.dev`.
الفورم بيحفظ في جدول `messages` على Supabase (المشروع `hidjlsdcwnsgmrqnlphy`).

## الخطوات

1. **اتأكد إن النشر خلص**: افتح `https://bakery-68n.pages.dev` واتأكد إن التعديل الجديد ظاهر.
2. **ابعت رسالة تجريبية من الفورم**: من قسم "تواصل معنا" في الموقع، ببيانات واضح إنها تجربة:
   - الاسم: `Claude test`
   - الرقم: `01000000000`
   - الرسالة: فيها رقم الـ commit وكلمة "safe to delete"
   لو مفيش متصفح، ابعت نفس الطلب اللي الفورم بيبعته (`index.html`، الـ submit handler بتاع `contactForm`):
   `POST {SUPABASE_URL}/rest/v1/messages` بالـ `apikey` = `SUPABASE_KEY` و `Prefer: return=minimal`.
   الرد لازم يكون `201`.
3. **اتأكد إنها وصلت الجدول**: المفتاح العام بيضيف بس ومش بيقرا، فلازم واحدة من دول:
   - أداة Supabase (`/mcp` ← claude.ai Supabase): `select * from messages order by created_at desc limit 5;`
   - أو صاحب المشروع يفتح جدول `messages` في الـ Table Editor أو لوحة الأدمن (`admin.html`).
4. **بلّغ بالنتيجة بصراحة**: لو الرسالة اتبعتت بس ما اتأكدتش إنها في الجدول، قول كده.

## ممنوع

- ما تحطش المفتاح الـ secret في أي ملف. المفتاح الـ publishable بس.
- ما تعملش push من غير ما صاحب المشروع يطلب، لأن أي push بيتنشر على طول.
