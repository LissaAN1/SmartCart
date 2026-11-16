-- =====================================================================
-- SmartCart · Sprint 2 · HU-13 · Detalle del precio con fuente, fecha y
-- confianza
-- Ejecutar en Supabase → SQL Editor, DESPUÉS de sprint2_hu12.sql y
-- sprint2_hu17.sql (usa ofertas_publicadas() y es_cliente()).
-- Es idempotente: se puede ejecutar más de una vez.
--
-- Qué agrega:
--   1. La tabla reporte_precio_incorrecto: lo que un cliente reporta cuando
--      un precio no es el real (escenario 3). Guarda el precio tal como se
--      veía (valor, fuente y fecha) para que quien lo revise sepa de qué
--      hablaban, aunque después el comercio lo cambie.
--   2. La función reportar_precio_incorrecto(), la única forma de crear un
--      reporte.
--
-- Lo que NO hace: la fuente, la fecha y el nivel de confianza ya llegan a la
-- app con precios_de_producto() (HU-12); el nivel se calcula en la app
-- (ConfianzaReglas). La revisión de los reportes (aceptar o descartar) es
-- de la moderación de la plataforma (HU-27); aquí solo quedan pendientes.
-- Las pruebas están en pruebas_hu13_politicas.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Reportes de precio incorrecto
-- ---------------------------------------------------------------------
create table if not exists public.reporte_precio_incorrecto (
  id_reporte            uuid primary key default gen_random_uuid(),
  id_usuario            uuid not null references public.usuario (id_usuario) on delete cascade,
  id_producto           uuid not null references public.producto (id_producto) on delete cascade,
  -- El precio vigente (el de la promoción si la había), su fuente y su fecha
  -- en el momento del reporte.
  precio_reportado      integer not null,
  fuente_reportada      text not null,
  precio_actualizado_en timestamptz not null,
  motivo                text,
  estado                text not null default 'pendiente',
  creado_en             timestamptz not null default now()
);

alter table public.reporte_precio_incorrecto
  drop constraint if exists reporte_precio_incorrecto_estado_check;
alter table public.reporte_precio_incorrecto
  add constraint reporte_precio_incorrecto_estado_check
  check (estado in ('pendiente', 'resuelto', 'descartado'));

alter table public.reporte_precio_incorrecto
  drop constraint if exists reporte_precio_incorrecto_motivo_check;
alter table public.reporte_precio_incorrecto
  add constraint reporte_precio_incorrecto_motivo_check
  check (motivo is null or char_length(motivo) between 1 and 300);

-- Un cliente tiene como máximo un reporte PENDIENTE por producto: no se llena
-- la revisión con el mismo aviso. Cuando se resuelve, puede reportar de nuevo.
create unique index if not exists reporte_precio_incorrecto_pendiente_uq
  on public.reporte_precio_incorrecto (id_usuario, id_producto)
  where estado = 'pendiente';

create index if not exists reporte_precio_incorrecto_producto_idx
  on public.reporte_precio_incorrecto (id_producto, creado_en desc);

alter table public.reporte_precio_incorrecto enable row level security;

-- Cada cliente ve solo sus propios reportes. Nadie crea, edita ni borra
-- directo: se hace con la función de abajo (y la moderación, en la HU-27).
drop policy if exists reporte_precio_incorrecto_select_own on public.reporte_precio_incorrecto;
create policy reporte_precio_incorrecto_select_own on public.reporte_precio_incorrecto
  for select to authenticated
  using (id_usuario = auth.uid() and public.es_cliente());

revoke all on public.reporte_precio_incorrecto from public, anon;
revoke insert, update, delete on public.reporte_precio_incorrecto from authenticated;
grant select on public.reporte_precio_incorrecto to authenticated;


-- ---------------------------------------------------------------------
-- 2. Reportar un precio incorrecto
-- security definer: escribe la tabla sin depender de sus políticas, pero
-- antes comprueba todo lo que importa. Devuelve 'registrado' o 'ya_reportado'.
-- Los textos de los errores salen en la app tal cual (código P0001).
-- ---------------------------------------------------------------------
create or replace function public.reportar_precio_incorrecto(
  p_id_producto uuid,
  p_motivo text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario uuid := auth.uid();
  -- btrim solo quita espacios por defecto: se le piden también tabuladores y
  -- saltos de línea, para que un motivo en blanco quede vacío (igual que
  -- trim() en la app).
  v_motivo  text := nullif(btrim(coalesce(p_motivo, ''), E' \t\r\n'), '');
  v_precio  integer;
  v_fuente  text;
  v_fecha   timestamptz;
begin
  if v_usuario is null then
    raise exception 'Inicia sesión para reportar un precio.';
  end if;
  if not public.es_cliente() then
    raise exception 'Solo los clientes pueden reportar un precio incorrecto.';
  end if;
  if v_motivo is not null and char_length(v_motivo) > 300 then
    raise exception 'El motivo no puede pasar de 300 caracteres.';
  end if;

  -- Solo se reporta lo que el cliente puede ver: un producto con precio de un
  -- comercio aprobado (ofertas_publicadas, de la HU-12). Se guarda el precio
  -- vigente, el de la promoción si la hay.
  select o.precio, o.fuente, o.actualizado_en
    into v_precio, v_fuente, v_fecha
    from public.ofertas_publicadas() o
   where o.id_producto = p_id_producto;
  if not found then
    raise exception 'Ese precio ya no está publicado.';
  end if;

  if exists (
    select 1 from public.reporte_precio_incorrecto r
     where r.id_usuario = v_usuario
       and r.id_producto = p_id_producto
       and r.estado = 'pendiente'
  ) then
    return 'ya_reportado';
  end if;

  insert into public.reporte_precio_incorrecto
    (id_usuario, id_producto, precio_reportado, fuente_reportada,
     precio_actualizado_en, motivo)
  values
    (v_usuario, p_id_producto, v_precio, v_fuente, v_fecha, v_motivo);
  return 'registrado';
exception
  -- Dos toques casi a la vez: el índice único deja pasar solo el primero.
  when unique_violation then
    return 'ya_reportado';
end;
$$;

revoke all on function public.reportar_precio_incorrecto(uuid, text) from public, anon;
grant execute on function public.reportar_precio_incorrecto(uuid, text) to authenticated;
