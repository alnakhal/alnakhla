create or replace function public.update_customer_order_status_with_inventory(
  p_order_number text,
  p_new_status text
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_order public.customer_orders%rowtype;
  item jsonb;
  product_id_value bigint;
  quantity_value integer;
  product_price numeric;
  product_cost numeric;
  owner_id uuid;
  movement_type_value text;
  quantity_delta_value integer;
begin
  if p_new_status not in (
    'pending', 'confirmed', 'shipped', 'delivered',
    'cancelled_company', 'returned'
  ) then
    raise exception 'حالة طلب غير صالحة: %', p_new_status;
  end if;

  select * into current_order
  from public.customer_orders
  where order_number = p_order_number
    and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'لم يتم العثور على الطلب أو لا تملك صلاحية تعديله';
  end if;

  owner_id := current_order.user_id;

  if p_new_status = 'shipped' and current_order.status <> 'shipped' then
    movement_type_value := 'shipped';
    quantity_delta_value := -1;
  elsif p_new_status = 'returned' and current_order.status <> 'returned' then
    movement_type_value := 'returned';
    quantity_delta_value := 1;
  else
    update public.customer_orders
    set status = p_new_status, updated_at = now()
    where id = current_order.id;
    return;
  end if;

  for item in select value from jsonb_array_elements(coalesce(current_order.items, '[]'::jsonb))
  loop
    product_id_value := nullif(item->>'id', '')::bigint;
    quantity_value := coalesce(nullif(item->>'quantity', '')::integer, 0);
    if product_id_value is null or quantity_value <= 0 then
      continue;
    end if;

    if exists (
      select 1 from public.inventory_movements
      where order_number = current_order.order_number
        and product_id = product_id_value
        and movement_type = movement_type_value
    ) then
      continue;
    end if;

    select p.price, p.cost into product_price, product_cost
    from public.products p
    where p.id = product_id_value
    for update;

    if not found then
      continue;
    end if;

    if movement_type_value = 'shipped' then
      update public.products
      set remaining_qty = remaining_qty - quantity_value
      where id = product_id_value
        and remaining_qty >= quantity_value;
      if not found then
        raise exception 'الكمية غير كافية للمنتج %', product_id_value;
      end if;
    else
      update public.products
      set remaining_qty = remaining_qty + quantity_value
      where id = product_id_value;
    end if;

    insert into public.inventory_movements (
      user_id, order_number, product_id, quantity, quantity_delta,
      movement_type, unit_price, unit_cost
    ) values (
      owner_id, current_order.order_number, product_id_value, quantity_value,
      quantity_delta_value * quantity_value, movement_type_value,
      coalesce(product_price, 0), coalesce(product_cost, 0)
    ) on conflict (order_number, product_id, movement_type) do nothing;
  end loop;

  update public.customer_orders
  set status = p_new_status, updated_at = now()
  where id = current_order.id;
end;
$$;

grant execute on function public.update_customer_order_status_with_inventory(text, text)
to authenticated;
