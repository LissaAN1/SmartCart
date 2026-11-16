-- =====================================================================
-- SmartCart · Sprint 2 · HU-17 · Carrito de compras y favoritos
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu14.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. es_cliente() y producto_disponible(): ayudas para las políticas.
--   2. Lectura de productos para clientes (solo de comercios aprobados).
--   3. carrito_item: el carrito de cada cliente (una fila por producto).
--   4. favorito_producto y favorito_comercio.
--   5. Funciones: agregar_al_carrito(), mi_carrito(), mis_favoritos_productos(),
--      mis_favoritos_comercios(), explorar_productos() y explorar_comercios().
-- Las pruebas de las políticas están en pruebas_hu17_politicas.sql.
--
-- Los mensajes de las funciones salen en español y la app los muestra tal
-- cual (SQLSTATE P0001).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Ayudas para las políticas
-- security definer: leen tablas sin depender de sus propias políticas.
-- ---------------------------------------------------------------------
create or replace function public.es_cliente()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_rol ur
    join public.rol r on r.id_rol = ur.id_rol
    where ur.id_usuario = auth.uid()
      and r.codigo = 'cliente'
  );
$$;

revoke all on function public.es_cliente() from public;
grant execute on function public.es_cliente() to authenticated;

-- ¿Existe el producto y su comercio está aprobado? Un producto de un comercio
-- pendiente o rechazado no se puede agregar al carrito ni a favoritos.
create or replace function public.producto_disponible(p_id_producto uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.producto p
    join public.comercio c on c.id_comercio = p.id_comercio
    where p.id_producto = p_id_producto
      and c.estado = 'aprobado'
  );
$$;

revoke all on function public.producto_disponible(uuid) from public;
grant execute on function public.producto_disponible(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 2. Los clientes leen los productos de comercios aprobados
-- Es solo lectura: crear, editar y eliminar sigue siendo del dueño
-- (sprint2_hu10.sql). Las políticas permisivas se suman con OR.
-- La búsqueda de la HU-12 puede reutilizar esta política.
-- ---------------------------------------------------------------------
drop policy if exists producto_select_cliente on public.producto;
create policy producto_select_cliente on public.producto
  for select to authenticated
  using (public.es_cliente() and public.es_comercio_aprobado(id_comercio));


-- ---------------------------------------------------------------------
-- 3. Carrito
-- Una fila por producto: agregar de nuevo suma a la cantidad, no duplica.
-- La app NO inserta directo: usa agregar_al_carrito(), que aplica los
-- límites (99 unidades por producto, 100 productos distintos).
-- ---------------------------------------------------------------------
create table if not exists public.carrito_item (
  id_usuario     uuid not null references public.usuario (id_usuario) on delete cascade,
  id_producto    uuid not null references public.producto (id_producto) on delete cascade,
  cantidad       integer not null default 1,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  primary key (id_usuario, id_producto)
);

alter table public.carrito_item drop constraint if exists carrito_item_cantidad_check;
alter table public.carrito_item add constraint carrito_item_cantidad_check
  check (cantidad between 1 and 99);

create index if not exists carrito_item_usuario_idx
  on public.carrito_item (id_usuario, actualizado_en desc);

-- Mantiene al día la fecha de la última modificación.
create or replace function public.carrito_item_tocar()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

drop trigger if exists carrito_item_tocar on public.carrito_item;
create trigger carrito_item_tocar
  before update on public.carrito_item
  for each row execute function public.carrito_item_tocar();

alter table public.carrito_item enable row level security;

drop policy if exists carrito_item_select_own on public.carrito_item;
create policy carrito_item_select_own on public.carrito_item
  for select to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

drop policy if exists carrito_item_update_own on public.carrito_item;
create policy carrito_item_update_own on public.carrito_item
  for update to authenticated
  using (id_usuario = auth.uid() and public.es_cliente())
  with check (id_usuario = auth.uid() and public.es_cliente());

drop policy if exists carrito_item_delete_own on public.carrito_item;
create policy carrito_item_delete_own on public.carrito_item
  for delete to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

-- Insertar solo por la función; actualizar, solo la cantidad.
revoke insert, update on public.carrito_item from authenticated;
grant update (cantidad) on public.carrito_item to authenticated;


-- ---------------------------------------------------------------------
-- 4. Favoritos: productos y comercios
-- id_usuario toma por defecto el de la sesión: la app inserta solo el id del
-- producto o del comercio, y la política exige que sea el de quien inserta.
-- ---------------------------------------------------------------------
create table if not exists public.favorito_producto (
  id_usuario  uuid not null default auth.uid() references public.usuario (id_usuario) on delete cascade,
  id_producto uuid not null references public.producto (id_producto) on delete cascade,
  creado_en   timestamptz not null default now(),
  primary key (id_usuario, id_producto)
);

create table if not exists public.favorito_comercio (
  id_usuario  uuid not null default auth.uid() references public.usuario (id_usuario) on delete cascade,
  id_comercio uuid not null references public.comercio (id_comercio) on delete cascade,
  creado_en   timestamptz not null default now(),
  primary key (id_usuario, id_comercio)
);

create index if not exists favorito_producto_usuario_idx
  on public.favorito_producto (id_usuario, creado_en desc);
create index if not exists favorito_comercio_usuario_idx
  on public.favorito_comercio (id_usuario, creado_en desc);

alter table public.favorito_producto enable row level security;
alter table public.favorito_comercio enable row level security;

drop policy if exists favorito_producto_select_own on public.favorito_producto;
create policy favorito_producto_select_own on public.favorito_producto
  for select to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

drop policy if exists favorito_producto_insert_own on public.favorito_producto;
create policy favorito_producto_insert_own on public.favorito_producto
  for insert to authenticated
  with check (
    id_usuario = auth.uid()
    and public.es_cliente()
    and public.producto_disponible(id_producto)
  );

drop policy if exists favorito_producto_delete_own on public.favorito_producto;
create policy favorito_producto_delete_own on public.favorito_producto
  for delete to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

drop policy if exists favorito_comercio_select_own on public.favorito_comercio;
create policy favorito_comercio_select_own on public.favorito_comercio
  for select to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

drop policy if exists favorito_comercio_insert_own on public.favorito_comercio;
create policy favorito_comercio_insert_own on public.favorito_comercio
  for insert to authenticated
  with check (
    id_usuario = auth.uid()
    and public.es_cliente()
    and public.es_comercio_aprobado(id_comercio)
  );

drop policy if exists favorito_comercio_delete_own on public.favorito_comercio;
create policy favorito_comercio_delete_own on public.favorito_comercio
  for delete to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

-- Un favorito se crea o se borra; no se edita.
revoke update on public.favorito_producto from authenticated;
revoke update on public.favorito_comercio from authenticated;


-- ---------------------------------------------------------------------
-- 5. Funciones
-- ---------------------------------------------------------------------
-- Las columnas de texto se devuelven con ::text: en la base real `comercio.nombre`
-- y otras columnas son varchar, y las funciones plpgsql exigen que el tipo
-- devuelto sea exactamente el declarado.

-- Agrega un producto al carrito. Si ya está, suma a la cantidad. Devuelve la
-- cantidad que queda.
create or replace function public.agregar_al_carrito(
  p_id_producto uuid,
  p_cantidad    integer default 1
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  c_max_unidades constant integer := 99;
  c_max_productos constant integer := 100;
  v_actual  integer;
  v_lineas  integer;
  v_nueva   integer;
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para usar el carrito.';
  end if;
  if p_cantidad is null or p_cantidad < 1 or p_cantidad > c_max_unidades then
    raise exception 'La cantidad debe estar entre 1 y %.', c_max_unidades;
  end if;
  if not public.producto_disponible(p_id_producto) then
    raise exception 'Ese producto ya no está disponible.';
  end if;

  select cantidad into v_actual
    from public.carrito_item
   where id_usuario = auth.uid() and id_producto = p_id_producto;

  if found then
    if v_actual >= c_max_unidades then
      raise exception 'Ya tienes % unidades de este producto, el máximo por producto.',
        c_max_unidades;
    end if;
    v_nueva := least(c_max_unidades, v_actual + p_cantidad);
    update public.carrito_item
       set cantidad = v_nueva
     where id_usuario = auth.uid() and id_producto = p_id_producto;
  else
    select count(*) into v_lineas
      from public.carrito_item where id_usuario = auth.uid();
    if v_lineas >= c_max_productos then
      raise exception 'Tu carrito está lleno: el máximo es de % productos distintos.',
        c_max_productos;
    end if;
    v_nueva := p_cantidad;
    insert into public.carrito_item (id_usuario, id_producto, cantidad)
    values (auth.uid(), p_id_producto, v_nueva);
  end if;

  return v_nueva;
end;
$$;

revoke all on function public.agregar_al_carrito(uuid, integer) from public;
grant execute on function public.agregar_al_carrito(uuid, integer) to authenticated;

-- El carrito de quien llama, con los datos del producto y el nombre del
-- comercio (que el cliente no puede leer de la tabla `comercio`). No filtra
-- por comercio aprobado: así la persona siempre puede quitar lo que ya tenía.
create or replace function public.mi_carrito()
returns table (
  id_producto   uuid,
  id_categoria  uuid,
  nombre        text,
  marca         text,
  codigo_barras text,
  categoria     text,
  id_comercio   uuid,
  comercio      text,
  cantidad      integer
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id_producto, p.id_categoria, p.nombre::text, p.marca::text,
         p.codigo_barras::text, coalesce(k.nombre, '')::text, p.id_comercio,
         c.nombre::text, i.cantidad
    from public.carrito_item i
    join public.producto p on p.id_producto = i.id_producto
    join public.comercio c on c.id_comercio = p.id_comercio
    left join public.categoria k on k.id_categoria = p.id_categoria
   where i.id_usuario = auth.uid()
   order by i.actualizado_en desc, p.id_producto
   limit 100;
$$;

revoke all on function public.mi_carrito() from public;
grant execute on function public.mi_carrito() to authenticated;

-- Favoritos de productos de quien llama, del más reciente al más antiguo.
-- limite = tamaño de página + 1, como el resto de listas.
create or replace function public.mis_favoritos_productos(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_producto   uuid,
  id_categoria  uuid,
  nombre        text,
  marca         text,
  codigo_barras text,
  categoria     text,
  id_comercio   uuid,
  comercio      text
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id_producto, p.id_categoria, p.nombre::text, p.marca::text,
         p.codigo_barras::text, coalesce(k.nombre, '')::text, p.id_comercio,
         c.nombre::text
    from public.favorito_producto f
    join public.producto p on p.id_producto = f.id_producto
    join public.comercio c on c.id_comercio = p.id_comercio
    left join public.categoria k on k.id_categoria = p.id_categoria
   where f.id_usuario = auth.uid()
   order by f.creado_en desc, p.id_producto
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_favoritos_productos(integer, integer) from public;
grant execute on function public.mis_favoritos_productos(integer, integer) to authenticated;

create or replace function public.mis_favoritos_comercios(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_comercio uuid,
  nombre      text,
  direccion   text,
  ciudad      text
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id_comercio, c.nombre::text, c.direccion::text, c.ciudad::text
    from public.favorito_comercio f
    join public.comercio c on c.id_comercio = f.id_comercio
   where f.id_usuario = auth.uid()
   order by f.creado_en desc, c.id_comercio
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_favoritos_comercios(integer, integer) from public;
grant execute on function public.mis_favoritos_comercios(integer, integer) to authenticated;

-- Productos de comercios APROBADOS, para que el cliente los explore y los
-- agregue. Filtra por nombre o marca. Es la lista mínima de la HU-17; la
-- búsqueda completa (rango de precios, código de barras) es la HU-12.
create or replace function public.explorar_productos(
  p_texto          text    default '',
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_producto   uuid,
  id_categoria  uuid,
  nombre        text,
  marca         text,
  codigo_barras text,
  categoria     text,
  id_comercio   uuid,
  comercio      text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  -- El texto se usa como patrón de ilike: se escapan % _ y \ para que
  -- cuenten como letras.
  v_patron text := '%' || replace(replace(replace(coalesce(btrim(p_texto), ''),
                    '\', '\\'), '%', '\%'), '_', '\_') || '%';
begin
  if not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para explorar productos.';
  end if;

  return query
  select p.id_producto, p.id_categoria, p.nombre::text, p.marca::text,
         p.codigo_barras::text, coalesce(k.nombre, '')::text, p.id_comercio,
         c.nombre::text
    from public.producto p
    join public.comercio c on c.id_comercio = p.id_comercio
    left join public.categoria k on k.id_categoria = p.id_categoria
   where c.estado = 'aprobado'
     and (p.nombre ilike v_patron or coalesce(p.marca, '') ilike v_patron)
   order by p.nombre, p.id_producto
   limit p_limite offset p_desplazamiento;
end;
$$;

revoke all on function public.explorar_productos(text, integer, integer) from public;
grant execute on function public.explorar_productos(text, integer, integer) to authenticated;

-- Comercios APROBADOS, para explorarlos y marcarlos como favoritos.
create or replace function public.explorar_comercios(
  p_texto          text    default '',
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_comercio uuid,
  nombre      text,
  direccion   text,
  ciudad      text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_patron text := '%' || replace(replace(replace(coalesce(btrim(p_texto), ''),
                    '\', '\\'), '%', '\%'), '_', '\_') || '%';
begin
  if not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para explorar comercios.';
  end if;

  return query
  select c.id_comercio, c.nombre::text, c.direccion::text, c.ciudad::text
    from public.comercio c
   where c.estado = 'aprobado'
     and (c.nombre ilike v_patron or c.ciudad ilike v_patron)
   order by c.nombre, c.id_comercio
   limit p_limite offset p_desplazamiento;
end;
$$;

revoke all on function public.explorar_comercios(text, integer, integer) from public;
grant execute on function public.explorar_comercios(text, integer, integer) to authenticated;
