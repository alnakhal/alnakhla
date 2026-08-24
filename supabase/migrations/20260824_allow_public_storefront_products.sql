drop policy if exists "Public can read visible products" on public.products;

create policy "Public can read visible products"
on public.products
for select
to anon, authenticated
using (coalesce(is_hidden, false) = false);