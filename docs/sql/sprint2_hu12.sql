-- =====================================================================
-- SmartCart · Sprint 2 · HU-12 · Búsqueda de productos
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu11.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. clave_producto(): agrupa el mismo producto de distintos comercios
--      (por código de barras; si no tiene, por nombre y marca).
--   2. buscar_productos(): resultados de la búsqueda del cliente, con el
--      rango de precios y en cuántos establecimientos está.
--   3. precios_de_producto(): el producto abierto con el precio de cada
--      establecimiento (escenario 2, al escanear el código).
--
-- Los clientes NO leen las tablas producto, precio_producto ni promocion:
-- sus políticas siguen siendo solo del dueño (HU-10 y HU-11). Estas
-- funciones son security definer y solo devuelven productos con precio de
-- comercios APROBADOS, a cuentas con sesión iniciada.
-- Las pruebas están en pruebas_hu12_busqueda.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Clave de agrupación
-- ---------------------------------------------------------------------
create or replace function public.clave_producto(
  p_codigo text,
  p_nombre text,
  p_marca text
)
returns text
language sql
immutable
as $$
  select case
    when p_codigo is not null and btrim(p_codigo) <> '' then 'cb:' || btrim(p_codigo)
    else 'nm:' || lower(btrim(p_nombre)) || '|' || lower(coalesce(btrim(p_marca), ''))
  end;
$$;


-- ---------------------------------------------------------------------
-- 2. Ofertas publicadas
-- Una fila por producto de un comercio aprobado que tiene precio. El
-- precio vigente es el de la promoción si hoy está dentro de sus fechas
-- (HU-11, escenario 3); si no, el normal.
-- ---------------------------------------------------------------------
create or replace function public.ofertas_publicadas()
returns table (
  clave           text,
  id_producto     uuid,
  nombre          text,
  marca           text,
  codigo_barras   text,
  categoria       text,
  foto_url        text,
  id_comercio     uuid,
  comercio        text,
  direccion       text,
  ciudad          text,
  precio          integer,
  precio_normal   integer,
  en_promocion    boolean,
  disponible      boolean,
  fuente          text,
  actualizado_en  timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    public.clave_producto(p.codigo_barras, p.nombre, p.marca),
    p.id_producto,
    p.nombre,
    p.marca,
    p.codigo_barras,
    k.nombre,
    p.foto_url,
    c.id_comercio,
    c.nombre,
    c.direccion,
    c.ciudad,
    case when pr.id_promocion is not null
              and current_date between pr.fecha_inicio and pr.fecha_fin
         then pr.precio_promocional else pp.precio end,
    pp.precio,
    coalesce(pr.id_promocion is not null
             and current_date between pr.fecha_inicio and pr.fecha_fin, false),
    pp.disponible,
    pp.fuente,
    pp.actualizado_en
  from public.producto p
  join public.comercio c
    on c.id_comercio = p.id_comercio and c.estado = 'aprobado'
  join public.precio_producto pp on pp.id_producto = p.id_producto
  join public.categoria k on k.id_categoria = p.id_categoria
  left join public.promocion pr on pr.id_producto = p.id_producto
  -- Solo para cuentas con sesión.
  where auth.uid() is not null;
$$;

-- Es interna: solo la usan las dos funciones de abajo. Supabase da permiso
-- de ejecución por defecto, por eso se quita también a authenticated.
revoke all on function public.ofertas_publicadas() from public, anon, authenticated;


-- ---------------------------------------------------------------------
-- 3. Búsqueda (escenarios 1 y 3)
-- Busca en el nombre o la marca (sin distinguir mayúsculas). El rango y
-- los establecimientos cuentan solo las ofertas disponibles; si todas
-- están agotadas, el producto sale igual, sin rango.
-- p_limite y p_desde paginan (la app pide una fila de más para saber si
-- hay otra página).
-- ---------------------------------------------------------------------
create or replace function public.buscar_productos(
  p_texto  text,
  p_limite integer default 21,
  p_desde  integer default 0
)
returns table (
  clave            text,
  nombre           text,
  marca            text,
  codigo_barras    text,
  categoria        text,
  foto_url         text,
  precio_min       integer,
  precio_max       integer,
  establecimientos integer
)
language sql
stable
security definer
set search_path = public
as $$
  with patron as (
    -- Los comodines que escriba la persona se buscan como texto.
    select '%' || replace(replace(replace(btrim(coalesce(p_texto, '')),
           '\', '\\'), '%', '\%'), '_', '\_') || '%' as valor
  )
  select
    o.clave,
    min(o.nombre),
    min(o.marca),
    min(o.codigo_barras),
    min(o.categoria),
    max(o.foto_url),
    min(o.precio) filter (where o.disponible),
    max(o.precio) filter (where o.disponible),
    (count(distinct o.id_comercio) filter (where o.disponible))::integer
  from public.ofertas_publicadas() o, patron
  where btrim(coalesce(p_texto, '')) <> ''
    and (o.nombre ilike patron.valor or coalesce(o.marca, '') ilike patron.valor)
  group by o.clave
  order by min(lower(o.nombre)), o.clave
  limit least(greatest(coalesce(p_limite, 21), 1), 51)
  offset greatest(coalesce(p_desde, 0), 0);
$$;

revoke all on function public.buscar_productos(text, integer, integer) from public, anon;
grant execute on function public.buscar_productos(text, integer, integer) to authenticated;


-- ---------------------------------------------------------------------
-- 4. Un producto con el precio de cada establecimiento (escenario 2)
-- Primero los disponibles y del más barato al más caro.
-- ---------------------------------------------------------------------
create or replace function public.precios_de_producto(p_clave text)
returns table (
  clave           text,
  id_producto     uuid,
  nombre          text,
  marca           text,
  codigo_barras   text,
  categoria       text,
  foto_url        text,
  comercio        text,
  direccion       text,
  ciudad          text,
  precio          integer,
  precio_normal   integer,
  en_promocion    boolean,
  disponible      boolean,
  fuente          text,
  actualizado_en  timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    o.clave, o.id_producto, o.nombre, o.marca, o.codigo_barras, o.categoria,
    o.foto_url, o.comercio, o.direccion, o.ciudad, o.precio, o.precio_normal,
    o.en_promocion, o.disponible, o.fuente, o.actualizado_en
  from public.ofertas_publicadas() o
  where o.clave = p_clave
  order by o.disponible desc, o.precio asc, o.comercio;
$$;

revoke all on function public.precios_de_producto(text) from public, anon;
grant execute on function public.precios_de_producto(text) to authenticated;
