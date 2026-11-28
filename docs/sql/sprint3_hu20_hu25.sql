-- =====================================================================
-- SmartCart · Sprint 3 · HU-20 (confirmación del carrito y generación de
-- órdenes) y HU-25 (calificaciones)
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint3_hu15_hu16.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. compra, orden y orden_item (con RLS): una compra tiene una orden por
--      cada comercio registrado; la orden nace en estado "generada".
--   2. lineas_compra() (interna), previsualizar_compra() y
--      confirmar_compra(): la base calcula los precios (los de la app no
--      cuentan), valida que cada comercio ofrezca lo elegido y genera todo
--      en una sola transacción.
--   3. calificacion y calificar_orden(): una calificación por orden y por
--      destinatario (comercio o repartidor), solo de órdenes completadas.
--      El promedio queda en usuario.calificacion_promedio.
--   4. mis_ordenes(): las órdenes del cliente, paginadas.
-- Las pruebas están en pruebas_hu20_hu25_politicas.sql.
--
-- ESTADOS DE LA ORDEN (la HU-21 define las transiciones entre ellos):
--   generada → aceptada → en_preparacion → lista_para_recoger →
--   (en_camino) → recogida | entregada,   y   rechazada.
-- "Completada" (la que se puede calificar) es recogida o entregada.
--
-- Los mensajes de las funciones salen en español (SQLSTATE P0001).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Compras, órdenes y sus productos
-- ---------------------------------------------------------------------
create table if not exists public.compra (
  id_compra  uuid primary key default gen_random_uuid(),
  id_cliente uuid not null references public.usuario (id_usuario) on delete cascade,
  total      integer not null,
  creado_en  timestamptz not null default now()
);

alter table public.compra drop constraint if exists compra_total_check;
alter table public.compra add constraint compra_total_check check (total > 0);

create table if not exists public.orden (
  id_orden          uuid primary key default gen_random_uuid(),
  numero            bigint generated always as identity,
  id_compra         uuid not null references public.compra (id_compra) on delete cascade,
  id_comercio       uuid not null references public.comercio (id_comercio),
  id_cliente        uuid not null references public.usuario (id_usuario) on delete cascade,
  -- La asigna la HU-22 al aceptar la entrega; HU-25 la usa para calificar.
  id_repartidor     uuid references public.usuario (id_usuario),
  estado            text not null default 'generada',
  tipo_entrega      text not null,
  direccion_entrega text,
  total             integer not null,
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

alter table public.orden drop constraint if exists orden_estado_check;
alter table public.orden add constraint orden_estado_check
  check (estado in ('generada', 'aceptada', 'en_preparacion',
                    'lista_para_recoger', 'en_camino', 'recogida',
                    'entregada', 'rechazada'));

alter table public.orden drop constraint if exists orden_tipo_entrega_check;
alter table public.orden add constraint orden_tipo_entrega_check
  check (tipo_entrega in ('recogida', 'entrega'));

-- Una entrega necesita saber adónde llevarla.
alter table public.orden drop constraint if exists orden_direccion_check;
alter table public.orden add constraint orden_direccion_check
  check (tipo_entrega = 'recogida'
         or (direccion_entrega is not null
             and char_length(btrim(direccion_entrega)) >= 5));

alter table public.orden drop constraint if exists orden_total_check;
alter table public.orden add constraint orden_total_check check (total > 0);

create index if not exists orden_cliente_idx
  on public.orden (id_cliente, creado_en desc);
create index if not exists orden_comercio_idx
  on public.orden (id_comercio, creado_en desc);

-- Lo que se compró, con el nombre y el precio de ESE momento: si el comercio
-- cambia el precio después, la orden no cambia.
create table if not exists public.orden_item (
  id_item         uuid primary key default gen_random_uuid(),
  id_orden        uuid not null references public.orden (id_orden) on delete cascade,
  id_producto     uuid references public.producto (id_producto) on delete set null,
  nombre          text not null,
  marca           text,
  cantidad        integer not null,
  precio_unitario integer not null
);

alter table public.orden_item drop constraint if exists orden_item_cantidad_check;
alter table public.orden_item add constraint orden_item_cantidad_check
  check (cantidad between 1 and 99);
alter table public.orden_item drop constraint if exists orden_item_precio_check;
alter table public.orden_item add constraint orden_item_precio_check
  check (precio_unitario > 0);

create index if not exists orden_item_orden_idx on public.orden_item (id_orden);

-- RLS: el cliente ve lo suyo; el comercio, las órdenes de SU establecimiento;
-- el administrador, todo. Nadie escribe directo: lo hace confirmar_compra().
alter table public.compra enable row level security;
alter table public.orden enable row level security;
alter table public.orden_item enable row level security;

drop policy if exists compra_select_own on public.compra;
create policy compra_select_own on public.compra
  for select to authenticated
  using (id_cliente = auth.uid());

drop policy if exists compra_select_admin on public.compra;
create policy compra_select_admin on public.compra
  for select to authenticated
  using (public.es_administrador());

drop policy if exists orden_select_cliente on public.orden;
create policy orden_select_cliente on public.orden
  for select to authenticated
  using (id_cliente = auth.uid());

drop policy if exists orden_select_comercio on public.orden;
create policy orden_select_comercio on public.orden
  for select to authenticated
  using (exists (
    select 1 from public.comercio c
     where c.id_comercio = orden.id_comercio and c.id_usuario = auth.uid()));

drop policy if exists orden_select_admin on public.orden;
create policy orden_select_admin on public.orden
  for select to authenticated
  using (public.es_administrador());

-- Los productos de una orden los ve quien ve la orden.
drop policy if exists orden_item_select on public.orden_item;
create policy orden_item_select on public.orden_item
  for select to authenticated
  using (exists (
    select 1 from public.orden o where o.id_orden = orden_item.id_orden));

revoke insert, update, delete on public.compra from authenticated;
revoke insert, update, delete on public.orden from authenticated;
revoke insert, update, delete on public.orden_item from authenticated;


-- ---------------------------------------------------------------------
-- 2. Resolver y confirmar la compra
-- p_lineas:   [{"id_producto": "...", "cantidad": 2}, ...]
-- p_entregas: [{"id_comercio": "...", "tipo": "recogida"|"entrega",
--               "direccion": "..."}, ...]   (una por comercio)
-- ---------------------------------------------------------------------

-- Interna: para cada línea, el producto, su comercio y el precio vigente
-- (el de la promoción si hoy está dentro de sus fechas; si no, el normal).
-- Solo trae productos de comercios APROBADOS.
create or replace function public.lineas_compra(p_lineas jsonb)
returns table (
  id_producto   uuid,
  nombre        text,
  marca         text,
  cantidad      integer,
  id_comercio   uuid,
  comercio      text,
  tipo_servicio text,
  precio        integer,
  disponible    boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id_producto,
         p.nombre::text,
         p.marca::text,
         l.cantidad,
         c.id_comercio,
         c.nombre::text,
         c.tipo_servicio::text,
         case when pr.id_promocion is not null
                   and current_date between pr.fecha_inicio and pr.fecha_fin
              then pr.precio_promocional else pp.precio end,
         (pp.precio is not null and pp.disponible)
    from jsonb_to_recordset(p_lineas) as l(id_producto uuid, cantidad integer)
    join public.producto p on p.id_producto = l.id_producto
    join public.comercio c
      on c.id_comercio = p.id_comercio and c.estado = 'aprobado'
    left join public.precio_producto pp on pp.id_producto = p.id_producto
    left join public.promocion pr on pr.id_producto = p.id_producto
   order by c.nombre, p.nombre;
$$;

revoke all on function public.lineas_compra(jsonb) from public, anon, authenticated;


-- Lo que la app muestra antes de confirmar: por cada línea, el comercio, lo
-- que ofrece (recogida, entrega o ambos) y el precio de hoy.
create or replace function public.previsualizar_compra(p_lineas jsonb)
returns table (
  id_producto   uuid,
  nombre        text,
  marca         text,
  cantidad      integer,
  id_comercio   uuid,
  comercio      text,
  tipo_servicio text,
  precio        integer,
  disponible    boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para comprar.';
  end if;
  if p_lineas is null or jsonb_typeof(p_lineas) <> 'array'
     or jsonb_array_length(p_lineas) = 0 then
    raise exception 'Tu carrito está vacío. Agrega productos para continuar.';
  end if;

  return query select * from public.lineas_compra(p_lineas);
end;
$$;

revoke all on function public.previsualizar_compra(jsonb) from public, anon;
grant execute on function public.previsualizar_compra(jsonb) to authenticated;


-- Genera la compra con una orden por cada comercio, todo o nada.
create or replace function public.confirmar_compra(
  p_lineas   jsonb,
  p_entregas jsonb
)
returns table (
  id_compra    uuid,
  id_orden     uuid,
  numero       bigint,
  id_comercio  uuid,
  comercio     text,
  tipo_entrega text,
  total        integer
)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_compra  uuid;
  v_orden   uuid;
  v_numero  bigint;
  v_total   integer;
  v_tipo    text;
  v_dir     text;
  g         record;
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para comprar.';
  end if;

  -- Un carrito vacío no genera nada.
  if p_lineas is null or jsonb_typeof(p_lineas) <> 'array'
     or jsonb_array_length(p_lineas) = 0 then
    raise exception 'Tu carrito está vacío. Agrega productos para confirmar la compra.';
  end if;
  if jsonb_array_length(p_lineas) > 100 then
    raise exception 'Tu compra tiene demasiados productos (máximo 100).';
  end if;
  if exists (
    select 1 from jsonb_to_recordset(p_lineas) as l(id_producto uuid, cantidad integer)
     where l.id_producto is null or l.cantidad is null
        or l.cantidad not between 1 and 99) then
    raise exception 'Hay un producto con una cantidad no válida (de 1 a 99).';
  end if;
  if (select count(distinct l.id_producto)
        from jsonb_to_recordset(p_lineas) as l(id_producto uuid, cantidad integer))
     <> jsonb_array_length(p_lineas) then
    raise exception 'Hay productos repetidos en la compra.';
  end if;

  -- Todos los productos deben seguir en comercios aprobados, con precio y
  -- disponibles.
  if (select count(*) from public.lineas_compra(p_lineas))
     <> jsonb_array_length(p_lineas) then
    raise exception 'Uno de los productos ya no está disponible. Revisa tu carrito.';
  end if;
  if exists (select 1 from public.lineas_compra(p_lineas) l
              where not l.disponible or l.precio is null) then
    raise exception 'Hay productos agotados o sin precio. Quítalos del carrito para continuar.';
  end if;

  if p_entregas is null or jsonb_typeof(p_entregas) <> 'array' then
    raise exception 'Elige recogida o entrega para cada comercio.';
  end if;

  select sum(l.precio * l.cantidad)::integer into v_total
    from public.lineas_compra(p_lineas) l;
  insert into public.compra (id_cliente, total)
  values (auth.uid(), v_total)
  returning compra.id_compra into v_compra;

  for g in
    select l.id_comercio, l.comercio as nombre, l.tipo_servicio,
           sum(l.precio * l.cantidad)::integer as subtotal
      from public.lineas_compra(p_lineas) l
     group by l.id_comercio, l.comercio, l.tipo_servicio
     order by l.comercio
  loop
    select e.tipo, e.direccion into v_tipo, v_dir
      from jsonb_to_recordset(p_entregas)
             as e(id_comercio uuid, tipo text, direccion text)
     where e.id_comercio = g.id_comercio;
    if not found then
      raise exception 'Elige recogida o entrega para %.', g.nombre;
    end if;
    if v_tipo is null or v_tipo not in ('recogida', 'entrega') then
      raise exception 'Elige recogida o entrega para %.', g.nombre;
    end if;
    if v_tipo = 'entrega' and g.tipo_servicio not in ('entrega', 'ambos') then
      raise exception '% no ofrece entrega. Elige recogida.', g.nombre;
    end if;
    if v_tipo = 'entrega'
       and (v_dir is null or char_length(btrim(v_dir)) < 5) then
      raise exception 'Escribe la dirección de entrega para %.', g.nombre;
    end if;

    insert into public.orden
      (id_compra, id_comercio, id_cliente, tipo_entrega, direccion_entrega, total)
    values
      (v_compra, g.id_comercio, auth.uid(), v_tipo,
       case when v_tipo = 'entrega' then btrim(v_dir) end, g.subtotal)
    returning orden.id_orden, orden.numero into v_orden, v_numero;

    insert into public.orden_item
      (id_orden, id_producto, nombre, marca, cantidad, precio_unitario)
    select v_orden, l.id_producto, l.nombre, l.marca, l.cantidad, l.precio
      from public.lineas_compra(p_lineas) l
     where l.id_comercio = g.id_comercio;

    return query select v_compra, v_orden, v_numero, g.id_comercio,
                        g.nombre::text, v_tipo, g.subtotal;
  end loop;

  -- Lo comprado sale del carrito.
  delete from public.carrito_item ci
   where ci.id_usuario = auth.uid()
     and ci.id_producto in (
       select l.id_producto
         from jsonb_to_recordset(p_lineas) as l(id_producto uuid, cantidad integer));
end;
$$;

revoke all on function public.confirmar_compra(jsonb, jsonb) from public, anon;
grant execute on function public.confirmar_compra(jsonb, jsonb) to authenticated;


-- ---------------------------------------------------------------------
-- 3. Calificaciones (HU-25)
-- ---------------------------------------------------------------------
create table if not exists public.calificacion (
  id_calificacion uuid primary key default gen_random_uuid(),
  id_orden        uuid not null references public.orden (id_orden) on delete cascade,
  id_cliente      uuid not null references public.usuario (id_usuario) on delete cascade,
  tipo            text not null,
  -- La cuenta calificada: el dueño del comercio o el repartidor.
  id_calificado   uuid not null references public.usuario (id_usuario) on delete cascade,
  estrellas       integer not null,
  comentario      text,
  creado_en       timestamptz not null default now()
);

alter table public.calificacion drop constraint if exists calificacion_tipo_check;
alter table public.calificacion add constraint calificacion_tipo_check
  check (tipo in ('comercio', 'repartidor'));

alter table public.calificacion drop constraint if exists calificacion_estrellas_check;
alter table public.calificacion add constraint calificacion_estrellas_check
  check (estrellas between 1 and 5);

alter table public.calificacion drop constraint if exists calificacion_comentario_check;
alter table public.calificacion add constraint calificacion_comentario_check
  check (comentario is null or char_length(comentario) <= 500);

-- Una sola vez por orden y por destinatario.
create unique index if not exists calificacion_orden_tipo_uq
  on public.calificacion (id_orden, tipo);

create index if not exists calificacion_calificado_idx
  on public.calificacion (id_calificado, creado_en desc);

alter table public.calificacion enable row level security;

-- Cada quien ve las que dio, las que recibió y, el administrador, todas.
drop policy if exists calificacion_select_cliente on public.calificacion;
create policy calificacion_select_cliente on public.calificacion
  for select to authenticated
  using (id_cliente = auth.uid());

drop policy if exists calificacion_select_calificado on public.calificacion;
create policy calificacion_select_calificado on public.calificacion
  for select to authenticated
  using (id_calificado = auth.uid());

drop policy if exists calificacion_select_admin on public.calificacion;
create policy calificacion_select_admin on public.calificacion
  for select to authenticated
  using (public.es_administrador());

revoke insert, update, delete on public.calificacion from authenticated;

-- Califica a quien atendió la orden. Devuelve el promedio y el total de
-- calificaciones de esa persona, ya con la nueva.
create or replace function public.calificar_orden(
  p_id_orden   uuid,
  p_tipo       text,
  p_estrellas  integer,
  p_comentario text default null
)
returns table (promedio numeric, total integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  o           public.orden%rowtype;
  v_calificado uuid;
  v_comentario text := nullif(btrim(coalesce(p_comentario, '')), '');
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para calificar.';
  end if;
  if p_tipo is null or p_tipo not in ('comercio', 'repartidor') then
    raise exception 'Elige a quién calificas: el comercio o el repartidor.';
  end if;
  if p_estrellas is null or p_estrellas not between 1 and 5 then
    raise exception 'La calificación va de 1 a 5 estrellas.';
  end if;
  if v_comentario is not null and char_length(v_comentario) > 500 then
    raise exception 'El comentario no puede pasar de 500 caracteres.';
  end if;

  select * into o from public.orden where id_orden = p_id_orden for update;
  if not found or o.id_cliente <> auth.uid() then
    raise exception 'Solo el cliente de una orden puede calificarla.';
  end if;
  if o.estado not in ('recogida', 'entregada') then
    raise exception 'Solo puedes calificar una orden completada.';
  end if;

  if p_tipo = 'comercio' then
    select c.id_usuario into v_calificado
      from public.comercio c where c.id_comercio = o.id_comercio;
  else
    v_calificado := o.id_repartidor;
    if v_calificado is null then
      raise exception 'Esta orden no tuvo repartidor.';
    end if;
  end if;

  if exists (select 1 from public.calificacion k
              where k.id_orden = p_id_orden and k.tipo = p_tipo) then
    raise exception 'Ya calificaste esta orden.';
  end if;

  insert into public.calificacion
    (id_orden, id_cliente, tipo, id_calificado, estrellas, comentario)
  values
    (p_id_orden, auth.uid(), p_tipo, v_calificado, p_estrellas, v_comentario);

  -- El promedio vive en la cuenta de quien recibe las calificaciones (la app
  -- ya lo lee de ahí para su perfil).
  update public.usuario u
     set calificacion_promedio = (
           select round(avg(k.estrellas)::numeric, 1)
             from public.calificacion k where k.id_calificado = v_calificado),
         total_calificaciones = (
           select count(*)::integer
             from public.calificacion k where k.id_calificado = v_calificado)
   where u.id_usuario = v_calificado;

  return query
    select u.calificacion_promedio::numeric, u.total_calificaciones::integer
      from public.usuario u where u.id_usuario = v_calificado;
end;
$$;

revoke all on function public.calificar_orden(uuid, text, integer, text) from public, anon;
grant execute on function public.calificar_orden(uuid, text, integer, text) to authenticated;


-- ---------------------------------------------------------------------
-- 4. Mis órdenes (paginadas: limite = tamaño de página + 1)
-- Va después de calificacion porque la usa para saber qué falta calificar.
-- ---------------------------------------------------------------------
create or replace function public.mis_ordenes(
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
         o.id_repartidor is not null,
         exists (select 1 from public.calificacion k
                  where k.id_orden = o.id_orden and k.tipo = 'comercio'),
         exists (select 1 from public.calificacion k
                  where k.id_orden = o.id_orden and k.tipo = 'repartidor')
    from public.orden o
    join public.comercio c on c.id_comercio = o.id_comercio
   where o.id_cliente = auth.uid()
   order by o.creado_en desc, o.id_orden
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_ordenes(integer, integer) from public, anon;
grant execute on function public.mis_ordenes(integer, integer) to authenticated;
