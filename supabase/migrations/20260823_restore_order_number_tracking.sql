drop function if exists public.get_public_order_tracking(text, text);
drop function if exists public.get_public_order_tracking(text);

create function public.get_public_order_tracking(p_order_number text)
returns table (
  order_number text,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  status_history jsonb,
  total_amount numeric,
  delivery_fee numeric,
  payment_method text,
  delivery_area text,
  items_count integer
)
language sql
security definer
set search_path = public
as $$
  select
    o.order_number,
    o.status,
    o.created_at,
    o.updated_at,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'status', h.status,
            'changed_at', h.changed_at
          ) order by h.changed_at asc, h.id asc
        )
        from public.order_status_history h
        where h.order_id = o.id
      ),
      '[]'::jsonb
    ) as status_history,
    o.total_amount,
    o.delivery_fee,
    o.payment_method,
    o.delivery_area,
    jsonb_array_length(coalesce(o.items, '[]'::jsonb))::integer as items_count
  from public.customer_orders o
  where upper(o.order_number) = upper(trim(p_order_number))
  limit 1;
$$;

grant execute on function public.get_public_order_tracking(text)
to anon, authenticated;
