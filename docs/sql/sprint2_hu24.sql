-- ⚠ REEMPLAZADO por sprint2_hu24_ajuste.sql (esta versión no coincide con el esquema real: notificacion sin `tipo`, comercio con estado_registro).
-- =====================================================================
-- SmartCart · Sprint 2 · HU-24 · Aprobación de comercios y repartidores
-- Ejecutar en Supabase → SQL Editor DESPUÉS de sprint2_hu06_07_08.sql.
-- Idempotente: se puede ejecutar más de una vez.
--
-- Qué crea:
--   1. es_administrador()          → ¿la sesión actual tiene el rol administrador?
--   2. notificacion                → avisos para el solicitante (decisión)
--   3. solicitudes_pendientes()    → lista paginada de comercios + repartidores
--   4. decidir_solicitud()         → aprueba/rechaza y notifica en UNA transacción
--   5. Políticas RLS exclusivas del administrador sobre comercio y
--      perfil_repartidor.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. ¿Es administrador?  (security definer: lee usuario_rol/rol sin que las
--    políticas de esas tablas estorben)
-- ---------------------------------------------------------------------
create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_rol ur
    join public.rol r on r.id_rol = ur.id_rol
    where ur.id_usuario = auth.uid()
      and r.codigo = 'administrador'
  );
$$;

revoke all on function public.es_administrador() from public;
grant execute on function public.es_administrador() to authenticated;


-- ---------------------------------------------------------------------
-- 2. notificacion
-- ---------------------------------------------------------------------
create table if not exists public.notificacion (
  id_notificacion uuid primary key default gen_random_uuid(),
  id_usuario      uuid not null references public.usuario (id_usuario) on delete cascade,
  tipo            text not null,            -- 'aprobacion' | 'rechazo' | ...
  titulo          text not null,
  mensaje         text not null,
  leida           boolean not null default false,
  creado_en       timestamptz not null default now()
);

create index if not exists notificacion_usuario_idx
  on public.notificacion (id_usuario, creado_en desc);

alter table public.notificacion enable row level security;

-- Cada persona ve solo sus notificaciones y puede marcarlas como leídas.
drop policy if exists notificacion_select_own on public.notificacion;
create policy notificacion_select_own on public.notificacion
  for select to authenticated
  using (id_usuario = auth.uid());

drop policy if exists notificacion_update_own on public.notificacion;
create policy notificacion_update_own on public.notificacion
  for update to authenticated
  using (id_usuario = auth.uid())
  with check (id_usuario = auth.uid());

-- Nadie inserta directo: las crea decidir_solicitud() (security definer).


-- ---------------------------------------------------------------------
-- 3. Lista paginada de solicitudes pendientes
--    p_limit / p_offset los manda la app (pide una fila de más para saber
--    si hay otra página).
-- ---------------------------------------------------------------------
create or replace function public.solicitudes_pendientes(p_limit int, p_offset int)
returns table (
  tipo       text,
  id         text,
  id_usuario uuid,
  nombre     text,
  detalle    text,
  contacto   text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.es_administrador() then
    raise exception 'No tienes permiso para esta acción' using errcode = '42501';
  end if;

  return query
  select s.tipo, s.id, s.id_usuario, s.nombre, s.detalle, s.contacto
  from (
    select 'comercio'::text                                  as tipo,
           c.id_comercio::text                               as id,
           c.id_usuario                                      as id_usuario,
           coalesce(c.nombre, '')                            as nombre,
           concat_ws(', ', c.direccion, c.ciudad)            as detalle,
           c.telefono                                        as contacto
    from public.comercio c
    where c.estado = 'pendiente'
    union all
    select 'repartidor'::text,
           p.id_usuario::text,
           p.id_usuario,
           coalesce(u.nombre, ''),
           u.correo,
           u.telefono
    from public.perfil_repartidor p
    join public.usuario u on u.id_usuario = p.id_usuario
    where p.estado = 'pendiente'
  ) s
  order by s.tipo, s.nombre, s.id
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
end;
$$;

revoke all on function public.solicitudes_pendientes(int, int) from public;
grant execute on function public.solicitudes_pendientes(int, int) to authenticated;


-- ---------------------------------------------------------------------
-- 4. Aprobar o rechazar (y avisar) en una sola transacción
--    p_tipo: 'comercio' | 'repartidor'
--    p_id:   id_comercio (comercio) o id_usuario (repartidor), como texto
-- ---------------------------------------------------------------------
create or replace function public.decidir_solicitud(
  p_tipo     text,
  p_id       text,
  p_aprobar  boolean,
  p_motivo   text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario uuid;
  v_nombre  text;
  v_estado  text := case when p_aprobar then 'aprobado' else 'rechazado' end;
  v_motivo  text := nullif(btrim(coalesce(p_motivo, '')), '');
begin
  if not public.es_administrador() then
    raise exception 'No tienes permiso para esta acción' using errcode = '42501';
  end if;
  if p_tipo not in ('comercio', 'repartidor') then
    raise exception 'Tipo de solicitud no válido' using errcode = '22023';
  end if;
  if not p_aprobar and v_motivo is null then
    raise exception 'Escribe el motivo del rechazo' using errcode = '22023';
  end if;

  if p_tipo = 'comercio' then
    update public.comercio
       set estado = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end
     where id_comercio::text = p_id
       and estado = 'pendiente'
    returning id_usuario, nombre into v_usuario, v_nombre;
  else
    update public.perfil_repartidor
       set estado = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end
     where id_usuario::text = p_id
       and estado = 'pendiente'
    returning id_usuario, null::text into v_usuario, v_nombre;
  end if;

  -- Sin fila: no existe o ya la resolvió otra persona.
  if v_usuario is null then
    raise exception 'La solicitud ya fue resuelta' using errcode = 'P0002';
  end if;

  insert into public.notificacion (id_usuario, tipo, titulo, mensaje)
  values (
    v_usuario,
    case when p_aprobar then 'aprobacion' else 'rechazo' end,
    case when p_aprobar then 'Solicitud aprobada' else 'Solicitud rechazada' end,
    case
      when p_tipo = 'comercio' and p_aprobar then
        'Tu comercio ' || coalesce(v_nombre, '') || ' fue aprobado. Ya puedes publicar tu catálogo.'
      when p_tipo = 'comercio' then
        'Tu comercio ' || coalesce(v_nombre, '') || ' fue rechazado. Motivo: ' || v_motivo
      when p_aprobar then
        'Tu registro como repartidor fue aprobado. Ya puedes activar tu disponibilidad.'
      else
        'Tu registro como repartidor fue rechazado. Motivo: ' || v_motivo
    end
  );
end;
$$;

revoke all on function public.decidir_solicitud(text, text, boolean, text) from public;
grant execute on function public.decidir_solicitud(text, text, boolean, text) to authenticated;


-- ---------------------------------------------------------------------
-- 5. RLS exclusivas del administrador
--    (el dueño sigue viendo lo suyo con las políticas de HU-07/HU-08; el
--    cambio de estado solo lo hace el administrador).
-- ---------------------------------------------------------------------
drop policy if exists comercio_admin_select on public.comercio;
create policy comercio_admin_select on public.comercio
  for select to authenticated
  using (public.es_administrador());

drop policy if exists comercio_admin_update on public.comercio;
create policy comercio_admin_update on public.comercio
  for update to authenticated
  using (public.es_administrador())
  with check (public.es_administrador());

drop policy if exists perfil_repartidor_admin_select on public.perfil_repartidor;
create policy perfil_repartidor_admin_select on public.perfil_repartidor
  for select to authenticated
  using (public.es_administrador());

drop policy if exists perfil_repartidor_admin_update on public.perfil_repartidor;
create policy perfil_repartidor_admin_update on public.perfil_repartidor
  for update to authenticated
  using (public.es_administrador())
  with check (public.es_administrador());
