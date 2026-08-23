alter table public.products
  add column if not exists sku text,
  add column if not exists barcode text,
  add column if not exists unit text not null default 'قطعة',
  add column if not exists minimum_stock integer not null default 0,
  add column if not exists discount_price numeric,
  add column if not exists brand text,
  add column if not exists weight numeric,
  add column if not exists dimensions text,
  add column if not exists variants text,
  add column if not exists internal_notes text,
  add column if not exists image_urls jsonb not null default '[]'::jsonb,
  add column if not exists baghdad_delivery_price numeric,
  add column if not exists other_governorates_delivery_price numeric,
  add column if not exists pickup_available boolean not null default false;

create unique index if not exists products_sku_unique_idx
on public.products (user_id, sku)
where sku is not null and length(trim(sku)) > 0;

create index if not exists products_barcode_idx
on public.products (user_id, barcode)
where barcode is not null and length(trim(barcode)) > 0;