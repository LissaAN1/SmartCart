-- =====================================================================
-- SmartCart · Verificar el esquema real de Supabase
-- Ejecutar en Supabase → SQL Editor. SOLO LEE: no cambia nada.
--
-- Devuelve una sola tabla con todo lo que la app necesita saber:
--   tabla     · cada tabla de `public`, si tiene RLS y cuántas filas tiene
--   columna   · cada columna con su tipo, si es obligatoria y su default
--   fk        · llaves foráneas (de qué columna a qué tabla)
--   politica  · políticas RLS (operación y a quién aplica)
--   funcion   · funciones propias (decidir_solicitud, es_administrador...)
--
-- Para compartir el resultado: botón "Export" → "Copy as CSV" (o
-- "Download CSV") y pégalo completo.
-- =====================================================================

with tablas as (
  select c.oid, c.relname as tabla, c.relrowsecurity as rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p')
)
select *
from (
  -- Tablas, RLS y número de filas.
  select
    1 as orden,
    'tabla' as tipo,
    t.tabla as objeto,
    case when t.rls then 'RLS activo' else 'RLS DESACTIVADO' end as detalle,
    (xpath('/row/c/text()',
           query_to_xml(format('select count(*) as c from public.%I', t.tabla),
                        false, true, '')))[1]::text || ' filas' as extra
  from tablas t

  union all

  -- Columnas en el orden en que están definidas.
  select
    2,
    'columna',
    t.tabla || '.' || a.attname,
    format_type(a.atttypid, a.atttypmod)
      || case when a.attnotnull then ' not null' else '' end,
    pg_get_expr(d.adbin, d.adrelid)
  from tablas t
  join pg_attribute a on a.attrelid = t.oid and a.attnum > 0 and not a.attisdropped
  left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum

  union all

  -- Llaves foráneas.
  select
    3,
    'fk',
    t.tabla || '.' || con.conname,
    pg_get_constraintdef(con.oid),
    null
  from tablas t
  join pg_constraint con on con.conrelid = t.oid and con.contype = 'f'

  union all

  -- Políticas RLS.
  select
    4,
    'politica',
    p.tablename || '.' || p.policyname,
    p.cmd || ' para ' || array_to_string(p.roles, ','),
    concat_ws(' | ', 'using: ' || p.qual, 'check: ' || p.with_check)
  from pg_policies p
  where p.schemaname = 'public'

  union all

  -- Funciones propias del esquema public.
  select
    5,
    'funcion',
    p.proname || '(' || pg_get_function_arguments(p.oid) || ')',
    case when p.prosecdef then 'security definer' else 'security invoker' end,
    'devuelve ' || pg_get_function_result(p.oid)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prokind = 'f'
) as esquema
order by orden, objeto;

-- Los perfiles de la tabla `rol` se ven aparte (descomenta y ejecuta solo
-- esta línea si hace falta):
-- select * from public.rol order by 1;
