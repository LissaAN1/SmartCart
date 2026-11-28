-- =====================================================================
-- SmartCart · Sprint 3 · HU-28 · Estadísticas reales del panel del
-- administrador
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu24.sql,
-- sprint2_hu14.sql y sprint3_hu20_hu25.sql (usa es_administrador(),
-- reporte_precio y orden).
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   estadisticas_panel(): todas las cifras del panel en una sola consulta,
--   solo para el administrador. Devuelve un objeto JSON; no devuelve datos de
--   ninguna persona, solo conteos.
-- Las pruebas están en pruebas_hu28_estadisticas.sql.
--
-- Cómo se cuenta cada cifra:
--   · Usuarios registrados por rol .. filas de usuario_rol de cada rol.
--   · Comercios por estado .......... filas de comercio por su estado.
--   · Repartidores .................. perfil_repartidor aprobados y, de
--                                     ellos, los disponibles (en línea).
--   · Pendientes .................... comercios y repartidores en estado
--                                     pendiente y reporte_precio pendientes.
--   · Órdenes ....................... pedidos de hoy (fecha de Colombia) y
--                                     órdenes por estado; null si no hay
--                                     ninguna.
-- =====================================================================

create or replace function public.estadisticas_panel()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  -- current_date va en UTC: "hoy" es el día en Colombia.
  v_hoy     date := (now() at time zone 'America/Bogota')::date;
  v_ordenes jsonb;
begin
  if not public.es_administrador() then
    raise exception 'Solo el administrador puede ver las estadísticas.'
      using errcode = '42501';
  end if;

  select case when coalesce(sum(e.cantidad), 0) = 0 then null
         else jsonb_build_object(
                'hoy', sum(e.de_hoy),
                'por_estado', jsonb_object_agg(e.estado, e.cantidad))
         end
    into v_ordenes
    from (
      select o.estado,
             count(*) as cantidad,
             count(*) filter (
               where (o.creado_en at time zone 'America/Bogota')::date = v_hoy
             ) as de_hoy
        from public.orden o
       group by o.estado
    ) e;

  return jsonb_build_object(
    'usuarios_por_rol', (
      select coalesce(jsonb_object_agg(u.codigo, u.cantidad), '{}'::jsonb)
        from (select r.codigo::text as codigo, count(ur.id_usuario) as cantidad
                from public.rol r
                left join public.usuario_rol ur on ur.id_rol = r.id_rol
               group by r.codigo) u),
    'comercios_por_estado', (
      select coalesce(jsonb_object_agg(c.estado, c.cantidad), '{}'::jsonb)
        from (select estado::text as estado, count(*) as cantidad
                from public.comercio
               where estado is not null
               group by estado) c),
    'repartidores_aprobados', (
      select count(*) from public.perfil_repartidor
       where estado = 'aprobado'),
    'repartidores_en_linea', (
      select count(*) from public.perfil_repartidor
       where estado = 'aprobado' and disponible),
    'solicitudes_comercio', (
      select count(*) from public.comercio where estado = 'pendiente'),
    'solicitudes_repartidor', (
      select count(*) from public.perfil_repartidor
       where estado = 'pendiente'),
    'reportes_precio_pendientes', (
      select count(*) from public.reporte_precio where estado = 'pendiente'),
    'ordenes', v_ordenes);
end;
$$;

revoke all on function public.estadisticas_panel() from public, anon;
grant execute on function public.estadisticas_panel() to authenticated;
