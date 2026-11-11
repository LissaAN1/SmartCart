-- =====================================================================
-- SmartCart · Sprint 2 · HU-24 · Aprobación de comercios y repartidores
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu06_07_08.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. es_administrador(): ¿la sesión actual tiene el rol administrador?
--   2. Políticas RLS exclusivas del administrador sobre comercio,
--      perfil_repartidor y usuario (leer y cambiar el estado).
--   3. Tabla notificacion: el aviso que recibe el solicitante.
--   4. decidir_solicitud(): aprueba o rechaza y notifica en UNA transacción.
-- Las pruebas de las políticas están en pruebas_hu24_politicas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. ¿Es administrador quien llama?
-- security definer: lee usuario_rol y rol sin depender de sus políticas
-- (si no, una política que la usa podría entrar en recursión).
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
-- Columnas para ordenar la lista y dejar registro de la decisión.
-- ---------------------------------------------------------------------
alter table public.comercio add column if not exists creado_en   timestamptz not null default now();
alter table public.comercio add column if not exists decidido_en timestamptz;

alter table public.perfil_repartidor add column if not exists motivo_rechazo text;
alter table public.perfil_repartidor add column if not exists decidido_en    timestamptz;

-- La lista de pendientes filtra por estado y ordena por fecha.
create index if not exists comercio_estado_creado_idx
  on public.comercio (estado, creado_en);
create index if not exists perfil_repartidor_estado_creado_idx
  on public.perfil_repartidor (estado, creado_en);


-- ---------------------------------------------------------------------
-- 2. Políticas del administrador
-- Las del dueño (sprint2_hu06_07_08.sql) siguen igual: el dueño solo ve lo
-- suyo y nunca puede cambiar el estado. Las políticas permisivas se suman
-- con OR, así que el administrador ve y edita todo y nadie más gana nada.
-- ---------------------------------------------------------------------
drop policy if exists comercio_select_admin on public.comercio;
create policy comercio_select_admin on public.comercio
  for select to authenticated
  using (public.es_administrador());

drop policy if exists comercio_update_admin on public.comercio;
create policy comercio_update_admin on public.comercio
  for update to authenticated
  using (public.es_administrador())
  with check (public.es_administrador());

drop policy if exists perfil_repartidor_select_admin on public.perfil_repartidor;
create policy perfil_repartidor_select_admin on public.perfil_repartidor
  for select to authenticated
  using (public.es_administrador());

drop policy if exists perfil_repartidor_update_admin on public.perfil_repartidor;
create policy perfil_repartidor_update_admin on public.perfil_repartidor
  for update to authenticated
  using (public.es_administrador())
  with check (public.es_administrador());

-- Para mostrar nombre, correo y teléfono del solicitante.
drop policy if exists usuario_select_admin on public.usuario;
create policy usuario_select_admin on public.usuario
  for select to authenticated
  using (public.es_administrador());


-- ---------------------------------------------------------------------
-- 3. Notificaciones
-- ---------------------------------------------------------------------
create table if not exists public.notificacion (
  id_notificacion bigint generated always as identity primary key,
  id_usuario      uuid not null references public.usuario (id_usuario) on delete cascade,
  titulo          text not null,
  mensaje         text not null,
  leida           boolean not null default false,
  creado_en       timestamptz not null default now()
);

create index if not exists notificacion_usuario_leida_idx
  on public.notificacion (id_usuario, leida);

alter table public.notificacion enable row level security;

drop policy if exists notificacion_select_own on public.notificacion;
create policy notificacion_select_own on public.notificacion
  for select to authenticated
  using (id_usuario = auth.uid());

-- La persona solo puede marcar como leídas las suyas (ver el grant de abajo).
drop policy if exists notificacion_update_own on public.notificacion;
create policy notificacion_update_own on public.notificacion
  for update to authenticated
  using (id_usuario = auth.uid())
  with check (id_usuario = auth.uid());

-- Solo el administrador crea notificaciones (las de la decisión).
drop policy if exists notificacion_insert_admin on public.notificacion;
create policy notificacion_insert_admin on public.notificacion
  for insert to authenticated
  with check (public.es_administrador());

-- Del update, el dueño solo puede tocar la columna `leida`.
revoke update on public.notificacion from authenticated;
grant select, insert on public.notificacion to authenticated;
grant update (leida) on public.notificacion to authenticated;


-- ---------------------------------------------------------------------
-- 4. Aprobar o rechazar una solicitud
-- security invoker: corre con los permisos de quien llama, así que las
-- políticas RLS de arriba se aplican igual. La comprobación inicial solo
-- da un error claro en vez de "0 filas actualizadas".
--   p_tipo   'comercio' | 'repartidor'
--   p_id     id_comercio (comercio) o id_usuario (repartidor)
--   p_motivo obligatorio al rechazar
-- Errores: 42501 sin permiso · 22023 dato inválido · P0002 ya no está pendiente
-- ---------------------------------------------------------------------
create or replace function public.decidir_solicitud(
  p_tipo    text,
  p_id      text,
  p_aprobar boolean,
  p_motivo  text default null
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_motivo  text := nullif(btrim(coalesce(p_motivo, '')), '');
  v_estado  text := case when p_aprobar then 'aprobado' else 'rechazado' end;
  v_usuario uuid;
  v_nombre  text;
  v_titulo  text;
  v_mensaje text;
begin
  if not public.es_administrador() then
    raise exception 'Solo el administrador puede aprobar o rechazar solicitudes.'
      using errcode = '42501';
  end if;

  if not p_aprobar and v_motivo is null then
    raise exception 'Escribe el motivo del rechazo.' using errcode = '22023';
  end if;

  if p_tipo = 'comercio' then
    update public.comercio
       set estado         = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end,
           decidido_en    = now()
     where id_comercio::text = p_id
       and estado = 'pendiente'
    returning id_usuario, nombre into v_usuario, v_nombre;

    v_titulo := case when p_aprobar
      then 'Tu comercio fue aprobado'
      else 'Tu comercio no fue aprobado' end;
    v_mensaje := case when p_aprobar
      then format('%s ya puede publicar su catálogo y sus precios en SmartCart.', v_nombre)
      else format('El registro de %s fue rechazado. Motivo: %s', v_nombre, v_motivo) end;

  elsif p_tipo = 'repartidor' then
    update public.perfil_repartidor
       set estado         = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end,
           decidido_en    = now()
     where id_usuario::text = p_id
       and estado = 'pendiente'
    returning id_usuario into v_usuario;

    v_titulo := case when p_aprobar
      then 'Tu registro de repartidor fue aprobado'
      else 'Tu registro de repartidor no fue aprobado' end;
    v_mensaje := case when p_aprobar
      then 'Ya puedes activar tu disponibilidad y recibir solicitudes de entrega.'
      else format('Motivo: %s', v_motivo) end;

  else
    raise exception 'Tipo de solicitud desconocido: %', p_tipo using errcode = '22023';
  end if;

  -- No existe, otro administrador ya la decidió o RLS no dejó actualizarla.
  if v_usuario is null then
    raise exception 'La solicitud ya no está pendiente.' using errcode = 'P0002';
  end if;

  insert into public.notificacion (id_usuario, titulo, mensaje)
  values (v_usuario, v_titulo, v_mensaje);
end;
$$;

revoke all on function public.decidir_solicitud(text, text, boolean, text) from public;
grant execute on function public.decidir_solicitud(text, text, boolean, text) to authenticated;
