-- =====================================================================
-- SmartCart · HU-14 · Prueba de las políticas y funciones del reporte
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu14.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba (el SQL Editor no
-- muestra los RAISE NOTICE). Simula sesiones reales: rol `authenticated` +
-- el id del usuario en request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un comercio APROBADO, una categoría y al menos 4
-- usuarios (el dueño del comercio y otros 3). Para no depender de qué roles
-- tengan, el script crea DENTRO de la transacción:
--   · coordenadas para el comercio aprobado,
--   · un producto en ese comercio,
--   · el rol colaborador para dos usuarios (y se asegura de que un tercero
--     NO lo tenga).
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

-- Tres usuarios distintos del dueño: dos serán colaboradores y uno no.
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
begin
  if v_comercio is null or v_categoria is null
     or '' in (current_setting('pruebas.colab1'),
               current_setting('pruebas.colab2'),
               current_setting('pruebas.nocolab')) then
    perform public.pruebas_log('AVISO: faltan datos (comercio aprobado, categoría o 4 usuarios); casi todo se saltará');
    return;
  end if;

  -- Coordenadas del comercio: 3.4519, -76.5320.
  update public.comercio
     set latitud = 3.4519, longitud = -76.5320
   where id_comercio = v_comercio::uuid;

  -- Un producto para reportar.
  insert into public.producto (id_comercio, id_categoria, nombre, codigo_barras)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto de prueba HU-14', '7700000001401')
  returning id_producto into v_producto;
  perform set_config('pruebas.producto', v_producto::text, true);

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

  -- Un comercio PENDIENTE de colab2 (si no tiene comercio), para la prueba E5.
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  select current_setting('pruebas.colab2')::uuid, 'Comercio pendiente de prueba',
         '+57 300 000 0000', 'Calle 1 # 1-1', 'Cali', '08:00', '18:00',
         'recogida', 'pendiente'
   where not exists (
     select 1 from public.comercio c
      where c.id_usuario = current_setting('pruebas.colab2')::uuid);

  perform public.pruebas_log('AVISO: datos de prueba creados dentro de la transacción');
end $$;


-- ── Escenario A: un colaborador reporta desde el establecimiento ─────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_uid text := current_setting('pruebas.colab1');
  v_dist double precision;
  v_n int;
  v_id uuid;
  v_estado text;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (A): faltan datos de prueba');
    return;
  end if;

  -- A1: lo ve entre los establecimientos cercanos (a unos 33 m).
  select distancia_m into v_dist
    from public.comercios_cercanos(3.4516, -76.5320)
   where id_comercio = v_comercio;
  if v_dist is null or v_dist not between 30 and 37 then
    raise exception 'FALLO A1: el comercio no aparece cerca o la distancia es rara (%)', v_dist;
  end if;
  perform public.pruebas_log('OK A1: el colaborador ve el comercio cercano a ' || round(v_dist) || ' m');

  -- A2: puede leer los productos del comercio aprobado.
  select count(*) into v_n from public.producto where id_producto = v_producto;
  if v_n <> 1 then
    raise exception 'FALLO A2: el colaborador no lee los productos del comercio';
  end if;
  perform public.pruebas_log('OK A2: el colaborador lee los productos del comercio');

  -- A3: reporte desde dentro del establecimiento: queda pendiente.
  v_id := public.enviar_reporte_precio(
    v_comercio, v_producto, 4900, 4500, true,
    v_uid || '/prueba.jpg', 3.4516, -76.5320);
  select estado, distancia_m into v_estado, v_dist
    from public.reporte_precio where id_reporte = v_id;
  if v_estado <> 'pendiente' or v_dist > 150 then
    raise exception 'FALLO A3: el reporte no quedó pendiente o la distancia es rara (%, %)', v_estado, v_dist;
  end if;
  perform set_config('pruebas.reporte', v_id::text, true);
  perform public.pruebas_log('OK A3: reporte desde el establecimiento guardado como pendiente');

  -- A4: sugerir un establecimiento nuevo.
  insert into public.establecimiento_sugerido
    (id_colaborador, nombre, direccion, ciudad, latitud, longitud)
  values (v_uid::uuid, 'Tienda de prueba', 'Calle 1 # 1-1', 'Cali', 3.4516, -76.5320);
  perform public.pruebas_log('OK A4: el colaborador sugiere un establecimiento');
end $$;


-- ── Escenario B: reglas que rechazan el reporte ──────────────────────────
do $$
declare
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_uid text := current_setting('pruebas.colab1');
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (B): faltan datos de prueba');
    return;
  end if;

  -- B1: escenario 2 del backlog: lejos del establecimiento (≈ 1,1 km).
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 4900, null, false,
      v_uid || '/lejos.jpg', 3.4616, -76.5320);
    raise exception 'FALLO B1: aceptó un reporte desde lejos';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like 'Debes estar en el establecimiento%' then
      raise exception 'FALLO B1: mensaje inesperado: %', sqlerrm;
    end if;
    perform public.pruebas_log('OK B1: lejos del establecimiento se rechaza (' || sqlerrm || ')');
  end;

  -- B2: escenario 3 del backlog: sin foto.
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 4900, null, false,
      '', 3.4516, -76.5320);
    raise exception 'FALLO B2: aceptó un reporte sin foto';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like 'La foto de la etiqueta es obligatoria%' then
      raise exception 'FALLO B2: mensaje inesperado: %', sqlerrm;
    end if;
    perform public.pruebas_log('OK B2: sin foto se rechaza');
  end;

  -- B3: la foto debe estar en la carpeta de quien reporta.
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 4900, null, false,
      current_setting('pruebas.colab2') || '/ajena.jpg', 3.4516, -76.5320);
    raise exception 'FALLO B3: aceptó la foto de otra carpeta';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B3: la foto de otra carpeta se rechaza');
  end;

  -- B4: el precio debe ser mayor que cero.
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 0, null, false,
      v_uid || '/cero.jpg', 3.4516, -76.5320);
    raise exception 'FALLO B4: aceptó un precio de cero';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B4: un precio de cero se rechaza');
  end;

  -- B5: la promoción debe ser menor que el precio normal.
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 4900, 4900, false,
      v_uid || '/promo.jpg', 3.4516, -76.5320);
    raise exception 'FALLO B5: aceptó una promoción igual al precio';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK B5: una promoción no menor que el precio se rechaza');
  end;

  -- B6: nadie inserta un reporte directo, saltándose la función.
  begin
    insert into public.reporte_precio
      (id_colaborador, id_comercio, id_producto, precio, foto_path, latitud, longitud, distancia_m)
    values (v_uid::uuid, v_comercio, v_producto, 100, v_uid || '/x.jpg', 0, 0, 0);
    raise exception 'FALLO B6: pudo insertar un reporte directo';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK B6: no se puede insertar un reporte saltándose la función');
  end;
end $$;


-- ── Escenario C: otro colaborador y alguien sin el modo Colaborador ──────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_reporte uuid := nullif(current_setting('pruebas.reporte', true), '')::uuid;
  v_n int;
begin
  if v_reporte is null then
    perform public.pruebas_log('SALTADA (C1): no se creó el reporte en A');
    return;
  end if;
  select count(*) into v_n from public.reporte_precio where id_reporte = v_reporte;
  if v_n <> 0 then
    raise exception 'FALLO C1: otro colaborador ve un reporte ajeno';
  end if;
  perform public.pruebas_log('OK C1: otro colaborador no ve reportes ajenos');

  select count(*) into v_n from public.establecimiento_sugerido;
  if v_n <> 0 then
    raise exception 'FALLO C2: otro colaborador ve sugerencias ajenas';
  end if;
  perform public.pruebas_log('OK C2: otro colaborador no ve sugerencias ajenas');
end $$;

reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocolab'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_producto uuid := nullif(current_setting('pruebas.producto', true), '')::uuid;
  v_uid text := current_setting('pruebas.nocolab');
  v_n int;
begin
  if v_producto is null then
    perform public.pruebas_log('SALTADA (C3-C6): faltan datos de prueba');
    return;
  end if;

  -- C3: sin el modo Colaborador no ve establecimientos.
  select count(*) into v_n from public.comercios_cercanos(3.4516, -76.5320);
  if v_n <> 0 then
    raise exception 'FALLO C3: alguien sin el modo Colaborador ve establecimientos';
  end if;
  perform public.pruebas_log('OK C3: sin el modo Colaborador no se listan establecimientos');

  -- C4: ni lee productos ajenos.
  select count(*) into v_n from public.producto where id_producto = v_producto;
  if v_n <> 0 then
    raise exception 'FALLO C4: alguien sin el modo Colaborador lee productos de un comercio';
  end if;
  perform public.pruebas_log('OK C4: sin el modo Colaborador no se leen productos ajenos');

  -- C5: ni envía reportes.
  begin
    perform public.enviar_reporte_precio(v_comercio, v_producto, 4900, null, false,
      v_uid || '/x.jpg', 3.4516, -76.5320);
    raise exception 'FALLO C5: alguien sin el modo Colaborador envió un reporte';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like 'Activa el modo Colaborador%' then
      raise exception 'FALLO C5: mensaje inesperado: %', sqlerrm;
    end if;
    perform public.pruebas_log('OK C5: sin el modo Colaborador no se envían reportes');
  end;

  -- C6: ni sugiere establecimientos.
  begin
    insert into public.establecimiento_sugerido
      (id_colaborador, nombre, direccion, ciudad, latitud, longitud)
    values (v_uid::uuid, 'No debería', 'Calle 1 # 1-1', 'Cali', 0, 0);
    raise exception 'FALLO C6: alguien sin el modo Colaborador sugirió un establecimiento';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK C6: sin el modo Colaborador no se sugieren establecimientos');
  end;
end $$;


-- ── Escenario D: no se puede sugerir a nombre de otro ────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
begin
  if nullif(current_setting('pruebas.producto', true), '') is null then
    perform public.pruebas_log('SALTADA (D1): faltan datos de prueba');
    return;
  end if;
  begin
    insert into public.establecimiento_sugerido
      (id_colaborador, nombre, direccion, ciudad, latitud, longitud)
    values (current_setting('pruebas.colab2')::uuid, 'A nombre de otro', 'Calle 1 # 1-1', 'Cali', 0, 0);
    raise exception 'FALLO D1: sugirió a nombre de otro usuario';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK D1: no se puede sugerir a nombre de otro usuario');
  end;
end $$;


-- ── Escenario E: el dueño guarda la ubicación de su comercio ─────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.dueno'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_comercio uuid := nullif(current_setting('pruebas.comercio'), '')::uuid;
  v_lat double precision;
  v_estado text;
  v_rows int;
begin
  if v_comercio is null then
    perform public.pruebas_log('SALTADA (E): no hay comercio aprobado');
    return;
  end if;

  -- E1: la función guarda las coordenadas y no toca el estado.
  perform public.fijar_ubicacion_comercio(3.5, -76.6);
  select latitud, estado into v_lat, v_estado
    from public.comercio where id_comercio = v_comercio;
  if v_lat <> 3.5 or v_estado <> 'aprobado' then
    raise exception 'FALLO E1: la ubicación no se guardó o cambió el estado (%, %)', v_lat, v_estado;
  end if;
  perform public.pruebas_log('OK E1: el dueño guarda la ubicación y su estado sigue aprobado');

  -- E2: coordenadas imposibles se rechazan.
  begin
    perform public.fijar_ubicacion_comercio(95, 0);
    raise exception 'FALLO E2: aceptó una latitud imposible';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK E2: una latitud imposible se rechaza');
  end;

  -- E3: el dueño aprobado no cambia su estado con un update directo. Si lo
  -- logra no se detiene el script (para ver el resto de resultados): se deja
  -- una ALERTA. Una cuenta que además es administrador sí puede cambiarlo, y
  -- eso es correcto; por eso la alerta dice si lo es.
  update public.comercio set estado = 'pendiente' where id_comercio = v_comercio;
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    perform public.pruebas_log(
      'ALERTA E3: el dueño pudo cambiar el estado de su comercio. ¿Es también '
      || 'administrador? ' || public.es_administrador()::text
      || '. Si dice false, hay una política de update en comercio que lo permite: '
      || 'revisa pg_policies.');
  else
    perform public.pruebas_log('OK E3: el dueño no cambia su estado con un update directo');
  end if;
end $$;

-- E4: quien no tiene comercio no puede fijar una ubicación.
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocolab'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
begin
  if nullif(current_setting('pruebas.comercio'), '') is null then
    perform public.pruebas_log('SALTADA (E4): no hay comercio aprobado');
    return;
  end if;
  begin
    perform public.fijar_ubicacion_comercio(3.5, -76.6);
    raise exception 'FALLO E4: alguien sin comercio fijó una ubicación';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    perform public.pruebas_log('OK E4: sin comercio no se puede fijar una ubicación');
  end;
end $$;

-- E5: el dueño de un comercio PENDIENTE no puede aprobarse a sí mismo. Es la
-- regla central de HU-07/HU-24: solo el administrador cambia el estado. Si
-- este update funciona, hay una política de más en `comercio` (por ejemplo
-- `comercio_update_own`, que sprint2_hu14.sql elimina).
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_rows int;
  v_estado text;
begin
  if nullif(current_setting('pruebas.producto', true), '') is null then
    perform public.pruebas_log('SALTADA (E5): faltan datos de prueba');
    return;
  end if;
  begin
    update public.comercio set estado = 'aprobado'
     where id_usuario = auth.uid() and estado = 'pendiente';
    get diagnostics v_rows = row_count;
  exception when insufficient_privilege then
    v_rows := 0;
  end;
  if v_rows <> 0 then
    perform public.pruebas_log(
      'ALERTA E5: el dueño de un comercio PENDIENTE pudo aprobarse solo. '
      || 'Elimina la política sobrante de comercio (ver sprint2_hu14.sql, sección 8).');
  else
    perform public.pruebas_log('OK E5: el dueño de un comercio pendiente no puede aprobarse solo');
  end if;
end $$;


-- ── Escenario F: Storage, el bucket "reportes" ───────────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_uid text := current_setting('pruebas.colab1');
  v_n int;
begin
  if nullif(current_setting('pruebas.producto', true), '') is null then
    perform public.pruebas_log('SALTADA (F): faltan datos de prueba');
    return;
  end if;

  -- F1: sube a su propia carpeta.
  insert into storage.objects (bucket_id, name, owner)
  values ('reportes', v_uid || '/foto-prueba.jpg', v_uid::uuid);
  perform public.pruebas_log('OK F1: el colaborador sube una foto a su carpeta');

  -- F2: la lee.
  select count(*) into v_n from storage.objects
   where bucket_id = 'reportes' and name = v_uid || '/foto-prueba.jpg';
  if v_n <> 1 then
    raise exception 'FALLO F2: el colaborador no ve su propia foto';
  end if;
  perform public.pruebas_log('OK F2: el colaborador ve su foto');

  -- F3: no sube a la carpeta de otro.
  begin
    insert into storage.objects (bucket_id, name, owner)
    values ('reportes', current_setting('pruebas.colab2') || '/intrusa.jpg', v_uid::uuid);
    raise exception 'FALLO F3: subió una foto a la carpeta de otro usuario';
  exception when insufficient_privilege then
    perform public.pruebas_log('OK F3: no se sube a la carpeta de otro usuario');
  end;
end $$;

reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.colab2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_n int;
begin
  if nullif(current_setting('pruebas.producto', true), '') is null then
    perform public.pruebas_log('SALTADA (F4): faltan datos de prueba');
    return;
  end if;
  -- F4: otro colaborador no ve la foto ajena.
  select count(*) into v_n from storage.objects
   where bucket_id = 'reportes' and name like current_setting('pruebas.colab1') || '/%';
  if v_n <> 0 then
    raise exception 'FALLO F4: otro colaborador ve fotos ajenas';
  end if;
  perform public.pruebas_log('OK F4: otro colaborador no ve fotos ajenas');
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
