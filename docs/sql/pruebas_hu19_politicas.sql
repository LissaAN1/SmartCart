-- =====================================================================
-- SmartCart · HU-19 · Prueba de la ubicación del cliente y de los
-- comercios dentro del radio
-- Ejecutar en Supabase → SQL Editor después de sprint3_hu19.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba.
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un comercio APROBADO y al menos 3 usuarios. Dentro
-- de la transacción el script:
--   · mueve el comercio aprobado a 111 m del punto de prueba,
--   · crea, si hay usuarios sin comercio, uno APROBADO a unos 5 km y uno
--     PENDIENTE a 155 m,
--   · da el rol cliente a dos usuarios y se lo quita a un tercero.
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
  set_config('pruebas.cerca', coalesce((
    select c.id_comercio::text from public.comercio c
     where c.estado = 'aprobado' order by c.id_comercio limit 1), ''), true),
  set_config('pruebas.cli1', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.cli2', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 1), ''), true),
  set_config('pruebas.nocli', coalesce((
    select u.id_usuario::text from public.usuario u
     order by u.id_usuario limit 1 offset 2), ''), true),
  -- Dueños para los comercios de prueba: usuarios que aún no tienen uno.
  set_config('pruebas.dueno_lejos', coalesce((
    select u.id_usuario::text from public.usuario u
     where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
     order by u.id_usuario limit 1 offset 0), ''), true),
  set_config('pruebas.dueno_pend', coalesce((
    select u.id_usuario::text from public.usuario u
     where not exists (select 1 from public.comercio c where c.id_usuario = u.id_usuario)
     order by u.id_usuario limit 1 offset 1), ''), true);

do $$
declare
  v_rol int;
  v_id uuid;
begin
  if '' in (current_setting('pruebas.cerca'),
            current_setting('pruebas.cli1'),
            current_setting('pruebas.cli2'),
            current_setting('pruebas.nocli')) then
    perform public.pruebas_log('AVISO: faltan datos (comercio aprobado o 3 usuarios); casi todo se saltará');
    return;
  end if;

  -- Punto de prueba: 3.4516, -76.5320 (Cali). El comercio aprobado queda a
  -- 0,001° de latitud (unos 111 m).
  update public.comercio
     set latitud = 3.4526, longitud = -76.5320
   where id_comercio = current_setting('pruebas.cerca')::uuid;

  if current_setting('pruebas.dueno_lejos') <> '' then
    insert into public.comercio
      (id_usuario, nombre, telefono, direccion, ciudad,
       hora_apertura, hora_cierre, tipo_servicio, estado, latitud, longitud)
    values
      (current_setting('pruebas.dueno_lejos')::uuid, 'Comercio lejano HU-19',
       '+57 300 000 0000', 'Calle 2 # 2-2', 'Cali', '08:00', '18:00',
       'recogida', 'aprobado', 3.4966, -76.5320)
    returning id_comercio into v_id;
    perform set_config('pruebas.lejos', v_id::text, true);
  end if;

  if current_setting('pruebas.dueno_pend') <> '' then
    insert into public.comercio
      (id_usuario, nombre, telefono, direccion, ciudad,
       hora_apertura, hora_cierre, tipo_servicio, estado, latitud, longitud)
    values
      (current_setting('pruebas.dueno_pend')::uuid, 'Comercio pendiente HU-19',
       '+57 300 000 0000', 'Calle 3 # 3-3', 'Cali', '08:00', '18:00',
       'recogida', 'pendiente', 3.4530, -76.5320)
    returning id_comercio into v_id;
    perform set_config('pruebas.pend', v_id::text, true);
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

  -- Si cli1 o cli2 ya tenían una ubicación guardada, la quitamos para
  -- empezar de cero (el ROLLBACK la devuelve).
  delete from public.ubicacion_cliente
   where id_usuario in (current_setting('pruebas.cli1')::uuid,
                        current_setting('pruebas.cli2')::uuid);

  perform public.pruebas_log('AVISO: datos de prueba creados dentro de la transacción');
end $$;


-- ── Cliente 1: guarda su ubicación y ve los comercios del radio ──────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_cerca uuid := nullif(current_setting('pruebas.cerca'), '')::uuid;
  v_lejos uuid := nullif(current_setting('pruebas.lejos', true), '')::uuid;
  v_pend  uuid := nullif(current_setting('pruebas.pend', true), '')::uuid;
  v_fila  record;
  v_n     int;
  v_ids   uuid[];
begin
  if v_cerca is null or current_setting('pruebas.cli1') = '' then
    perform public.pruebas_log('SALTADA (A y B): faltan datos de prueba');
    return;
  end if;

  -- A1: guardar crea la fila propia con los valores enviados.
  perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 2000, null);
  select * into v_fila from public.ubicacion_cliente;
  if v_fila.id_usuario::text <> current_setting('pruebas.cli1')
     or v_fila.radio_m <> 2000 or v_fila.direccion is not null
     or v_fila.latitud <> 3.4516 then
    raise exception 'FALLO A1: la ubicación no quedó guardada como se envió';
  end if;
  perform public.pruebas_log('OK A1: el cliente guarda su ubicación y su radio');

  -- A2: guardar otra vez reemplaza la fila (no duplica) y guarda la
  -- dirección escrita sin espacios sobrantes.
  perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 10000, '  Calle 5 # 38-20, Cali  ');
  select count(*) into v_n from public.ubicacion_cliente;
  select * into v_fila from public.ubicacion_cliente;
  if v_n <> 1 or v_fila.radio_m <> 10000
     or v_fila.direccion is distinct from 'Calle 5 # 38-20, Cali' then
    raise exception 'FALLO A2: guardar otra vez no reemplazó la fila (% filas)', v_n;
  end if;
  perform public.pruebas_log('OK A2: guardar otra vez reemplaza la ubicación y el radio');

  -- A3: radio fuera de rango.
  begin
    perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 500, null);
    raise exception 'FALLO A3: se aceptó un radio de 500 m';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  begin
    perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 25000, null);
    raise exception 'FALLO A3: se aceptó un radio de 25 km';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK A3: un radio fuera de 1 a 20 km se rechaza');

  -- A4: coordenadas imposibles.
  begin
    perform public.guardar_ubicacion_cliente(95, -76.5320, 2000, null);
    raise exception 'FALLO A4: se aceptó una latitud de 95';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK A4: unas coordenadas imposibles se rechazan');

  -- A5: dirección de más de 200 caracteres.
  begin
    perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 2000, repeat('x', 201));
    raise exception 'FALLO A5: se aceptó una dirección de 201 caracteres';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK A5: una dirección de más de 200 caracteres se rechaza');

  -- A6: el cliente no escribe la tabla directo (solo con la función).
  begin
    update public.ubicacion_cliente set radio_m = 3000;
    raise exception 'FALLO A6: el cliente actualizó la tabla directo';
  exception when insufficient_privilege then
    null;
  end;
  begin
    delete from public.ubicacion_cliente;
    raise exception 'FALLO A6: el cliente borró la fila directo';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK A6: la tabla no se escribe directo, solo con guardar_ubicacion_cliente()');

  -- B1 (escenario 1): con 2 km entra el comercio cercano y no el de 5 km.
  select array_agg(id_comercio) into v_ids
    from public.comercios_en_radio(3.4516, -76.5320, 2000);
  if not (v_cerca = any(coalesce(v_ids, '{}'))) then
    raise exception 'FALLO B1: el comercio a 111 m no aparece en un radio de 2 km';
  end if;
  if v_lejos is not null and v_lejos = any(coalesce(v_ids, '{}')) then
    raise exception 'FALLO B1: el comercio a 5 km aparece en un radio de 2 km';
  end if;
  perform public.pruebas_log('OK B1: un radio de 2 km trae el comercio cercano y deja fuera el de 5 km');

  -- B2 (escenario 3): al ampliar a 10 km también entra el lejano, y la
  -- lista va del más cercano al más lejano.
  if v_lejos is null then
    perform public.pruebas_log('SALTADA B2: no hay usuario libre para crear el comercio lejano');
  else
    select array_agg(id_comercio order by distancia_m) into v_ids
      from public.comercios_en_radio(3.4516, -76.5320, 10000);
    if not (v_lejos = any(coalesce(v_ids, '{}'))) then
      raise exception 'FALLO B2: al ampliar a 10 km no aparece el comercio a 5 km';
    end if;
    if array_position(v_ids, v_cerca) > array_position(v_ids, v_lejos) then
      raise exception 'FALLO B2: la lista no va del más cercano al más lejano';
    end if;
    select d.distancia_m into v_fila
      from public.comercios_en_radio(3.4516, -76.5320, 10000) d
     where d.id_comercio = v_lejos;
    if v_fila.distancia_m not between 4800 and 5100 then
      raise exception 'FALLO B2: la distancia al comercio lejano es % m', v_fila.distancia_m;
    end if;
    perform public.pruebas_log('OK B2: ampliar el radio incluye el comercio lejano, ordenado por distancia');
  end if;

  -- B3: un comercio pendiente no aparece aunque esté cerca.
  if v_pend is null then
    perform public.pruebas_log('SALTADA B3: no hay usuario libre para crear el comercio pendiente');
  else
    select array_agg(id_comercio) into v_ids
      from public.comercios_en_radio(3.4516, -76.5320, 20000);
    if v_pend = any(coalesce(v_ids, '{}')) then
      raise exception 'FALLO B3: aparece un comercio pendiente';
    end if;
    perform public.pruebas_log('OK B3: un comercio pendiente no aparece en el mapa');
  end if;

  -- B4: radio fuera de rango en la consulta.
  begin
    perform * from public.comercios_en_radio(3.4516, -76.5320, 50000);
    raise exception 'FALLO B4: se aceptó un radio de 50 km';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK B4: la consulta rechaza un radio fuera de rango');
end $$;


-- ── Cliente 2: no ve ni cambia la ubicación del cliente 1 ────────────────
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
  if current_setting('pruebas.cli2') = '' then
    perform public.pruebas_log('SALTADA (C): faltan datos de prueba');
    return;
  end if;

  select count(*) into v_n from public.ubicacion_cliente;
  if v_n <> 0 then
    raise exception 'FALLO C1: el cliente 2 ve % ubicaciones ajenas', v_n;
  end if;
  perform public.pruebas_log('OK C1: un cliente no ve la ubicación de otro');

  perform public.guardar_ubicacion_cliente(4.6097, -74.0817, 5000, null);
  select count(*) into v_n from public.ubicacion_cliente;
  if v_n <> 1 then
    raise exception 'FALLO C2: el cliente 2 ve % filas tras guardar la suya', v_n;
  end if;
  perform public.pruebas_log('OK C2: guardar la propia no toca la de otro cliente');
end $$;

reset role;
do $$
declare
  v_fila record;
begin
  if current_setting('pruebas.cli1') = '' then return; end if;
  select * into v_fila from public.ubicacion_cliente
   where id_usuario = current_setting('pruebas.cli1')::uuid;
  if v_fila.radio_m <> 10000 or v_fila.latitud <> 3.4516 then
    raise exception 'FALLO C3: la ubicación del cliente 1 cambió';
  end if;
  perform public.pruebas_log('OK C3: la ubicación del cliente 1 sigue igual');
end $$;


-- ── Sin rol cliente: no guarda ni consulta ───────────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocli'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
begin
  if current_setting('pruebas.nocli') = '' then
    perform public.pruebas_log('SALTADA (D): faltan datos de prueba');
    return;
  end if;

  begin
    perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 2000, null);
    raise exception 'FALLO D1: una cuenta sin rol cliente guardó una ubicación';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK D1: sin rol cliente no se guarda la ubicación');

  begin
    perform * from public.comercios_en_radio(3.4516, -76.5320, 2000);
    raise exception 'FALLO D2: una cuenta sin rol cliente consultó el mapa';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
  end;
  perform public.pruebas_log('OK D2: sin rol cliente no se consultan los comercios del radio');
end $$;


-- ── Sin sesión ───────────────────────────────────────────────────────────
reset role;
set local role anon;

do $$
begin
  begin
    perform public.guardar_ubicacion_cliente(3.4516, -76.5320, 2000, null);
    raise exception 'FALLO E1: una sesión anónima guardó una ubicación';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform * from public.comercios_en_radio(3.4516, -76.5320, 2000);
    raise exception 'FALLO E1: una sesión anónima consultó el mapa';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK E1: sin sesión no se guarda ni se consulta');
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
