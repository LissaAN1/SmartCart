-- =====================================================================
-- SmartCart · HU-28 · Prueba de las estadísticas del panel
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu28.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba. Simula sesiones
-- reales: rol `authenticated` + el id del usuario en request.jwt.claims.
--
-- Compara cada cifra con el conteo de su tabla. Necesita en la base al
-- menos 3 usuarios, uno de ellos sin comercio. Dentro de la transacción da
-- el rol administrador a un usuario, se lo quita a otro, crea un comercio
-- pendiente y órdenes de prueba, y al final borra las órdenes para probar el
-- panel sin ellas.
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

create function public.pruebas_ok(cond boolean, msg text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FALLO %', msg;
  end if;
  perform public.pruebas_log('OK ' || msg);
end;
$$;

-- ── Preparación (como administrador de la base: RLS no aplica) ───────────
select set_config('pruebas.dueno', coalesce((
  select u.id_usuario::text from public.usuario u
   where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
   order by u.id_usuario limit 1), ''), true);

select
  set_config('pruebas.admin', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.otro', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 1), ''), true);

do $$
declare
  v_rol int;
  v_id uuid;
begin
  if '' in (current_setting('pruebas.dueno'), current_setting('pruebas.admin'),
            current_setting('pruebas.otro')) then
    raise exception 'FALLO: faltan datos (3 usuarios, uno sin comercio)';
  end if;

  select id_rol into v_rol from public.rol where codigo = 'administrador';
  insert into public.usuario_rol (id_usuario, id_rol)
  select current_setting('pruebas.admin')::uuid, v_rol
   where not exists (
     select 1 from public.usuario_rol ur
      where ur.id_usuario = current_setting('pruebas.admin')::uuid
        and ur.id_rol = v_rol);
  delete from public.usuario_rol
   where id_usuario = current_setting('pruebas.otro')::uuid and id_rol = v_rol;

  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  values (current_setting('pruebas.dueno')::uuid, 'Comercio pendiente HU-28',
          '+57 300 000 0000', 'Calle 1 # 1-1', 'Cali', '08:00', '18:00',
          'recogida', 'pendiente')
  returning id_comercio into v_id;
  perform set_config('pruebas.comercio', v_id::text, true);

  perform set_config('request.jwt.claims', json_build_object(
    'sub', current_setting('pruebas.admin'), 'role', 'authenticated')::text, true);
end $$;


-- ── Escenario 1: las cifras salen de la base ─────────────────────────────
set local role authenticated;
select set_config('pruebas.r', public.estadisticas_panel()::text, true);
reset role;

do $$
declare
  r jsonb := current_setting('pruebas.r')::jsonb;
  v_mal int;
begin
  select count(*) into v_mal from public.rol x
   where coalesce((r -> 'usuarios_por_rol' ->> x.codigo)::int, -1)
         <> (select count(*) from public.usuario_rol ur where ur.id_rol = x.id_rol);
  perform public.pruebas_ok(v_mal = 0,
    'A1: usuarios registrados por rol coinciden con usuario_rol');

  perform public.pruebas_ok(
    coalesce((r -> 'comercios_por_estado' ->> 'aprobado')::int, 0)
      = (select count(*) from public.comercio where estado = 'aprobado')
    and coalesce((r -> 'comercios_por_estado' ->> 'pendiente')::int, 0)
      = (select count(*) from public.comercio where estado = 'pendiente')
    and coalesce((r -> 'comercios_por_estado' ->> 'rechazado')::int, 0)
      = (select count(*) from public.comercio where estado = 'rechazado'),
    'A2: comercios por estado coinciden con la tabla comercio');

  perform public.pruebas_ok(
    (r ->> 'repartidores_aprobados')::int
      = (select count(*) from public.perfil_repartidor where estado = 'aprobado')
    and (r ->> 'repartidores_en_linea')::int
      = (select count(*) from public.perfil_repartidor
          where estado = 'aprobado' and disponible),
    'A3: repartidores aprobados y en línea coinciden con perfil_repartidor');

  perform public.pruebas_ok(
    (r ->> 'solicitudes_comercio')::int
      = (select count(*) from public.comercio where estado = 'pendiente')
    and (r ->> 'solicitudes_repartidor')::int
      = (select count(*) from public.perfil_repartidor where estado = 'pendiente'),
    'A4: solicitudes pendientes de comercios y repartidores');

  perform public.pruebas_ok(
    (r ->> 'reportes_precio_pendientes')::int
      = (select count(*) from public.reporte_precio where estado = 'pendiente'),
    'A5: reportes de precio pendientes coinciden con reporte_precio');
end $$;


-- ── Escenario 2: las cifras se actualizan al aprobar ─────────────────────
set local role authenticated;
select public.decidir_solicitud(
  'comercio', current_setting('pruebas.comercio'), true, null);
select set_config('pruebas.r2', public.estadisticas_panel()::text, true);
reset role;

do $$
declare
  a jsonb := current_setting('pruebas.r')::jsonb;
  b jsonb := current_setting('pruebas.r2')::jsonb;
begin
  perform public.pruebas_ok(
    (b ->> 'solicitudes_comercio')::int = (a ->> 'solicitudes_comercio')::int - 1
    and coalesce((b -> 'comercios_por_estado' ->> 'pendiente')::int, 0)
        = (a -> 'comercios_por_estado' ->> 'pendiente')::int - 1
    and (b -> 'comercios_por_estado' ->> 'aprobado')::int
        = coalesce((a -> 'comercios_por_estado' ->> 'aprobado')::int, 0) + 1,
    'B1: al aprobar un comercio baja pendientes y sube aprobados');
end $$;


-- ── Órdenes: pedidos de hoy y por estado ─────────────────────────────────
do $$
declare
  v_compra uuid;
  v_antes_hoy int;
  v_antes_gen int;
  r jsonb;
begin
  r := public.estadisticas_panel();
  v_antes_hoy := coalesce((r -> 'ordenes' ->> 'hoy')::int, 0);
  v_antes_gen := coalesce((r -> 'ordenes' -> 'por_estado' ->> 'generada')::int, 0);

  insert into public.compra (id_cliente, total)
  values (current_setting('pruebas.otro')::uuid, 2000)
  returning id_compra into v_compra;
  -- Una de hoy y otra de hace tres días.
  insert into public.orden
    (id_compra, id_comercio, id_cliente, tipo_entrega, total, creado_en)
  values
    (v_compra, current_setting('pruebas.comercio')::uuid,
     current_setting('pruebas.otro')::uuid, 'recogida', 1000, now()),
    (v_compra, current_setting('pruebas.comercio')::uuid,
     current_setting('pruebas.otro')::uuid, 'recogida', 1000,
     now() - interval '3 days');

  r := public.estadisticas_panel();
  perform public.pruebas_ok(
    (r -> 'ordenes' ->> 'hoy')::int = v_antes_hoy + 1,
    'C1: pedidos de hoy cuenta solo las órdenes de hoy en Colombia');
  perform public.pruebas_ok(
    (r -> 'ordenes' -> 'por_estado' ->> 'generada')::int = v_antes_gen + 2
    and (r -> 'ordenes' -> 'por_estado' ->> 'generada')::int
        = (select count(*) from public.orden where estado = 'generada'),
    'C2: órdenes por estado coinciden con la tabla orden');
end $$;


-- ── Escenario 3: sin órdenes ─────────────────────────────────────────────
delete from public.orden;

do $$
begin
  perform public.pruebas_ok(
    jsonb_typeof(public.estadisticas_panel() -> 'ordenes') = 'null',
    'D1: sin órdenes no hay cifras de órdenes');
end $$;


-- ── Escenario 4: usuario sin permiso ─────────────────────────────────────
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('pruebas.otro'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  begin
    perform public.estadisticas_panel();
    raise exception 'FALLO E1: una cuenta sin rol administrador vio las estadísticas';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK E1: sin rol administrador la base lo rechaza');
end $$;

reset role;
set local role anon;

do $$
begin
  begin
    perform public.estadisticas_panel();
    raise exception 'FALLO E2: una sesión anónima vio las estadísticas';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK E2: sin sesión no se consultan');
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
