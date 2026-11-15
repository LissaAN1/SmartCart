-- =====================================================================
-- SmartCart · Sprint 2 · HU-10 · Gestión del catálogo del comercio
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu24.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. categoria: lista fija y compartida; el comercio solo elige una.
--   2. producto: pertenece a un comercio y a una categoría.
--   3. es_comercio_aprobado_propio(): ¿el comercio es de quien llama y
--      está aprobado? Es la regla que usan todas las políticas.
--   4. Políticas RLS de producto: solo el dueño de un comercio APROBADO
--      lee, crea, edita y elimina sus productos.
-- Las pruebas de las políticas están en pruebas_hu10_politicas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Categorías
-- ---------------------------------------------------------------------
create table if not exists public.categoria (
  id_categoria uuid primary key default gen_random_uuid(),
  nombre       text not null unique
);

-- Son las mismas categorías que muestra el Home del cliente.
insert into public.categoria (nombre) values
  ('Super'), ('Frutas'), ('Lácteos'), ('Aseo'), ('Café'), ('Panadería')
on conflict (nombre) do nothing;

alter table public.categoria enable row level security;

-- Lectura para cualquier cuenta con sesión. Nadie escribe desde la app.
drop policy if exists categoria_select_all on public.categoria;
create policy categoria_select_all on public.categoria
  for select to authenticated
  using (true);

revoke insert, update, delete on public.categoria from authenticated;


-- ---------------------------------------------------------------------
-- 2. Productos
-- Si se elimina el comercio o el producto, lo que dependa de ellos
-- (precios en HU-11, carrito y favoritos en HU-17) se elimina en cascada.
-- ---------------------------------------------------------------------
create table if not exists public.producto (
  id_producto   uuid primary key default gen_random_uuid(),
  id_comercio   uuid not null references public.comercio (id_comercio) on delete cascade,
  id_categoria  uuid not null references public.categoria (id_categoria),
  nombre        text not null,
  marca         text,
  codigo_barras text,
  creado_en     timestamptz not null default now()
);

-- Las mismas reglas que valida la app (ProductoValidators), por si alguien
-- escribe saltándose la interfaz.
alter table public.producto drop constraint if exists producto_nombre_check;
alter table public.producto add constraint producto_nombre_check
  check (char_length(btrim(nombre)) between 3 and 100);

alter table public.producto drop constraint if exists producto_marca_check;
alter table public.producto add constraint producto_marca_check
  check (marca is null or char_length(marca) <= 60);

alter table public.producto drop constraint if exists producto_codigo_barras_check;
alter table public.producto add constraint producto_codigo_barras_check
  check (codigo_barras is null or codigo_barras ~ '^[0-9]{8,14}$');

-- Un código de barras no se repite dentro del mismo comercio.
create unique index if not exists producto_comercio_codigo_key
  on public.producto (id_comercio, codigo_barras)
  where codigo_barras is not null;

-- La lista del catálogo filtra por comercio y ordena por fecha.
create index if not exists producto_comercio_creado_idx
  on public.producto (id_comercio, creado_en desc, id_producto);


-- ---------------------------------------------------------------------
-- 3. ¿Es un comercio mío y está aprobado?
-- security definer: lee comercio sin depender de sus políticas.
-- ---------------------------------------------------------------------
create or replace function public.es_comercio_aprobado_propio(p_id_comercio uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.comercio c
    where c.id_comercio = p_id_comercio
      and c.id_usuario = auth.uid()
      and c.estado = 'aprobado'
  );
$$;

revoke all on function public.es_comercio_aprobado_propio(uuid) from public;
grant execute on function public.es_comercio_aprobado_propio(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 4. Políticas de producto
-- Un comercio pendiente o rechazado no pasa la función, así que no puede
-- leer ni escribir productos aunque se salte la pantalla de espera.
-- En update, `with check` impide mover un producto a otro comercio.
-- ---------------------------------------------------------------------
alter table public.producto enable row level security;

drop policy if exists producto_select_own on public.producto;
create policy producto_select_own on public.producto
  for select to authenticated
  using (public.es_comercio_aprobado_propio(id_comercio));

drop policy if exists producto_insert_own on public.producto;
create policy producto_insert_own on public.producto
  for insert to authenticated
  with check (public.es_comercio_aprobado_propio(id_comercio));

drop policy if exists producto_update_own on public.producto;
create policy producto_update_own on public.producto
  for update to authenticated
  using (public.es_comercio_aprobado_propio(id_comercio))
  with check (public.es_comercio_aprobado_propio(id_comercio));

drop policy if exists producto_delete_own on public.producto;
create policy producto_delete_own on public.producto
  for delete to authenticated
  using (public.es_comercio_aprobado_propio(id_comercio));

-- La lectura para los clientes (búsqueda de HU-12) se agrega en esa
-- historia, con su propia política.
