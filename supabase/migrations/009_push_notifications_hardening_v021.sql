create index if not exists push_delivery_events_space_id_idx
  on public.push_delivery_events(space_id);

create index if not exists push_delivery_events_sender_user_id_idx
  on public.push_delivery_events(sender_user_id);

drop policy if exists "push_delivery_events_deny_clients"
  on public.push_delivery_events;

create policy "push_delivery_events_deny_clients"
  on public.push_delivery_events
  for all
  to authenticated
  using (false)
  with check (false);
