-- =====================================================================
-- SmartCart · Sprint 2 · HU-11 · Precios, disponibilidad y promociones
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu10.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. precio_producto: precio actual (COP) y disponibilidad de cada
--      producto, con la fecha de actualización y la fuente.
--   2. historial_precio: cada cambio de precio o disponibilidad queda
--      registrado. Lo llena un trigger, nunca la app.
--   3. promocion: una promoción por producto, con precio y fechas.
--   4. es_producto_propio(): ¿el producto es de un comercio mío y
--      aprobado? Es la regla que usan las políticas de esta historia.
--   5. Políticas RLS: solo el dueño de un comercio APROBADO lee y cambia
--      los precios, el historial y las promociones de sus productos.
-- Las pruebas de las políticas están en pruebas_hu11_politicas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Precio actual y disponibilidad
-- Un producto tiene un solo precio actual (relación 1 a 1 con producto).
-- Pesos colombianos enteros: el COP no maneja centavos en la práctica.
-- ---------------------------------------------------------------------
create table if not exists public.precio_producto (
  id_producto    uuid primary key references public.producto (id_producto) on delete cascade,
  precio         integer not null,
  disponible     boolean not null default true,
  fuente         text not null default 'comercio',
  actualizado_en timestamptz not null default now()
);

-- Las mismas reglas que valida la app (PrecioValidators).
alter table public.precio_producto drop constraint if exists precio_producto_precio_check;
alter table public.precio_producto add constraint precio_producto_precio_check
  check (precio > 0 and precio <= 100000000);

-- HU-13 mostrará la fuente; por ahora el comercio es la única que escribe
-- aquí (los reportes del colaborador van en su propia tabla, HU-14).
alter table public.precio_producto drop constraint if exists precio_producto_fuente_check;
alter table public.precio_producto add constraint precio_producto_fuente_check
  check (fuente in ('comercio', 'colaborador'));


-- ---------------------------------------------------------------------
-- 2. Historial de precios
-- ---------------------------------------------------------------------
create table if not exists public.historial_precio (
  id_historial  uuid primary key default gen_random_uuid(),
  id_producto   uuid not null references public.producto (id_producto) on delete cascade,
  precio        integer not null,
  disponible    boolean not null,
  fuente        text not null,
  registrado_en timestamptz not null default now()
);

-- La pantalla muestra los cambios más recientes de un producto.
create index if not exists historial_precio_producto_idx
  on public.historial_precio (id_producto, registrado_en desc);


-- ---------------------------------------------------------------------
-- 3. Promociones
-- Una sola promoción por producto: guardar otra la reemplaza. Fuera de
-- sus fechas no se muestra (la app compara con la fecha de hoy).
-- ---------------------------------------------------------------------
create table if not exists public.promocion (
  id_promocion       uuid primary key default gen_random_uuid(),
  id_producto        uuid not null unique references public.producto (id_producto) on delete cascade,
  precio_promocional integer not null,
  fecha_inicio       date not null,
  fecha_fin          date not null,
  actualizado_en     timestamptz not null default now()
);

alter table public.promocion drop constraint if exists promocion_precio_check;
alter table public.promocion add constraint promocion_precio_check
  check (precio_promocional > 0 and precio_promocional <= 100000000);

alter table public.promocion drop constraint if exists promocion_fechas_check;
alter table public.promocion add constraint promocion_fechas_check
  check (fecha_fin >= fecha_inicio);


-- ---------------------------------------------------------------------
-- 4. Triggers
-- La base fija la fecha de actualización y escribe el historial, así no
-- dependen de lo que mande la app.
-- ---------------------------------------------------------------------
create or replace function public.precio_producto_antes_de_guardar()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

drop trigger if exists precio_producto_fecha on public.precio_producto;
create trigger precio_producto_fecha
  before insert or update on public.precio_producto
  for each row execute function public.precio_producto_antes_de_guardar();

-- security definer: escribe en historial_precio aunque la cuenta no tenga
-- permiso de insertar ahí directamente.
create or replace function public.precio_producto_registrar_historial()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.precio = old.precio
     and new.disponible = old.disponible then
    return new;
  end if;
  insert into public.historial_precio
    (id_producto, precio, disponible, fuente, registrado_en)
  values
    (new.id_producto, new.precio, new.disponible, new.fuente, new.actualizado_en);
  return new;
end;
$$;

revoke all on function public.precio_producto_registrar_historial() from public;

drop trigger if exists precio_producto_historial on public.precio_producto;
create trigger precio_producto_historial
  after insert or update on public.precio_producto
  for each row execute function public.precio_producto_registrar_historial();

create or replace function public.promocion_antes_de_guardar()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

drop trigger if exists promocion_fecha on public.promocion;
create trigger promocion_fecha
  before insert or update on public.promocion
  for each row execute function public.promocion_antes_de_guardar();


-- ---------------------------------------------------------------------
-- 5. ¿Es un producto de un comercio mío y aprobado?
-- Reutiliza la regla de HU-10 (es_comercio_aprobado_propio).
-- ---------------------------------------------------------------------
create or replace function public.es_producto_propio(p_id_producto uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.producto p
    where p.id_producto = p_id_producto
      and public.es_comercio_aprobado_propio(p.id_comercio)
  );
$$;

revoke all on function public.es_producto_propio(uuid) from public;
grant execute on function public.es_producto_propio(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 6. Políticas
-- Un comercio pendiente o rechazado no pasa la función. En update,
-- `with check` impide mover un precio o una promoción a otro producto.
-- La lectura para los clientes (búsqueda de HU-12) se agrega en esa
-- historia, con su propia política.
-- ---------------------------------------------------------------------
alter table public.precio_producto enable row level security;

drop policy if exists precio_producto_select_own on public.precio_producto;
create policy precio_producto_select_own on public.precio_producto
  for select to authenticated
  using (public.es_producto_propio(id_producto));

drop policy if exists precio_producto_insert_own on public.precio_producto;
create policy precio_producto_insert_own on public.precio_producto
  for insert to authenticated
  with check (public.es_producto_propio(id_producto) and fuente = 'comercio');

drop policy if exists precio_producto_update_own on public.precio_producto;
create policy precio_producto_update_own on public.precio_producto
  for update to authenticated
  using (public.es_producto_propio(id_producto))
  with check (public.es_producto_propio(id_producto) and fuente = 'comercio');

-- El precio no se borra desde la app: se borra en cascada con el producto.
revoke delete on public.precio_producto from authenticated;


-- El historial solo se lee; lo escribe el trigger.
alter table public.historial_precio enable row level security;

drop policy if exists historial_precio_select_own on public.historial_precio;
create policy historial_precio_select_own on public.historial_precio
  for select to authenticated
  using (public.es_producto_propio(id_producto));

revoke insert, update, delete on public.historial_precio from authenticated;


alter table public.promocion enable row level security;

drop policy if exists promocion_select_own on public.promocion;
create policy promocion_select_own on public.promocion
  for select to authenticated
  using (public.es_producto_propio(id_producto));

drop policy if exists promocion_insert_own on public.promocion;
create policy promocion_insert_own on public.promocion
  for insert to authenticated
  with check (public.es_producto_propio(id_producto));

drop policy if exists promocion_update_own on public.promocion;
create policy promocion_update_own on public.promocion
  for update to authenticated
  using (public.es_producto_propio(id_producto))
  with check (public.es_producto_propio(id_producto));

drop policy if exists promocion_delete_own on public.promocion;
create policy promocion_delete_own on public.promocion
  for delete to authenticated
  using (public.es_producto_propio(id_producto));
