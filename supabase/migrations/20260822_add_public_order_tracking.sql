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

create or replace function public.broadcast_public_order_status()
returns trigger
language plpgsql
security definer
set search_path = public, realtime
as $$
begin
  if new.status is distinct from old.status then
    perform realtime.broadcast_changes(
      'public-order-tracking:' || new.order_number,
      'status_changed',
      'UPDATE',
      jsonb_build_object(
        'order_number', new.order_number,
        'status', new.status,
        'updated_at', new.updated_at
      ),
      jsonb_build_object(
        'order_number', old.order_number,
        'status', old.status,
        'updated_at', old.updated_at
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists customer_orders_public_tracking on public.customer_orders;
create trigger customer_orders_public_tracking
after update on public.customer_orders
for each row
execute function public.broadcast_public_order_status();
