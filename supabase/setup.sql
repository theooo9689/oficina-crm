-- Execute uma única vez no Supabase: SQL Editor > New query > Run.
create table if not exists public.leads (
  id text not null default gen_random_uuid()::text,
  user_id uuid not null references auth.users(id) on delete cascade,
  company text not null,
  category text not null default '',
  city text not null default '',
  phone text not null default '',
  whatsapp text not null default '',
  stage text not null default 'Prospectado',
  note text not null default '',
  lead_date text not null default '',
  estimate text not null default '',
  last_activity text not null default '',
  created_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists leads_user_id_idx on public.leads(user_id);
alter table public.leads enable row level security;
revoke all on public.leads from anon;
grant select, insert, update, delete on public.leads to authenticated;

drop policy if exists "Users can read their own CRM leads" on public.leads;
create policy "Users can read their own CRM leads"
  on public.leads for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can add their own CRM leads" on public.leads;
create policy "Users can add their own CRM leads"
  on public.leads for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own CRM leads" on public.leads;
create policy "Users can update their own CRM leads"
  on public.leads for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own CRM leads" on public.leads;
create policy "Users can delete their own CRM leads"
  on public.leads for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Habilita atualizações em tempo real para outros dispositivos conectados.
do $$
begin
  alter publication supabase_realtime add table public.leads;
exception when duplicate_object then
  null;
end $$;

