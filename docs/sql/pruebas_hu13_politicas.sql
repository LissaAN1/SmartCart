-- =====================================================================
-- SmartCart · HU-13 · Prueba de los reportes de precio incorrecto y de lo
-- que el cliente ve de cada precio (fuente y fecha)
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu13.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba anota "OK ..." o se detiene con "FALLO ...".
-- Al final devuelve una tabla con una fila por prueba (el SQL Editor no
-- muestra los RAISE NOTICE, por eso las anotamos y las devolvemos).
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un comercio APROBADO, una categoría y al menos 4
-- usuarios (el dueño del comercio y otros 3). El script crea DENTRO de la
-- transacción:
--   · tres productos del comercio aprobado con precio: uno del comercio con
--     promoción vigente, uno de la comunidad con 10 días, y uno más,
--   · un comercio PENDIENTE con un producto con precio,
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
  v_id uuid;
begin
  if v_comercio is null or v_categoria is null
     or '' in (current_setting('pruebas.cli1'),
               current_setting('pruebas.cli2'),
               current_setting('pruebas.nocli')) then
    perform public.pruebas_log('AVISO: faltan datos (comercio aprobado, categoría o 4 usuarios); casi todo se saltará');
    return;
  end if;

  -- El trigger de precio_producto fija actualizado_en = now() en cada
  -- escritura; lo apagamos un momento para poder dejar un precio de hace 10
  -- días. El ROLLBACK final deja todo como estaba.
  alter table public.precio_producto disable trigger precio_producto_fecha;

  -- A: del comercio, con promoción vigente (el precio que se ve es 4200).
  insert into public.producto (id_comercio, id_categoria, nombre, marca, codigo_barras)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto A HU-13', 'MarcaPrueba', '7700000001301')
  returning id_producto into v_id;
  perform set_config('pruebas.p_a', v_id::text, true);
  insert into public.precio_producto (id_producto, precio, fuente, actualizado_en)
  values (v_id, 5000, 'comercio', now());
  insert into public.promocion (id_producto, precio_promocional, fecha_inicio, fecha_fin)
  values (v_id, 4200, current_date, current_date + 3);

  -- B: de la comunidad, actualizado hace 10 días (desactualizado).
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto B HU-13')
  returning id_producto into v_id;
  perform set_config('pruebas.p_b', v_id::text, true);
  insert into public.precio_producto (id_producto, precio, fuente, actualizado_en)
  values (v_id, 3000, 'colaborador', now() - interval '10 days');

  -- C: uno más, para el motivo en blanco.
  insert into public.producto (id_comercio, id_categoria, nombre)
  values (v_comercio::uuid, v_categoria::uuid, 'Producto C HU-13')
  returning id_producto into v_id;
  perform set_config('pruebas.p_c', v_id::text, true);
  insert into public.precio_producto (id_producto, precio, fuente, actualizado_en)
  values (v_id, 1000, 'comercio', now());

  alter table public.precio_producto enable trigger precio_producto_fecha;

  -- Un comercio PENDIENTE con un producto con precio (dueño: nocli).
  insert into public.comercio
    (id_usuario, nombre, telefono, direccion, ciudad,
     hora_apertura, hora_cierre, tipo_servicio, estado)
  select current_setting('pruebas.nocli')::uuid, 'Comercio pendiente HU-13',
         '+57 300 000 0000', 'Calle 1 # 1-1', 'Cali', '08:00', '18:00',
         'recogida', 'pendiente'
   where not exists (
     select 1 from public.comercio c
      where c.id_usuario = current_setting('pruebas.nocli')::uuid);

  select c.id_comercio into v_id
    from public.comercio c
   where c.id_usuario = current_setting('pruebas.nocli')::uuid
     and c.estado = 'pendiente';
  if v_id is not null then
    insert into public.producto (id_comercio, id_categoria, nombre)
    values (v_id, v_categoria::uuid, 'Producto pendiente HU-13')
    returning id_producto into v_id;
    insert into public.precio_producto (id_producto, precio) values (v_id, 2500);
    perform set_config('pruebas.p_pend', v_id::text, true);
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


-- ── Escenarios 1 y 2: lo que el cliente ve de cada precio ────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_fila record;
begin
  if nullif(current_setting('pruebas.p_a', true), '') is null then
    perform public.pruebas_log('SALTADA (A): faltan datos de prueba');
    return;
  end if;

  -- Un precio del comercio, de hoy, con promoción: llega la fuente, la fecha
  -- de hoy y el precio vigente (la app calcula de ahí la confianza alta).
  select * into v_fila
    from public.precios_de_producto(public.clave_producto('7700000001301', null, null));
  if v_fila.fuente is distinct from 'comercio' then
    raise exception 'FALLO A1: el precio no trae la fuente comercio';
  end if;
  if v_fila.precio <> 4200 or v_fila.precio_normal <> 5000 then
    raise exception 'FALLO A1: el precio vigente no es el de la promoción';
  end if;
  if v_fila.actualizado_en < now() - interval '1 minute' then
    raise exception 'FALLO A1: la fecha no es la de hoy';
  end if;
  perform public.pruebas_log('OK A1: el detalle trae la fuente, la fecha de hoy y el precio vigente');

  -- Un precio de la comunidad con 10 días: llega con su fuente y su fecha
  -- vieja (la app lo marca desactualizado y baja su confianza).
  select * into v_fila
    from public.precios_de_producto(public.clave_producto(null, 'Producto B HU-13', null));
  if v_fila.fuente is distinct from 'colaborador' then
    raise exception 'FALLO A2: el precio no trae la fuente colaborador';
  end if;
  if v_fila.actualizado_en > now() - interval '9 days'
     or v_fila.actualizado_en < now() - interval '11 days' then
    raise exception 'FALLO A2: la fecha no es la de hace 10 días (%)', v_fila.actualizado_en;
  end if;
  perform public.pruebas_log('OK A2: el detalle trae la fuente comunidad y la fecha de hace 10 días');
end $$;


-- ── Escenario 3: reportar un precio incorrecto ───────────────────────────
do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
  v_b uuid := nullif(current_setting('pruebas.p_b', true), '')::uuid;
  v_c uuid := nullif(current_setting('pruebas.p_c', true), '')::uuid;
  v_pend uuid := nullif(current_setting('pruebas.p_pend', true), '')::uuid;
  v_cli1 uuid := nullif(current_setting('pruebas.cli1'), '')::uuid;
  v_res text;
  v_fila record;
  v_n int;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (B): faltan datos de prueba');
    return;
  end if;

  -- B1: el reporte queda pendiente, con el precio vigente y su fuente.
  v_res := public.reportar_precio_incorrecto(v_a, 'El precio en la tienda es otro');
  if v_res <> 'registrado' then
    raise exception 'FALLO B1: se esperaba registrado y salió %', v_res;
  end if;
  select * into v_fila from public.reporte_precio_incorrecto
   where id_producto = v_a and id_usuario = v_cli1;
  if v_fila.id_reporte is null or v_fila.estado <> 'pendiente'
     or v_fila.precio_reportado <> 4200 or v_fila.fuente_reportada <> 'comercio'
     or v_fila.motivo is distinct from 'El precio en la tienda es otro' then
    raise exception 'FALLO B1: el reporte no quedó como se esperaba';
  end if;
  perform public.pruebas_log('OK B1: el reporte queda pendiente con el precio vigente y su fuente');

  -- B2: el mismo cliente no repite un reporte pendiente.
  v_res := public.reportar_precio_incorrecto(v_a, null);
  select count(*) into v_n from public.reporte_precio_incorrecto
   where id_producto = v_a and id_usuario = v_cli1;
  if v_res <> 'ya_reportado' or v_n <> 1 then
    raise exception 'FALLO B2: un reporte pendiente se duplicó (% / %)', v_res, v_n;
  end if;
  perform public.pruebas_log('OK B2: un reporte pendiente no se duplica');

  -- B3: un precio de la comunidad desactualizado también se reporta, y el
  -- reporte guarda su fuente y su fecha vieja. Sin motivo.
  v_res := public.reportar_precio_incorrecto(v_b);
  select * into v_fila from public.reporte_precio_incorrecto
   where id_producto = v_b and id_usuario = v_cli1;
  if v_res <> 'registrado' or v_fila.motivo is not null
     or v_fila.fuente_reportada <> 'colaborador'
     or v_fila.precio_actualizado_en > now() - interval '9 days' then
    raise exception 'FALLO B3: el reporte del precio de la comunidad no quedó bien';
  end if;
  perform public.pruebas_log('OK B3: se reporta un precio de la comunidad con su fuente y su fecha');

  -- B4: un motivo en blanco se guarda como si no hubiera motivo.
  v_res := public.reportar_precio_incorrecto(v_c, E'   \n  ');
  select * into v_fila from public.reporte_precio_incorrecto
   where id_producto = v_c and id_usuario = v_cli1;
  if v_res <> 'registrado' or v_fila.motivo is not null then
    raise exception 'FALLO B4: un motivo en blanco debía guardarse como vacío';
  end if;
  perform public.pruebas_log('OK B4: un motivo en blanco no se guarda');

  -- B5: el motivo tiene un máximo de 300 caracteres.
  begin
    perform public.reportar_precio_incorrecto(v_c, repeat('x', 301));
    raise exception 'FALLO B5: se aceptó un motivo de 301 caracteres';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like '%300 caracteres%' then
      raise exception 'FALLO B5: mensaje inesperado: %', sqlerrm;
    end if;
  end;
  perform public.pruebas_log('OK B5: un motivo de más de 300 caracteres se rechaza');

  -- B6: un producto que no existe no se reporta.
  begin
    perform public.reportar_precio_incorrecto(gen_random_uuid(), null);
    raise exception 'FALLO B6: se reportó un producto que no existe';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like '%ya no está publicado%' then
      raise exception 'FALLO B6: mensaje inesperado: %', sqlerrm;
    end if;
  end;
  perform public.pruebas_log('OK B6: un producto que no existe no se reporta');

  -- B7: el precio de un comercio pendiente no está publicado: no se reporta.
  if v_pend is null then
    perform public.pruebas_log('SALTADA B7: no hay comercio pendiente de prueba');
  else
    begin
      perform public.reportar_precio_incorrecto(v_pend, null);
      raise exception 'FALLO B7: se reportó el precio de un comercio pendiente';
    exception when raise_exception then
      if sqlerrm like 'FALLO%' then raise; end if;
    end;
    perform public.pruebas_log('OK B7: el precio de un comercio pendiente no se reporta');
  end if;

  -- C1: el cliente ve sus 3 reportes y solo los suyos.
  select count(*) into v_n from public.reporte_precio_incorrecto;
  if v_n <> 3 then
    raise exception 'FALLO C1: el cliente ve % reportes y debía ver sus 3', v_n;
  end if;
  perform public.pruebas_log('OK C1: el cliente ve sus propios reportes');
end $$;


-- ── Otro cliente: no ve ni toca los reportes ajenos ──────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli2'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
  v_n int;
  v_res text;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (C): faltan datos de prueba');
    return;
  end if;

  select count(*) into v_n from public.reporte_precio_incorrecto;
  if v_n <> 0 then
    raise exception 'FALLO C2: otro cliente ve % reportes ajenos', v_n;
  end if;
  perform public.pruebas_log('OK C2: otro cliente no ve los reportes ajenos');

  -- El reporte pendiente de cli1 no impide que cli2 reporte el mismo precio.
  v_res := public.reportar_precio_incorrecto(v_a, null);
  if v_res <> 'registrado' then
    raise exception 'FALLO C3: otro cliente no pudo reportar el mismo precio (%)', v_res;
  end if;
  perform public.pruebas_log('OK C3: dos clientes pueden reportar el mismo precio');
end $$;


-- ── Nadie escribe la tabla directo ───────────────────────────────────────
do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (D): faltan datos de prueba');
    return;
  end if;

  begin
    insert into public.reporte_precio_incorrecto
      (id_usuario, id_producto, precio_reportado, fuente_reportada, precio_actualizado_en)
    values (auth.uid(), v_a, 1, 'comercio', now());
    raise exception 'FALLO D1: un cliente insertó un reporte saltándose la función';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK D1: no se inserta un reporte saltándose la función');

  begin
    update public.reporte_precio_incorrecto set estado = 'resuelto';
    raise exception 'FALLO D2: un cliente cambió el estado de un reporte';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK D2: un cliente no cambia el estado de un reporte');

  begin
    delete from public.reporte_precio_incorrecto;
    raise exception 'FALLO D3: un cliente borró reportes';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK D3: un cliente no borra reportes');
end $$;


-- ── Sin el rol cliente no se reporta ─────────────────────────────────────
reset role;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.nocli'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (E): faltan datos de prueba');
    return;
  end if;

  begin
    perform public.reportar_precio_incorrecto(v_a, null);
    raise exception 'FALLO E1: alguien sin rol cliente reportó un precio';
  exception when raise_exception then
    if sqlerrm like 'FALLO%' then raise; end if;
    if sqlerrm not like '%Solo los clientes%' then
      raise exception 'FALLO E1: mensaje inesperado: %', sqlerrm;
    end if;
  end;
  perform public.pruebas_log('OK E1: sin rol cliente no se reporta un precio');
end $$;


-- ── Cuando se resuelve, el cliente puede volver a reportar ───────────────
reset role;
do $$
begin
  update public.reporte_precio_incorrecto
     set estado = 'resuelto'
   where id_usuario = nullif(current_setting('pruebas.cli1'), '')::uuid
     and id_producto = nullif(current_setting('pruebas.p_a', true), '')::uuid;
end $$;

select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.cli1'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
  v_res text;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (F): faltan datos de prueba');
    return;
  end if;

  v_res := public.reportar_precio_incorrecto(v_a, 'Sigue mal');
  if v_res <> 'registrado' then
    raise exception 'FALLO F1: no se pudo reportar de nuevo tras resolverse (%)', v_res;
  end if;
  perform public.pruebas_log('OK F1: un reporte resuelto permite reportar otra vez');
end $$;


-- ── Sin sesión ───────────────────────────────────────────────────────────
reset role;
set local role anon;

do $$
declare
  v_a uuid := nullif(current_setting('pruebas.p_a', true), '')::uuid;
begin
  if v_a is null then
    perform public.pruebas_log('SALTADA (G): faltan datos de prueba');
    return;
  end if;

  begin
    perform public.reportar_precio_incorrecto(v_a, null);
    raise exception 'FALLO G1: una sesión anónima reportó un precio';
  exception when insufficient_privilege then
    null;
  end;
  perform public.pruebas_log('OK G1: sin sesión no se reporta un precio');
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
