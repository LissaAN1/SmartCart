-- =====================================================================
-- SmartCart · HU-17 · Prueba de las políticas y funciones del carrito y
-- de los favoritos
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu17.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba (el SQL Editor no
-- muestra los RAISE NOTICE, por eso las anotamos y las devolvemos).
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un comercio APROBADO, una categoría y al menos 4
-- usuarios (el dueño del comercio y otros 3). Para no depender de qué roles
-- tengan, el script crea DENTRO de la transacción:
--   · un producto en el comercio aprobado,
--   · un comercio PENDIENTE (de un usuario sin comercio) con un producto,
--   · el rol cliente para dos usuarios, y se asegura de que un tercero NO
--     lo tenga.
-- Si falta algo, la prueba correspondiente aparece como "SALTADA".
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
  set_config('pruebas.comercio', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.dueno', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true);

-- Tres usuarios distintos del dueño: dos serán clientes y uno no.
select
  set_config('pruebas.cli1', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.cli2', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.nocli', coalesce((
    select u.id_usuario::text from public.usuario u
     where u.id_usuario::text <> current_setting('pruebas.dueno')
     order by u.id_usuario limit 1 offset 2), ''), true);

do $$
declare
  v_comercio  text := nullif(current_setting('pruebas.comercio'), '');
  v_categoria text := nullif(current_setting('pruebas.categoria'), '');
  v_rol int;
  v_pend uuid;
begin
  if v_comercio is null or v_categoria is null
     or '' in (current_setting('pruebas.cli1'),
               current_setting('pruebas.cli2'),
               current_setting('pruebas.nocli')) then
    perform public.pruebas_log('AVISO: faltan datos (comercio aprobado, categoría o 4 usuarios); casi todo se saltará');
    return;
  end if;

  -- Un producto en el comercio aprobado.
  insert into public.producto (id_comercio, id_categoria, nombre, codigo_barras)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto de prueba HU-17', '7700000001701')
  returning id_producto into v_pend;
  perform set_config('pruebas.producto', v_pend::text, true);

  -- Un comercio PENDIENTE con un producto (dueño: nocli, que no tendrá rol
  -- cliente). Si nocli ya tiene un comercio, se usa ese si está pendiente.
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  select current_setting('pruebas.nocli')::uuid, 'Comercio pendiente HU-17',
         '+57 300 000 0000', 'Calle 1 # 1-1', 'Cali', '08:00', '18:00',
         'recogida', 'pendiente'
   where not exists (
     select 1 from public.comercio c
      where c.id_usuario = current_setting('pruebas.nocli')::uuid);

  select c.id_comercio into v_pend
    from public.comercio c
   where c.id_usuario = current_setting('pruebas.nocli')::uuid
     and c.estado = 'pendiente';
  if v_pend is not null then
    perform set_config('pruebas.comercio_pendiente', v_pend::text, true);
    insert into public.producto (id_comercio, id_categoria, nombre)
    values (v_pend, v_categoria::uuid, 'Producto pendiente HU-17')
    returning id_producto into v_pend;
    perform set_config('pruebas.producto_pendiente', v_pend::text, true);
  end if;

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

  perform public.pruebas_log('AVISO: datos de prueba creados dentro de la transacción');
end $$;


-- ── Escenario A: un cliente explora lo que hay ───────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_pend_prod uuid := nullif(current_setting('pruebas.producto_pendiente', true), '')::uuid;
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_pend_com uuid := nullif(current_setting('pruebas.comercio_pendiente', true), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (A): faltan datos de prueba');
    return;
  end if;

  -- A1: ve los productos de comercios aprobados con el nombre del comercio.
  -- (Se pide una página grande: por defecto la función devuelve 21 filas y
  -- la base real ya tiene más productos.)
  select count(*) into v_n from public.explorar_productos('', 100000, 0)
   where id_producto = v_producto and comercio is not null;
  if v_n <> 1 then
    raise exception 'FALLO A1: el cliente no ve un producto de un comercio aprobado';
  end if;
  perform public.pruebas_log('OK A1: el cliente explora los productos de comercios aprobados');

  -- A2: no ve los de un comercio pendiente.
  if v_pend_prod is not null then
    select count(*) into v_n from public.explorar_productos('', 100000, 0)
     where id_producto = v_pend_prod;
    if v_n <> 0 then
      raise exception 'FALLO A2: el cliente ve un producto de un comercio pendiente';
    end if;
    perform public.pruebas_log('OK A2: los productos de un comercio pendiente no aparecen');
  else
    perform public.pruebas_log('SALTADA (A2): no se pudo crear un comercio pendiente');
  end if;

  -- A3: el filtro por nombre funciona; el comodín % se trata como letra.
  select count(*) into v_n from public.explorar_productos('Producto de prueba HU-17')
   where id_producto = v_producto;
  if v_n <> 1 then
    raise exception 'FALLO A3: el filtro por nombre no encuentra el producto';
  end if;
  select count(*) into v_n from public.explorar_productos('%');
  if v_n <> 0 then
    raise exception 'FALLO A3: el comodín %% no se escapó';
  end if;
  perform public.pruebas_log('OK A3: el filtro por nombre funciona y escapa los comodines');

  -- A4: comercios aprobados sí, pendientes no.
  select count(*) into v_n from public.explorar_comercios('', 100000, 0)
   where id_comercio = v_comercio;
  if v_n <> 1 then
    raise exception 'FALLO A4: el cliente no ve un comercio aprobado';
  end if;
  if v_pend_com is not null then
    select count(*) into v_n from public.explorar_comercios('', 100000, 0)
     where id_comercio = v_pend_com;
    if v_n <> 0 then
      raise exception 'FALLO A4: el cliente ve un comercio pendiente';
    end if;
  end if;
  perform public.pruebas_log('OK A4: el cliente explora solo comercios aprobados');

  -- A5: el cliente no lee la tabla producto directamente: solo ve los
  -- productos por las funciones (A1). Así se mantiene la regla de la HU-10 y
  -- de la HU-12 (los productos son del dueño).
  select count(*) into v_n from public.producto where id_producto = v_producto;
  if v_n <> 0 then
    raise exception 'FALLO A5: el cliente lee la tabla producto directamente';
  end if;
  perform public.pruebas_log('OK A5: el cliente no lee la tabla producto, solo las funciones');
end $$;


-- ── Escenario B: el carrito ──────────────────────────────────────────────
do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_pend_prod uuid := nullif(current_setting('pruebas.producto_pendiente', true), '')::uuid;
  v_uid text := current_setting('pruebas.cli1');
  v_cant int;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (B): faltan datos de prueba');
    return;
  end if;

  -- B1: escenario 1 del backlog: agregar un producto lo deja con cantidad 1.
  v_cant := public.agregar_al_carrito(v_producto);
  if v_cant <> 1 then
    raise exception 'FALLO B1: agregar no dejó cantidad 1 (%)', v_cant;
  end if;
  perform public.pruebas_log('OK B1: agregar al carrito deja el producto con cantidad 1');

  -- B2: agregar otra vez suma 1 y no duplica la línea.
  v_cant := public.agregar_al_carrito(v_producto);
  select count(*) into v_n from public.mi_carrito() where id_producto = v_producto;
  if v_cant <> 2 or v_n <> 1 then
    raise exception 'FALLO B2: agregar dos veces no sumó o duplicó la línea (%, %)', v_cant, v_n;
  end if;
  perform public.pruebas_log('OK B2: agregar de nuevo suma 1 y mantiene una sola línea');

  -- B3: mi_carrito trae los datos del producto y el nombre del comercio.
  select count(*) into v_n from public.mi_carrito()
   where id_producto = v_producto and cantidad = 2
     and nombre = 'Producto de prueba HU-17' and comercio is not null;
  if v_n <> 1 then
    raise exception 'FALLO B3: mi_carrito no trae los datos esperados';
  end if;
  perform public.pruebas_log('OK B3: mi_carrito trae el producto, la cantidad y el comercio');

  -- B4: escenario 2 del backlog: cambiar la cantidad actualiza el carrito.
  update public.carrito_item set cantidad = 5 where id_producto = v_producto;
  get diagnostics v_n = row_count;
  if v_n <> 1 or (select cantidad from public.mi_carrito() where id_producto = v_producto) <> 5 then
    raise exception 'FALLO B4: no se pudo cambiar la cantidad';
  end if;
  perform public.pruebas_log('OK B4: el cliente cambia la cantidad de un producto');

  -- B5: la cantidad debe estar entre 1 y 99.
  begin
    update public.carrito_item set cantidad = 0 where id_producto = v_producto;
    raise exception 'FALLO B5: aceptó cantidad 0';
  exception when check_violation then
    perform public.pruebas_log('OK B5a: una cantidad de 0 se rechaza');
  end;
  begin
    update public.carrito_item set cantidad = 100 where id_producto = v_producto;
    raise exception 'FALLO B5: aceptó cantidad 100';
  exception when check_violation then
    perform public.pruebas_log('OK B5b: una cantidad de 100 se rechaza');
  end;

  -- B6: no se puede mover la línea a otro producto ni insertar directo.
  begin
    update public.carrito_item set id_producto = gen_random_uuid()
     where id_producto = v_producto;
    raise exception 'FALLO B6: cambió el producto de una línea';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B6a: no se puede cambiar el producto de una línea');
  end;
  begin
    insert into public.carrito_item (id_usuario, id_producto, cantidad)
    values (v_uid::uuid, v_producto, 1);
    raise exception 'FALLO B6: insertó una línea saltándose la función';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B6b: no se inserta en el carrito saltándose la función');
  end;

  -- B7: el máximo de 99 unidades por producto.
  update public.carrito_item set cantidad = 99 where id_producto = v_producto;
  begin
    perform public.agregar_al_carrito(v_producto);
    raise exception 'FALLO B7: pasó de 99 unidades';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like '%99 unidades%' then
      raise exception 'FALLO B7: mensaje inesperado: %', sqlerrm;
    end if;
    perform public.pruebas_log('OK B7: no pasa de 99 unidades por producto');
  end;

  -- B8: un producto de un comercio pendiente no se puede agregar.
  if v_pend_prod is not null then
    begin
      perform public.agregar_al_carrito(v_pend_prod);
      raise exception 'FALLO B8: agregó un producto de un comercio pendiente';
    exception when raise_exception then
      if sqlerrm like 'FALLO%' then raise; end if;
      if sqlerrm not like '%ya no está disponible%' then
        raise exception 'FALLO B8: mensaje inesperado: %', sqlerrm;
      end if;
      perform public.pruebas_log('OK B8: un producto de un comercio pendiente no se agrega');
    end;
  else
    perform public.pruebas_log('SALTADA (B8): no se pudo crear un comercio pendiente');
  end if;

  -- B9: un producto que no existe tampoco.
  begin
    perform public.agregar_al_carrito(gen_random_uuid());
    raise exception 'FALLO B9: agregó un producto que no existe';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B9: un producto que no existe no se agrega');
  end;

  -- B10: la cantidad pedida debe ser válida.
  begin
    perform public.agregar_al_carrito(v_producto, 0);
    raise exception 'FALLO B10: aceptó agregar 0 unidades';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B10: agregar 0 unidades se rechaza');
  end;

  -- B11: quitar un producto.
  delete from public.carrito_item where id_producto = v_producto;
  get diagnostics v_n = row_count;
  select count(*) into v_cant from public.mi_carrito();
  if v_n <> 1 or v_cant <> 0 then
    raise exception 'FALLO B11: no se pudo quitar el producto (%, %)', v_n, v_cant;
  end if;
  perform public.pruebas_log('OK B11: el cliente quita un producto del carrito');
end $$;


-- ── Escenario C: otro cliente no ve ni toca el carrito ajeno ─────────────
do $$
begin
  if nullif(current_setting('pruebas.producto', true), '') is not null then
    -- cli1 deja una línea para que cli2 intente tocarla.
    perform public.agregar_al_carrito(current_setting('pruebas.producto')::uuid);
  end if;
end $$;

reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (C): faltan datos de prueba');
    return;
  end if;

  select count(*) into v_n from public.mi_carrito();
  if v_n <> 0 then
    raise exception 'FALLO C1: otro cliente ve el carrito de alguien más';
  end if;
  select count(*) into v_n from public.carrito_item;
  if v_n <> 0 then
    raise exception 'FALLO C1: otro cliente lee líneas de carrito ajenas';
  end if;
  perform public.pruebas_log('OK C1: otro cliente no ve carritos ajenos');

  update public.carrito_item set cantidad = 7 where id_producto = v_producto;
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'FALLO C2: otro cliente cambió el carrito de alguien más';
  end if;
  delete from public.carrito_item where id_producto = v_producto;
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'FALLO C2: otro cliente borró una línea de alguien más';
  end if;
  perform public.pruebas_log('OK C2: otro cliente no modifica carritos ajenos');
end $$;


-- ── Escenario D: quien no es cliente no usa nada de esto ─────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocli'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (D): faltan datos de prueba');
    return;
  end if;

  begin
    perform public.agregar_al_carrito(v_producto);
    raise exception 'FALLO D1: alguien sin rol cliente agregó al carrito';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like 'Inicia sesión como cliente%' then
      raise exception 'FALLO D1: mensaje inesperado: %', sqlerrm;
    end if;
    perform public.pruebas_log('OK D1: sin rol cliente no se agrega al carrito');
  end;

  begin
    perform * from public.explorar_productos('');
    raise exception 'FALLO D2: alguien sin rol cliente exploró productos';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK D2: sin rol cliente no se exploran productos');
  end;

  select count(*) into v_n from public.producto where id_producto = v_producto;
  if v_n <> 0 then
    raise exception 'FALLO D3: alguien sin rol cliente lee productos de otros comercios';
  end if;
  perform public.pruebas_log('OK D3: sin rol cliente no se leen productos ajenos');

  begin
    insert into public.favorito_comercio (id_comercio) values (v_comercio);
    raise exception 'FALLO D4: alguien sin rol cliente marcó un favorito';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D4: sin rol cliente no se marcan favoritos');
  end;
end $$;


-- ── Escenario E: favoritos (escenario 3 del backlog) ─────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_pend_prod uuid := nullif(current_setting('pruebas.producto_pendiente', true), '')::uuid;
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_pend_com uuid := nullif(current_setting('pruebas.comercio_pendiente', true), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (E): faltan datos de prueba');
    return;
  end if;

  -- E1: marcar un producto (id_usuario toma el de la sesión).
  insert into public.favorito_producto (id_producto) values (v_producto);
  select count(*) into v_n from public.mis_favoritos_productos()
   where id_producto = v_producto and comercio is not null;
  if v_n <> 1 then
    raise exception 'FALLO E1: el favorito no aparece en mis_favoritos_productos';
  end if;
  perform public.pruebas_log('OK E1: el cliente guarda un producto como favorito');

  -- E2: marcar un comercio.
  insert into public.favorito_comercio (id_comercio) values (v_comercio);
  select count(*) into v_n from public.mis_favoritos_comercios() where id_comercio = v_comercio;
  if v_n <> 1 then
    raise exception 'FALLO E2: el favorito no aparece en mis_favoritos_comercios';
  end if;
  perform public.pruebas_log('OK E2: el cliente guarda un comercio como favorito');

  -- E3: no se duplica.
  begin
    insert into public.favorito_producto (id_producto) values (v_producto);
    raise exception 'FALLO E3: duplicó un favorito';
  exception when unique_violation then
    perform public.pruebas_log('OK E3: un favorito no se duplica');
  end;

  -- E4: un producto o comercio de un comercio pendiente no se marca.
  if v_pend_prod is not null then
    begin
      insert into public.favorito_producto (id_producto) values (v_pend_prod);
      raise exception 'FALLO E4: marcó un producto de un comercio pendiente';
    exception when insufficient_privilege then
      perform public.pruebas_log('OK E4a: un producto de un comercio pendiente no se marca');
    end;
    begin
      insert into public.favorito_comercio (id_comercio) values (v_pend_com);
      raise exception 'FALLO E4: marcó un comercio pendiente';
    exception when insufficient_privilege then
      perform public.pruebas_log('OK E4b: un comercio pendiente no se marca');
    end;
  else
    perform public.pruebas_log('SALTADA (E4): no se pudo crear un comercio pendiente');
  end if;

  -- E5: no se marca a nombre de otro usuario.
  begin
    insert into public.favorito_comercio (id_usuario, id_comercio)
    values (current_setting('pruebas.cli2')::uuid, v_comercio);
    raise exception 'FALLO E5: marcó un favorito a nombre de otro usuario';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK E5: no se marca un favorito a nombre de otro usuario');
  end;

  -- E6: un favorito no se edita.
  begin
    update public.favorito_producto set creado_en = now() where id_producto = v_producto;
    raise exception 'FALLO E6: editó un favorito';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK E6: un favorito no se edita');
  end;
end $$;

-- E7: otro cliente no ve ni borra los favoritos ajenos.
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (E7): faltan datos de prueba');
    return;
  end if;
  select count(*) into v_n from public.favorito_producto;
  if v_n <> 0 then
    raise exception 'FALLO E7: otro cliente ve favoritos ajenos';
  end if;
  select count(*) into v_n from public.mis_favoritos_productos();
  if v_n <> 0 then
    raise exception 'FALLO E7: el historial de otro cliente muestra favoritos ajenos';
  end if;
  delete from public.favorito_producto where id_producto = v_producto;
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'FALLO E7: otro cliente borró un favorito ajeno';
  end if;
  perform public.pruebas_log('OK E7: otro cliente no ve ni borra favoritos ajenos');
end $$;

-- E8: el cliente quita sus favoritos.
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (E8): faltan datos de prueba');
    return;
  end if;
  delete from public.favorito_producto where id_producto = v_producto;
  get diagnostics v_n = row_count;
  if v_n <> 1 then
    raise exception 'FALLO E8: no se pudo quitar un favorito de producto';
  end if;
  delete from public.favorito_comercio where id_comercio = v_comercio;
  get diagnostics v_n = row_count;
  if v_n <> 1 then
    raise exception 'FALLO E8: no se pudo quitar un favorito de comercio';
  end if;
  perform public.pruebas_log('OK E8: el cliente quita sus favoritos');
end $$;


-- ── Escenario F: sin sesión no se lee nada ───────────────────────────────
reset role;
set local role anon;

do $$
declare
  v_n int;
begin
  begin
    select count(*) into v_n from public.carrito_item;
  exception when insufficient_privilege then
    v_n := 0;
  end;
  if v_n <> 0 then
    raise exception 'FALLO F1: una sesión anónima lee carritos';
  end if;
  perform public.pruebas_log('OK F1: sin sesión no se leen carritos');
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
-- Una fila por prueba. "SALTADA" o "AVISO" significan que esa prueba no
-- demostró nada porque faltaban datos. Si alguna falló, la ejecución se
-- detuvo antes con un error "FALLO ...".
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
