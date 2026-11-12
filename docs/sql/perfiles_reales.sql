-- =====================================================================
-- SmartCart · Perfiles con datos reales
-- Ejecutar en Supabase → SQL Editor (proyecto oslxqv…). Idempotente.
--
-- cambiar_disponibilidad(): el repartidor activa/desactiva su
-- disponibilidad. Es una función (y no un UPDATE directo) para que el dueño
-- pueda cambiar SOLO `disponible`, y solo si ya está aprobado; así no puede
-- aprobarse a sí mismo editando `estado`.
-- =====================================================================
create or replace function public.cambiar_disponibilidad(p_disponible boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.perfil_repartidor
     set disponible = p_disponible
   where id_usuario = auth.uid()
     and estado = 'aprobado';

  if not found then
    raise exception 'Solo un repartidor aprobado puede cambiar su disponibilidad'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.cambiar_disponibilidad(boolean) from public;
grant execute on function public.cambiar_disponibilidad(boolean) to authenticated;
