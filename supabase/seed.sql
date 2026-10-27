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

