alter table public.customer_orders
  drop constraint if exists customer_orders_invoice_status_check;

alter table public.customer_orders
  add constraint customer_orders_invoice_status_check
  check (invoice_status in ('draft', 'modified', 'pending_payment', 'paid', 'processing', 'completed', 'cancelled'));
