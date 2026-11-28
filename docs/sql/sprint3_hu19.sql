-- =====================================================================
-- SmartCart · Sprint 3 · HU-19 · Ubicación, radio de búsqueda y mapa
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu14.sql y
-- sprint2_hu17.sql (usa distancia_metros() y es_cliente()).
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. ubicacion_cliente: la ubicación y el radio de búsqueda de cada
--      cliente. Se recuperan al volver a abrir la app y la comparación del
--      carrito (HU-18) los usa para calcular distancias.
--   2. guardar_ubicacion_cliente(): única forma de escribirla; valida los
--      valores y solo deja guardar la propia.
--   3. comercios_en_radio(): los comercios aprobados con ubicación que
--      quedan dentro del radio, para el mapa del cliente. comercios_cercanos()
--      de la HU-14 sigue siendo solo para colaboradores.
-- Las pruebas están en pruebas_hu19_politicas.sql.
--
-- REGLAS (la app las repite en RadioReglas; si cambias un valor, cámbialo
-- en los dos lados):
--   · Radio .............. de 1 000 a 20 000 m.
--   · Dirección .......... opcional (vacía si la ubicación vino del GPS),
--                          hasta 200 caracteres.
--   · Comercios en radio . hasta 200 por consulta, del más cercano al más
--                          lejano.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Ubicación del cliente
-- Una fila por cliente. La app la lee directo (política de lectura propia)
-- y la escribe solo con guardar_ubicacion_cliente().
-- ---------------------------------------------------------------------
create table if not exists public.ubicacion_cliente (
  id_usuario     uuid primary key references public.usuario (id_usuario) on delete cascade,
  latitud        double precision not null,
  longitud       double precision not null,
  direccion      text,
  radio_m        integer not null default 5000,
  actualizado_en timestamptz not null default now()
);

alter table public.ubicacion_cliente drop constraint if exists ubicacion_cliente_coordenadas_check;
alter table public.ubicacion_cliente add constraint ubicacion_cliente_coordenadas_check
  check (latitud between -90 and 90 and longitud between -180 and 180);

alter table public.ubicacion_cliente drop constraint if exists ubicacion_cliente_radio_check;
alter table public.ubicacion_cliente add constraint ubicacion_cliente_radio_check
  check (radio_m between 1000 and 20000);

alter table public.ubicacion_cliente drop constraint if exists ubicacion_cliente_direccion_check;
alter table public.ubicacion_cliente add constraint ubicacion_cliente_direccion_check
  check (direccion is null or char_length(direccion) between 1 and 200);

alter table public.ubicacion_cliente enable row level security;

drop policy if exists ubicacion_cliente_select_own on public.ubicacion_cliente;
create policy ubicacion_cliente_select_own on public.ubicacion_cliente
  for select to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

-- Sin políticas de escritura: la escritura pasa por la función de abajo.
revoke insert, update, delete on public.ubicacion_cliente from anon, authenticated;
grant select on public.ubicacion_cliente to authenticated;


-- ---------------------------------------------------------------------
-- 2. Guardar la ubicación y el radio del cliente
-- Crea la fila o la reemplaza. La dirección en blanco se guarda vacía.
-- ---------------------------------------------------------------------
create or replace function public.guardar_ubicacion_cliente(
  p_latitud   double precision,
  p_longitud  double precision,
  p_radio_m   integer,
  p_direccion text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  c_radio_min constant integer := 1000;
  c_radio_max constant integer := 20000;
  v_direccion text := nullif(btrim(coalesce(p_direccion, '')), '');
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para guardar tu ubicación.';
  end if;
  if p_latitud is null or p_longitud is null
     or p_latitud not between -90 and 90
     or p_longitud not between -180 and 180 then
    raise exception 'La ubicación no es válida. Inténtalo de nuevo.';
  end if;
  if p_radio_m is null or p_radio_m not between c_radio_min and c_radio_max then
    raise exception 'El radio debe estar entre 1 y 20 km.';
  end if;
  if char_length(v_direccion) > 200 then
    raise exception 'La dirección puede tener hasta 200 caracteres.';
  end if;

  insert into public.ubicacion_cliente
    (id_usuario, latitud, longitud, direccion, radio_m, actualizado_en)
  values
    (auth.uid(), p_latitud, p_longitud, v_direccion, p_radio_m, now())
  on conflict (id_usuario) do update
    set latitud        = excluded.latitud,
        longitud       = excluded.longitud,
        direccion      = excluded.direccion,
        radio_m        = excluded.radio_m,
        actualizado_en = excluded.actualizado_en;
end;
$$;

revoke all on function public.guardar_ubicacion_cliente(double precision, double precision, integer, text) from public, anon;
grant execute on function public.guardar_ubicacion_cliente(double precision, double precision, integer, text) to authenticated;


-- ---------------------------------------------------------------------
-- 3. Comercios dentro del radio (escenarios 1 y 3)
-- Solo comercios APROBADOS que guardaron su ubicación (HU-14). La lista
-- es acotada (un mapa no muestra páginas): hasta p_limite filas.
-- ---------------------------------------------------------------------
create or replace function public.comercios_en_radio(
  p_latitud  double precision,
  p_longitud double precision,
  p_radio_m  integer,
  p_limite   integer default 200
)
returns table (
  id_comercio uuid,
  nombre      text,
  direccion   text,
  ciudad      text,
  latitud     double precision,
  longitud    double precision,
  distancia_m double precision
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.es_cliente() then
    raise exception 'Inicia sesión como cliente para ver los comercios cercanos.';
  end if;
  if p_latitud is null or p_longitud is null
     or p_latitud not between -90 and 90
     or p_longitud not between -180 and 180 then
    raise exception 'La ubicación no es válida. Inténtalo de nuevo.';
  end if;
  if p_radio_m is null or p_radio_m not between 1000 and 20000 then
    raise exception 'El radio debe estar entre 1 y 20 km.';
  end if;

  -- En algunas bases comercio.latitud/longitud ya existían como numeric
  -- (sprint2_hu14.sql solo las crea si faltan); return query exige el tipo
  -- exacto de la tabla de resultado, por eso las convertimos.
  return query
  select c.id_comercio, c.nombre::text, c.direccion::text, c.ciudad::text,
         c.latitud::double precision, c.longitud::double precision, d.metros
    from public.comercio c
   cross join lateral (
     select public.distancia_metros(p_latitud, p_longitud, c.latitud, c.longitud) as metros
   ) d
   where c.estado = 'aprobado'
     and c.latitud is not null
     and d.metros <= p_radio_m
   order by d.metros, c.id_comercio
   limit least(greatest(coalesce(p_limite, 200), 1), 200);
end;
$$;

revoke all on function public.comercios_en_radio(double precision, double precision, integer, integer) from public, anon;
grant execute on function public.comercios_en_radio(double precision, double precision, integer, integer) to authenticated;
