# Sprint 3 · HU-28 · Estadísticas reales del panel del administrador

Informe de implementación. Rama: `feat/hu28-estadisticas-admin`, creada desde `develop` (`f8f1865`). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como administrador, quiero ver en mi panel de control estadísticas calculadas con los datos reales de la plataforma, para supervisar SmartCart con información confiable y no con cifras fijas. (Sprint Backlog 3, HU-28, 3 puntos, Must.)

## 2. Alcance implementado

| Criterio de aceptación | Estado | Cómo se cumple |
|---|---|---|
| Todas las cifras salen de la base; desaparecen las de ejemplo | Implementado | `estadisticas_panel()` (SQL) → `PanelEstadisticas`. Se eliminaron 12.480, 1.326, 342 y 87. |
| Usuarios registrados por rol; "Usuarios activos" pasa a "Usuarios registrados" | Implementado | Conteo de `usuario_rol` por rol, bajo "USUARIOS REGISTRADOS". |
| Comercios por estado | Implementado | Aprobados, pendientes y rechazados de `comercio`. |
| Repartidores aprobados y en línea | Implementado | `perfil_repartidor` aprobados y, de ellos, con `disponible`. |
| Solicitudes pendientes y reportes de precio pendientes | Implementado | `comercio`, `perfil_repartidor` y `reporte_precio` en estado pendiente. |
| Pedidos de hoy y órdenes por estado; sin órdenes, "No hay información disponible" | Implementado | Tabla `orden` (HU-20); "hoy" en la fecha de Colombia. La función devuelve `ordenes: null` si no hay ninguna. |
| Se consultan cada vez que se abre el panel o se vuelve a él | Implementado | El `RolShell` consulta al entrar, al volver de Aprobaciones y al tocar la pestaña Panel. |
| Sin variaciones porcentuales ni "Estado del sistema" | Implementado | Se quitaron las notas y `TarjetaEstadoSistema`. |
| Indicador de carga y error con reintento | Implementado | `EstadisticasBloc` y `PanelEstadisticas`. |
| Solo el administrador | Implementado | `estadisticas_panel()` rechaza con 42501 a otro rol y no tiene permiso para sesiones anónimas; el caso de uso además da un mensaje claro. |

Escenarios 1 a 4: prueba automática y prueba SQL. Ver `docs/HU28_informe_pruebas.md`.

## 3. Decisiones

| Tema | Decisión | Por qué |
|---|---|---|
| Una sola función | `estadisticas_panel()` devuelve un JSON con todos los conteos | Una consulta por apertura del panel y un solo punto donde se comprueba el permiso. Solo devuelve conteos, ningún dato personal. |
| Usuarios | Por rol, sin total | Una cuenta puede tener varios roles; sumarlos contaría personas dos veces. |
| Reportes pendientes | Solo `reporte_precio` | Es la tabla que cita el backlog. Los de precio incorrecto de clientes son de la bandeja de la HU-27. |
| Estados de órdenes | Solo se listan los que tienen al menos una orden | Evita una lista de ceros. |
| Recarga | Mientras vuelve a consultar se mantienen las cifras con una barra de carga; si falla, se quitan y se muestra el error | No mostrar cifras posiblemente viejas junto a un error. Si llegan dos respuestas, vale la última pedida. |
| Insignias | La pestaña "Aprobar" y el acceso rápido muestran las solicitudes pendientes; "Acción Requerida" solo aparece si hay | Usa el mismo dato real; antes el aviso salía siempre. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint3_hu28.sql` | `estadisticas_panel()`. Idempotente. |
| `docs/sql/pruebas_hu28_estadisticas.sql` | 11 pruebas: cada cifra contra el conteo de su tabla, actualización al aprobar, pedidos de hoy, sin órdenes y permisos. Termina en `ROLLBACK`. |
| `lib/features/estadisticas/` | Entidad, contrato, `GetEstadisticasUseCase`, data source, repositorio, `EstadisticasBloc` y `PanelEstadisticas`. |
| `test/estadisticas/`, `test/support/fakes_estadisticas.dart` | Pruebas y dobles. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/admin/presentation/pages/admin_home_screen.dart` | Cifras reales, insignias y aviso según las solicitudes. |
| `lib/features/admin/presentation/widgets/admin_widgets.dart` | Se eliminó "Estado del sistema" (`TarjetaEstadoSistema`, `ServicioSistema`, `EstadoServicio`). |
| `lib/features/home/presentation/pages/role_shell.dart`, `lib/app_router.dart` | Crean el Bloc del panel y lo recargan al abrirlo o volver. |
| `lib/core/constants/supabase_tables.dart`, `lib/core/di/injector.dart` | Función, claves y 4 registros (154 en total). |
| `test/di/injector_test.dart` | Registros de la HU-28. |

## 5. Arquitectura

`PanelEstadisticas` → `EstadisticasBloc` → `GetEstadisticasUseCase` → `EstadisticasRepository` → `SupabaseEstadisticasDataSource`. El dominio no importa Flutter ni Supabase y reutiliza `UserRole`, `ApprovalStatus` y `EstadoOrden`.

## 6. Cómo probarlo

Ver "Probar el panel del administrador (HU-28)" en el README.

## 7. Pendientes y limitaciones

- El SQL ya se ejecutó en Supabase y sus 11 pruebas dan `OK`. **Falta probarla en Android**; las pruebas de Flutter usan dobles.
- Las cifras no se actualizan solas mientras el panel está abierto.
- "Moderación", "Quejas" e "Incentivos" siguen como "próximamente" (no son de esta historia).
