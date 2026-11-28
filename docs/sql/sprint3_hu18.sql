-- =====================================================================
-- SmartCart · Sprint 3 · HU-18 · Alternativas de carrito según el criterio
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu12.sql,
-- sprint2_hu17.sql y sprint3_hu19.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. Corrige ofertas_publicadas() (HU-12): la promoción vigente se decide
--      con la fecha de Colombia. Supabase trabaja en UTC y current_date
--      cambiaba de día a las 7:00 p. m. hora de Colombia, así que una
--      promoción que terminaba "hoy" dejaba de valer en la noche.
--   2. ofertas_del_carrito(): para cada producto del carrito del cliente,
--      todas las ofertas publicadas del MISMO producto en comercios
--      aprobados (regla de la HU-12: código de barras o, si no tiene, nombre
--      y marca), con su precio vigente, disponibilidad, fuente, fecha,
--      coordenadas del comercio y calificación de su dueño.
-- La app calcula las alternativas con estas filas (ComparadorCarrito); la
-- base no guarda ninguna alternativa.
-- Las pruebas están en pruebas_hu18_ofertas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Ofertas publicadas con la fecha de Colombia
-- Mismo resultado y mismas columnas que en sprint2_hu12.sql; solo cambia
-- el día con que se compara la promoción.
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
  with hoy as (
    select (now() at time zone 'America/Bogota')::date as dia
  )
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
              and hoy.dia between pr.fecha_inicio and pr.fecha_fin
         then pr.precio_promocional else pp.precio end,
    pp.precio,
    coalesce(pr.id_promocion is not null
             and hoy.dia between pr.fecha_inicio and pr.fecha_fin, false),
    pp.disponible,
    pp.fuente,
    pp.actualizado_en
  from hoy, public.producto p
  join public.comercio c
    on c.id_comercio = p.id_comercio and c.estado = 'aprobado'
  join public.precio_producto pp on pp.id_producto = p.id_producto
  join public.categoria k on k.id_categoria = p.id_categoria
  left join public.promocion pr on pr.id_producto = p.id_producto
  -- Solo para cuentas con sesión.
  where auth.uid() is not null;
$$;

revoke all on function public.ofertas_publicadas() from public, anon, authenticated;


-- ---------------------------------------------------------------------
-- 2. Ofertas de los productos del carrito
-- Una fila por (línea del carrito, oferta del mismo producto). Una línea
-- cuyo producto no tiene ninguna oferta publicada sale una vez, con las
-- columnas de la oferta en null: así la app puede avisar cuál falta
-- (escenario 5). Se devuelven también las ofertas agotadas: la app las
-- necesita para mostrar el estado del producto en el carrito y las descarta
-- al comparar.
--
-- La calificación sale de usuario.calificacion_promedio y
-- usuario.total_calificaciones del dueño del comercio, que llena la HU-25.
-- La leemos con to_jsonb para que la función funcione aunque esas columnas
-- todavía no existan en la base (entonces llegan en null y la app muestra
-- "Sin calificaciones").
-- ---------------------------------------------------------------------
create or replace function public.ofertas_del_carrito()
returns table (
  id_linea              uuid,
  cantidad              integer,
  clave                 text,
  nombre                text,
  marca                 text,
  id_producto           uuid,
  id_comercio           uuid,
  comercio              text,
  direccion             text,
  ciudad                text,
  latitud               double precision,
  longitud              double precision,
  precio                integer,
  precio_normal         integer,
  en_promocion          boolean,
  disponible            boolean,
  fuente                text,
  actualizado_en        timestamptz,
  calificacion          numeric,
  total_calificaciones  integer
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para comparar tu carrito.';
  end if;

  return query
  with lineas as (
    select i.id_producto, i.cantidad,
           public.clave_producto(p.codigo_barras, p.nombre, p.marca) as clave,
           p.nombre::text as nombre, p.marca::text as marca
      from public.carrito_item i
      join public.producto p on p.id_producto = i.id_producto
     where i.id_usuario = auth.uid()
  )
  select l.id_producto, l.cantidad, l.clave, l.nombre, l.marca,
         o.id_producto, o.id_comercio, o.comercio, o.direccion, o.ciudad,
         c.latitud::double precision, c.longitud::double precision,
         o.precio, o.precio_normal, o.en_promocion, o.disponible,
         o.fuente, o.actualizado_en,
         nullif(to_jsonb(u) ->> 'calificacion_promedio', '')::numeric,
         coalesce(nullif(to_jsonb(u) ->> 'total_calificaciones', '')::numeric, 0)::integer
    from lineas l
    left join public.ofertas_publicadas() o on o.clave = l.clave
    left join public.comercio c on c.id_comercio = o.id_comercio
    left join public.usuario u on u.id_usuario = c.id_usuario
   order by l.id_producto, o.precio nulls last, o.id_comercio;
end;
$$;

revoke all on function public.ofertas_del_carrito() from public, anon;
grant execute on function public.ofertas_del_carrito() to authenticated;
