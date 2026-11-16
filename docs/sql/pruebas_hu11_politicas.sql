-- =====================================================================
-- SmartCart · HU-11 · Prueba de precios, historial y promociones
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu11.sql.
--
-- Igual que pruebas_hu10_politicas.sql: corre dentro de una transacción que
-- termina en ROLLBACK (no deja datos), anota "OK ..." o se detiene con
-- "FALLO ...", y al final devuelve una fila por prueba.
--
-- Necesita en la base: un comercio APROBADO, otro usuario cualquiera y al
-- menos una categoría. Si falta algo, la prueba aparece como "SALTADA".
-- =====================================================================

begin;

create function public.pruebas_log(msg text) returns void
language sql as $$
  select set_config(
    'pruebas.log',
    coalesce(current_setting('pruebas.log', true), '') || msg || E'\n',
    true);
$$;

-- Ids de prueba, leídos antes de cambiar de rol (cuando RLS no aplica).
select
  set_config('pruebas.comercio_aprobado', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.dueno_aprobado', coalesce((
    select c.id_usuario::text from public.comercio c
     where c.estado = 'aprobado' limit 1), ''), true),
  set_config('pruebas.categoria', coalesce((
    select k.id_categoria::text from public.categoria k limit 1), ''), true);

select set_config('pruebas.otro_usuario', coalesce((
  select u.id_usuario::text from public.usuario u
   where u.id_usuario::text <> current_setting('pruebas.dueno_aprobado')
   limit 1), ''), true);


-- ── Escenario A: el dueño aprobado gestiona precios y promociones ────────
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
  v_fuente text;
  v_fecha timestamptz;
begin
  if v_comercio is null or v_categoria is null then
    perform public.pruebas_log('SALTADA (A): falta un comercio aprobado o una categoría');
    return;
  end if;

  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto HU-11 de prueba')
  returning id_producto into v_id;
  perform set_config('pruebas.producto', v_id::text, true);

  -- Escenario 1 de la HU: actualizar un precio con fecha y fuente.
  insert into public.precio_producto (id_producto, precio) values (v_id, 2500);
  select fuente, actualizado_en into v_fuente, v_fecha
    from public.precio_producto where id_producto = v_id;
  if v_fuente <> 'comercio' or v_fecha is null then
    raise exception 'FALLO A1: el precio no guardó la fuente o la fecha';
  end if;
  perform public.pruebas_log('OK A1: el dueño registra el precio con fuente "comercio" y fecha');

  update public.precio_producto set precio = 2800 where id_producto = v_id;
  select count(*) into v_rows from public.historial_precio where id_producto = v_id;
  if v_rows <> 2 then
    raise exception 'FALLO A2: el historial tiene % filas, se esperaban 2', v_rows;
  end if;
  perform public.pruebas_log('OK A2: cada cambio de precio queda en el historial');

  -- Guardar el mismo precio no agrega otra fila al historial.
  update public.precio_producto set precio = 2800 where id_producto = v_id;
  select count(*) into v_rows from public.historial_precio where id_producto = v_id;
  if v_rows <> 2 then
    raise exception 'FALLO A3: guardar el mismo precio agregó una fila al historial';
  end if;
  perform public.pruebas_log('OK A3: guardar sin cambios no duplica el historial');

  -- Escenario 2 de la HU: marcar agotado.
  update public.precio_producto set disponible = false where id_producto = v_id;
  select count(*) into v_rows from public.historial_precio
   where id_producto = v_id and disponible = false;
  if v_rows <> 1 then
    raise exception 'FALLO A4: marcar agotado no quedó en el historial';
  end if;
  perform public.pruebas_log('OK A4: marcar agotado queda registrado');

  begin
    update public.precio_producto set precio = 0 where id_producto = v_id;
    raise exception 'FALLO A5: se guardó un precio en 0';
  exception when check_violation then
    perform public.pruebas_log('OK A5: el precio debe ser positivo');
  end;

  begin
    insert into public.historial_precio (id_producto, precio, disponible, fuente)
    values (v_id, 1, true, 'comercio');
    raise exception 'FALLO A6: la app pudo escribir el historial directamente';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK A6: el historial solo lo escribe la base');
  end;

  insert into public.promocion (id_producto, precio_promocional, fecha_inicio, fecha_fin)
  values (v_id, 2000, current_date, current_date + 7);
  perform public.pruebas_log('OK A7: el dueño crea una promoción');

  begin
    update public.promocion set fecha_fin = fecha_inicio - 1 where id_producto = v_id;
    raise exception 'FALLO A8: se guardó una promoción que termina antes de empezar';
  exception when check_violation then
    perform public.pruebas_log('OK A8: la fecha de fin no puede ser anterior al inicio');
  end;
end $$;


-- ── Escenario B: otro usuario no ve ni toca precios ajenos ───────────────
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
    perform public.pruebas_log('SALTADA (B): no hay otro usuario o no se creó el producto en A');
    return;
  end if;

  select count(*) into v_rows from public.precio_producto where id_producto = v_producto::uuid;
  if v_rows <> 0 then
    raise exception 'FALLO B1: otro usuario ve un precio ajeno';
  end if;
  perform public.pruebas_log('OK B1: otro usuario no ve precios ajenos');

  update public.precio_producto set precio = 1 where id_producto = v_producto::uuid;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO B2: otro usuario cambió un precio ajeno';
  end if;
  perform public.pruebas_log('OK B2: otro usuario no cambia precios ajenos');

  select count(*) into v_rows from public.historial_precio where id_producto = v_producto::uuid;
  if v_rows <> 0 then
    raise exception 'FALLO B3: otro usuario ve el historial ajeno';
  end if;
  perform public.pruebas_log('OK B3: otro usuario no ve el historial ajeno');

  delete from public.promocion where id_producto = v_producto::uuid;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO B4: otro usuario eliminó una promoción ajena';
  end if;
  perform public.pruebas_log('OK B4: otro usuario no elimina promociones ajenas');
end $$;


-- ── Escenario C: sin sesión no se lee nada ───────────────────────────────
reset role;
set local role anon;

do $$
declare
  v_rows int;
begin
  select (select count(*) from public.precio_producto)
       + (select count(*) from public.promocion)
       + (select count(*) from public.historial_precio)
    into v_rows;
  if v_rows <> 0 then
    raise exception 'FALLO C1: una sesión anónima lee precios';
  end if;
  perform public.pruebas_log('OK C1: sin sesión no se leen precios, promociones ni historial');
end $$;


-- ── Resultado ────────────────────────────────────────────────────────────
reset role;
select unnest(
  string_to_array(trim(both E'\n' from current_setting('pruebas.log', true)), E'\n')
) as resultado;

rollback;
