-- =====================================================================
-- SmartCart · HU-15 y HU-16 · Prueba de la validación de reportes y de los
-- puntos, niveles y reputación
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu15_hu16.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba. Simula sesiones
-- reales: rol `authenticated` + el id del usuario en request.jwt.claims.
--
-- Necesita en la base: un comercio APROBADO, una categoría y al menos 4
-- usuarios (el dueño del comercio y otros 3). Dentro de la transacción el
-- script crea: coordenadas del comercio, un producto sin precio, fotos de
-- prueba en el bucket "reportes", el rol colaborador para dos usuarios (y un
-- tercero sin él) y su fila de perfil_colaborador.
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- Anota "OK" o se detiene con "FALLO".
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
select
  set_config('pruebas.comercio', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.dueno', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true);

select
  set_config('pruebas.colab1', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.colab2', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.nocolab', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 2), ''), true);

do $$
declare
  v_comercio text := nullif(current_setting('pruebas.comercio'), '');
  v_categoria text := nullif(current_setting('pruebas.categoria'), '');
  v_rol int;
  v_producto uuid;
  v_u text;
begin
  if v_comercio is null or v_categoria is null
     or '' in (current_setting('pruebas.colab1'),
               current_setting('pruebas.colab2'),
               current_setting('pruebas.nocolab')) then
    raise exception 'FALLO: faltan datos (comercio aprobado, categoría o 4 usuarios)';
  end if;

  -- Comercio en 3.4519, -76.5320.
  update public.comercio set latitud = 3.4519, longitud = -76.5320
   where id_comercio = v_comercio::uuid;

  -- Un producto SIN precio.
  insert into public.producto (id_comercio, id_categoria, nombre, codigo_barras)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto de prueba HU-15', '7700000001501')
  returning id_producto into v_producto;
  perform set_config('pruebas.producto', v_producto::text, true);
  delete from public.precio_producto where id_producto = v_producto;

  -- Roles: colab1 y colab2 con rol colaborador; nocolab sin él.
  select id_rol into v_rol from public.rol where codigo = 'colaborador';
  insert into public.usuario_rol (id_usuario, id_rol)
  select u::uuid, v_rol
    from unnest(array[current_setting('pruebas.colab1'), current_setting('pruebas.colab2')]) u
   where not exists (
     select 1 from public.usuario_rol ur
      where ur.id_usuario = u::uuid and ur.id_rol = v_rol);
  delete from public.usuario_rol
   where id_usuario = current_setting('pruebas.nocolab')::uuid and id_rol = v_rol;

  -- Perfil de colaborador de partida: 0 puntos, nivel 1, reputación 50.
  foreach v_u in array array[current_setting('pruebas.colab1'), current_setting('pruebas.colab2')] loop
    insert into public.perfil_colaborador (id_usuario, puntos_saldo, nivel, reputacion)
    values (v_u::uuid, 0, 1, 50)
    on conflict (id_usuario) do update
      set puntos_saldo = 0, nivel = 1, reputacion = 50;
    delete from public.movimiento_puntos where id_usuario = v_u::uuid;
  end loop;

  -- Fotos de prueba (la regla de evidencia comprueba que existan).
  insert into storage.objects (bucket_id, name)
  select 'reportes', current_setting('pruebas.colab1') || '/' || n || '.jpg'
    from unnest(array['ok1', 'ok2', 'ok3', 'ok4', 'ok5']) n;
  insert into storage.objects (bucket_id, name)
  select 'reportes', current_setting('pruebas.colab2') || '/' || n || '.jpg'
    from unnest(array['ok1', 'ok2']) n;
end $$;


-- ── Reglas de puntos y niveles (funciones puras, como administrador) ────
do $$
declare
  v_producto uuid := current_setting('pruebas.producto')::uuid;
begin
  perform public.pruebas_ok(public.nivel_para_puntos(0) = 1
    and public.nivel_para_puntos(99) = 1
    and public.nivel_para_puntos(100) = 2
    and public.nivel_para_puntos(499) = 2
    and public.nivel_para_puntos(500) = 3,
    'P1: niveles Nuevo (0-99), Frecuente (100-499) y Experto (500+)');

  perform public.pruebas_ok(public.puntos_para_reporte(v_producto) = 20,
    'P2: un producto sin precio da 20 puntos (10 + 10 por sin datos)');

  insert into public.precio_producto (id_producto, precio, disponible, fuente)
  values (v_producto, 4000, true, 'comercio');
  perform public.pruebas_ok(public.puntos_para_reporte(v_producto) = 10,
    'P3: un producto con precio reciente da 10 puntos');

  -- Retrocede la fecha del precio (el trigger la fija a "ahora" en cada update).
  alter table public.precio_producto disable trigger precio_producto_fecha;
  update public.precio_producto set actualizado_en = now() - interval '10 days'
   where id_producto = v_producto;
  alter table public.precio_producto enable trigger precio_producto_fecha;
  perform public.pruebas_ok(public.puntos_para_reporte(v_producto) = 15,
    'P4: un precio de más de 7 días da 15 puntos (10 + 5 por desactualizado)');

  -- Vuelve a dejar el producto sin precio para el escenario A.
  delete from public.precio_producto where id_producto = v_producto;
  delete from public.historial_precio where id_producto = v_producto;
end $$;


-- ── Escenario A: la revisión automática de un reporte (colab1) ───────────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_comercio uuid := current_setting('pruebas.comercio')::uuid;
  v_producto uuid := current_setting('pruebas.producto')::uuid;
  v_uid text := current_setting('pruebas.colab1');
  v_id uuid;
  r record;
begin
  -- A1 (escenario 1 de la HU-15): producto sin precio, desde el local y con
  -- foto: pasa a validado.
  v_id := public.enviar_reporte_precio(v_comercio, v_producto, 4900, null, false,
            v_uid || '/ok1.jpg', 3.4516, -76.5320);
  perform set_config('pruebas.r1', v_id::text, true);
  select * into r from public.mis_reportes() where id_reporte = v_id;
  perform public.pruebas_ok(r.estado = 'validado' and r.motivo is null
    and not r.requiere_confirmacion,
    'A1: un reporte que cumple ubicación, evidencia y coherencia pasa a validado');

  -- A2: un precio parecido al registrado (6 %) también se valida.
  v_id := public.enviar_reporte_precio(v_comercio, v_producto, 5200, null, false,
            v_uid || '/ok2.jpg', 3.4516, -76.5320);
  select * into r from public.mis_reportes() where id_reporte = v_id;
  perform public.pruebas_ok(r.estado = 'validado',
    'A2: un precio parecido al registrado (6 %) también se valida');

  -- A3 (escenario 2): la foto no existe → rechazado con motivo.
  v_id := public.enviar_reporte_precio(v_comercio, v_producto, 5000, null, false,
            v_uid || '/no-existe.jpg', 3.4516, -76.5320);
  select * into r from public.mis_reportes() where id_reporte = v_id;
  perform public.pruebas_ok(r.estado = 'rechazado'
    and r.motivo = 'No se encontró la foto de la etiqueta.',
    'A3: sin la foto de la etiqueta se rechaza y dice el motivo');

  -- A4 (escenario 3): precio muy distinto (73 %) → pendiente de confirmación.
  v_id := public.enviar_reporte_precio(v_comercio, v_producto, 9000, null, false,
            v_uid || '/ok3.jpg', 3.4516, -76.5320);
  perform set_config('pruebas.dudoso', v_id::text, true);
  select * into r from public.mis_reportes() where id_reporte = v_id;
  perform public.pruebas_ok(r.estado = 'pendiente' and r.requiere_confirmacion
    and r.motivo like 'El precio es muy distinto%',
    'A4: un precio muy distinto al historial queda pendiente de confirmación');

  -- A5: no puede confirmar su propio reporte.
  begin
    perform public.confirmar_reporte_colaborador(v_id, 3.4516, -76.5320);
    raise exception 'FALLO A5: confirmó su propio reporte';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_ok(sqlerrm = 'No puedes confirmar tu propio reporte.',
      'A5: el autor no puede confirmar su propio reporte');
  end;

  -- A6: su historial de puntos trae solo lo suyo, con 2 movimientos.
  perform public.pruebas_ok(
    (select count(*) from public.mis_movimientos_puntos()) = 2,
    'A6: el historial de puntos muestra los 2 reportes validados');

  -- A7: el resumen: 30 puntos (20 + 10), nivel 1 y reputación 47
  -- (50 + 1 + 1 por los validados, - 5 por el rechazado por falso).
  select * into r from public.resumen_puntos();
  perform public.pruebas_ok(r.puntos_saldo = 30 and r.puntos_acumulados = 30
    and r.nivel = 1 and r.reputacion = 47,
    'A7: el resumen muestra 30 puntos, nivel 1 y reputación 47');
end $$;

reset role;

-- Lo que la base dejó (como administrador): precio con fuente colaborador,
-- puntos por validado, nada por rechazado, reputación y avisos.
do $$
declare
  v_producto uuid := current_setting('pruebas.producto')::uuid;
  v_colab1 uuid := current_setting('pruebas.colab1')::uuid;
  v_precio integer;
  v_fuente text;
begin
  select precio, fuente into v_precio, v_fuente
    from public.precio_producto where id_producto = v_producto;
  perform public.pruebas_ok(v_precio = 5200 and v_fuente = 'colaborador',
    'A8: el precio validado quedó en 5200 con la fuente "colaborador" (Comunidad)');

  perform public.pruebas_ok(
    (select count(*) from public.historial_precio where id_producto = v_producto) = 2,
    'A9: cada precio validado quedó en el historial');

  perform public.pruebas_ok(
    (select sum(puntos) from public.movimiento_puntos where id_usuario = v_colab1) = 30,
    'A10: solo los reportes validados dieron puntos (el rechazado y el pendiente no)');

  perform public.pruebas_ok(
    (select puntos from public.movimiento_puntos m
      join public.reporte_precio r on r.id_reporte = m.id_reporte
      where r.id_reporte = current_setting('pruebas.r1')::uuid) = 20,
    'A11: el primer reporte (producto sin datos) dio 20 puntos');

  -- El rechazo por foto falsa bajó la reputación: 52 → 47.
  perform public.pruebas_ok(
    (select reputacion from public.perfil_colaborador where id_usuario = v_colab1) = 47,
    'A12: el reporte rechazado por falso bajó la reputación (52 → 47)');

  perform public.pruebas_ok(
    (select count(*) from public.notificacion
      where id_usuario = v_colab1 and titulo = 'Reporte validado') = 2
    and (select count(*) from public.notificacion
      where id_usuario = v_colab1 and titulo = 'Reporte rechazado') = 1,
    'A13: el colaborador recibió un aviso por cada reporte validado y rechazado');

  -- El precio no cambió con el rechazado ni con el pendiente.
  perform public.pruebas_ok(v_precio = 5200,
    'A14: ni el rechazado ni el pendiente cambiaron el precio');

  -- Reportes desde lejos: la revisión lo rechazaría, y la función de envío
  -- ya lo impide antes (no llega a existir).
  perform public.pruebas_ok(
    (select count(*) from public.reporte_precio
      where id_colaborador = v_colab1 and distancia_m > 150) = 0,
    'A15: no existen reportes enviados desde más de 150 m');
end $$;


-- ── Escenario B: otro colaborador confirma el reporte dudoso (colab2) ────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_dudoso uuid := current_setting('pruebas.dudoso')::uuid;
  r record;
begin
  -- B1: lo ve entre los reportes por confirmar, con el precio registrado.
  select * into r from public.reportes_por_confirmar() where id_reporte = v_dudoso;
  perform public.pruebas_ok(r.precio = 9000 and r.precio_actual = 5200,
    'B1: el reporte dudoso aparece por confirmar (9000 contra 5200)');

  -- B2: desde lejos (≈ 1,1 km) no puede confirmar.
  begin
    perform public.confirmar_reporte_colaborador(v_dudoso, 3.4616, -76.5320);
    raise exception 'FALLO B2: confirmó desde lejos';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_ok(
      sqlerrm = 'Debes estar en el establecimiento para confirmar el precio.',
      'B2: confirmar exige estar en el establecimiento');
  end;

  -- B3: desde el local sí: el reporte pasa a validado.
  perform public.confirmar_reporte_colaborador(v_dudoso, 3.4516, -76.5320);
  perform public.pruebas_ok(
    (select count(*) from public.reportes_por_confirmar() where id_reporte = v_dudoso) = 0,
    'B3: confirmado, el reporte sale de la lista por confirmar');

  -- B4: no se puede confirmar dos veces.
  begin
    perform public.confirmar_reporte_colaborador(v_dudoso, 3.4516, -76.5320);
    raise exception 'FALLO B4: confirmó dos veces';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_ok(sqlerrm = 'Este reporte ya no necesita confirmación.',
      'B4: un reporte ya confirmado no se confirma otra vez');
  end;

  -- B5: no ve los puntos de otra persona.
  perform public.pruebas_ok(
    (select count(*) from public.movimiento_puntos
      where id_usuario = current_setting('pruebas.colab1')::uuid) = 0,
    'B5: un colaborador no ve los movimientos de puntos de otro');
end $$;

reset role;

do $$
declare
  v_producto uuid := current_setting('pruebas.producto')::uuid;
  v_colab1 uuid := current_setting('pruebas.colab1')::uuid;
begin
  perform public.pruebas_ok(
    (select precio from public.precio_producto where id_producto = v_producto) = 9000,
    'B6: al confirmarse, el precio quedó en 9000 (fuente "colaborador")');
  -- 20 + 10 + 10 por el reporte confirmado (el precio era reciente).
  perform public.pruebas_ok(
    (select sum(puntos) from public.movimiento_puntos where id_usuario = v_colab1) = 40
    and (select reputacion from public.perfil_colaborador where id_usuario = v_colab1) = 48,
    'B7: el autor ganó 10 puntos al confirmarse y su reputación subió (48)');
end $$;


-- ── Escenario C: sin el modo Colaborador (nocolab) ───────────────────────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocolab'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  begin
    perform 1 from public.reportes_por_confirmar();
    raise exception 'FALLO C1: vio reportes por confirmar sin ser colaborador';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK C1: sin el modo Colaborador no ve los reportes por confirmar');
  end;
  begin
    perform 1 from public.resumen_puntos();
    raise exception 'FALLO C2: vio puntos sin ser colaborador';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK C2: sin el modo Colaborador no ve sus puntos');
  end;
  begin
    perform public.confirmar_reporte_colaborador(
      current_setting('pruebas.dudoso')::uuid, 3.4516, -76.5320);
    raise exception 'FALLO C3: confirmó sin ser colaborador';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK C3: sin el modo Colaborador no confirma');
  end;
end $$;


-- ── Escenario D: nadie escribe directo (colab1) ──────────────────────────
reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_colab1 uuid := current_setting('pruebas.colab1')::uuid;
begin
  begin
    insert into public.movimiento_puntos (id_usuario, puntos, tipo, motivo)
    values (v_colab1, 1000, 'ajuste', 'trampa');
    raise exception 'FALLO D1: un colaborador se asignó puntos';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D1: un colaborador no puede asignarse puntos');
  end;
  begin
    update public.reporte_precio set estado = 'validado'
     where id_colaborador = v_colab1;
    raise exception 'FALLO D2: un colaborador cambió el estado de un reporte';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D2: un colaborador no cambia el estado de un reporte');
  end;
  begin
    perform public.revisar_reporte(current_setting('pruebas.dudoso')::uuid);
    raise exception 'FALLO D3: ejecutó la revisión directamente';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D3: la revisión solo la ejecutan los triggers');
  end;
end $$;


-- ── Escenario E: el comercio confirma o corrige (dueño) ──────────────────
-- Dos reportes dudosos de colab1 (el producto vale 9000 ahora).
reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_comercio uuid := current_setting('pruebas.comercio')::uuid;
  v_producto uuid := current_setting('pruebas.producto')::uuid;
  v_uid text := current_setting('pruebas.colab1');
begin
  perform set_config('pruebas.dudoso2', public.enviar_reporte_precio(
    v_comercio, v_producto, 1000, null, false, v_uid || '/ok4.jpg',
    3.4516, -76.5320)::text, true);
  perform set_config('pruebas.dudoso3', public.enviar_reporte_precio(
    v_comercio, v_producto, 20000, null, false, v_uid || '/ok5.jpg',
    3.4516, -76.5320)::text, true);
  perform public.pruebas_ok(
    (select count(*) from public.mis_reportes()
      where id_reporte in (current_setting('pruebas.dudoso2')::uuid,
                           current_setting('pruebas.dudoso3')::uuid)
        and estado = 'pendiente' and requiere_confirmacion) = 2,
    'E0: dos reportes muy distintos al precio actual quedaron por confirmar');
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.dueno'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_d2 uuid := current_setting('pruebas.dudoso2')::uuid;
  v_d3 uuid := current_setting('pruebas.dudoso3')::uuid;
begin
  perform public.pruebas_ok(
    (select count(*) from public.reportes_de_mi_comercio()
      where id_reporte in (v_d2, v_d3)) = 2,
    'E1: el dueño ve los reportes de la comunidad sobre sus productos');

  -- E2: corrige uno con un precio inválido.
  begin
    perform public.corregir_reporte_comercio(v_d2, 0);
    raise exception 'FALLO E2: corrigió con un precio inválido';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK E2: no se corrige con un precio inválido');
  end;

  -- E3: corrige el primero con 9500; confirma el segundo.
  perform public.corregir_reporte_comercio(v_d2, 9500);
  perform public.confirmar_reporte_comercio(v_d3);
  perform public.pruebas_ok(
    (select count(*) from public.reportes_de_mi_comercio()
      where id_reporte in (v_d2, v_d3)) = 0,
    'E3: corregidos o confirmados, salen de la lista del comercio');
end $$;

-- Otro colaborador (no es el dueño) no puede confirmar por el comercio.
reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  begin
    perform public.confirmar_reporte_comercio(current_setting('pruebas.dudoso')::uuid);
    raise exception 'FALLO E4: confirmó por el comercio sin ser el dueño';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK E4: solo el dueño confirma o corrige por el comercio');
  end;
end $$;

reset role;

do $$
declare
  v_producto uuid := current_setting('pruebas.producto')::uuid;
  v_colab1 uuid := current_setting('pruebas.colab1')::uuid;
  v_d2 uuid := current_setting('pruebas.dudoso2')::uuid;
  v_d3 uuid := current_setting('pruebas.dudoso3')::uuid;
  r record;
begin
  -- El último en actuar fue la confirmación del comercio: 20000.
  select precio, fuente into r from public.precio_producto where id_producto = v_producto;
  perform public.pruebas_ok(r.precio = 20000 and r.fuente = 'colaborador',
    'E5: el precio confirmado por el comercio quedó en 20000');

  perform public.pruebas_ok(
    (select estado from public.reporte_precio where id_reporte = v_d2) = 'rechazado'
    and (select motivo from public.reporte_precio where id_reporte = v_d2)
        like 'El comercio indicó que el precio correcto es $ 9500%',
    'E6: el reporte corregido por el comercio se rechaza con ese motivo');

  perform public.pruebas_ok(
    (select estado from public.reporte_precio where id_reporte = v_d3) = 'validado',
    'E7: el reporte confirmado por el comercio queda validado');

  -- La corrección del comercio no es un reporte falso: la reputación solo
  -- subió por el confirmado (48 + 1 = 49) y no bajó por el corregido.
  perform public.pruebas_ok(
    (select reputacion from public.perfil_colaborador where id_usuario = v_colab1) = 49,
    'E8: corregir no penaliza al colaborador (reputación 49)');
end $$;


-- ── Escenario F: subida de nivel ─────────────────────────────────────────
-- colab2 parte con 95 puntos acumulados (nivel 1). Un reporte validado de 10
-- puntos lo lleva a 105 y a nivel 2 (Frecuente).
do $$
begin
  insert into public.movimiento_puntos (id_usuario, puntos, tipo, motivo)
  values (current_setting('pruebas.colab2')::uuid, 95, 'reporte_validado',
          'Puntos de partida de la prueba');
  update public.perfil_colaborador set puntos_saldo = 95
   where id_usuario = current_setting('pruebas.colab2')::uuid;
end $$;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  r record;
begin
  -- El precio actual es 20000; un reporte de 20500 es coherente (2,5 %).
  perform public.enviar_reporte_precio(
    current_setting('pruebas.comercio')::uuid,
    current_setting('pruebas.producto')::uuid,
    20500, null, false,
    current_setting('pruebas.colab2') || '/ok1.jpg', 3.4516, -76.5320);

  select * into r from public.resumen_puntos();
  perform public.pruebas_ok(r.puntos_acumulados = 105 and r.nivel = 2
    and r.puntos_saldo = 105,
    'F1: al llegar a 105 puntos acumulados el nivel sube a 2 (Frecuente)');
end $$;

reset role;


-- ── Resultado ────────────────────────────────────────────────────────────
-- Una fila por prueba. Si alguna falló, la ejecución se detuvo antes con un
-- error "FALLO ...".
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
