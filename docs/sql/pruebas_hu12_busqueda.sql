-- =====================================================================
-- SmartCart · HU-12 · Prueba de la búsqueda de productos
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu12.sql.
--
-- Igual que las pruebas de HU-10 y HU-11: corre dentro de una transacción
-- que termina en ROLLBACK (no deja datos), anota "OK ..." o se detiene con
-- "FALLO ...", y al final devuelve una fila por prueba.
--
-- Necesita: un comercio APROBADO, un usuario cualquiera (el "cliente") y
-- una categoría. Si hay un comercio PENDIENTE, también prueba que sus
-- productos no aparezcan.
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- Datos de prueba, creados como administrador de la base (sin RLS). El
-- nombre lleva un sufijo raro para no chocar con productos reales.
do $$
declare
  v_aprobado uuid;
  v_pendiente uuid;
  v_categoria uuid;
  v_cliente uuid;
  v_p1 uuid;
  v_p2 uuid;
  v_p3 uuid;
begin
  select id_comercio into v_aprobado from public.comercio
   where estado = 'aprobado' limit 1;
  select id_comercio into v_pendiente from public.comercio
   where estado = 'pendiente' limit 1;
  select id_categoria into v_categoria from public.categoria limit 1;
  select id_usuario into v_cliente from public.usuario limit 1;

  if v_aprobado is null or v_categoria is null or v_cliente is null then
    perform public.pruebas_log('SALTADA: falta un comercio aprobado, una categoría o un usuario');
    return;
  end if;
  perform set_config('pruebas.cliente', v_cliente::text, true);

  -- Mismo código de barras en el comercio aprobado (con precio y promoción
  -- vigente) y un producto agotado.
  insert into public.producto (id_comercio, id_categoria, nombre, marca, codigo_barras)
  values (v_aprobado, v_categoria, 'Arroz zqxprueba', 'Diana', '7709999000011')
  returning id_producto into v_p1;
  insert into public.precio_producto (id_producto, precio) values (v_p1, 5000);
  insert into public.promocion (id_producto, precio_promocional, fecha_inicio, fecha_fin)
  values (v_p1, 4200, current_date, current_date + 3);

  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_aprobado, v_categoria, 'Lenteja zqxprueba agotada')
  returning id_producto into v_p2;
  insert into public.precio_producto (id_producto, precio, disponible)
  values (v_p2, 3000, false);

  if v_pendiente is not null then
    insert into public.producto (id_comercio, id_categoria, nombre)
    values (v_pendiente, v_categoria, 'Panela zqxprueba pendiente')
    returning id_producto into v_p3;
    insert into public.precio_producto (id_producto, precio) values (v_p3, 2500);
  end if;
end $$;


-- ── Como cliente con sesión ──────────────────────────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cliente', true), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_fila record;
  v_rows int;
begin
  if current_setting('pruebas.cliente', true) is null then
    return;
  end if;

  -- Escenario 1: buscar por nombre devuelve el rango con la promoción vigente.
  select * into v_fila from public.buscar_productos('ARROZ zqxprueba');
  if v_fila.clave is null then
    raise exception 'FALLO A1: la búsqueda por nombre no encontró el producto';
  end if;
  if v_fila.precio_min <> 4200 or v_fila.establecimientos <> 1 then
    raise exception 'FALLO A1: rango % - %, establecimientos %',
      v_fila.precio_min, v_fila.precio_max, v_fila.establecimientos;
  end if;
  perform public.pruebas_log('OK A1: busca por nombre sin distinguir mayúsculas y usa la promoción vigente');

  select count(*) into v_rows from public.buscar_productos('diana');
  if v_rows < 1 then
    raise exception 'FALLO A2: la búsqueda por marca no encontró el producto';
  end if;
  perform public.pruebas_log('OK A2: busca por marca');

  -- Un producto agotado aparece, pero sin rango ni establecimientos.
  select * into v_fila from public.buscar_productos('lenteja zqxprueba');
  if v_fila.clave is null or v_fila.precio_min is not null or v_fila.establecimientos <> 0 then
    raise exception 'FALLO A3: el producto agotado no se muestra como agotado';
  end if;
  perform public.pruebas_log('OK A3: un producto agotado sale sin rango');

  -- Escenario 3: sin resultados.
  select count(*) into v_rows from public.buscar_productos('zqxprueba-no-existe');
  if v_rows <> 0 then
    raise exception 'FALLO A4: una búsqueda sin coincidencias devolvió filas';
  end if;
  select count(*) into v_rows from public.buscar_productos('   ');
  if v_rows <> 0 then
    raise exception 'FALLO A4: una búsqueda vacía devolvió filas';
  end if;
  perform public.pruebas_log('OK A4: sin coincidencias o sin texto no hay resultados');

  -- Los comodines se buscan como texto.
  select count(*) into v_rows from public.buscar_productos('%');
  if v_rows <> 0 then
    raise exception 'FALLO A5: "%%" funcionó como comodín';
  end if;
  perform public.pruebas_log('OK A5: "%" no sirve como comodín');

  -- Productos de comercios pendientes no aparecen.
  select count(*) into v_rows from public.buscar_productos('panela zqxprueba');
  if v_rows <> 0 then
    raise exception 'FALLO A6: aparece un producto de un comercio pendiente';
  end if;
  perform public.pruebas_log('OK A6: no aparecen productos de comercios pendientes');

  -- Escenario 2: al escanear, el producto con el precio de cada establecimiento.
  select * into v_fila from public.precios_de_producto('cb:7709999000011');
  if v_fila.precio is distinct from 4200 or not v_fila.en_promocion
     or v_fila.precio_normal <> 5000 then
    raise exception 'FALLO A7: el detalle no trae el precio vigente y el normal';
  end if;
  perform public.pruebas_log('OK A7: el detalle por código trae precio vigente, normal y promoción');

  -- El cliente sigue sin poder leer las tablas directamente.
  select count(*) into v_rows from public.precio_producto;
  if v_rows <> 0 then
    raise exception 'FALLO A8: un cliente lee precio_producto directamente';
  end if;
  perform public.pruebas_log('OK A8: el cliente no lee las tablas, solo las funciones');

  begin
    perform * from public.ofertas_publicadas();
    raise exception 'FALLO A9: un cliente pudo llamar la función interna';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK A9: la función interna no se puede llamar desde la app');
  end;
end $$;


-- ── Sin sesión ───────────────────────────────────────────────────────────
reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

do $$
begin
  begin
    perform * from public.buscar_productos('arroz');
    raise exception 'FALLO B1: una sesión anónima pudo buscar';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B1: sin sesión no se puede buscar');
  end;
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
