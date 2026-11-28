-- =====================================================================
-- SmartCart · Sprint 3 · HU-23 · Seguimiento y notificaciones de órdenes
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint3_hu20_hu25.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. orden.cerrada_en: el cliente confirmó la recogida o la recepción.
--   2. orden_estado: el historial de estados de cada orden (la línea de
--      tiempo "Estado del pedido"), lo llena un trigger.
--   3. Aviso al cliente cada vez que cambia el estado de su orden, en la
--      tabla notificacion (HU-24). Lo hace un trigger, así que sirve para
--      los cambios del comercio (HU-21) y del repartidor (HU-22) sin que
--      ellos escriban avisos. Ese aviso dispara también el push.
--   4. confirmar_recepcion(): el cliente confirma la recogida o la
--      recepción y la orden se cierra.
--   5. ordenes_cliente() y detalle_orden(): la lista "En curso" /
--      "Historial" y el detalle de una orden.
--   6. dispositivo_push y registrar_dispositivo(): el token de Firebase de
--      cada teléfono, para las notificaciones push.
-- Las pruebas están en pruebas_hu23_politicas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Cierre de la orden por el cliente
-- ---------------------------------------------------------------------
alter table public.orden add column if not exists cerrada_en timestamptz;


-- ---------------------------------------------------------------------
-- 2. Historial de estados
-- ---------------------------------------------------------------------
create table if not exists public.orden_estado (
  id_orden_estado bigint generated always as identity primary key,
  id_orden        uuid not null references public.orden (id_orden) on delete cascade,
  estado          text not null,
  creado_en       timestamptz not null default now()
);

create index if not exists orden_estado_orden_idx
  on public.orden_estado (id_orden, creado_en);

alter table public.orden_estado enable row level security;

-- Lo ve quien ve la orden (cliente, comercio o administrador, por las
-- políticas de orden de la HU-20). Nadie lo escribe desde la app.
drop policy if exists orden_estado_select on public.orden_estado;
create policy orden_estado_select on public.orden_estado
  for select to authenticated
  using (exists (
    select 1 from public.orden o where o.id_orden = orden_estado.id_orden));

revoke insert, update, delete on public.orden_estado from authenticated;

-- Las órdenes que ya existían arrancan su historial con el estado actual.
insert into public.orden_estado (id_orden, estado, creado_en)
select o.id_orden, o.estado, o.creado_en
  from public.orden o
 where not exists (
   select 1 from public.orden_estado e where e.id_orden = o.id_orden);


-- ---------------------------------------------------------------------
-- 3. Triggers: historial, fecha de actualización y aviso al cliente
-- ---------------------------------------------------------------------

-- Texto del aviso para cada estado. Las órdenes con entrega no se "recogen":
-- el repartidor las lleva.
create or replace function public.mensaje_estado_orden(
  p_estado text,
  p_numero bigint,
  p_comercio text,
  p_tipo_entrega text
)
returns table (titulo text, mensaje text)
language sql
immutable
as $$
  select
    case p_estado
      when 'aceptada'           then 'Orden #' || p_numero || ' aceptada'
      when 'en_preparacion'     then 'Estamos preparando tu orden #' || p_numero
      when 'lista_para_recoger' then
        case when p_tipo_entrega = 'recogida'
             then '¡Tu orden #' || p_numero || ' está lista para recoger!'
             else 'Tu orden #' || p_numero || ' está lista para enviarse' end
      when 'en_camino'          then 'Tu orden #' || p_numero || ' va en camino'
      when 'recogida'           then 'Orden #' || p_numero || ' recogida'
      when 'entregada'          then 'Tu orden #' || p_numero || ' fue entregada'
      when 'rechazada'          then 'Orden #' || p_numero || ' rechazada'
      else 'Orden #' || p_numero || ' actualizada'
    end,
    case p_estado
      when 'aceptada'           then p_comercio || ' aceptó tu orden.'
      when 'en_preparacion'     then p_comercio || ' está alistando tus productos.'
      when 'lista_para_recoger' then
        case when p_tipo_entrega = 'recogida'
             then 'Acércate a ' || p_comercio || ' y muestra tu código de recogida.'
             else 'Un repartidor la recogerá en ' || p_comercio || '.' end
      when 'en_camino'          then 'El repartidor ya salió de ' || p_comercio || ' con tu pedido.'
      when 'recogida'           then 'Gracias por comprar en ' || p_comercio || '.'
      when 'entregada'          then 'Confirma la recepción en Mis órdenes.'
      when 'rechazada'          then p_comercio || ' no pudo atender tu orden.'
      else 'Revisa el estado en Mis órdenes.'
    end;
$$;

create or replace function public.orden_registrar_estado()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_comercio text;
  v_aviso record;
begin
  if tg_op = 'UPDATE' and new.estado is not distinct from old.estado then
    return new;
  end if;

  insert into public.orden_estado (id_orden, estado)
  values (new.id_orden, new.estado);

  -- Al nacer la orden no se avisa (el cliente acaba de confirmarla), ni
  -- cuando el cambio lo hizo el mismo cliente (confirmar la recogida).
  if tg_op = 'UPDATE' and auth.uid() is distinct from new.id_cliente then
    select c.nombre into v_comercio
      from public.comercio c where c.id_comercio = new.id_comercio;
    select * into v_aviso
      from public.mensaje_estado_orden(
        new.estado, new.numero, coalesce(v_comercio, 'El comercio'),
        new.tipo_entrega);
    insert into public.notificacion (id_usuario, titulo, mensaje)
    values (new.id_cliente, v_aviso.titulo, v_aviso.mensaje);
  end if;
  return new;
end;
$$;

revoke all on function public.orden_registrar_estado() from public;

drop trigger if exists orden_estado_historial on public.orden;
create trigger orden_estado_historial
  after insert or update of estado on public.orden
  for each row execute function public.orden_registrar_estado();

-- actualizado_en sigue cada cambio, venga de donde venga.
create or replace function public.orden_antes_de_actualizar()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

drop trigger if exists orden_fecha_actualizacion on public.orden;
create trigger orden_fecha_actualizacion
  before update on public.orden
  for each row execute function public.orden_antes_de_actualizar();


-- ---------------------------------------------------------------------
-- 4. Confirmar la recogida o la recepción (escenario 2)
--   · Recogida: con la orden "Lista para recoger" (o ya "Recogida").
--   · Entrega: con la orden "Entregada" por el repartidor (HU-22).
-- La orden queda cerrada; si era una recogida, pasa a "Recogida".
-- ---------------------------------------------------------------------
create or replace function public.confirmar_recepcion(p_id_orden uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orden;
begin
  select * into o from public.orden where id_orden = p_id_orden;
  if o.id_orden is null or o.id_cliente is distinct from auth.uid() then
    raise exception 'No encontramos esa orden.' using errcode = 'P0001';
  end if;
  if o.cerrada_en is not null then
    raise exception 'Ya confirmaste esta orden.' using errcode = 'P0001';
  end if;

  if o.tipo_entrega = 'recogida'
     and o.estado in ('lista_para_recoger', 'recogida') then
    update public.orden
       set estado = 'recogida', cerrada_en = now()
     where id_orden = p_id_orden;
  elsif o.tipo_entrega = 'entrega' and o.estado = 'entregada' then
    update public.orden set cerrada_en = now() where id_orden = p_id_orden;
  else
    raise exception 'Todavía no puedes confirmar esta orden: espera a que esté %.',
      case when o.tipo_entrega = 'recogida' then 'lista para recoger'
           else 'entregada' end
      using errcode = 'P0001';
  end if;

  return now();
end;
$$;

revoke all on function public.confirmar_recepcion(uuid) from public, anon;
grant execute on function public.confirmar_recepcion(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 5. Lista y detalle para el cliente
-- "En curso": sin cerrar y no rechazada. "Historial": cerrada o rechazada.
-- p_limite = tamaño de página + 1 (la app sabe así si hay otra página).
-- ---------------------------------------------------------------------
create or replace function public.ordenes_cliente(
  p_en_curso       boolean,
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_orden              uuid,
  numero                bigint,
  comercio              text,
  estado                text,
  tipo_entrega          text,
  total                 integer,
  creado_en             timestamptz,
  actualizado_en        timestamptz,
  cerrada_en            timestamptz,
  productos             integer,
  tiene_repartidor      boolean,
  calificada_comercio   boolean,
  calificada_repartidor boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select o.id_orden,
         o.numero,
         c.nombre::text,
         o.estado,
         o.tipo_entrega,
         o.total,
         o.creado_en,
         o.actualizado_en,
         o.cerrada_en,
         (select coalesce(sum(i.cantidad), 0)::integer
            from public.orden_item i where i.id_orden = o.id_orden),
         o.id_repartidor is not null,
         exists (select 1 from public.calificacion k
                  where k.id_orden = o.id_orden and k.tipo = 'comercio'),
         exists (select 1 from public.calificacion k
                  where k.id_orden = o.id_orden and k.tipo = 'repartidor')
    from public.orden o
    join public.comercio c on c.id_comercio = o.id_comercio
   where o.id_cliente = auth.uid()
     and (o.cerrada_en is null and o.estado <> 'rechazada') = p_en_curso
   order by o.actualizado_en desc, o.id_orden
   limit least(greatest(coalesce(p_limite, 21), 1), 51)
   offset greatest(coalesce(p_desplazamiento, 0), 0);
$$;

revoke all on function public.ordenes_cliente(boolean, integer, integer) from public, anon;
grant execute on function public.ordenes_cliente(boolean, integer, integer) to authenticated;

-- Cuántas órdenes tiene el cliente en curso (el número de la pestaña).
create or replace function public.ordenes_en_curso()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
    from public.orden o
   where o.id_cliente = auth.uid()
     and o.cerrada_en is null and o.estado <> 'rechazada';
$$;

revoke all on function public.ordenes_en_curso() from public, anon;
grant execute on function public.ordenes_en_curso() to authenticated;

-- El detalle: datos de la orden y del comercio. Los productos y el
-- historial se leen de orden_item y orden_estado (sus políticas ya dejan
-- verlos a quien ve la orden).
create or replace function public.detalle_orden(p_id_orden uuid)
returns table (
  id_orden           uuid,
  numero             bigint,
  estado             text,
  tipo_entrega       text,
  total              integer,
  creado_en          timestamptz,
  actualizado_en     timestamptz,
  cerrada_en         timestamptz,
  direccion_entrega  text,
  comercio           text,
  comercio_direccion text,
  comercio_ciudad    text,
  comercio_latitud   double precision,
  comercio_longitud  double precision,
  tiene_repartidor   boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select o.id_orden, o.numero, o.estado, o.tipo_entrega, o.total,
         o.creado_en, o.actualizado_en, o.cerrada_en, o.direccion_entrega,
         c.nombre::text, c.direccion::text, c.ciudad::text,
         -- En algunas bases son numeric (ver sprint3_hu19.sql).
         c.latitud::double precision, c.longitud::double precision,
         o.id_repartidor is not null
    from public.orden o
    join public.comercio c on c.id_comercio = o.id_comercio
   where o.id_orden = p_id_orden and o.id_cliente = auth.uid();
$$;

revoke all on function public.detalle_orden(uuid) from public, anon;
grant execute on function public.detalle_orden(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 6. Dispositivos para las notificaciones push (Firebase)
-- Un token por teléfono. Si el teléfono cambia de cuenta, el token pasa a
-- la cuenta nueva. Solo lo lee la Edge Function (con la llave de servicio).
-- ---------------------------------------------------------------------
create table if not exists public.dispositivo_push (
  token          text primary key,
  id_usuario     uuid not null references public.usuario (id_usuario) on delete cascade,
  plataforma     text not null default 'android',
  actualizado_en timestamptz not null default now()
);

alter table public.dispositivo_push drop constraint if exists dispositivo_push_plataforma_check;
alter table public.dispositivo_push add constraint dispositivo_push_plataforma_check
  check (plataforma in ('android', 'ios', 'web'));

create index if not exists dispositivo_push_usuario_idx
  on public.dispositivo_push (id_usuario);

alter table public.dispositivo_push enable row level security;
revoke all on public.dispositivo_push from authenticated, anon;

create or replace function public.registrar_dispositivo(
  p_token text,
  p_plataforma text default 'android'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Inicia sesión para activar las notificaciones.'
      using errcode = 'P0001';
  end if;
  if p_token is null or char_length(btrim(p_token)) < 20 then
    raise exception 'El token del dispositivo no es válido.'
      using errcode = 'P0001';
  end if;
  insert into public.dispositivo_push (token, id_usuario, plataforma, actualizado_en)
  values (btrim(p_token), auth.uid(), coalesce(p_plataforma, 'android'), now())
  on conflict (token) do update
    set id_usuario = excluded.id_usuario,
        plataforma = excluded.plataforma,
        actualizado_en = now();
end;
$$;

revoke all on function public.registrar_dispositivo(text, text) from public, anon;
grant execute on function public.registrar_dispositivo(text, text) to authenticated;

-- Al cerrar sesión el teléfono deja de recibir avisos de esa cuenta.
create or replace function public.quitar_dispositivo(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.dispositivo_push
   where token = btrim(p_token) and id_usuario = auth.uid();
$$;

revoke all on function public.quitar_dispositivo(text) from public, anon;
grant execute on function public.quitar_dispositivo(text) to authenticated;
