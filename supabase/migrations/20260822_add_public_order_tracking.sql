create or replace function public.get_public_order_tracking(p_order_number text)
returns table (
  order_number text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select o.order_number, o.status, o.created_at, o.updated_at
  from public.customer_orders o
  where upper(o.order_number) = upper(trim(p_order_number))
  limit 1;
$$;

revoke all on function public.get_public_order_tracking(text) from public;
grant execute on function public.get_public_order_tracking(text) to anon, authenticated;
