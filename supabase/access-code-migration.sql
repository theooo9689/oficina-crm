-- Modo sem e-mail/senha: um código compartilhado por dispositivo.
-- Execute no Supabase SQL Editor depois de publicar a página.
-- O código em texto puro não fica neste arquivo nem no GitHub.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

create table if not exists private.crm_access (
  singleton boolean primary key default true check (singleton),
  code_salt text not null,
  code_hash text not null
);
revoke all on schema private from public, anon, authenticated;
revoke all on private.crm_access from public, anon, authenticated;

insert into private.crm_access(singleton, code_salt, code_hash)
values (true, 'g8CAN7m8_RoR4U2vt34P2Q', '50768fd65823e1b782b29e30a26f1942f72e6484c97c61056cbc822bd9aea03d')
on conflict (singleton) do update
set code_salt = excluded.code_salt,
    code_hash = excluded.code_hash;

-- O pgcrypto pode já existir em outro schema do projeto. Use o schema real.
do $$
declare
  digest_schema text;
begin
  select n.nspname into digest_schema
  from pg_catalog.pg_extension e
  join pg_catalog.pg_namespace n on n.oid = e.extnamespace
  where e.extname = 'pgcrypto';

  if digest_schema is null then
    raise exception 'A extensão pgcrypto não está disponível.';
  end if;

  execute pg_catalog.format($ddl$
    create or replace function private.crm_code_matches(p_code text)
    returns boolean
    language sql
    stable
    security definer
    set search_path = ''
    as $fn$
      select exists (
        select 1
        from private.crm_access a
        where a.singleton
          and encode(%I.digest(coalesce(p_code, '') || a.code_salt, 'sha256'), 'hex') = a.code_hash
      );
    $fn$;
  $ddl$, digest_schema);
end $$;
revoke all on function private.crm_code_matches(text) from public, anon, authenticated;

create table if not exists public.crm_shared_leads (
  id text primary key,
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
  created_at timestamptz not null default now()
);
alter table public.crm_shared_leads enable row level security;
revoke all on public.crm_shared_leads from public, anon, authenticated;

-- Migra registros que já estavam na tabela autenticada anterior, sem apagá-los.
do $$
begin
  if to_regclass('public.leads') is not null then
    execute $m$
      insert into public.crm_shared_leads
        (id, company, category, city, phone, whatsapp, stage, note, lead_date, estimate, last_activity)
      select id, company, coalesce(category,''), coalesce(city,''), coalesce(phone,''),
        coalesce(whatsapp,''), coalesce(stage,'Prospectado'), coalesce(note,''),
        coalesce(lead_date,''), coalesce(estimate,''), coalesce(last_activity,'')
      from public.leads
      on conflict (id) do nothing
    $m$;
  end if;
end $$;

create or replace function public.crm_list_leads(p_access_code text)
returns setof public.crm_shared_leads
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.crm_code_matches(p_access_code) then
    raise exception 'Código de acesso incorreto' using errcode = '42501';
  end if;
  return query select * from public.crm_shared_leads order by company;
end;
$$;

create or replace function public.crm_save_lead(p_access_code text, p_lead jsonb)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id text := coalesce(nullif(p_lead->>'id',''), pg_catalog.gen_random_uuid()::text);
begin
  if not private.crm_code_matches(p_access_code) then
    raise exception 'Código de acesso incorreto' using errcode = '42501';
  end if;
  insert into public.crm_shared_leads
    (id, company, category, city, phone, whatsapp, stage, note, lead_date, estimate, last_activity)
  values (
    v_id, coalesce(p_lead->>'company','Lead sem nome'), coalesce(p_lead->>'category',''),
    coalesce(p_lead->>'city',''), coalesce(p_lead->>'phone',''), coalesce(p_lead->>'whatsapp',''),
    coalesce(p_lead->>'stage','Prospectado'), coalesce(p_lead->>'note',''),
    coalesce(p_lead->>'date',''), coalesce(p_lead->>'estimate',''), coalesce(p_lead->>'lastActivity','')
  )
  on conflict (id) do update set
    company=excluded.company, category=excluded.category, city=excluded.city, phone=excluded.phone,
    whatsapp=excluded.whatsapp, stage=excluded.stage, note=excluded.note, lead_date=excluded.lead_date,
    estimate=excluded.estimate, last_activity=excluded.last_activity;
  return v_id;
end;
$$;

create or replace function public.crm_delete_lead(p_access_code text, p_lead_id text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.crm_code_matches(p_access_code) then
    raise exception 'Código de acesso incorreto' using errcode = '42501';
  end if;
  delete from public.crm_shared_leads where id = p_lead_id;
  return found;
end;
$$;

revoke all on function public.crm_list_leads(text) from public;
revoke all on function public.crm_save_lead(text, jsonb) from public;
revoke all on function public.crm_delete_lead(text, text) from public;
grant execute on function public.crm_list_leads(text) to anon, authenticated;
grant execute on function public.crm_save_lead(text, jsonb) to anon, authenticated;
grant execute on function public.crm_delete_lead(text, text) to anon, authenticated;


