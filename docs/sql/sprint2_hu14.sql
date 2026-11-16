-- =====================================================================
-- SmartCart · Sprint 2 · HU-14 · Reporte de precio por el colaborador
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu10.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. es_colaborador() y es_comercio_aprobado(): ayudas para las políticas.
--   2. comercio.latitud / longitud + fijar_ubicacion_comercio(): sin
--      coordenadas no se puede comprobar que el colaborador esté en el lugar.
--   3. distancia_metros() y comercios_cercanos(): los establecimientos entre
--      los que el colaborador elige.
--   4. Lectura de productos para colaboradores (para identificar el producto).
--   5. reporte_precio y enviar_reporte_precio(): guarda el reporte PENDIENTE
--      solo si el colaborador está a menos de 150 m del establecimiento.
--   6. establecimiento_sugerido: para sugerir un lugar que aún no está.
--   7. El bucket de Storage "reportes" con las fotos de las etiquetas.
--   8. Cierra una política heredada de comercio que dejaba al dueño aprobarse.
--   9. mis_reportes(): el historial de reportes del colaborador.
-- Las pruebas de las políticas están en pruebas_hu14_politicas.sql.
--
-- Los mensajes de las funciones salen en español y la app los muestra tal
-- cual (SQLSTATE P0001).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Ayudas para las políticas
-- security definer: leen tablas sin depender de sus propias políticas.
-- ---------------------------------------------------------------------
create or replace function public.es_colaborador()
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
      and r.codigo = 'colaborador'
  );
$$;

revoke all on function public.es_colaborador() from public;
grant execute on function public.es_colaborador() to authenticated;

create or replace function public.es_comercio_aprobado(p_id_comercio uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.comercio c
    where c.id_comercio = p_id_comercio and c.estado = 'aprobado'
  );
$$;

revoke all on function public.es_comercio_aprobado(uuid) from public;
grant execute on function public.es_comercio_aprobado(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 2. Coordenadas del comercio
-- Las dos columnas van juntas o ninguna. Las políticas de comercio no
-- cambian: el dueño las llena al registrarse (insert) o después con
-- fijar_ubicacion_comercio(), que toca SOLO estas columnas. Una política de
-- update nueva dejaría al dueño cambiar también su estado de aprobación.
-- ---------------------------------------------------------------------
alter table public.comercio add column if not exists latitud  double precision;
alter table public.comercio add column if not exists longitud double precision;

alter table public.comercio drop constraint if exists comercio_ubicacion_check;
alter table public.comercio add constraint comercio_ubicacion_check check (
  (latitud is null and longitud is null)
  or (latitud between -90 and 90 and longitud between -180 and 180)
);

create or replace function public.fijar_ubicacion_comercio(
  p_latitud  double precision,
  p_longitud double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Inicia sesión para guardar la ubicación de tu comercio.';
  end if;
  if p_latitud is null or p_longitud is null
     or p_latitud not between -90 and 90
     or p_longitud not between -180 and 180 then
    raise exception 'La ubicación no es válida. Inténtalo de nuevo.';
  end if;

  update public.comercio
     set latitud = p_latitud, longitud = p_longitud
   where id_usuario = auth.uid();

  if not found then
    raise exception 'Primero registra tu comercio.';
  end if;
end;
$$;

revoke all on function public.fijar_ubicacion_comercio(double precision, double precision) from public;
grant execute on function public.fijar_ubicacion_comercio(double precision, double precision) to authenticated;


-- ---------------------------------------------------------------------
-- 3. Distancia y establecimientos cercanos
-- distancia_metros: fórmula de haversine (radio de la Tierra 6 371 000 m).
-- comercios_cercanos: solo comercios APROBADOS con ubicación, para
-- colaboradores. Devuelve página + 1 fila como el resto de listas
-- (limite = tamaño de página + 1). El radio por defecto es amplio a
-- propósito: la app deja elegir un lugar lejano y el envío lo rechaza.
-- ---------------------------------------------------------------------
create or replace function public.distancia_metros(
  lat1 double precision, lon1 double precision,
  lat2 double precision, lon2 double precision
)
returns double precision
language sql
immutable
as $$
  select 2 * 6371000 * asin(least(1, sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2)
    + cos(radians(lat1)) * cos(radians(lat2))
      * power(sin(radians(lon2 - lon1) / 2), 2)
  )));
$$;

create or replace function public.comercios_cercanos(
  p_latitud       double precision,
  p_longitud      double precision,
  p_radio_m       integer default 20000,
  p_limite        integer default 21,
  p_desplazamiento integer default 0
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
language sql
stable
security definer
set search_path = public
as $$
  select c.id_comercio, c.nombre, c.direccion, c.ciudad,
         c.latitud, c.longitud, d.metros
    from public.comercio c
   cross join lateral (
     select public.distancia_metros(p_latitud, p_longitud, c.latitud, c.longitud) as metros
   ) d
   where public.es_colaborador()
     and c.estado = 'aprobado'
     and c.latitud is not null
     and d.metros <= p_radio_m
   order by d.metros, c.id_comercio
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.comercios_cercanos(double precision, double precision, integer, integer, integer) from public;
grant execute on function public.comercios_cercanos(double precision, double precision, integer, integer, integer) to authenticated;


-- ---------------------------------------------------------------------
-- 4. Los colaboradores leen los productos de comercios aprobados
-- Es solo lectura: crear, editar y eliminar sigue siendo del dueño
-- (políticas de sprint2_hu10.sql). Las permisivas se suman con OR.
-- ---------------------------------------------------------------------
drop policy if exists producto_select_colaborador on public.producto;
create policy producto_select_colaborador on public.producto
  for select to authenticated
  using (public.es_colaborador() and public.es_comercio_aprobado(id_comercio));


-- ---------------------------------------------------------------------
-- 5. Reportes de precio
-- La app NO inserta directo: llama a enviar_reporte_precio(), que comprueba
-- la distancia en el servidor (la app también la comprueba, pero quien se
-- salte la app no se salta esto).
-- ---------------------------------------------------------------------
create table if not exists public.reporte_precio (
  id_reporte         uuid primary key default gen_random_uuid(),
  id_colaborador     uuid not null references public.usuario (id_usuario) on delete cascade,
  id_comercio        uuid not null references public.comercio (id_comercio) on delete cascade,
  id_producto        uuid not null references public.producto (id_producto) on delete cascade,
  precio             bigint not null,
  precio_promocional bigint,
  agotado            boolean not null default false,
  foto_path          text not null,
  latitud            double precision not null,
  longitud           double precision not null,
  distancia_m        double precision not null,
  estado             text not null default 'pendiente',
  creado_en          timestamptz not null default now()
);

-- Precio en pesos colombianos (COP), sin decimales.
alter table public.reporte_precio drop constraint if exists reporte_precio_precio_check;
alter table public.reporte_precio add constraint reporte_precio_precio_check
  check (precio > 0 and precio <= 100000000);

alter table public.reporte_precio drop constraint if exists reporte_precio_promocional_check;
alter table public.reporte_precio add constraint reporte_precio_promocional_check
  check (precio_promocional is null or (precio_promocional > 0 and precio_promocional < precio));

alter table public.reporte_precio drop constraint if exists reporte_precio_estado_check;
alter table public.reporte_precio add constraint reporte_precio_estado_check
  check (estado in ('pendiente', 'validado', 'rechazado'));

create index if not exists reporte_precio_colaborador_idx
  on public.reporte_precio (id_colaborador, creado_en desc);
create index if not exists reporte_precio_estado_idx
  on public.reporte_precio (estado, creado_en);

alter table public.reporte_precio enable row level security;

-- Cada colaborador ve solo los suyos; el administrador los ve todos
-- (los revisará en HU-15).
drop policy if exists reporte_precio_select_own on public.reporte_precio;
create policy reporte_precio_select_own on public.reporte_precio
  for select to authenticated
  using (id_colaborador = auth.uid());

drop policy if exists reporte_precio_select_admin on public.reporte_precio;
create policy reporte_precio_select_admin on public.reporte_precio
  for select to authenticated
  using (public.es_administrador());

-- Nadie escribe directo desde la app.
revoke insert, update, delete on public.reporte_precio from authenticated;

create or replace function public.enviar_reporte_precio(
  p_id_comercio        uuid,
  p_id_producto        uuid,
  p_precio             bigint,
  p_precio_promocional bigint,
  p_agotado            boolean,
  p_foto_path          text,
  p_latitud            double precision,
  p_longitud           double precision
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  -- Distancia máxima, en metros, entre el colaborador y el establecimiento.
  c_radio_m constant double precision := 150;
  v_lat   double precision;
  v_lng   double precision;
  v_dist  double precision;
  v_id    uuid;
begin
  if auth.uid() is null or not public.es_colaborador() then
    raise exception 'Activa el modo Colaborador para reportar precios.';
  end if;

  if p_precio is null or p_precio <= 0 then
    raise exception 'El precio debe ser mayor que cero.';
  end if;
  if p_precio_promocional is not null
     and (p_precio_promocional <= 0 or p_precio_promocional >= p_precio) then
    raise exception 'El precio de la promoción debe ser menor que el precio normal.';
  end if;

  -- La foto de la etiqueta es obligatoria y debe estar en la carpeta de
  -- quien reporta (así nadie reutiliza la foto de otra persona).
  if p_foto_path is null or btrim(p_foto_path) = '' then
    raise exception 'La foto de la etiqueta es obligatoria.';
  end if;
  if split_part(p_foto_path, '/', 1) <> auth.uid()::text then
    raise exception 'La foto no es válida. Vuelve a tomarla.';
  end if;

  if p_latitud is null or p_longitud is null then
    raise exception 'No pudimos conocer tu ubicación. Inténtalo de nuevo.';
  end if;

  select c.latitud, c.longitud into v_lat, v_lng
    from public.comercio c
   where c.id_comercio = p_id_comercio and c.estado = 'aprobado';
  if not found then
    raise exception 'Ese establecimiento no está disponible.';
  end if;
  if v_lat is null then
    raise exception 'Ese establecimiento aún no tiene ubicación registrada.';
  end if;

  if not exists (
    select 1 from public.producto p
     where p.id_producto = p_id_producto and p.id_comercio = p_id_comercio
  ) then
    raise exception 'Ese producto no pertenece al establecimiento.';
  end if;

  v_dist := public.distancia_metros(p_latitud, p_longitud, v_lat, v_lng);
  if v_dist > c_radio_m then
    raise exception 'Debes estar en el establecimiento para reportar el precio. Estás a % m.',
      round(v_dist);
  end if;

  insert into public.reporte_precio (
    id_colaborador, id_comercio, id_producto, precio, precio_promocional,
    agotado, foto_path, latitud, longitud, distancia_m
  ) values (
    auth.uid(), p_id_comercio, p_id_producto, p_precio, p_precio_promocional,
    coalesce(p_agotado, false), p_foto_path, p_latitud, p_longitud, v_dist
  )
  returning id_reporte into v_id;

  return v_id;
end;
$$;

revoke all on function public.enviar_reporte_precio(uuid, uuid, bigint, bigint, boolean, text, double precision, double precision) from public;
grant execute on function public.enviar_reporte_precio(uuid, uuid, bigint, bigint, boolean, text, double precision, double precision) to authenticated;


-- ---------------------------------------------------------------------
-- 6. Sugerir un establecimiento que aún no está en la plataforma
-- Guarda también dónde estaba el colaborador al sugerirlo.
-- ---------------------------------------------------------------------
create table if not exists public.establecimiento_sugerido (
  id_sugerencia  uuid primary key default gen_random_uuid(),
  id_colaborador uuid not null references public.usuario (id_usuario) on delete cascade,
  nombre         text not null,
  direccion      text not null,
  ciudad         text not null,
  latitud        double precision not null,
  longitud       double precision not null,
  estado         text not null default 'pendiente',
  creado_en      timestamptz not null default now()
);

alter table public.establecimiento_sugerido drop constraint if exists establecimiento_sugerido_nombre_check;
alter table public.establecimiento_sugerido add constraint establecimiento_sugerido_nombre_check
  check (char_length(btrim(nombre)) between 3 and 100
     and char_length(btrim(direccion)) between 3 and 150
     and char_length(btrim(ciudad)) between 3 and 60);

alter table public.establecimiento_sugerido enable row level security;

drop policy if exists establecimiento_sugerido_select_own on public.establecimiento_sugerido;
create policy establecimiento_sugerido_select_own on public.establecimiento_sugerido
  for select to authenticated
  using (id_colaborador = auth.uid());

drop policy if exists establecimiento_sugerido_select_admin on public.establecimiento_sugerido;
create policy establecimiento_sugerido_select_admin on public.establecimiento_sugerido
  for select to authenticated
  using (public.es_administrador());

drop policy if exists establecimiento_sugerido_insert_own on public.establecimiento_sugerido;
create policy establecimiento_sugerido_insert_own on public.establecimiento_sugerido
  for insert to authenticated
  with check (id_colaborador = auth.uid() and public.es_colaborador() and estado = 'pendiente');

revoke update, delete on public.establecimiento_sugerido from authenticated;


-- ---------------------------------------------------------------------
-- 7. Storage: fotos de las etiquetas
-- Bucket privado. Cada colaborador sube a su propia carpeta
-- ("<id_usuario>/<archivo>"); solo ella y el administrador pueden verlas.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('reportes', 'reportes', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists reportes_insert_own on storage.objects;
create policy reportes_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'reportes'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.es_colaborador()
  );

drop policy if exists reportes_select_own on storage.objects;
create policy reportes_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'reportes'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.es_administrador())
  );

-- La app borra la foto si el envío del reporte falla después de subirla.
drop policy if exists reportes_delete_own on storage.objects;
create policy reportes_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'reportes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );


-- ---------------------------------------------------------------------
-- 8. Cierra una política heredada que dejaba al dueño cambiar su estado
-- Encontrada con pruebas_hu14_politicas.sql (prueba E3). La base real tenía,
-- además de comercio_update_own_pendiente (sprint2_hu06_07_08.sql), una
-- política antigua `comercio_update_own` cuyo `with check` mira la columna
-- heredada `estado_registro` y no `estado`. Las políticas permisivas se
-- suman con OR, así que el dueño podía actualizar CUALQUIER columna de su
-- comercio, incluido `estado`, y aprobarse solo.
-- La app no actualiza `comercio` directamente (solo inserta y usa funciones),
-- y quedan las políticas que sí son correctas: el dueño edita mientras está
-- pendiente sin poder cambiar el estado, y el administrador decide.
-- ---------------------------------------------------------------------
drop policy if exists comercio_update_own on public.comercio;


-- ---------------------------------------------------------------------
-- 9. Historial de reportes del colaborador
-- El colaborador puede leer sus filas de reporte_precio, pero no la tabla
-- comercio (solo el dueño y el administrador), así que el nombre del
-- establecimiento sale de esta función. Devuelve SOLO los reportes de quien
-- llama, del más reciente al más antiguo, sin importar su estado: los
-- pendientes también aparecen. Pagina como el resto (limite = tamaño de
-- página + 1).
-- ---------------------------------------------------------------------
create or replace function public.mis_reportes(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_reporte         uuid,
  producto           text,
  comercio           text,
  precio             bigint,
  precio_promocional bigint,
  agotado            boolean,
  estado             text,
  creado_en          timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id_reporte,
         coalesce(p.nombre, 'Producto eliminado'),
         coalesce(c.nombre, 'Establecimiento'),
         r.precio, r.precio_promocional, r.agotado, r.estado, r.creado_en
    from public.reporte_precio r
    left join public.producto p on p.id_producto = r.id_producto
    left join public.comercio c on c.id_comercio = r.id_comercio
   where r.id_colaborador = auth.uid()
   order by r.creado_en desc, r.id_reporte
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_reportes(integer, integer) from public;
grant execute on function public.mis_reportes(integer, integer) to authenticated;
