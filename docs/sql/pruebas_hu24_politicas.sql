-- =====================================================================
-- SmartCart · HU-24 · Prueba de las políticas de permisos
-- Ejecutar en Supabase → SQL Editor después de sprint2_hu24.sql.
--
-- Corre todo dentro de una transacción que termina en ROLLBACK: no deja
-- datos cambiados. Cada prueba imprime "OK ..." o falla con "FALLO ...".
-- Simula sesiones reales: rol `authenticated` + el id del usuario en
-- request.jwt.claims (lo que auth.uid() lee).
--
-- Necesita en la base: un usuario SIN rol administrador, un usuario CON rol
-- administrador y al menos un comercio pendiente. Si falta algo, la prueba
-- correspondiente se salta con un aviso.
-- =====================================================================

begin;

-- Ids de prueba. Se leen antes de cambiar de rol (cuando RLS no aplica) y
-- se guardan en variables de la transacción, no en una tabla: así no se
-- crea nada que pueda quedar expuesto. Cadena vacía = no se encontró.
select
  set_config('pruebas.no_admin', coalesce((
    select u.id_usuario::text
      from public.usuario u
     where not exists (
       select 1 from public.usuario_rol ur join public.rol r on r.id_rol = ur.id_rol
        where ur.id_usuario = u.id_usuario and r.codigo = 'administrador')
     limit 1), ''), true),
  set_config('pruebas.admin', coalesce((
    select ur.id_usuario::text
      from public.usuario_rol ur join public.rol r on r.id_rol = ur.id_rol
     where r.codigo = 'administrador'
     limit 1), ''), true),
  set_config('pruebas.comercio_pendiente', coalesce((
    select c.id_comercio::text
      from public.comercio c
     where c.estado = 'pendiente'
     limit 1), ''), true);


-- ── Escenario 3: un usuario que NO es administrador ──────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.no_admin'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_id   text := nullif(current_setting('pruebas.comercio_pendiente'), '');
  v_rows int;
begin
  if current_setting('pruebas.no_admin') = '' then
    raise notice 'SALTADA: no hay usuarios sin rol administrador';
    return;
  end if;

  -- a) No puede usar la función de decisión.
  begin
    perform public.decidir_solicitud('comercio', coalesce(v_id, '0'), true, null);
    raise exception 'FALLO: un no administrador pudo aprobar un comercio';
  exception when insufficient_privilege then
    raise notice 'OK: decidir_solicitud rechaza a un no administrador (42501)';
  end;

  -- b) Tampoco puede cambiar el estado con un UPDATE directo: RLS no le
  --    deja ver comercios ajenos, así que no actualiza ninguna fila.
  update public.comercio set estado = 'aprobado'
   where id_comercio::text = v_id and id_usuario <> auth.uid();
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO: un no administrador aprobó % comercio(s) ajeno(s)', v_rows;
  end if;
  raise notice 'OK: UPDATE directo sobre un comercio ajeno no afecta filas';

  -- c) Ni aprobarse a sí mismo como repartidor (no hay política de update).
  update public.perfil_repartidor set estado = 'aprobado'
   where id_usuario = auth.uid();
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FALLO: un repartidor se aprobó a sí mismo';
  end if;
  raise notice 'OK: un repartidor no puede aprobarse a sí mismo';

  -- d) Ni crear notificaciones.
  begin
    insert into public.notificacion (id_usuario, titulo, mensaje)
    values (auth.uid(), 'x', 'x');
    raise exception 'FALLO: un no administrador creó una notificación';
  exception when insufficient_privilege then
    raise notice 'OK: un no administrador no puede crear notificaciones';
  end;
end $$;

reset role;


-- ── Escenarios 1 y 2: el administrador ───────────────────────────────
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('pruebas.admin'), 'role', 'authenticated')::text,
  true);
set local role authenticated;

do $$
declare
  v_id      text := nullif(current_setting('pruebas.comercio_pendiente'), '');
  v_estado  text;
  v_dueno   uuid;
  v_avisos  int;
begin
  if current_setting('pruebas.admin') = '' then
    raise notice 'SALTADA: no hay ningún usuario con rol administrador';
    return;
  end if;
  if v_id is null then
    raise notice 'SALTADA: no hay comercios pendientes';
    return;
  end if;

  -- Rechazar sin motivo: se pide el motivo.
  begin
    perform public.decidir_solicitud('comercio', v_id, false, '   ');
    raise exception 'FALLO: se rechazó un comercio sin motivo';
  exception when invalid_parameter_value then
    raise notice 'OK: rechazar sin motivo pide el motivo (22023)';
  end;

  -- Aprobar: cambia el estado y notifica al dueño.
  perform public.decidir_solicitud('comercio', v_id, true, null);
  select estado, id_usuario into v_estado, v_dueno
    from public.comercio where id_comercio::text = v_id;
  if v_estado <> 'aprobado' then
    raise exception 'FALLO: el comercio quedó en estado %', v_estado;
  end if;
  raise notice 'OK: el administrador aprueba el comercio';

  reset role;  -- el administrador no puede leer notificaciones ajenas
  select count(*) into v_avisos
    from public.notificacion where id_usuario = v_dueno and leida = false;
  if v_avisos = 0 then
    raise exception 'FALLO: el dueño no recibió la notificación';
  end if;
  raise notice 'OK: el dueño recibió la notificación de la decisión';
  set local role authenticated;

  -- Decidir dos veces la misma solicitud no se permite.
  begin
    perform public.decidir_solicitud('comercio', v_id, true, null);
    raise exception 'FALLO: se decidió dos veces la misma solicitud';
  exception when no_data_found then
    raise notice 'OK: una solicitud ya decidida no se puede volver a decidir';
  end;
end $$;

rollback;
