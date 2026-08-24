alter table public.customer_orders
alter column user_id drop not null;

create policy "Guests can create customer orders"
on public.customer_orders for insert
to anon, authenticated
with check (true);

drop policy if exists "Store owners can read store orders" on public.customer_orders;
create policy "Store owners can read store orders"
on public.customer_orders for select
to authenticated
using (auth.uid() = store_user_id);
