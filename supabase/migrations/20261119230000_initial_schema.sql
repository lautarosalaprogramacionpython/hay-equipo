-- Hay Equipo: esquema inicial para Supabase/PostgreSQL.
-- Los jugadores se crean desde auth.users; el teléfono Auth verificado es la
-- fuente de verdad y players.phone_number conserva su representación E.164.
-- Ejecutar como migración, no pegar en un proyecto Firebase.

create type public.field_type as enum ('5', '7');
create type public.team_role as enum ('captain', 'player');
create type public.join_request_status as enum ('pending', 'accepted', 'rejected');
create type public.match_status as enum (
  'proposed',
  'accepted',
  'rejected',
  'scheduled',
  'completed',
  'cancelled'
);
create type public.conversation_type as enum ('dm', 'team', 'match');
create type public.report_email_status as enum ('pending', 'sending', 'sent', 'failed');

-- Perfiles. No se permite que el cliente cree perfiles directamente:
-- el trigger de auth.users los crea usando el teléfono verificado por Supabase.
create table public.players (
  id uuid primary key references auth.users (id) on delete cascade,
  phone_number text not null,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint players_phone_e164_format check (
    phone_number ~ '^\+[1-9][0-9]{7,14}$'
  ),
  constraint players_phone_number_unique unique (phone_number)
);

comment on column public.players.phone_number is
  'Teléfono verificado por Supabase Auth, normalizado a E.164; dato privado.';
comment on column public.players.email is
  'Email opcional; dato privado, no usar como identificador de acceso.';

-- UNIQUE es la garantía atómica ante registros concurrentes. Este trigger
-- complementa la constraint con una validación temprana y un error legible;
-- no se debe reemplazar la constraint por una comprobación SELECT solamente.
create or replace function public.validate_player_phone_number()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.phone_number is null
     or new.phone_number !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception using
      errcode = '22023',
      message = 'PHONE_INVALID_E164';
  end if;

  if exists (
    select 1
    from public.players as p
    where p.phone_number = new.phone_number
      and p.id <> new.id
  ) then
    raise exception using
      errcode = '23505',
      constraint = 'players_phone_number_unique',
      message = 'PHONE_ALREADY_REGISTERED';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger players_validate_phone_before_write
before insert or update on public.players
for each row execute function public.validate_player_phone_number();

-- Supabase Phone Auth writes auth.users.phone after the OTP flow. A duplicate
-- phone raises a unique violation here and rolls back Auth user creation too.
create or replace function public.sync_player_from_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_phone text;
  v_name text;
begin
  v_phone := new.phone;
  if v_phone is null then
    raise exception using
      errcode = '22023',
      message = 'PHONE_REQUIRED';
  end if;

  v_name := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
    'Jugador'
  );

  insert into public.players (id, phone_number, display_name, email)
  values (
    new.id,
    v_phone,
    v_name,
    coalesce(new.email, nullif(new.raw_user_meta_data ->> 'email', ''))
  )
  on conflict (id) do update
    set phone_number = excluded.phone_number,
        display_name = excluded.display_name,
        email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

create trigger auth_user_sync_player
after insert or update of phone, email, raw_user_meta_data on auth.users
for each row execute function public.sync_player_from_auth_user();

-- Equipos y membresías. Cada equipo obtiene automáticamente su capitán y su
-- conversación privada al crearse.
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  field_type public.field_type not null,
  description text check (description is null or char_length(description) <= 500),
  badge_color text check (
    badge_color is null or badge_color ~ '^#[0-9A-Fa-f]{6}$'
  ),
  created_by uuid not null references public.players (id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.team_members (
  team_id uuid not null references public.teams (id) on delete cascade,
  player_id uuid not null references public.players (id) on delete cascade,
  role public.team_role not null default 'player',
  joined_at timestamptz not null default now(),
  primary key (team_id, player_id)
);

-- Un solo capitán por equipo; los equipos pueden tener varios jugadores.
create unique index team_members_one_captain_uidx
  on public.team_members (team_id)
  where role = 'captain';

create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  player_id uuid not null references public.players (id) on delete cascade,
  status public.join_request_status not null default 'pending',
  message text check (message is null or char_length(message) <= 500),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);

-- Permite conservar solicitudes rechazadas/aceptadas y evita duplicados
-- simultáneos pendientes para el mismo jugador y equipo.
create unique index join_requests_one_pending_uidx
  on public.join_requests (team_id, player_id)
  where status = 'pending';
create index join_requests_team_status_idx
  on public.join_requests (team_id, status, created_at desc);
create index join_requests_player_created_idx
  on public.join_requests (player_id, created_at desc);

-- Desafíos entre dos equipos. Los participantes son una instantánea de las
-- plantillas al crear el partido y se usan para autorizar el chat del reto.
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  home_team_id uuid not null references public.teams (id) on delete restrict,
  away_team_id uuid not null references public.teams (id) on delete restrict,
  field_type public.field_type not null,
  status public.match_status not null default 'proposed',
  scheduled_at timestamptz,
  venue text check (venue is null or char_length(venue) <= 250),
  created_by uuid not null references public.players (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint matches_distinct_teams check (home_team_id <> away_team_id)
);

create table public.match_participants (
  match_id uuid not null references public.matches (id) on delete cascade,
  team_id uuid not null references public.teams (id) on delete restrict,
  player_id uuid not null references public.players (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (match_id, player_id)
);

create index match_participants_player_match_idx
  on public.match_participants (player_id, match_id);
create index matches_status_scheduled_idx
  on public.matches (status, scheduled_at)
  where status in ('proposed', 'accepted', 'scheduled');
create index matches_home_team_created_idx
  on public.matches (home_team_id, created_at desc);
create index matches_away_team_created_idx
  on public.matches (away_team_id, created_at desc);

-- Conversaciones persistentes y mensajes. realtime.messages se usa además
-- para autorizar Broadcast privado en el tópico generado de cada conversación.
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  channel_type public.conversation_type not null,
  team_id uuid references public.teams (id) on delete cascade,
  match_id uuid references public.matches (id) on delete cascade,
  dm_user_low uuid references public.players (id) on delete cascade,
  dm_user_high uuid references public.players (id) on delete cascade,
  created_by uuid not null references public.players (id) on delete restrict,
  created_at timestamptz not null default now(),
  topic text generated always as (
    case channel_type
      when 'dm' then 'dm:' || id::text
      when 'team' then 'team:' || team_id::text
      when 'match' then 'match:' || match_id::text
    end
  ) stored,
  constraint conversations_channel_target_check check (
    (channel_type = 'dm'
      and team_id is null and match_id is null
      and dm_user_low is not null and dm_user_high is not null
      and dm_user_low < dm_user_high)
    or
    (channel_type = 'team'
      and team_id is not null and match_id is null
      and dm_user_low is null and dm_user_high is null)
    or
    (channel_type = 'match'
      and team_id is null and match_id is not null
      and dm_user_low is null and dm_user_high is null)
  ),
  constraint conversations_topic_unique unique (topic),
  constraint conversations_dm_pair_unique unique (dm_user_low, dm_user_high),
  constraint conversations_team_unique unique (team_id),
  constraint conversations_match_unique unique (match_id)
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  player_id uuid not null references public.players (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, player_id)
);

create index conversation_participants_player_idx
  on public.conversation_participants (player_id, conversation_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.players (id) on delete restrict,
  body text not null check (char_length(btrim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc, id desc);
create index team_members_player_team_idx
  on public.team_members (player_id, team_id);

-- Helpers SECURITY DEFINER evitan recursión de RLS al comprobar membresías.
-- Cada función solo comprueba la identidad de la sesión actual.
create or replace function public.is_team_member(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.team_members as tm
    where tm.team_id = p_team_id
      and tm.player_id = auth.uid()
  );
$$;

create or replace function public.is_team_captain(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.team_members as tm
    where tm.team_id = p_team_id
      and tm.player_id = auth.uid()
      and tm.role = 'captain'
  );
$$;

create or replace function public.is_conversation_participant(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.conversation_participants as cp
    where cp.conversation_id = p_conversation_id
      and cp.player_id = auth.uid()
  );
$$;

create or replace function public.can_access_conversation_topic(p_topic text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.conversations as c
    join public.conversation_participants as cp
      on cp.conversation_id = c.id
    where c.topic = p_topic
      and cp.player_id = auth.uid()
  );
$$;

revoke all on function public.is_team_member(uuid) from public, anon;
revoke all on function public.is_team_captain(uuid) from public, anon;
revoke all on function public.is_conversation_participant(uuid) from public, anon;
revoke all on function public.can_access_conversation_topic(text) from public, anon;
grant execute on function public.is_team_member(uuid) to authenticated;
grant execute on function public.is_team_captain(uuid) to authenticated;
grant execute on function public.is_conversation_participant(uuid) to authenticated;
grant execute on function public.can_access_conversation_topic(text) to authenticated;

create or replace function public.is_match_participant(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.match_participants as mp
    where mp.match_id = p_match_id
      and mp.player_id = auth.uid()
  );
$$;

revoke all on function public.is_match_participant(uuid) from public, anon;
grant execute on function public.is_match_participant(uuid) to authenticated;

-- Crear un equipo crea su capitán y la conversación de equipo.
create or replace function public.initialize_team()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conversation_id uuid;
begin
  insert into public.team_members (team_id, player_id, role)
  values (new.id, new.created_by, 'captain');

  insert into public.conversations (channel_type, team_id, created_by)
  values ('team', new.id, new.created_by)
  returning id into v_conversation_id;

  insert into public.conversation_participants (conversation_id, player_id)
  values (v_conversation_id, new.created_by);

  return new;
end;
$$;

create trigger teams_initialize_after_insert
after insert on public.teams
for each row execute function public.initialize_team();

-- Todo nuevo miembro se incorpora al chat de su equipo.
create or replace function public.add_member_to_team_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.conversation_participants (conversation_id, player_id)
  select c.id, new.player_id
  from public.conversations as c
  where c.channel_type = 'team'
    and c.team_id = new.team_id
  on conflict do nothing;
  return new;
end;
$$;

create trigger team_member_add_to_chat
after insert on public.team_members
for each row execute function public.add_member_to_team_conversation();

create or replace function public.remove_member_from_team_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.conversation_participants as cp
  using public.conversations as c
  where c.id = cp.conversation_id
    and c.channel_type = 'team'
    and c.team_id = old.team_id
    and cp.player_id = old.player_id;
  return old;
end;
$$;

create trigger team_member_remove_from_chat
after delete on public.team_members
for each row execute function public.remove_member_from_team_conversation();

-- Una solicitud aceptada agrega al jugador a la plantilla; el trigger de
-- membresía lo agrega también a la conversación privada del equipo.
create or replace function public.apply_join_request_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status = 'accepted' then
    new.decided_at := now();
    insert into public.team_members (team_id, player_id, role)
    values (new.team_id, new.player_id, 'player')
    on conflict (team_id, player_id) do nothing;
  elsif old.status = 'pending' and new.status = 'rejected' then
    new.decided_at := now();
  else
    raise exception using
      errcode = '23514',
      message = 'JOIN_REQUEST_INVALID_TRANSITION';
  end if;
  return new;
end;
$$;

create trigger join_request_apply_decision
before update of status on public.join_requests
for each row execute function public.apply_join_request_decision();

-- Crear un partido genera una conversación match:<uuid> e incorpora como
-- participantes a los jugadores de ambas plantillas en ese momento.
create or replace function public.initialize_match()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conversation_id uuid;
begin
  insert into public.conversations (channel_type, match_id, created_by)
  values ('match', new.id, new.created_by)
  returning id into v_conversation_id;

  insert into public.match_participants (match_id, team_id, player_id)
  select new.id, tm.team_id, tm.player_id
  from public.team_members as tm
  where tm.team_id in (new.home_team_id, new.away_team_id)
  on conflict (match_id, player_id) do nothing;

  insert into public.conversation_participants (conversation_id, player_id)
  select v_conversation_id, mp.player_id
  from public.match_participants as mp
  where mp.match_id = new.id
  on conflict do nothing;

  return new;
end;
$$;

create trigger matches_initialize_after_insert
after insert on public.matches
for each row execute function public.initialize_match();

-- Solo transiciones válidas de un desafío; IDs/equipos/cancha/creador no se
-- pueden cambiar después de crear el partido.
create or replace function public.guard_match_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.home_team_id is distinct from old.home_team_id
     or new.away_team_id is distinct from old.away_team_id
     or new.field_type is distinct from old.field_type
     or new.created_by is distinct from old.created_by then
    raise exception using errcode = '23514', message = 'MATCH_IDENTITY_IMMUTABLE';
  end if;

  if old.status = 'proposed'
     and new.status in ('accepted', 'rejected')
     and public.is_team_captain(old.away_team_id) then
    new.updated_at := now();
    return new;
  end if;

  if old.status = 'accepted'
     and new.status in ('accepted', 'scheduled', 'cancelled')
     and (public.is_team_captain(old.home_team_id)
       or public.is_team_captain(old.away_team_id)) then
    new.updated_at := now();
    return new;
  end if;

  if old.status = 'scheduled'
     and new.status in ('scheduled', 'completed', 'cancelled')
     and (public.is_team_captain(old.home_team_id)
       or public.is_team_captain(old.away_team_id)) then
    new.updated_at := now();
    return new;
  end if;

  raise exception using errcode = '23514', message = 'MATCH_INVALID_TRANSITION';
end;
$$;

create trigger matches_guard_update
before update on public.matches
for each row execute function public.guard_match_update();

-- Crear un DM mediante RPC impide que un cliente agregue a terceros a una
-- conversación existente. El topic es dm:<conversation_uuid>.
create or replace function public.create_direct_conversation(p_other_player uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_conversation_id uuid;
begin
  if v_me is null then
    raise exception using errcode = '28000', message = 'AUTHENTICATION_REQUIRED';
  end if;
  if p_other_player is null or p_other_player = v_me then
    raise exception using errcode = '22023', message = 'INVALID_DIRECT_CHAT_PLAYER';
  end if;

  v_low := least(v_me, p_other_player);
  v_high := greatest(v_me, p_other_player);

  insert into public.conversations (
    channel_type, dm_user_low, dm_user_high, created_by
  )
  values ('dm', v_low, v_high, v_me)
  on conflict (dm_user_low, dm_user_high) do nothing
  returning id into v_conversation_id;

  if v_conversation_id is null then
    select c.id into v_conversation_id
    from public.conversations as c
    where c.channel_type = 'dm'
      and c.dm_user_low = v_low
      and c.dm_user_high = v_high;
  end if;

  insert into public.conversation_participants (conversation_id, player_id)
  values
    (v_conversation_id, v_low),
    (v_conversation_id, v_high)
  on conflict do nothing;

  return v_conversation_id;
end;
$$;

revoke all on function public.create_direct_conversation(uuid) from public, anon;
grant execute on function public.create_direct_conversation(uuid) to authenticated;

-- Reportes: el cliente crea un reporte propio; solo una Edge Function con
-- service_role procesa y cambia email_status. La dirección no es un secreto.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.players (id) on delete restrict,
  reported_player_id uuid not null references public.players (id) on delete restrict,
  category text not null check (
    category in (
      'conducta_antideportiva',
      'acoso_amenazas',
      'perfil_falso',
      'otro'
    )
  ),
  details text not null check (char_length(btrim(details)) between 10 and 4000),
  context text check (context is null or char_length(context) <= 1000),
  team_id uuid references public.teams (id) on delete set null,
  match_id uuid references public.matches (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  created_at timestamptz not null default now(),
  markdown_body text not null default '',
  recipient_email text not null default 'nsala932@gmail.com',
  email_status public.report_email_status not null default 'pending',
  email_attempts integer not null default 0 check (email_attempts >= 0),
  resend_id text,
  email_error text,
  sent_at timestamptz,
  constraint reports_not_self check (reporter_id <> reported_player_id)
);

create index reports_reporter_created_idx
  on public.reports (reporter_id, created_at desc);
create index reports_email_queue_idx
  on public.reports (created_at)
  where email_status in ('pending', 'failed');

-- Escapa caracteres Markdown de los campos aportados por usuarios.
create or replace function public.escape_markdown(p_value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_result text := coalesce(p_value, '');
  v_character text;
begin
  v_result := replace(v_result, E'\\', E'\\\\');
  foreach v_character in array array[
    '`', '*', '_', '{', '}', '[', ']', '(', ')', '#', '+', '-', '.',
    '!', '|', '>', '~'
  ] loop
    v_result := replace(v_result, v_character, E'\\' || v_character);
  end loop;
  return v_result;
end;
$$;

create or replace function public.prepare_report_for_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reporter_name text;
  v_reported_name text;
  v_team_name text;
begin
  select p.display_name into v_reporter_name
  from public.players as p where p.id = new.reporter_id;
  select p.display_name into v_reported_name
  from public.players as p where p.id = new.reported_player_id;
  if new.team_id is not null then
    select t.name into v_team_name
    from public.teams as t where t.id = new.team_id;
  end if;

  new.created_at := now();
  new.markdown_body := format(
    E'# Reporte de jugador — Hay Equipo\n\n' ||
    E'- **Fecha (UTC):** %s\n' ||
    E'- **Reportante:** %s (`%s`)\n' ||
    E'- **Jugador reportado:** %s (`%s`)\n' ||
    E'- **Motivo:** %s\n\n' ||
    E'## Contexto\n%s\n\n' ||
    E'## Descripción del incidente\n%s\n\n' ||
    E'## Referencias\n- Equipo: %s\n- Partido: %s\n- Conversación: %s\n',
    to_char(new.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    public.escape_markdown(coalesce(v_reporter_name, 'Jugador')),
    new.reporter_id,
    public.escape_markdown(coalesce(v_reported_name, 'Jugador')),
    new.reported_player_id,
    public.escape_markdown(new.category),
    case
      when new.context is null or btrim(new.context) = '' then '_No indicado._'
      else public.escape_markdown(new.context)
    end,
    public.escape_markdown(new.details),
    case
      when v_team_name is null then '_No indicado._'
      else public.escape_markdown(v_team_name)
    end,
    coalesce(new.match_id::text, '_No indicado._'),
    coalesce(new.conversation_id::text, '_No indicado._')
  );

  -- El cliente no puede redirigir el correo ni declarar un reporte ya enviado.
  new.recipient_email := 'nsala932@gmail.com';
  new.email_status := 'pending';
  new.email_attempts := 0;
  new.resend_id := null;
  new.email_error := null;
  new.sent_at := null;
  return new;
end;
$$;

create trigger reports_prepare_before_insert
before insert on public.reports
for each row execute function public.prepare_report_for_email();

-- Índices de acceso frecuente para listados y validaciones.
create index teams_created_by_created_idx
  on public.teams (created_by, created_at desc);
create index team_members_team_role_idx
  on public.team_members (team_id, role);
create index matches_created_by_created_idx
  on public.matches (created_by, created_at desc);

-- Vistas de perfil: el directorio expone solo nombre/UUID; teléfono y email
-- se consultan únicamente a través de la vista privada propia.
create view public.player_directory
with (security_barrier = true)
as
select p.id, p.display_name, p.created_at
from public.players as p;

create view public.my_private_player_profile
with (security_barrier = true)
as
select p.id, p.phone_number, p.email
from public.players as p
where p.id = auth.uid();

-- RLS: habilitarla en todas las tablas accesibles por PostgREST.
alter table public.players enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.join_requests enable row level security;
alter table public.matches enable row level security;
alter table public.match_participants enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Perfiles: el acceso directo solo permite al jugador leer/editar su perfil.
create policy players_select_self
on public.players for select to authenticated
using (id = (select auth.uid()));

create policy players_update_self
on public.players for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Equipos visibles para jugadores autenticados; solo el creador puede
-- actualizarlos. La membresía de capitán se crea mediante el trigger.
create policy teams_select_authenticated
on public.teams for select to authenticated
using (true);

create policy teams_insert_by_creator
on public.teams for insert to authenticated
with check (created_by = (select auth.uid()));

create policy teams_update_by_captain
on public.teams for update to authenticated
using (public.is_team_captain(id))
with check (public.is_team_captain(id));

create policy team_members_select_team
on public.team_members for select to authenticated
using (public.is_team_member(team_id));

create policy team_members_insert_by_captain
on public.team_members for insert to authenticated
with check (
  public.is_team_captain(team_id)
  and role = 'player'
  and player_id <> (select auth.uid())
);

create policy team_members_delete_by_captain
on public.team_members for delete to authenticated
using (
  public.is_team_captain(team_id)
  and role = 'player'
);

-- El jugador abre una solicitud propia; solo capitanes del equipo la leen y
-- resuelven. La aceptación agrega la membresía en el trigger anterior.
create policy join_requests_insert_self
on public.join_requests for insert to authenticated
with check (
  player_id = (select auth.uid())
  and status = 'pending'
  and not public.is_team_member(team_id)
);

create policy join_requests_select_requester_or_captain
on public.join_requests for select to authenticated
using (
  player_id = (select auth.uid())
  or public.is_team_captain(team_id)
);

create policy join_requests_update_by_captain
on public.join_requests for update to authenticated
using (
  public.is_team_captain(team_id)
  and status = 'pending'
)
with check (
  public.is_team_captain(team_id)
  and status in ('accepted', 'rejected')
);

-- Los desafíos solo los crea un integrante del equipo local. Todos los
-- participantes pueden leer; el trigger de transición valida quién responde.
create policy matches_select_participant
on public.matches for select to authenticated
using (public.is_match_participant(id));

create policy matches_insert_home_member
on public.matches for insert to authenticated
with check (
  created_by = (select auth.uid())
  and public.is_team_member(home_team_id)
);

create policy matches_update_participant
on public.matches for update to authenticated
using (public.is_match_participant(id))
with check (public.is_match_participant(id));

create policy match_participants_select_self_or_team
on public.match_participants for select to authenticated
using (
  player_id = (select auth.uid())
  or public.is_match_participant(match_id)
);

-- Solo los participantes de la conversación pueden ver sus metadatos,
-- participantes y mensajes. Los chats de equipo/partido se provisionan por
-- triggers; los DM se provisionan con create_direct_conversation().
create policy conversations_select_participant
on public.conversations for select to authenticated
using (public.is_conversation_participant(id));

create policy conversation_participants_select_member
on public.conversation_participants for select to authenticated
using (public.is_conversation_participant(conversation_id));

create policy messages_select_participant
on public.messages for select to authenticated
using (public.is_conversation_participant(conversation_id));

create policy messages_insert_participant
on public.messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and public.is_conversation_participant(conversation_id)
);

-- Reportante puede crear y consultar sus reportes. No puede cambiar el
-- Markdown, el destinatario, el resultado del correo ni el estado de envío.
create policy reports_insert_self
on public.reports for insert to authenticated
with check (
  reporter_id = (select auth.uid())
  and reported_player_id <> (select auth.uid())
  and email_status = 'pending'
);

create policy reports_select_reporter
on public.reports for select to authenticated
using (reporter_id = (select auth.uid()));

-- El contenido del Broadcast privado comparte los mismos topics persistentes:
-- dm:<conversation_uuid>, team:<conversation_uuid>, match:<conversation_uuid>.
-- realtime.messages es administrada por Supabase; no crearla ni modificarla.
create policy hay_equipo_realtime_receive
on realtime.messages for select to authenticated
using (public.can_access_conversation_topic((select realtime.topic())));

create policy hay_equipo_realtime_send
on realtime.messages for insert to authenticated
with check (public.can_access_conversation_topic((select realtime.topic())));

-- Permisos de tabla y vistas. El teléfono/email no se conceden en players;
-- el perfil privado propio se entrega mediante una vista filtrada por auth.uid().
revoke all on public.players from anon, authenticated;
grant select (id, display_name, created_at) on public.players to authenticated;
grant update (display_name) on public.players to authenticated;

grant select on public.player_directory to authenticated;
grant select on public.my_private_player_profile to authenticated;

grant select on public.teams, public.team_members, public.join_requests,
  public.matches, public.match_participants, public.conversations,
  public.conversation_participants, public.messages, public.reports
to authenticated;

grant insert (name, field_type, description, badge_color, created_by)
  on public.teams to authenticated;
grant insert (team_id, player_id, message)
  on public.join_requests to authenticated;
grant insert (
  home_team_id, away_team_id, field_type, scheduled_at, venue, created_by
) on public.matches to authenticated;
grant insert (conversation_id, sender_id, body)
  on public.messages to authenticated;
grant insert (
  reporter_id, reported_player_id, category, details, context,
  team_id, match_id, conversation_id
) on public.reports to authenticated;

grant update (name, field_type, description, badge_color)
  on public.teams to authenticated;
grant update (status)
  on public.join_requests to authenticated;
grant update (status, scheduled_at, venue)
  on public.matches to authenticated;
grant delete on public.team_members to authenticated;

-- Índices: UNIQUE en players hace atómica la unicidad telefónica; los índices
-- parciales evitan solicitudes pendientes duplicadas y aceleran la cola de
-- email. Los índices compuestos empiezan por las columnas de filtro (team,
-- player, conversation o status) y después ordenan por fecha para los feeds.

-- Ejemplo del cuerpo que la Edge Function enviará a Resend:
-- POST https://api.resend.com/emails
-- Authorization: Bearer <RESEND_API_KEY almacenada como secret de Supabase>
-- Content-Type: application/json
--
-- {
--   "from": "Hay Equipo <reportes@tu-dominio-verificado.com>",
--   "to": ["nsala932@gmail.com"],
--   "subject": "Reporte de jugador - Hay Equipo",
--   "text": "# Reporte de jugador — Hay Equipo\n\n- **Fecha (UTC):** 2026-11-19T23:11:40Z\n- **Reportante:** Jugador (`uuid-reportante`)\n- **Jugador reportado:** Jugador (`uuid-reportado`)\n- **Motivo:** conducta_antideportiva\n\n## Contexto\nPartido entre Equipo A y Equipo B\n\n## Descripción del incidente\nDescripción enviada desde la aplicación."
-- }
--
-- La Edge Function consulta reports con service_role, marca sending/sent/failed,
-- guarda resend_id/email_error y nunca expone RESEND_API_KEY al cliente móvil.
