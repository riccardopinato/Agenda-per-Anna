alter table public.push_delivery_events
  add column if not exists device_count integer not null default 0,
  add column if not exists delivered_count integer not null default 0,
  add column if not exists failed_count integer not null default 0,
  add column if not exists removed_invalid_tokens integer not null default 0,
  add column if not exists delivery_status text not null default 'queued',
  add column if not exists last_error text,
  add column if not exists completed_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'push_delivery_events_delivery_status_check'
  ) then
    alter table public.push_delivery_events
      add constraint push_delivery_events_delivery_status_check
      check (
        delivery_status in (
          'queued',
          'delivered',
          'partial',
          'failed',
          'no_devices',
          'deduplicated'
        )
      );
  end if;
end
$$;

create index if not exists push_delivery_events_status_created_idx
  on public.push_delivery_events(delivery_status, created_at desc);
