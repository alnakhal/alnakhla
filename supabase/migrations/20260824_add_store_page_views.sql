create table if not exists public.store_page_views (
  store_id uuid primary key references public.stores(id) on delete cascade,
  visitor_count bigint not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.store_page_views enable row level security;

create or replace function public.record_store_page_view(
  p_store_slug text default null,
  p_store_user_id uuid default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_store_id uuid;
  v_count bigint;
begin
  select id into v_store_id
  from public.stores
  where (p_store_slug is not null and slug = trim(p_store_slug))
     or (p_store_user_id is not null and user_id = p_store_user_id)
  limit 1;

  if v_store_id is null then
    return 0;
  end if;

  insert into public.store_page_views (store_id, visitor_count)
  values (v_store_id, 1)
  on conflict (store_id) do update
    set visitor_count = public.store_page_views.visitor_count + 1,
        updated_at = now()
  returning visitor_count into v_count;

  return v_count;
end;
$$;

revoke all on function public.record_store_page_view(text, uuid) from public;
grant execute on function public.record_store_page_view(text, uuid) to anon, authenticated;

create or replace function public.get_store_page_view_count(p_store_id uuid)
returns bigint
language sql
security definer
set search_path = public
as $$
  select coalesce(visitor_count, 0)
  from public.store_page_views
  where store_id = p_store_id;
$$;

revoke all on function public.get_store_page_view_count(uuid) from public;
grant execute on function public.get_store_page_view_count(uuid) to authenticated;

create or replace function public.get_store_page_view_count_for_store(
  p_store_slug text default null,
  p_store_user_id uuid default null
)
returns bigint
language sql
security definer
set search_path = public
as $$
  select coalesce(v.visitor_count, 0)
  from public.stores s
  left join public.store_page_views v on v.store_id = s.id
  where (
    (p_store_slug is not null and s.slug = trim(p_store_slug))
    or (p_store_user_id is not null and s.user_id = p_store_user_id)
  )
  and s.user_id = auth.uid()
  limit 1;
$$;

revoke all on function public.get_store_page_view_count_for_store(text, uuid) from public;
grant execute on function public.get_store_page_view_count_for_store(text, uuid) to authenticated;