-- =====================================================================
-- SmartCart · Sprint 2 · HU-06, HU-07 y HU-08
-- Ejecutar en Supabase → SQL Editor.
--
-- IMPORTANTE: este script NO se ha ejecutado contra el proyecto real (el
-- repositorio no incluye el esquema y el host de Supabase del .env no
-- resolvía al momento de escribirlo). Antes de correrlo, compara con las
-- tablas existentes (Table Editor) y ajusta los nombres de columna en
-- `SupabaseColumns` (lib/core/constants/supabase_tables.dart) si difieren.
-- Es idempotente: se puede ejecutar más de una vez.
-- =====================================================================


-- ---------------------------------------------------------------------
-- HU-08 · perfil_repartidor
-- Una fila por repartidor. Nace 'pendiente' y sin disponibilidad; solo el
-- administrador cambia el estado (HU-24).
-- ---------------------------------------------------------------------
create table if not exists public.perfil_repartidor (
  id_usuario     uuid primary key references public.usuario (id_usuario) on delete cascade,
  estado         text not null default 'pendiente'
                 check (estado in ('pendiente', 'aprobado', 'rechazado')),
  motivo_rechazo text,
  disponible     boolean not null default false,
  creado_en      timestamptz not null default now()
);

alter table public.perfil_repartidor enable row level security;

drop policy if exists perfil_repartidor_select_own on public.perfil_repartidor;
create policy perfil_repartidor_select_own on public.perfil_repartidor
  for select to authenticated
  using (id_usuario = auth.uid());

-- La persona solo puede crear SU fila y únicamente pendiente / no disponible.
drop policy if exists perfil_repartidor_insert_own on public.perfil_repartidor;
create policy perfil_repartidor_insert_own on public.perfil_repartidor
  for insert to authenticated
  with check (
    id_usuario = auth.uid()
    and estado = 'pendiente'
    and disponible = false
  );

-- No hay política de update para el dueño: no puede aprobarse a sí mismo ni
-- activar su disponibilidad. La política del administrador se crea en HU-24.


-- ---------------------------------------------------------------------
-- HU-07 · comercio
-- Si la tabla ya existe (Sprint 1), `add column if not exists` solo agrega
-- lo que falte. Revisa que no queden otras columnas NOT NULL sin valor por
-- defecto: el insert de la app solo llena las columnas de abajo.
-- ---------------------------------------------------------------------
create table if not exists public.comercio (
  id_comercio uuid primary key default gen_random_uuid()
);

alter table public.comercio add column if not exists id_usuario     uuid references public.usuario (id_usuario) on delete cascade;
alter table public.comercio add column if not exists nombre         text;
alter table public.comercio add column if not exists telefono       text;
alter table public.comercio add column if not exists direccion      text;
alter table public.comercio add column if not exists ciudad         text;
alter table public.comercio add column if not exists hora_apertura  text;   -- 'HH:mm'
alter table public.comercio add column if not exists hora_cierre    text;   -- 'HH:mm'
alter table public.comercio add column if not exists tipo_servicio  text;   -- recogida | entrega | ambos
alter table public.comercio add column if not exists estado         text not null default 'pendiente';
alter table public.comercio add column if not exists motivo_rechazo text;

alter table public.comercio drop constraint if exists comercio_estado_check;
alter table public.comercio add constraint comercio_estado_check
  check (estado in ('pendiente', 'aprobado', 'rechazado'));

alter table public.comercio drop constraint if exists comercio_tipo_servicio_check;
alter table public.comercio add constraint comercio_tipo_servicio_check
  check (tipo_servicio is null or tipo_servicio in ('recogida', 'entrega', 'ambos'));

-- Un comercio por dueño (la app tampoco crea un segundo).
create unique index if not exists comercio_id_usuario_key on public.comercio (id_usuario);

alter table public.comercio enable row level security;

-- Solo el dueño ve y edita su comercio.
drop policy if exists comercio_select_own on public.comercio;
create policy comercio_select_own on public.comercio
  for select to authenticated
  using (id_usuario = auth.uid());

-- Nace siempre pendiente.
drop policy if exists comercio_insert_own on public.comercio;
create policy comercio_insert_own on public.comercio
  for insert to authenticated
  with check (id_usuario = auth.uid() and estado = 'pendiente');

-- Mientras esté pendiente el dueño puede corregir sus datos, pero no
-- cambiarle el estado: aprobar/rechazar es del administrador (HU-24).
drop policy if exists comercio_update_own_pendiente on public.comercio;
create policy comercio_update_own_pendiente on public.comercio
  for update to authenticated
  using (id_usuario = auth.uid() and estado = 'pendiente')
  with check (id_usuario = auth.uid() and estado = 'pendiente');


-- ---------------------------------------------------------------------
-- HU-06 · perfil_colaborador y usuario_rol
-- No requieren cambios: el onboarding usa las políticas del Sprint 1
-- (perfil_colab_insert_own y usuario_rol_insert_own). Verifica que
-- usuario_rol_insert_own permita a un cliente agregarse el rol
-- 'colaborador' DESPUÉS de haberse registrado (no solo durante el registro).
-- ---------------------------------------------------------------------
