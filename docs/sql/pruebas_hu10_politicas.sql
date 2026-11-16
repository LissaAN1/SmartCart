-- =====================================================================
-- SmartCart · HU-10 · Prueba de las políticas de permisos de producto
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu10.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba (el SQL Editor no
-- muestra los RAISE NOTICE, por eso las anotamos y las devolvemos).
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un comercio APROBADO, un comercio PENDIENTE (de otro
-- dueño) y la tabla categoria con al menos una fila. Si falta algo, la
-- prueba correspondiente se salta y aparece como "SALTADA".
-- =====================================================================

begin;

-- Anota un resultado en una variable de la transacción. Se crea aquí dentro,
-- así que el ROLLBACK final la elimina y no queda nada en la base.
create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- Ids de prueba, leídos antes de cambiar de rol (cuando RLS no aplica).
-- Cadena vacía = no se encontró.
select
  set_config('pruebas.comercio_aprobado', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.dueno_aprobado', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.comercio_pendiente', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'pendiente' limit 1), ''), true),
  set_config('pruebas.dueno_pendiente', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'pendiente' limit 1), ''), true),
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true);

-- Un usuario que no es dueño del comercio aprobado.
select set_config('pruebas.otro_usuario', coalesce((
  select u.id_usuario::text from public.usuario u
   where u.id_usuario::text <> current_setting('pruebas.dueno_aprobado')
   limit 1), ''), true);

-- Desde la HU-14 los colaboradores leen los productos de comercios aprobados
-- (política producto_select_colaborador, para elegir qué reportar). Si este
-- "otro usuario" tiene ese rol, la prueba lo vería y fallaría sin que haya un
-- error de seguridad. Por eso le quitamos el rol DENTRO de la transacción (el
-- ROLLBACK final lo devuelve): queremos probar a alguien sin permiso de lectura.
delete from public.usuario_rol
 where id_usuario::text = nullif(current_setting('pruebas.otro_usuario'), '')
   and id_rol in (select id_rol from public.rol where codigo = 'colaborador');

-- Si la base no tiene ningún comercio pendiente, creamos uno temporal para
-- poder probar el escenario 2. Se crea aquí dentro, con un usuario que aún no
-- tenga comercio, y el ROLLBACK final lo elimina.
do $$
declare
  v_dueno uuid;
  v_id uuid;
begin
  if nullif(current_setting('pruebas.comercio_pendiente'), '') is not null then
    return;
  end if;

  select u.id_usuario into v_dueno
    from public.usuario u
   where not exists (
     select 1 from public.comercio c where c.id_usuario = u.id_usuario)
   limit 1;
  if v_dueno is null then
    perform public.pruebas_log('AVISO: no hay un usuario libre para crear el comercio pendiente');
    return;
  end if;

  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  values
    (v_dueno, 'Comercio pendiente de prueba', '+57 300 000 0000',
     'Calle 1 # 1-1', 'Cali', '08:00', '18:00', 'recogida', 'pendiente')
  returning id_comercio into v_id;

  perform set_config('pruebas.comercio_pendiente', v_id::text, true);
  perform set_config('pruebas.dueno_pendiente', v_dueno::text, true);
  perform public.pruebas_log('AVISO: se creó un comercio pendiente temporal para la prueba');
end $$;


-- ── Escenario A: el dueño de un comercio aprobado gestiona sus productos ──
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.dueno_aprobado'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_comercio text := nullif(current_setting('pruebas.comercio_aprobado'), '');
  v_categoria text := nullif(current_setting('pruebas.categoria'), '');
  v_id uuid;
  v_rows int;
begin
  if v_comercio is null or v_categoria is null then
    perform public.pruebas_log('SALTADA (A): falta un comercio aprobado o una categoría');
    return;
  end if;

  insert into public.producto (id_comercio, id_categoria, nombre, codigo_barras)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto de prueba', '7700000000001')
  returning id_producto into v_id;
  perform set_config('pruebas.producto', v_id::text, true);
  perform public.pruebas_log('OK A1: el dueño aprobado crea un producto');

  select count(*) into v_rows from public.producto where id_producto = v_id;
  if v_rows <> 1 then
    raise exception 'FALLO A2: el dueño no ve su propio producto';
  end if;
  perform public.pruebas_log('OK A2: el dueño ve su producto');

  update public.producto set nombre = 'Producto editado' where id_producto = v_id;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'FALLO A3: el dueño no pudo editar su producto';
  end if;
  perform public.pruebas_log('OK A3: el dueño edita su producto');

  -- No puede mover el producto a otro comercio (with check).
  if nullif(current_setting('pruebas.comercio_pendiente'), '') is null then
    perform public.pruebas_log('SALTADA (A4): no hay otro comercio al que mover el producto');
  else
    begin
      update public.producto
         set id_comercio = current_setting('pruebas.comercio_pendiente')::uuid
       where id_producto = v_id;
      raise exception 'FALLO A4: pudo mover el producto a otro comercio';
    exception when insufficient_privilege then
      perform public.pruebas_log('OK A4: no puede mover el producto a otro comercio');
    end;
  end if;
end $$;


-- ── Escenario B: el dueño de un comercio PENDIENTE no puede cargar ───────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.dueno_pendiente'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_comercio text := nullif(current_setting('pruebas.comercio_pendiente'), '');
  v_categoria text := nullif(current_setting('pruebas.categoria'), '');
begin
  if v_comercio is null or v_categoria is null then
    perform public.pruebas_log('SALTADA (B): falta un comercio pendiente o una categoría');
    return;
  end if;

  begin
    insert into public.producto (id_comercio, id_categoria, nombre)
    values (v_comercio::uuid, v_categoria::uuid, 'No debería guardarse');
    raise exception 'FALLO B1: un comercio pendiente pudo crear un producto';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B1: un comercio pendiente no puede crear productos');
  end;
end $$;


-- ── Escenario C: otro usuario no ve ni toca productos ajenos ─────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.otro_usuario'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto text := nullif(current_setting('pruebas.producto', true), '');
  v_rows int;
begin
  if current_setting('pruebas.otro_usuario') = '' or v_producto is null then
    perform public.pruebas_log('SALTADA (C): no hay otro usuario o no se creó el producto en A');
    return;
  end if;

  select count(*) into v_rows from public.producto where id_producto = v_producto::uuid;
  if v_rows <> 0 then
    raise exception 'FALLO C1: otro usuario ve un producto ajeno';
  end if;
  perform public.pruebas_log('OK C1: otro usuario no ve productos ajenos');

  update public.producto set nombre = 'Hackeado' where id_producto = v_producto::uuid;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO C2: otro usuario editó un producto ajeno';
  end if;
  perform public.pruebas_log('OK C2: otro usuario no edita productos ajenos');

  delete from public.producto where id_producto = v_producto::uuid;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO C3: otro usuario eliminó un producto ajeno';
  end if;
  perform public.pruebas_log('OK C3: otro usuario no elimina productos ajenos');
end $$;


-- ── Escenario D: sin sesión no se lee nada ───────────────────────────────
reset role;
set local role anon;

do $$
declare
  v_rows int;
begin
  select count(*) into v_rows from public.producto;
  if v_rows <> 0 then
    raise exception 'FALLO D1: una sesión anónima lee productos';
  end if;
  perform public.pruebas_log('OK D1: sin sesión no se leen productos');
end $$;


-- ── Escenario E: el dueño elimina su producto ────────────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.dueno_aprobado'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_producto text := nullif(current_setting('pruebas.producto', true), '');
  v_rows int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (E): no se creó el producto en A');
    return;
  end if;
  delete from public.producto where id_producto = v_producto::uuid;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'FALLO E1: el dueño no pudo eliminar su producto';
  end if;
  perform public.pruebas_log('OK E1: el dueño elimina su producto');
end $$;

-- ── Resultado ────────────────────────────────────────────────────────────
-- Una fila por prueba. Si ves "SALTADA", esa prueba no demostró nada: falta
-- un dato en la base. Si alguna prueba falló, la ejecución se detuvo antes
-- con un error "FALLO ...".
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
