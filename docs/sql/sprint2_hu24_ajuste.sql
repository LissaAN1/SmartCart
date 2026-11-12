-- =====================================================================
-- SmartCart · HU-24 · AJUSTE al esquema real
-- Reemplaza a sprint2_hu24.sql (que no coincidía con tus tablas).
-- Ejecutar en Supabase → SQL Editor del proyecto oslxqv…  Idempotente.
--
-- Esquema real tenido en cuenta:
--   comercio            → estado, estado_registro (ambas NOT NULL), motivo_rechazo, decidido_en
--   perfil_repartidor   → estado, motivo_rechazo, decidido_en
--   notificacion        → id_notificacion (bigint), id_usuario, titulo, mensaje, leida, creado_en
--                         (SIN columna `tipo`)
--
-- Crea/reemplaza:
--   1. solicitudes_pendientes(p_limit, p_offset)   ← faltaba; la lista de la app la usa
--   2. decidir_solicitud(p_tipo, p_id, p_aprobar, p_motivo)
-- Ambas usan es_administrador(), que ya existe.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Lista paginada de solicitudes pendientes (comercios + repartidores)
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
    select 'comercio'::text                               as tipo,
           c.id_comercio::text                            as id,
           c.id_usuario                                   as id_usuario,
           coalesce(c.nombre::text, '')                   as nombre,
           concat_ws(', ', c.direccion::text, c.ciudad)   as detalle,
           c.telefono::text                               as contacto
    from public.comercio c
    where c.estado = 'pendiente'
    union all
    select 'repartidor'::text,
           p.id_usuario::text,
           p.id_usuario,
           coalesce(u.nombre::text, ''),
           u.correo::text,
           u.telefono::text
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
-- 2. Aprobar / rechazar y avisar (una sola transacción)
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
       set estado         = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end,
           decidido_en    = now()
     where id_comercio::text = p_id
       and estado = 'pendiente'
    returning id_usuario, nombre::text into v_usuario, v_nombre;

    -- Mantiene al día la columna heredada `estado_registro`. Si su restricción
    -- no admite estos valores, se ignora: la app lee `estado`.
    if v_usuario is not null then
      begin
        update public.comercio
           set estado_registro = v_estado
         where id_comercio::text = p_id;
      exception when check_violation then
        null;
      end;
    end if;
  else
    update public.perfil_repartidor
       set estado         = v_estado,
           motivo_rechazo = case when p_aprobar then null else v_motivo end,
           decidido_en    = now()
     where id_usuario::text = p_id
       and estado = 'pendiente'
    returning id_usuario, null::text into v_usuario, v_nombre;
  end if;

  -- Sin fila: no existe o ya la resolvió otra persona.
  if v_usuario is null then
    raise exception 'La solicitud ya fue resuelta' using errcode = 'P0002';
  end if;

  insert into public.notificacion (id_usuario, titulo, mensaje)
  values (
    v_usuario,
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
