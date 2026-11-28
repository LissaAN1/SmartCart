-- =====================================================================
-- SmartCart · HU-23 · Prueba del seguimiento y las notificaciones
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu23.sql.
--
-- Igual que las pruebas anteriores: corre dentro de una transacción que
-- termina en ROLLBACK (no deja datos), anota "OK ..." o se detiene con
-- "FALLO ...", y al final devuelve una fila por prueba.
--
-- Necesita: un comercio APROBADO y dos usuarios (el "cliente" y "otro").
-- Las órdenes de prueba se crean aquí dentro.
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- Datos de prueba, como administrador de la base (sin RLS ni auth.uid()).
do $$
declare
  v_comercio uuid;
  v_cliente uuid;
  v_otro uuid;
  v_compra uuid;
  v_recogida uuid;
  v_entrega uuid;
  v_rows int;
begin
  select id_comercio into v_comercio from public.comercio
   where estado = 'aprobado' limit 1;
  select id_usuario into v_cliente from public.usuario
   where id_usuario not in (select id_usuario from public.comercio) limit 1;
  select id_usuario into v_otro from public.usuario
   where id_usuario <> coalesce(v_cliente, gen_random_uuid())
     and id_usuario not in (select id_usuario from public.comercio) limit 1;
  if v_comercio is null or v_cliente is null or v_otro is null then
    perform public.pruebas_log('SALTADA: falta un comercio aprobado o dos usuarios');
    return;
  end if;
  perform set_config('pruebas.cliente', v_cliente::text, true);
  perform set_config('pruebas.otro', v_otro::text, true);

  insert into public.compra (id_cliente, total) values (v_cliente, 30000)
  returning id_compra into v_compra;

  insert into public.orden (id_compra, id_comercio, id_cliente, tipo_entrega, total)
  values (v_compra, v_comercio, v_cliente, 'recogida', 20000)
  returning id_orden into v_recogida;
  insert into public.orden_item (id_orden, nombre, cantidad, precio_unitario)
  values (v_recogida, 'Arroz de prueba', 2, 10000);

  insert into public.orden (id_compra, id_comercio, id_cliente, tipo_entrega,
                            direccion_entrega, total)
  values (v_compra, v_comercio, v_cliente, 'entrega', 'Calle 1 # 2-3', 10000)
  returning id_orden into v_entrega;

  perform set_config('pruebas.recogida', v_recogida::text, true);
  perform set_config('pruebas.entrega', v_entrega::text, true);

  -- A1: al nacer, la orden empieza su historial y no avisa.
  select count(*) into v_rows from public.orden_estado where id_orden = v_recogida;
  if v_rows <> 1 then
    raise exception 'FALLO A1: la orden nueva tiene % filas de historial', v_rows;
  end if;
  select count(*) into v_rows from public.notificacion
   where id_usuario = v_cliente and titulo like '%#' || (
     select numero from public.orden where id_orden = v_recogida) || '%';
  if v_rows <> 0 then
    raise exception 'FALLO A1: crear la orden ya avisó al cliente';
  end if;
  perform public.pruebas_log('OK A1: la orden nueva registra su estado y no avisa');

  -- A2 (escenario 1): el comercio la marca "Lista para recoger" y el cliente
  -- recibe el aviso. (Aquí la cambia el administrador de la base, como la
  -- cambiaría la HU-21.)
  update public.orden set estado = 'aceptada' where id_orden = v_recogida;
  update public.orden set estado = 'lista_para_recoger' where id_orden = v_recogida;
  select count(*) into v_rows from public.orden_estado where id_orden = v_recogida;
  if v_rows <> 3 then
    raise exception 'FALLO A2: el historial tiene % filas, se esperaban 3', v_rows;
  end if;
  select count(*) into v_rows from public.notificacion
   where id_usuario = v_cliente and titulo like '%lista para recoger%';
  if v_rows < 1 then
    raise exception 'FALLO A2: el cliente no recibió el aviso de "lista para recoger"';
  end if;
  perform public.pruebas_log('OK A2: cada cambio de estado queda en el historial y avisa al cliente');

  -- Guardar el mismo estado no repite historial ni aviso.
  update public.orden set estado = 'lista_para_recoger' where id_orden = v_recogida;
  select count(*) into v_rows from public.orden_estado where id_orden = v_recogida;
  if v_rows <> 3 then
    raise exception 'FALLO A3: repetir el estado agregó historial';
  end if;
  perform public.pruebas_log('OK A3: repetir el mismo estado no duplica nada');
end $$;


-- ── Como el cliente ──────────────────────────────────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cliente', true), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_recogida uuid := nullif(current_setting('pruebas.recogida', true), '')::uuid;
  v_entrega uuid := nullif(current_setting('pruebas.entrega', true), '')::uuid;
  v_rows int;
  v_estado text;
  v_avisos_antes int;
begin
  if v_recogida is null then
    return;
  end if;

  select count(*) into v_rows from public.ordenes_cliente(true) where id_orden = v_recogida;
  if v_rows <> 1 or public.ordenes_en_curso() < 2 then
    raise exception 'FALLO B1: la orden no aparece "En curso"';
  end if;
  perform public.pruebas_log('OK B1: el cliente ve sus órdenes en curso y cuántas son');

  select count(*) into v_rows from public.detalle_orden(v_recogida);
  if v_rows <> 1 then
    raise exception 'FALLO B2: el cliente no ve el detalle de su orden';
  end if;
  select count(*) into v_rows from public.orden_estado where id_orden = v_recogida;
  if v_rows <> 3 then
    raise exception 'FALLO B2: el cliente no ve el historial de su orden';
  end if;
  perform public.pruebas_log('OK B2: el cliente ve el detalle y el historial');

  -- La orden con entrega aún no se entregó: no se puede confirmar.
  begin
    perform public.confirmar_recepcion(v_entrega);
    raise exception 'FALLO B3: confirmó una entrega que no ha llegado';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B3: no se confirma una orden que aún no llega');
  end;

  -- Confirmar la recogida cierra la orden y no se avisa a sí mismo.
  select count(*) into v_avisos_antes from public.notificacion;
  perform public.confirmar_recepcion(v_recogida);
  select estado into v_estado from public.orden where id_orden = v_recogida;
  select count(*) into v_rows from public.ordenes_cliente(false) where id_orden = v_recogida;
  if v_estado <> 'recogida' or v_rows <> 1 then
    raise exception 'FALLO B4: la orden no quedó recogida y en el historial';
  end if;
  select count(*) into v_rows from public.notificacion;
  if v_rows <> v_avisos_antes then
    raise exception 'FALLO B4: el cliente recibió un aviso por su propia confirmación';
  end if;
  perform public.pruebas_log('OK B4: confirmar la recogida la cierra y pasa al historial');

  begin
    perform public.confirmar_recepcion(v_recogida);
    raise exception 'FALLO B5: confirmó dos veces';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B5: una orden se confirma una sola vez');
  end;

  -- El cliente no puede cambiar el estado directamente. (Bloque propio: si
  -- el error se atrapara al final del bloque grande, se desharía B4.)
  begin
    update public.orden set estado = 'entregada' where id_orden = v_entrega;
    select estado into v_estado from public.orden where id_orden = v_entrega;
    if v_estado = 'entregada' then
      raise exception 'FALLO B6: el cliente cambió el estado de su orden';
    end if;
    perform public.pruebas_log('OK B6: el cliente no cambia el estado a mano');
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B6: el cliente no cambia el estado a mano');
  end;
end $$;

-- Push: registrar el dispositivo, sin poder leer la tabla.
do $$
declare
  v_rows int;
begin
  if current_setting('pruebas.cliente', true) is null then
    return;
  end if;
  perform public.registrar_dispositivo('token-de-prueba-zqx-1234567890', 'android');
  perform public.registrar_dispositivo('token-de-prueba-zqx-1234567890', 'android');
  perform public.pruebas_log('OK B7: el cliente registra su dispositivo (dos veces sin duplicar)');
  begin
    select count(*) into v_rows from public.dispositivo_push;
    raise exception 'FALLO B8: el cliente lee la tabla de dispositivos';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B8: la app no lee los tokens de nadie');
  end;
end $$;


-- ── Entrega: el repartidor la entrega y el cliente confirma ─────────────
reset role;
do $$
declare
  v_entrega uuid := nullif(current_setting('pruebas.entrega', true), '')::uuid;
  v_rows int;
begin
  if v_entrega is null then return; end if;
  update public.orden set estado = 'entregada' where id_orden = v_entrega;
  select count(*) into v_rows from public.dispositivo_push
   where token = 'token-de-prueba-zqx-1234567890'
     and id_usuario = current_setting('pruebas.cliente')::uuid;
  if v_rows <> 1 then
    raise exception 'FALLO B7: el token no quedó una sola vez';
  end if;
end $$;

select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cliente', true), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_entrega uuid := nullif(current_setting('pruebas.entrega', true), '')::uuid;
  v_cerrada timestamptz;
begin
  if v_entrega is null then return; end if;
  perform public.confirmar_recepcion(v_entrega);
  select cerrada_en into v_cerrada from public.orden where id_orden = v_entrega;
  if v_cerrada is null then
    raise exception 'FALLO B9: confirmar la recepción no cerró la orden';
  end if;
  perform public.pruebas_log('OK B9: escenario 2, confirmar la recepción cierra la orden entregada');
end $$;


-- ── Otro usuario ─────────────────────────────────────────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.otro', true), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_recogida uuid := nullif(current_setting('pruebas.recogida', true), '')::uuid;
  v_rows int;
begin
  if v_recogida is null then return; end if;
  select count(*) into v_rows from public.detalle_orden(v_recogida);
  if v_rows <> 0 then
    raise exception 'FALLO C1: otro usuario ve el detalle de una orden ajena';
  end if;
  select count(*) into v_rows from public.orden_estado where id_orden = v_recogida;
  if v_rows <> 0 then
    raise exception 'FALLO C1: otro usuario ve el historial de una orden ajena';
  end if;
  perform public.pruebas_log('OK C1: otro usuario no ve órdenes ajenas');

  begin
    perform public.confirmar_recepcion(v_recogida);
    raise exception 'FALLO C2: otro usuario confirmó una orden ajena';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK C2: otro usuario no confirma órdenes ajenas');
  end;
end $$;


-- ── Sin sesión ───────────────────────────────────────────────────────────
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

do $$
begin
  begin
    perform * from public.ordenes_cliente(true);
    raise exception 'FALLO D1: una sesión anónima pudo ver órdenes';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D1: sin sesión no se ven órdenes');
  end;
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
