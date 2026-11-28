-- =====================================================================
-- SmartCart · HU-20 y HU-25 · Prueba de la generación de órdenes y de las
-- calificaciones
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu20_hu25.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba. Simula sesiones
-- reales: rol `authenticated` + el id del usuario en request.jwt.claims.
--
-- Necesita en la base: un comercio APROBADO, una categoría y al menos 5
-- usuarios (el dueño de ese comercio, uno sin comercio y otros 3). Dentro de
-- la transacción el script crea: un segundo comercio (solo recogida),
-- productos con precio, una promoción, un producto agotado, el rol cliente
-- para dos usuarios y el carrito de uno de ellos.
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

-- Comprueba que una llamada falle con un mensaje que contiene [esperado].
create function public.pruebas_falla(sentencia text, esperado text, msg text)
returns void
language plpgsql as $$
begin
  begin
    execute sentencia;
  exception when others then
    if sqlerrm like '%' || esperado || '%' then
      perform public.pruebas_log('OK ' || msg || ' (' || sqlerrm || ')');
      return;
    end if;
    raise exception 'FALLO %: mensaje inesperado: %', msg, sqlerrm;
  end;
  raise exception 'FALLO %: no falló', msg;
end;
$$;

-- ── Preparación (como administrador de la base: RLS no aplica) ───────────
select
  set_config('pruebas.comercioA', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' order by c.id_comercio limit 1), ''), true),
  set_config('pruebas.duenoA', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'aprobado' order by c.id_comercio limit 1), ''), true),
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true);

-- El dueño del comercio B no puede tener ya un comercio.
select set_config('pruebas.duenoB', coalesce((
  select u.id_usuario::text from public.usuario u
   where u.id_usuario::text <> current_setting('pruebas.duenoA')
     and not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
   order by u.id_usuario limit 1), ''), true);

select
  set_config('pruebas.cli1', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text not in
           (current_setting('pruebas.duenoA'), current_setting('pruebas.duenoB'))
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.cli2', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text not in
           (current_setting('pruebas.duenoA'), current_setting('pruebas.duenoB'))
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.rep', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text not in
           (current_setting('pruebas.duenoA'), current_setting('pruebas.duenoB'))
     order by u.id_usuario limit 1 offset 2), ''), true);

do $$
declare
  v_a text := nullif(current_setting('pruebas.comercioA'), '');
  v_cat text := nullif(current_setting('pruebas.categoria'), '');
  v_rol int;
  v_b uuid;
  v_pa1 uuid; v_pa2 uuid; v_pa3 uuid; v_pb1 uuid;
begin
  if v_a is null or v_cat is null
     or '' in (current_setting('pruebas.cli1'), current_setting('pruebas.cli2'),
               current_setting('pruebas.duenoB'), current_setting('pruebas.rep')) then
    raise exception 'FALLO: faltan datos (comercio aprobado, categoría o 5 usuarios)';
  end if;

  -- Comercio A: recogida y entrega.
  update public.comercio set tipo_servicio = 'ambos'
   where id_comercio = v_a::uuid;

  -- Comercio B (de duenoB): SOLO recogida.
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  values (current_setting('pruebas.duenoB')::uuid, 'Comercio B de prueba',
          '+57 300 000 0000', 'Calle 2 # 2-2', 'Cali', '08:00', '18:00',
          'recogida', 'aprobado')
  returning id_comercio into v_b;
  perform set_config('pruebas.comercioB', v_b::text, true);

  -- Productos con precio. A: arroz 5000, aceite 12000 (promoción 10000 hoy),
  -- sal 2000 AGOTADA. B: leche 4000.
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_a::uuid, v_cat::uuid, 'Arroz de prueba HU-20') returning id_producto into v_pa1;
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_a::uuid, v_cat::uuid, 'Aceite de prueba HU-20') returning id_producto into v_pa2;
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_a::uuid, v_cat::uuid, 'Sal de prueba HU-20') returning id_producto into v_pa3;
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_b, v_cat::uuid, 'Leche de prueba HU-20') returning id_producto into v_pb1;

  insert into public.precio_producto (id_producto, precio, disponible, fuente) values
    (v_pa1, 5000, true, 'comercio'),
    (v_pa2, 12000, true, 'comercio'),
    (v_pa3, 2000, false, 'comercio'),
    (v_pb1, 4000, true, 'comercio');
  -- La promoción termina HOY en Colombia: debe valer.
  insert into public.promocion (id_producto, precio_promocional, fecha_inicio, fecha_fin)
  values (v_pa2, 10000,
          (now() at time zone 'America/Bogota')::date - 1,
          (now() at time zone 'America/Bogota')::date);

  perform set_config('pruebas.pa1', v_pa1::text, true);
  perform set_config('pruebas.pa2', v_pa2::text, true);
  perform set_config('pruebas.pa3', v_pa3::text, true);
  perform set_config('pruebas.pb1', v_pb1::text, true);

  -- cli1 y cli2 son clientes; rep NO (así también prueba a un no cliente).
  select id_rol into v_rol from public.rol where codigo = 'cliente';
  insert into public.usuario_rol (id_usuario, id_rol)
  select u::uuid, v_rol
    from unnest(array[current_setting('pruebas.cli1'), current_setting('pruebas.cli2')]) u
   where not exists (
     select 1 from public.usuario_rol ur
      where ur.id_usuario = u::uuid and ur.id_rol = v_rol);
  delete from public.usuario_rol
   where id_usuario = current_setting('pruebas.rep')::uuid and id_rol = v_rol;

  -- Estado limpio de las calificaciones de los dueños.
  update public.usuario set calificacion_promedio = null, total_calificaciones = 0
   where id_usuario in (current_setting('pruebas.duenoA')::uuid,
                        current_setting('pruebas.duenoB')::uuid,
                        current_setting('pruebas.rep')::uuid);

  -- Los clientes de prueba arrancan sin ubicación guardada.
  delete from public.ubicacion_cliente
   where id_usuario in (current_setting('pruebas.cli1')::uuid,
                        current_setting('pruebas.cli2')::uuid);

  -- Carrito de cli1: arroz x2, aceite x1 (A) y leche x3 (B).
  delete from public.carrito_item where id_usuario = current_setting('pruebas.cli1')::uuid;
  insert into public.carrito_item (id_usuario, id_producto, cantidad) values
    (current_setting('pruebas.cli1')::uuid, v_pa1, 2),
    (current_setting('pruebas.cli1')::uuid, v_pa2, 1),
    (current_setting('pruebas.cli1')::uuid, v_pb1, 3);
end $$;


-- ── HU-20 · Escenario A: lo que no debe generar órdenes (cli1) ───────────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_a text := current_setting('pruebas.comercioA');
  v_b text := current_setting('pruebas.comercioB');
  v_lineas text := format(
    '[{"id_producto":"%s","cantidad":2},{"id_producto":"%s","cantidad":1},{"id_producto":"%s","cantidad":3}]',
    current_setting('pruebas.pa1'), current_setting('pruebas.pa2'), current_setting('pruebas.pb1'));
  r record;
begin
  -- A1 (escenario 3 del backlog): un carrito vacío no genera órdenes.
  perform public.pruebas_falla(
    $q$select * from public.confirmar_compra('[]'::jsonb, '[]'::jsonb)$q$,
    'carrito está vacío', 'A1: un carrito vacío no se puede confirmar');

  -- A2: la vista previa trae el comercio, lo que ofrece y el precio de hoy.
  select * into r from public.previsualizar_compra(v_lineas::jsonb)
   where id_producto = current_setting('pruebas.pa2')::uuid;
  perform public.pruebas_ok(r.precio = 10000 and r.disponible
    and r.tipo_servicio = 'ambos',
    'A2: la vista previa usa el precio de la promoción (10000) y lo que ofrece el comercio');

  -- A3 (escenario 2): entrega en un comercio que no la ofrece.
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, %L::jsonb)$q$,
      v_lineas,
      format('[{"id_comercio":"%s","tipo":"recogida"},{"id_comercio":"%s","tipo":"entrega"}]', v_a, v_b)),
    'no ofrece entrega', 'A3: no se elige entrega en un comercio que no la ofrece');

  -- A4 (escenario 3): la entrega exige la ubicación guardada.
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, %L::jsonb)$q$,
      v_lineas,
      format('[{"id_comercio":"%s","tipo":"entrega"},{"id_comercio":"%s","tipo":"recogida"}]', v_a, v_b)),
    'Configura tu ubicación', 'A4: una entrega sin ubicación guardada se rechaza');

  -- A5: falta elegir para un comercio.
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, %L::jsonb)$q$,
      v_lineas, format('[{"id_comercio":"%s","tipo":"recogida"}]', v_a)),
    'Elige recogida o entrega', 'A5: hay que elegir recogida o entrega para cada comercio');

  -- A6: un producto agotado impide confirmar.
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, %L::jsonb)$q$,
      format('[{"id_producto":"%s","cantidad":1}]', current_setting('pruebas.pa3')),
      format('[{"id_comercio":"%s","tipo":"recogida"}]', v_a)),
    'agotados', 'A6: un producto agotado impide confirmar');

  -- A7: productos repetidos y cantidades no válidas.
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, '[]'::jsonb)$q$,
      format('[{"id_producto":"%s","cantidad":1},{"id_producto":"%s","cantidad":1}]',
             current_setting('pruebas.pa1'), current_setting('pruebas.pa1'))),
    'repetidos', 'A7: no se repite un producto');
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, '[]'::jsonb)$q$,
      format('[{"id_producto":"%s","cantidad":0}]', current_setting('pruebas.pa1'))),
    'cantidad no válida', 'A8: la cantidad va de 1 a 99');

  -- A9: nada de lo anterior dejó órdenes ni sacó productos del carrito.
  perform public.pruebas_ok(
    (select count(*) from public.compra) = 0
    and (select count(*) from public.orden) = 0
    and (select count(*) from public.carrito_item) = 3,
    'A9: los intentos fallidos no dejaron compras ni vaciaron el carrito');

  -- A10: las funciones internas no se llaman desde la app.
  begin
    perform * from public.lineas_compra('[]'::jsonb);
    raise exception 'FALLO A10: ejecutó lineas_compra directamente';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK A10: lineas_compra es interna');
  end;
end $$;


-- ── HU-20 · Escenario B: confirmar con dos comercios (cli1) ──────────────
do $$
declare
  v_a text := current_setting('pruebas.comercioA');
  v_b text := current_setting('pruebas.comercioB');
begin
  perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 5000, 'Calle 9 # 9-9, Cali');

  -- B1 (escenario 1): dos comercios → una compra con dos órdenes.
  create temp table pruebas_resultado on commit drop as
  select * from public.confirmar_compra(
    format('[{"id_producto":"%s","cantidad":2},{"id_producto":"%s","cantidad":1},{"id_producto":"%s","cantidad":3}]',
      current_setting('pruebas.pa1'), current_setting('pruebas.pa2'),
      current_setting('pruebas.pb1'))::jsonb,
    format('[{"id_comercio":"%s","tipo":"entrega"},{"id_comercio":"%s","tipo":"recogida"}]', v_a, v_b)::jsonb);

  perform public.pruebas_ok(
    (select count(*) from pruebas_resultado) = 2
    and (select count(distinct id_compra) from pruebas_resultado) = 1,
    'B1: dos comercios generan una compra con dos órdenes');

  perform public.pruebas_ok(
    (select total from pruebas_resultado where id_comercio = v_a::uuid) = 20000
    and (select total from pruebas_resultado where id_comercio = v_b::uuid) = 12000
    and (select total from public.compra) = 32000,
    'B2: los totales salen de los precios de la base (20000 + 12000 = 32000)');

  perform public.pruebas_ok(
    (select count(*) from public.orden where estado = 'generada') = 2,
    'B3: cada orden nace en estado "generada"');

  perform public.pruebas_ok(
    (select tipo_entrega from public.orden where id_comercio = v_a::uuid) = 'entrega'
    and (select direccion_entrega from public.orden where id_comercio = v_a::uuid) = 'Calle 9 # 9-9, Cali'
    and (select latitud_entrega from public.orden where id_comercio = v_a::uuid) = 3.4516
    and (select tipo_entrega from public.orden where id_comercio = v_b::uuid) = 'recogida'
    and (select direccion_entrega from public.orden where id_comercio = v_b::uuid) is null
    and (select latitud_entrega from public.orden where id_comercio = v_b::uuid) is null,
    'B4: la entrega queda con la ubicación guardada como destino; la recogida no');

  perform public.pruebas_ok(
    (select count(*) from public.orden_item) = 3
    and (select sum(precio_unitario * cantidad) from public.orden_item) = 32000,
    'B5: la orden guarda los 3 productos con su precio de ese momento');

  perform public.pruebas_ok(
    (select count(*) from public.carrito_item) = 0,
    'B6: lo comprado sale del carrito');

  perform public.pruebas_ok(
    (select count(distinct numero) from public.orden) = 2,
    'B7: cada orden tiene su número');
end $$;

reset role;

-- B8: si el comercio cambia el precio, la orden no cambia.
do $$
begin
  update public.precio_producto set precio = 9999
   where id_producto = current_setting('pruebas.pa1')::uuid;
  perform public.pruebas_ok(
    (select precio_unitario from public.orden_item
      where id_producto = current_setting('pruebas.pa1')::uuid) = 5000,
    'B8: un cambio de precio posterior no altera la orden ya generada');
end $$;


-- ── HU-20 · Escenario C: quién ve qué ────────────────────────────────────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  r record;
begin
  perform public.pruebas_ok(
    (select count(*) from public.orden) = 2
    and (select count(*) from public.orden_item) = 3
    and (select count(*) from public.compra) = 1,
    'C1: el cliente ve sus 2 órdenes, sus productos y su compra');

  -- C2: mis_ordenes pagina (límite = página + 1).
  perform public.pruebas_ok(
    (select count(*) from public.mis_ordenes()) = 2
    and (select count(*) from public.mis_ordenes(1, 0)) = 1
    and (select count(*) from public.mis_ordenes(1, 1)) = 1,
    'C2: mis_ordenes devuelve las órdenes por páginas');

  select * into r from public.mis_ordenes() limit 1;
  perform public.pruebas_ok(r.estado = 'generada' and not r.calificada_comercio
    and not r.tiene_repartidor,
    'C3: mis_ordenes marca la orden como generada, sin calificar y sin repartidor');

  -- C4: no escribe directo.
  begin
    insert into public.orden (id_compra, id_comercio, id_cliente, tipo_entrega, total)
    values (gen_random_uuid(), current_setting('pruebas.comercioA')::uuid,
            current_setting('pruebas.cli1')::uuid, 'recogida', 1);
    raise exception 'FALLO C4: un cliente insertó una orden directo';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK C4: un cliente no inserta órdenes directo');
  end;
  begin
    update public.orden set estado = 'entregada';
    raise exception 'FALLO C5: un cliente cambió el estado de una orden';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK C5: un cliente no cambia el estado de una orden');
  end;
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.orden) = 0
    and (select count(*) from public.orden_item) = 0
    and (select count(*) from public.compra) = 0
    and (select count(*) from public.mis_ordenes()) = 0,
    'C6: otro cliente no ve las órdenes ajenas');
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.duenoA'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.orden) = 1
    and (select id_comercio from public.orden) = current_setting('pruebas.comercioA')::uuid
    and (select count(*) from public.orden_item) = 2,
    'C7: el comercio solo ve las órdenes de su establecimiento y sus productos');
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.duenoB'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.orden) = 1
    and (select id_comercio from public.orden) = current_setting('pruebas.comercioB')::uuid,
    'C8: el otro comercio ve solo la suya');
end $$;

-- Quien no es cliente no puede comprar.
reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.rep'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_falla(
    format($q$select * from public.confirmar_compra(%L::jsonb, '[]'::jsonb)$q$,
      format('[{"id_producto":"%s","cantidad":1}]', current_setting('pruebas.pa1'))),
    'como cliente', 'C9: quien no es cliente no puede confirmar una compra');
end $$;


-- ── HU-25 · Calificaciones ───────────────────────────────────────────────
-- Preparación: A entregada (con repartidor) y B recogida (sin repartidor).
reset role;
do $$
begin
  update public.orden set estado = 'generada';
  update public.orden set id_repartidor = current_setting('pruebas.rep')::uuid
   where id_comercio = current_setting('pruebas.comercioA')::uuid;
end $$;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_ordenA uuid := (select id_orden from public.orden
                     where id_comercio = current_setting('pruebas.comercioA')::uuid);
begin
  perform set_config('pruebas.ordenA', v_ordenA::text, true);
  perform set_config('pruebas.ordenB', (select id_orden::text from public.orden
                     where id_comercio = current_setting('pruebas.comercioB')::uuid), true);

  -- D1: solo se califica una orden completada.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'comercio', 5, null)$q$, v_ordenA),
    'orden completada', 'D1: no se califica una orden que no está completada');
end $$;

reset role;
update public.orden set estado = 'entregada'
 where id_comercio = current_setting('pruebas.comercioA')::uuid;
update public.orden set estado = 'recogida'
 where id_comercio = current_setting('pruebas.comercioB')::uuid;

-- Antes de calificar, el comercio B está "Sin calificaciones".
do $$
begin
  perform public.pruebas_ok(
    (select total_calificaciones from public.usuario
      where id_usuario = current_setting('pruebas.duenoB')::uuid) = 0
    and (select calificacion_promedio from public.usuario
      where id_usuario = current_setting('pruebas.duenoB')::uuid) is null,
    'D2: un comercio sin calificaciones no tiene promedio (la app muestra "Sin calificaciones")');
end $$;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_a uuid := current_setting('pruebas.ordenA')::uuid;
  v_b uuid := current_setting('pruebas.ordenB')::uuid;
  r record;
begin
  -- D3 (escenario 1): 5 estrellas al comercio guarda la calificación y
  -- actualiza el promedio.
  select * into r from public.calificar_orden(v_a, 'comercio', 5, '  Excelente atención  ');
  perform public.pruebas_ok(r.promedio = 5.0 and r.total = 1,
    'D3: calificar con 5 estrellas guarda la calificación y el promedio (5.0, 1)');

  perform public.pruebas_ok(
    (select comentario from public.calificacion where id_orden = v_a and tipo = 'comercio')
      = 'Excelente atención',
    'D4: el comentario se guarda sin espacios sobrantes');

  -- D5 (escenario 2): no se califica dos veces.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'comercio', 1, null)$q$, v_a),
    'Ya calificaste', 'D5: una orden se califica una sola vez');

  -- D6: el rango va de 1 a 5.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'repartidor', 0, null)$q$, v_a),
    'de 1 a 5', 'D6: 0 estrellas no es válido');
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'repartidor', 6, null)$q$, v_a),
    'de 1 a 5', 'D7: 6 estrellas no es válido');

  -- D8: el comentario no pasa de 500 caracteres.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'repartidor', 4, %L)$q$,
      v_a, repeat('x', 501)),
    '500 caracteres', 'D8: el comentario tiene tope de 500 caracteres');

  -- D9: a quien no hubo, no se califica.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'repartidor', 4, null)$q$, v_b),
    'no tuvo repartidor', 'D9: no se califica al repartidor de una orden sin repartidor');

  -- D10: al repartidor de la orden A sí.
  select * into r from public.calificar_orden(v_a, 'repartidor', 4, null);
  perform public.pruebas_ok(r.promedio = 4.0 and r.total = 1,
    'D10: se califica al repartidor de la orden (4.0, 1)');

  -- D11: tipo inválido.
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'otro', 4, null)$q$, v_a),
    'Elige a quién', 'D11: solo se califica al comercio o al repartidor');

  -- D12: no escribe directo.
  begin
    insert into public.calificacion (id_orden, id_cliente, tipo, id_calificado, estrellas)
    values (v_b, current_setting('pruebas.cli1')::uuid, 'comercio',
            current_setting('pruebas.duenoB')::uuid, 5);
    raise exception 'FALLO D12: un cliente insertó una calificación directo';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D12: un cliente no inserta calificaciones directo');
  end;

  -- D13: mis_ordenes avisa qué ya se calificó.
  select * into r from public.mis_ordenes() where id_orden = v_a;
  perform public.pruebas_ok(r.calificada_comercio and r.calificada_repartidor
    and r.tiene_repartidor and r.estado = 'entregada',
    'D13: mis_ordenes marca la orden como calificada (comercio y repartidor)');
end $$;

-- Otro cliente no puede calificar una orden ajena.
reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_falla(
    format($q$select * from public.calificar_orden(%L::uuid, 'comercio', 5, null)$q$,
      current_setting('pruebas.ordenB')),
    'Solo el cliente de una orden', 'D14: solo el cliente de la orden puede calificarla');
end $$;

-- Un segundo pedido al comercio A, calificado con 3: el promedio es 4.0. Se
-- confirma como una alternativa de la HU-18: se compra un producto y sale del
-- carrito otro (el equivalente que el cliente tenía).
reset role;
insert into public.carrito_item (id_usuario, id_producto, cantidad)
values (current_setting('pruebas.cli1')::uuid, current_setting('pruebas.pa2')::uuid, 1);
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_orden uuid;
  r record;
begin
  select o.id_orden into v_orden from public.confirmar_compra(
    format('[{"id_producto":"%s","cantidad":1}]', current_setting('pruebas.pa1'))::jsonb,
    format('[{"id_comercio":"%s","tipo":"recogida"}]', current_setting('pruebas.comercioA'))::jsonb,
    array[current_setting('pruebas.pa2')::uuid]) o;
  perform set_config('pruebas.ordenA2', v_orden::text, true);
  perform public.pruebas_ok(
    (select count(*) from public.carrito_item) = 0,
    'B9: al confirmar una alternativa salen del carrito los productos que cubre');
end $$;

reset role;
update public.orden set estado = 'recogida'
 where id_orden = current_setting('pruebas.ordenA2')::uuid;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
declare
  r record;
begin
  select * into r from public.calificar_orden(
    current_setting('pruebas.ordenA2')::uuid, 'comercio', 3, null);
  perform public.pruebas_ok(r.promedio = 4.0 and r.total = 2,
    'D15: el promedio de 5 y 3 estrellas es 4.0 con 2 calificaciones');
end $$;

reset role;
do $$
begin
  perform public.pruebas_ok(
    (select calificacion_promedio from public.usuario
      where id_usuario = current_setting('pruebas.duenoA')::uuid) = 4.0
    and (select total_calificaciones from public.usuario
      where id_usuario = current_setting('pruebas.duenoA')::uuid) = 2,
    'D16: el promedio queda en la cuenta del comercio (lo que muestra su perfil)');
end $$;


-- El comercio no puede cambiar su propia calificación escribiendo la tabla.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.duenoA'), 'role', 'authenticated')::text, true);
set local role authenticated;
update public.usuario set calificacion_promedio = 5.0, total_calificaciones = 999
 where id_usuario = current_setting('pruebas.duenoA')::uuid;

reset role;
do $$
begin
  perform public.pruebas_ok(
    (select calificacion_promedio from public.usuario
      where id_usuario = current_setting('pruebas.duenoA')::uuid) = 4.0
    and (select total_calificaciones from public.usuario
      where id_usuario = current_setting('pruebas.duenoA')::uuid) = 2,
    'D17: nadie cambia su propia calificación escribiendo en usuario');
end $$;


-- ── HU-25 · Quién ve las calificaciones ──────────────────────────────────
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.duenoA'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.calificacion) = 2,
    'E1: el comercio ve las calificaciones que recibió');
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.duenoB'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.calificacion) = 0,
    'E2: otro comercio no ve las calificaciones ajenas');
end $$;

reset role;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text, true);
set local role authenticated;

do $$
begin
  perform public.pruebas_ok(
    (select count(*) from public.calificacion) = 0,
    'E3: otro cliente no ve calificaciones que no dio');
end $$;

reset role;


-- ── Resultado ────────────────────────────────────────────────────────────
-- Una fila por prueba. Si alguna falló, la ejecución se detuvo antes con un
-- error "FALLO ...".
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
