-- =====================================================================
-- SmartCart · Sprint 3 · HU-15 (validación de reportes) y HU-16 (puntos,
-- niveles y reputación)
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu14.sql.
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. reporte_precio: motivo, requiere_confirmacion, es_falso, revisado_en.
--   2. movimiento_puntos y confirmacion_reporte (con RLS).
--   3. Reglas de puntos y niveles: nivel_para_puntos(), puntos_para_reporte().
--   4. revisar_reporte(): revisa cada reporte nuevo (ubicación, evidencia y
--      coherencia con el historial) y lo deja validado, rechazado, o
--      pendiente de confirmación.
--   5. Triggers: al enviarse un reporte se revisa; al cambiar de estado se
--      aplica el resultado (precio con fuente "colaborador", puntos,
--      reputación y aviso al colaborador).
--   6. Confirmar o corregir un reporte dudoso: otro colaborador o el comercio.
--   7. Lecturas para la app: mis_reportes() (con motivo), reportes por
--      confirmar, resumen de puntos y su historial. Todas paginadas.
-- Las pruebas están en pruebas_hu15_hu16_politicas.sql.
--
-- PERMISOS: en Supabase las funciones de `public` reciben EXECUTE para anon y
-- authenticated por defecto, y `revoke ... from public` no lo quita. Por eso
-- las funciones internas (revisión, puntos, triggers) se revocan a
-- anon y authenticated de forma explícita, y las que usa la app, a anon.
--
-- REGLAS (la app las repite en Dart; si cambias un valor, cámbialo en los
-- dos lados):
--   · Ubicación ........ el reporte se envió a ≤ 150 m del establecimiento
--                        (ReporteReglas.radioMaximoM).
--   · Evidencia ........ la foto existe en el bucket "reportes".
--   · Coherencia ....... si el precio difiere más de 30 % del precio actual
--                        queda PENDIENTE hasta que lo confirme otro
--                        colaborador o el comercio (ValidacionReglas).
--   · Puntos ........... 10 base; +10 si el producto no tenía precio; +5 si
--                        tenía precio de más de 7 días (PuntosReglas).
--   · Niveles .......... Nuevo 0-99, Frecuente 100-499, Experto 500+
--                        (según los puntos acumulados por reportes).
--   · Reputación ....... 0 a 100: +1 por reporte validado, -5 por reporte
--                        rechazado por falso (ubicación o evidencia).
--
-- Los mensajes de las funciones salen en español (SQLSTATE P0001).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Columnas nuevas de reporte_precio
-- ---------------------------------------------------------------------
alter table public.reporte_precio add column if not exists motivo text;
alter table public.reporte_precio add column if not exists requiere_confirmacion boolean not null default false;
alter table public.reporte_precio add column if not exists es_falso boolean not null default false;
alter table public.reporte_precio add column if not exists revisado_en timestamptz;

-- Un reporte rechazado siempre explica por qué (NOT VALID: no revisa filas
-- anteriores a esta versión).
alter table public.reporte_precio drop constraint if exists reporte_precio_rechazo_motivo_check;
alter table public.reporte_precio add constraint reporte_precio_rechazo_motivo_check
  check (estado <> 'rechazado' or motivo is not null) not valid;

-- La pantalla "por confirmar" busca los pendientes que esperan confirmación.
create index if not exists reporte_precio_confirmacion_idx
  on public.reporte_precio (creado_en desc)
  where estado = 'pendiente' and requiere_confirmacion;


-- ---------------------------------------------------------------------
-- 2. Movimientos de puntos y confirmaciones
-- ---------------------------------------------------------------------
create table if not exists public.movimiento_puntos (
  id_movimiento uuid primary key default gen_random_uuid(),
  id_usuario    uuid not null references public.usuario (id_usuario) on delete cascade,
  id_reporte    uuid references public.reporte_precio (id_reporte) on delete set null,
  puntos        integer not null,
  tipo          text not null default 'reporte_validado',
  motivo        text not null,
  creado_en     timestamptz not null default now()
);

-- 'canje' lo usará la HU-26; 'ajuste' lo podrá usar la moderación (HU-27).
alter table public.movimiento_puntos drop constraint if exists movimiento_puntos_tipo_check;
alter table public.movimiento_puntos add constraint movimiento_puntos_tipo_check
  check (tipo in ('reporte_validado', 'canje', 'ajuste'));

-- Un reporte da puntos una sola vez.
create unique index if not exists movimiento_puntos_reporte_uq
  on public.movimiento_puntos (id_reporte) where tipo = 'reporte_validado';

create index if not exists movimiento_puntos_usuario_idx
  on public.movimiento_puntos (id_usuario, creado_en desc);

alter table public.movimiento_puntos enable row level security;

drop policy if exists movimiento_puntos_select_own on public.movimiento_puntos;
create policy movimiento_puntos_select_own on public.movimiento_puntos
  for select to authenticated
  using (id_usuario = auth.uid());

drop policy if exists movimiento_puntos_select_admin on public.movimiento_puntos;
create policy movimiento_puntos_select_admin on public.movimiento_puntos
  for select to authenticated
  using (public.es_administrador());

-- Nadie escribe directo: los puntos los asignan las funciones de abajo.
revoke insert, update, delete on public.movimiento_puntos from authenticated;


create table if not exists public.confirmacion_reporte (
  id_reporte uuid not null references public.reporte_precio (id_reporte) on delete cascade,
  id_usuario uuid not null references public.usuario (id_usuario) on delete cascade,
  rol        text not null,
  creado_en  timestamptz not null default now(),
  primary key (id_reporte, id_usuario)
);

alter table public.confirmacion_reporte drop constraint if exists confirmacion_reporte_rol_check;
alter table public.confirmacion_reporte add constraint confirmacion_reporte_rol_check
  check (rol in ('colaborador', 'comercio'));

alter table public.confirmacion_reporte enable row level security;

drop policy if exists confirmacion_reporte_select_own on public.confirmacion_reporte;
create policy confirmacion_reporte_select_own on public.confirmacion_reporte
  for select to authenticated
  using (id_usuario = auth.uid());

revoke insert, update, delete on public.confirmacion_reporte from authenticated;


-- ---------------------------------------------------------------------
-- 3. Reglas de niveles y puntos
-- ---------------------------------------------------------------------
create or replace function public.nivel_para_puntos(p_acumulados bigint)
returns integer
language sql
immutable
as $$
  select case
    when p_acumulados >= 500 then 3   -- Experto
    when p_acumulados >= 100 then 2   -- Frecuente
    else 1                            -- Nuevo
  end;
$$;

-- Puntos que gana un reporte validado de [p_id_producto]. Se calcula con el
-- estado del precio ANTES de aplicar el reporte.
create or replace function public.puntos_para_reporte(p_id_producto uuid)
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  c_base          constant integer := 10;
  c_sin_datos     constant integer := 10;
  c_desactualizado constant integer := 5;
  c_dias          constant integer := 7;
  v_actualizado   timestamptz;
begin
  select pp.actualizado_en into v_actualizado
    from public.precio_producto pp
   where pp.id_producto = p_id_producto;

  if not found then
    return c_base + c_sin_datos;                       -- producto sin precio
  elsif (current_date - v_actualizado::date) > c_dias then
    -- Días de calendario, como ConfianzaReglas.diasDeAntiguedad (HU-13).
    return c_base + c_desactualizado;                  -- precio desactualizado
  end if;
  return c_base;
end;
$$;

revoke all on function public.puntos_para_reporte(uuid) from public, anon, authenticated;


-- ---------------------------------------------------------------------
-- 4. Revisión automática de un reporte nuevo
-- ---------------------------------------------------------------------
create or replace function public.revisar_reporte(p_id_reporte uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  c_radio_m   constant double precision := 150;
  c_diferencia constant numeric := 0.30;
  r           public.reporte_precio%rowtype;
  v_ref       integer;
  v_estado    text;
  v_motivo    text;
  v_confirmar boolean := false;
  v_falso     boolean := false;
begin
  select * into r from public.reporte_precio
   where id_reporte = p_id_reporte for update;
  if not found or r.estado <> 'pendiente' then
    return;
  end if;

  if r.distancia_m > c_radio_m then
    -- Ubicación
    v_estado := 'rechazado';
    v_motivo := 'La ubicación no coincide con el establecimiento.';
    v_falso  := true;
  elsif r.foto_path is null or btrim(r.foto_path) = ''
        or not exists (
          select 1 from storage.objects o
           where o.bucket_id = 'reportes' and o.name = r.foto_path) then
    -- Evidencia
    v_estado := 'rechazado';
    v_motivo := 'No se encontró la foto de la etiqueta.';
    v_falso  := true;
  else
    -- Coherencia con el historial del producto
    select pp.precio into v_ref
      from public.precio_producto pp
     where pp.id_producto = r.id_producto;

    if v_ref is not null
       and abs(r.precio - v_ref)::numeric / v_ref > c_diferencia then
      v_estado    := 'pendiente';
      v_confirmar := true;
      v_motivo    := 'El precio es muy distinto al registrado ($ ' || v_ref
                     || '). Espera la confirmación de otro colaborador o del comercio.';
    else
      v_estado := 'validado';
    end if;
  end if;

  update public.reporte_precio
     set estado = v_estado,
         motivo = v_motivo,
         requiere_confirmacion = v_confirmar,
         es_falso = v_falso,
         revisado_en = case when v_estado = 'pendiente' then null else now() end
   where id_reporte = p_id_reporte;
end;
$$;

revoke all on function public.revisar_reporte(uuid) from public, anon, authenticated;

create or replace function public.reporte_precio_revisar_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.revisar_reporte(new.id_reporte);
  return null;
end;
$$;

revoke all on function public.reporte_precio_revisar_trigger() from public, anon, authenticated;

drop trigger if exists reporte_precio_revisar on public.reporte_precio;
create trigger reporte_precio_revisar
  after insert on public.reporte_precio
  for each row execute function public.reporte_precio_revisar_trigger();


-- ---------------------------------------------------------------------
-- 5. Resultado de la revisión: precio, puntos, reputación y aviso
-- Corre una sola vez, cuando el reporte pasa de pendiente a validado o
-- rechazado (sea por la revisión automática o por una confirmación).
-- ---------------------------------------------------------------------
create or replace function public.reporte_precio_aplicar_resultado()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_puntos   integer;
  v_producto text;
begin
  select p.nombre into v_producto
    from public.producto p where p.id_producto = new.id_producto;
  v_producto := coalesce(v_producto, 'el producto');

  if new.estado = 'validado' then
    -- Los puntos se calculan ANTES de actualizar el precio.
    v_puntos := public.puntos_para_reporte(new.id_producto);

    -- El precio queda con la fuente "colaborador" (la app la muestra como
    -- "Comunidad") y su fecha; los triggers de la HU-11 anotan el historial.
    insert into public.precio_producto (id_producto, precio, disponible, fuente)
    values (new.id_producto, new.precio::integer, not new.agotado, 'colaborador')
    on conflict (id_producto) do update
      set precio = excluded.precio,
          disponible = excluded.disponible,
          fuente = 'colaborador';

    insert into public.movimiento_puntos (id_usuario, id_reporte, puntos, tipo, motivo)
    values (new.id_colaborador, new.id_reporte, v_puntos, 'reporte_validado',
            'Reporte validado: ' || v_producto);

    update public.perfil_colaborador pc
       set puntos_saldo = pc.puntos_saldo + v_puntos,
           nivel = public.nivel_para_puntos((
             select coalesce(sum(m.puntos), 0)
               from public.movimiento_puntos m
              where m.id_usuario = new.id_colaborador
                and m.tipo = 'reporte_validado')),
           reputacion = least(100, pc.reputacion + 1)
     where pc.id_usuario = new.id_colaborador;

    insert into public.notificacion (id_usuario, titulo, mensaje)
    values (new.id_colaborador, 'Reporte validado',
            'Tu reporte de ' || v_producto || ' fue validado. Ganaste '
            || v_puntos || ' puntos.');

  elsif new.estado = 'rechazado' then
    if new.es_falso then
      update public.perfil_colaborador pc
         set reputacion = greatest(0, pc.reputacion - 5)
       where pc.id_usuario = new.id_colaborador;
    end if;

    insert into public.notificacion (id_usuario, titulo, mensaje)
    values (new.id_colaborador, 'Reporte rechazado',
            'Tu reporte de ' || v_producto || ' fue rechazado. '
            || coalesce(new.motivo, ''));
  end if;

  return null;
end;
$$;

revoke all on function public.reporte_precio_aplicar_resultado() from public, anon, authenticated;

drop trigger if exists reporte_precio_resultado on public.reporte_precio;
create trigger reporte_precio_resultado
  after update of estado on public.reporte_precio
  for each row
  when (old.estado = 'pendiente' and new.estado in ('validado', 'rechazado'))
  execute function public.reporte_precio_aplicar_resultado();


-- ---------------------------------------------------------------------
-- 6. Confirmar o corregir un reporte dudoso
-- ---------------------------------------------------------------------

-- Otro colaborador confirma el reporte. También debe estar a ≤ 150 m del
-- establecimiento: confirmar sin estar ahí no sirve de nada.
create or replace function public.confirmar_reporte_colaborador(
  p_id_reporte uuid,
  p_latitud    double precision,
  p_longitud   double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  c_radio_m constant double precision := 150;
  r         public.reporte_precio%rowtype;
  v_lat     double precision;
  v_lng     double precision;
begin
  if auth.uid() is null or not public.es_colaborador() then
    raise exception 'Activa el modo Colaborador para confirmar reportes.';
  end if;

  select * into r from public.reporte_precio
   where id_reporte = p_id_reporte for update;
  if not found or r.estado <> 'pendiente' or not r.requiere_confirmacion then
    raise exception 'Este reporte ya no necesita confirmación.';
  end if;
  if r.id_colaborador = auth.uid() then
    raise exception 'No puedes confirmar tu propio reporte.';
  end if;
  if exists (select 1 from public.confirmacion_reporte
              where id_reporte = p_id_reporte and id_usuario = auth.uid()) then
    raise exception 'Ya confirmaste este reporte.';
  end if;
  if p_latitud is null or p_longitud is null then
    raise exception 'No pudimos conocer tu ubicación. Inténtalo de nuevo.';
  end if;

  select c.latitud, c.longitud into v_lat, v_lng
    from public.comercio c where c.id_comercio = r.id_comercio;
  if v_lat is null
     or public.distancia_metros(p_latitud, p_longitud, v_lat, v_lng) > c_radio_m then
    raise exception 'Debes estar en el establecimiento para confirmar el precio.';
  end if;

  insert into public.confirmacion_reporte (id_reporte, id_usuario, rol)
  values (p_id_reporte, auth.uid(), 'colaborador');

  update public.reporte_precio
     set estado = 'validado', motivo = null,
         requiere_confirmacion = false, revisado_en = now()
   where id_reporte = p_id_reporte;
end;
$$;

revoke all on function public.confirmar_reporte_colaborador(uuid, double precision, double precision) from public, anon;
grant execute on function public.confirmar_reporte_colaborador(uuid, double precision, double precision) to authenticated;


-- El dueño del comercio confirma el precio reportado.
create or replace function public.confirmar_reporte_comercio(p_id_reporte uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.reporte_precio%rowtype;
begin
  select * into r from public.reporte_precio
   where id_reporte = p_id_reporte for update;
  if not found or r.estado <> 'pendiente' or not r.requiere_confirmacion then
    raise exception 'Este reporte ya no necesita confirmación.';
  end if;
  if not exists (select 1 from public.comercio c
                  where c.id_comercio = r.id_comercio
                    and c.id_usuario = auth.uid() and c.estado = 'aprobado') then
    raise exception 'Solo el comercio del establecimiento puede confirmar este reporte.';
  end if;

  insert into public.confirmacion_reporte (id_reporte, id_usuario, rol)
  values (p_id_reporte, auth.uid(), 'comercio')
  on conflict do nothing;

  update public.reporte_precio
     set estado = 'validado', motivo = null,
         requiere_confirmacion = false, revisado_en = now()
   where id_reporte = p_id_reporte;
end;
$$;

revoke all on function public.confirmar_reporte_comercio(uuid) from public, anon;
grant execute on function public.confirmar_reporte_comercio(uuid) to authenticated;


-- El dueño corrige: el reporte se rechaza (sin penalizar al colaborador:
-- no es un reporte falso) y el precio queda con el valor del comercio.
create or replace function public.corregir_reporte_comercio(
  p_id_reporte uuid,
  p_precio     bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.reporte_precio%rowtype;
begin
  if p_precio is null or p_precio <= 0 or p_precio > 100000000 then
    raise exception 'El precio debe estar entre $ 1 y $ 100000000.';
  end if;

  select * into r from public.reporte_precio
   where id_reporte = p_id_reporte for update;
  if not found or r.estado <> 'pendiente' or not r.requiere_confirmacion then
    raise exception 'Este reporte ya no necesita confirmación.';
  end if;
  if not exists (select 1 from public.comercio c
                  where c.id_comercio = r.id_comercio
                    and c.id_usuario = auth.uid() and c.estado = 'aprobado') then
    raise exception 'Solo el comercio del establecimiento puede corregir este reporte.';
  end if;

  insert into public.precio_producto (id_producto, precio, disponible, fuente)
  values (r.id_producto, p_precio::integer, true, 'comercio')
  on conflict (id_producto) do update
    set precio = excluded.precio, fuente = 'comercio';

  insert into public.confirmacion_reporte (id_reporte, id_usuario, rol)
  values (p_id_reporte, auth.uid(), 'comercio')
  on conflict do nothing;

  update public.reporte_precio
     set estado = 'rechazado',
         motivo = 'El comercio indicó que el precio correcto es $ ' || p_precio || '.',
         requiere_confirmacion = false, es_falso = false, revisado_en = now()
   where id_reporte = p_id_reporte;
end;
$$;

revoke all on function public.corregir_reporte_comercio(uuid, bigint) from public, anon;
grant execute on function public.corregir_reporte_comercio(uuid, bigint) to authenticated;


-- ---------------------------------------------------------------------
-- 7. Lecturas para la app (paginadas: limite = tamaño de página + 1)
-- ---------------------------------------------------------------------

-- mis_reportes cambia de columnas (motivo y confirmación), así que hay que
-- borrarla y crearla de nuevo.
drop function if exists public.mis_reportes(integer, integer);

create function public.mis_reportes(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_reporte            uuid,
  producto              text,
  comercio              text,
  precio                bigint,
  precio_promocional    bigint,
  agotado               boolean,
  estado                text,
  creado_en             timestamptz,
  motivo                text,
  requiere_confirmacion boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id_reporte,
         coalesce(p.nombre, 'Producto eliminado')::text,
         coalesce(c.nombre, 'Establecimiento')::text,
         r.precio, r.precio_promocional, r.agotado, r.estado::text, r.creado_en,
         r.motivo::text, r.requiere_confirmacion
    from public.reporte_precio r
    left join public.producto p on p.id_producto = r.id_producto
    left join public.comercio c on c.id_comercio = r.id_comercio
   where r.id_colaborador = auth.uid()
   order by r.creado_en desc, r.id_reporte
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_reportes(integer, integer) from public, anon;
grant execute on function public.mis_reportes(integer, integer) to authenticated;


-- Reportes de otros colaboradores que esperan una confirmación (los que ya
-- confirmé o escribí yo no aparecen).
create or replace function public.reportes_por_confirmar(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_reporte    uuid,
  producto      text,
  comercio      text,
  precio        bigint,
  precio_actual integer,
  creado_en     timestamptz,
  motivo        text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.es_colaborador() then
    raise exception 'Activa el modo Colaborador para confirmar reportes.';
  end if;

  -- Los nombres se convierten a text: en esta base son varchar y RETURN QUERY
  -- exige el tipo exacto de la tabla de salida.
  return query
  select r.id_reporte,
         coalesce(p.nombre, 'Producto eliminado')::text,
         coalesce(c.nombre, 'Establecimiento')::text,
         r.precio, pp.precio, r.creado_en, r.motivo::text
    from public.reporte_precio r
    left join public.producto p on p.id_producto = r.id_producto
    left join public.comercio c on c.id_comercio = r.id_comercio
    left join public.precio_producto pp on pp.id_producto = r.id_producto
   where r.estado = 'pendiente' and r.requiere_confirmacion
     and r.id_colaborador <> auth.uid()
     and not exists (select 1 from public.confirmacion_reporte cr
                      where cr.id_reporte = r.id_reporte and cr.id_usuario = auth.uid())
   order by r.creado_en desc, r.id_reporte
   limit p_limite offset p_desplazamiento;
end;
$$;

revoke all on function public.reportes_por_confirmar(integer, integer) from public, anon;
grant execute on function public.reportes_por_confirmar(integer, integer) to authenticated;


-- Reportes de la comunidad sobre productos de MI comercio que esperan que yo
-- los confirme o los corrija.
create or replace function public.reportes_de_mi_comercio(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_reporte    uuid,
  producto      text,
  comercio      text,
  precio        bigint,
  precio_actual integer,
  creado_en     timestamptz,
  motivo        text
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id_reporte,
         coalesce(p.nombre, 'Producto eliminado')::text,
         c.nombre::text,
         r.precio, pp.precio, r.creado_en, r.motivo::text
    from public.reporte_precio r
    join public.comercio c on c.id_comercio = r.id_comercio
    left join public.producto p on p.id_producto = r.id_producto
    left join public.precio_producto pp on pp.id_producto = r.id_producto
   where c.id_usuario = auth.uid() and c.estado = 'aprobado'
     and r.estado = 'pendiente' and r.requiere_confirmacion
   order by r.creado_en desc, r.id_reporte
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.reportes_de_mi_comercio(integer, integer) from public, anon;
grant execute on function public.reportes_de_mi_comercio(integer, integer) to authenticated;


-- Puntos, nivel y reputación del colaborador.
create or replace function public.resumen_puntos()
returns table (
  puntos_saldo     integer,
  puntos_acumulados bigint,
  nivel            integer,
  reputacion       numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.es_colaborador() then
    raise exception 'Activa el modo Colaborador para ver tus puntos.';
  end if;

  return query
  select pc.puntos_saldo,
         coalesce((select sum(m.puntos) from public.movimiento_puntos m
                    where m.id_usuario = pc.id_usuario
                      and m.tipo = 'reporte_validado'), 0)::bigint,
         pc.nivel, pc.reputacion
    from public.perfil_colaborador pc
   where pc.id_usuario = auth.uid();
end;
$$;

revoke all on function public.resumen_puntos() from public, anon;
grant execute on function public.resumen_puntos() to authenticated;


-- Historial de puntos del colaborador, del más reciente al más antiguo.
create or replace function public.mis_movimientos_puntos(
  p_limite         integer default 21,
  p_desplazamiento integer default 0
)
returns table (
  id_movimiento uuid,
  puntos        integer,
  tipo          text,
  motivo        text,
  creado_en     timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select m.id_movimiento, m.puntos, m.tipo::text, m.motivo::text, m.creado_en
    from public.movimiento_puntos m
   where m.id_usuario = auth.uid()
   order by m.creado_en desc, m.id_movimiento
   limit p_limite offset p_desplazamiento;
$$;

revoke all on function public.mis_movimientos_puntos(integer, integer) from public, anon;
grant execute on function public.mis_movimientos_puntos(integer, integer) to authenticated;
