- Bakery. المعلومات في index.html (جزء «عدّل البيانات من هنا»)، وما تخترعش غيرها.
- كل push على main بيتنشر على Cloudflare Pages لوحده.
- الفورم بيحفظ في جدول messages على Supabase.
- بعد أي تعديل: ابعت رسالة من الفورم على لينك pages.dev، واتأكد إنها وصلت الجدول.

## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
