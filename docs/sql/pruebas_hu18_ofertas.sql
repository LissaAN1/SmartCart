-- =====================================================================
-- SmartCart · HU-18 · Prueba de las ofertas del carrito
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu18.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba.
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: una categoría, 3 usuarios sin comercio (dueños de
-- los comercios de prueba) y otros 3 usuarios. Dentro de la transacción
-- crea dos comercios APROBADOS (A y B) y uno PENDIENTE (P), sus productos
-- y precios, y el carrito del cliente 1:
--   · X: mismo código de barras en A (promoción vigente hasta HOY en
--     Colombia), B y P;
--   · Y: sin código, mismo nombre y marca en A y B (en B agotado);
--   · W: solo en A y sin precio.
-- Si falta algo, las pruebas aparecen como "SALTADA".
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- ── Preparación (como administrador de la base: RLS no aplica) ───────────
select
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true),
  set_config('pruebas.dueno_a', coalesce((
    select u.id_usuario::text from public.usuario u
     where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.dueno_b', coalesce((
    select u.id_usuario::text from public.usuario u
     where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.dueno_p', coalesce((
    select u.id_usuario::text from public.usuario u
     where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
     order by u.id_usuario limit 1 offset 2), ''), true),
  set_config('pruebas.cli1', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.cli2', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.nocli', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 2), ''), true);

do $$
declare
  v_cat uuid;
  v_a uuid; v_b uuid; v_p uuid;
  v_xa uuid; v_xb uuid; v_xp uuid; v_ya uuid; v_yb uuid; v_wa uuid;
  v_rol int;
  v_hoy date := (now() at time zone 'America/Bogota')::date;
begin
  if '' in (current_setting('pruebas.categoria'),
            current_setting('pruebas.dueno_a'),
            current_setting('pruebas.dueno_b'),
            current_setting('pruebas.dueno_p'),
            current_setting('pruebas.cli1'),
            current_setting('pruebas.cli2'),
            current_setting('pruebas.nocli')) then
    perform public.pruebas_log('AVISO: faltan datos (categoría, 3 usuarios sin comercio u otros 3 usuarios); todo se saltará');
    return;
  end if;
  v_cat := current_setting('pruebas.categoria')::uuid;

  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado, latitud, longitud)
  values
    (current_setting('pruebas.dueno_a')::uuid, 'Comercio A HU-18', '+57 300 000 0000',
     'Calle A', 'Cali', '08:00', '18:00', 'ambos', 'aprobado', 3.4526, -76.5320)
  returning id_comercio into v_a;
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado, latitud, longitud)
  values
    (current_setting('pruebas.dueno_b')::uuid, 'Comercio B HU-18', '+57 300 000 0000',
     'Calle B', 'Cali', '08:00', '18:00', 'recogida', 'aprobado', 3.4966, -76.5320)
  returning id_comercio into v_b;
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  values
    (current_setting('pruebas.dueno_p')::uuid, 'Comercio P HU-18', '+57 300 000 0000',
     'Calle P', 'Cali', '08:00', '18:00', 'recogida', 'pendiente')
  returning id_comercio into v_p;

  -- X: mismo código de barras en los tres.
  insert into public.producto (id_comercio, id_categoria, nombre, marca, codigo_barras)
  values (v_a, v_cat, 'Arroz HU-18', 'Marca', '7700000018001') returning id_producto into v_xa;
  insert into public.producto (id_comercio, id_categoria, nombre, marca, codigo_barras)
  values (v_b, v_cat, 'Arroz blanco HU-18', 'Marca', '7700000018001') returning id_producto into v_xb;
  insert into public.producto (id_comercio, id_categoria, nombre, marca, codigo_barras)
  values (v_p, v_cat, 'Arroz HU-18', 'Marca', '7700000018001') returning id_producto into v_xp;
  insert into public.precio_producto (id_producto, precio) values (v_xa, 5000);
  insert into public.precio_producto (id_producto, precio) values (v_xb, 4500);
  insert into public.precio_producto (id_producto, precio) values (v_xp, 3000);
  -- La promoción de X en A termina HOY (fecha de Colombia): debe valer.
  insert into public.promocion (id_producto, precio_promocional, fecha_inicio, fecha_fin)
  values (v_xa, 4000, v_hoy - 1, v_hoy);

  -- Y: sin código; mismo nombre y marca con otras mayúsculas y espacios.
  insert into public.producto (id_comercio, id_categoria, nombre, marca)
  values (v_a, v_cat, 'Yogur HU-18', 'Marca18') returning id_producto into v_ya;
  insert into public.producto (id_comercio, id_categoria, nombre, marca)
  values (v_b, v_cat, ' yogur hu-18 ', 'MARCA18') returning id_producto into v_yb;
  insert into public.precio_producto (id_producto, precio) values (v_ya, 3000);
  insert into public.precio_producto (id_producto, precio, disponible) values (v_yb, 2800, false);

  -- W: solo en A y sin precio.
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_a, v_cat, 'Producto sin precio HU-18') returning id_producto into v_wa;

  -- Roles: cli1 y cli2 con rol cliente; nocli sin él.
  select id_rol into v_rol from public.rol where codigo = 'cliente';
  insert into public.usuario_rol (id_usuario, id_rol)
  select u::uuid, v_rol
    from unnest(array[current_setting('pruebas.cli1'), current_setting('pruebas.cli2')]) u
   where not exists (
     select 1 from public.usuario_rol ur
      where ur.id_usuario = u::uuid and ur.id_rol = v_rol);
  delete from public.usuario_rol
   where id_usuario = current_setting('pruebas.nocli')::uuid and id_rol = v_rol;

  -- Carrito del cliente 1 (y el del cliente 2 vacío).
  delete from public.carrito_item
   where id_usuario in (current_setting('pruebas.cli1')::uuid,
                        current_setting('pruebas.cli2')::uuid);
  insert into public.carrito_item (id_usuario, id_producto, cantidad) values
    (current_setting('pruebas.cli1')::uuid, v_xa, 2),
    (current_setting('pruebas.cli1')::uuid, v_ya, 1),
    (current_setting('pruebas.cli1')::uuid, v_wa, 3);

  perform set_config('pruebas.a', v_a::text, true);
  perform set_config('pruebas.b', v_b::text, true);
  perform set_config('pruebas.p', v_p::text, true);
  perform set_config('pruebas.xa', v_xa::text, true);
  perform set_config('pruebas.ya', v_ya::text, true);
  perform set_config('pruebas.yb', v_yb::text, true);
  perform set_config('pruebas.wa', v_wa::text, true);
  perform public.pruebas_log('AVISO: datos de prueba creados dentro de la transacción');
end $$;


-- ── Cliente 1: las ofertas de su carrito ─────────────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_xa uuid := nullif(current_setting('pruebas.xa', true), '')::uuid;
  v_ya uuid := nullif(current_setting('pruebas.ya', true), '')::uuid;
  v_yb uuid := nullif(current_setting('pruebas.yb', true), '')::uuid;
  v_wa uuid := nullif(current_setting('pruebas.wa', true), '')::uuid;
  v_a  uuid := nullif(current_setting('pruebas.a', true), '')::uuid;
  v_b  uuid := nullif(current_setting('pruebas.b', true), '')::uuid;
  v_p  uuid := nullif(current_setting('pruebas.p', true), '')::uuid;
  v_fila record;
  v_n int;
  v_comercios uuid[];
  v_precios int[];
begin
  if v_xa is null then
    perform public.pruebas_log('SALTADA (A): faltan datos de prueba');
    return;
  end if;

  -- A1: X se reconoce por código de barras en A y B; el comercio pendiente
  -- no aparece.
  select array_agg(o.id_comercio order by o.precio), array_agg(o.precio order by o.precio)
    into v_comercios, v_precios
    from public.ofertas_del_carrito() o where o.id_linea = v_xa;
  if v_comercios is distinct from array[v_a, v_b] then
    raise exception 'FALLO A1: las ofertas de X no son las de A y B (%)', v_comercios;
  end if;
  if v_p = any(v_comercios) then
    raise exception 'FALLO A1: aparece la oferta de un comercio pendiente';
  end if;
  perform public.pruebas_log('OK A1: el mismo producto se reconoce por código de barras y solo en comercios aprobados');

  -- A2: el precio vigente de X en A es el de la promoción que termina hoy
  -- en Colombia, y las ofertas van de la más barata a la más cara.
  select * into v_fila from public.ofertas_del_carrito() o
   where o.id_linea = v_xa and o.id_comercio = v_a;
  if v_fila.precio <> 4000 or v_fila.precio_normal <> 5000 or not v_fila.en_promocion then
    raise exception 'FALLO A2: el precio de X en A es % (normal %, promoción %)',
      v_fila.precio, v_fila.precio_normal, v_fila.en_promocion;
  end if;
  if v_precios is distinct from array[4000, 4500] then
    raise exception 'FALLO A2: las ofertas no van ordenadas por precio (%)', v_precios;
  end if;
  perform public.pruebas_log('OK A2: la promoción que termina hoy (hora de Colombia) da el precio vigente');

  -- A3: la línea trae la cantidad del carrito y las coordenadas del comercio.
  if v_fila.cantidad <> 2 or v_fila.latitud <> 3.4526 or v_fila.longitud <> -76.5320 then
    raise exception 'FALLO A3: cantidad % o coordenadas (%, %) inesperadas',
      v_fila.cantidad, v_fila.latitud, v_fila.longitud;
  end if;
  if v_fila.total_calificaciones is null or v_fila.total_calificaciones < 0 then
    raise exception 'FALLO A3: total_calificaciones no es un número válido';
  end if;
  perform public.pruebas_log('OK A3: cada oferta trae la cantidad, las coordenadas y la calificación del comercio');

  -- A4: Y (sin código) se reconoce por nombre y marca; la oferta agotada de
  -- B llega marcada como no disponible.
  select count(*) into v_n from public.ofertas_del_carrito() o where o.id_linea = v_ya;
  select * into v_fila from public.ofertas_del_carrito() o
   where o.id_linea = v_ya and o.id_producto = v_yb;
  if v_n <> 2 or v_fila.id_producto is null or v_fila.disponible then
    raise exception 'FALLO A4: Y tiene % ofertas o la de B no llega agotada', v_n;
  end if;
  perform public.pruebas_log('OK A4: sin código se reconoce por nombre y marca, y la oferta agotada llega marcada');

  -- A5 (escenario 5): W no tiene ninguna oferta: sale una vez, sin oferta.
  select count(*) into v_n from public.ofertas_del_carrito() o where o.id_linea = v_wa;
  select * into v_fila from public.ofertas_del_carrito() o where o.id_linea = v_wa;
  if v_n <> 1 or v_fila.id_producto is not null or v_fila.cantidad <> 3 then
    raise exception 'FALLO A5: el producto sin ofertas salió % veces o con oferta', v_n;
  end if;
  perform public.pruebas_log('OK A5: un producto sin ofertas sale una vez y sin oferta, para avisar que falta');

  -- A6: solo las líneas del carrito propio.
  select count(distinct o.id_linea) into v_n from public.ofertas_del_carrito() o;
  if v_n <> 3 then
    raise exception 'FALLO A6: se esperaban 3 líneas y salieron %', v_n;
  end if;
  perform public.pruebas_log('OK A6: salen las 3 líneas del carrito');

  -- A7: la función interna de la HU-12 no se llama directo.
  begin
    perform * from public.ofertas_publicadas();
    raise exception 'FALLO A7: un cliente llamó ofertas_publicadas() directo';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK A7: ofertas_publicadas() sigue siendo interna');
end $$;


-- ── Cliente 2: con el carrito vacío no ve el carrito ajeno ───────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_n int;
begin
  if nullif(current_setting('pruebas.xa', true), '') is null then
    perform public.pruebas_log('SALTADA (B): faltan datos de prueba');
    return;
  end if;
  select count(*) into v_n from public.ofertas_del_carrito();
  if v_n <> 0 then
    raise exception 'FALLO B1: un carrito vacío devolvió % filas', v_n;
  end if;
  perform public.pruebas_log('OK B1: un carrito vacío no devuelve nada (escenario 6) ni ve el ajeno');
end $$;


-- ── Sin rol cliente y sin sesión ─────────────────────────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocli'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
begin
  if current_setting('pruebas.nocli') = '' then
    perform public.pruebas_log('SALTADA (C): faltan datos de prueba');
    return;
  end if;
  begin
    perform * from public.ofertas_del_carrito();
    raise exception 'FALLO C1: una cuenta sin rol cliente comparó un carrito';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK C1: sin rol cliente no se comparan carritos');
end $$;

reset role;
set local role anon;

do $$
begin
  begin
    perform * from public.ofertas_del_carrito();
    raise exception 'FALLO D1: una sesión anónima comparó un carrito';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK D1: sin sesión no se compara');
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
