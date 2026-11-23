# Sprint 3 · HU-15 y HU-16 · Validación de reportes y puntos, niveles y reputación

Informe de implementación. Rama: `feat/validation-reputation`, creada desde `main`. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> **HU-15.** Como colaborador, quiero que mis reportes se validen y poder ver su estado, para que la información sea confiable y saber si gané puntos.
> **HU-16.** Como colaborador, quiero ganar puntos por mis reportes validados y ver mi nivel, mi reputación y mi historial, para saber mi progreso y que mis reportes pesen más.

## 2. Alcance implementado

### HU-15 · Validación y estado de los reportes

| Criterio del backlog | Estado | Cómo se cumple |
|---|---|---|
| Cada reporte se revisa por ubicación, evidencia y coherencia con el historial | Implementado | `revisar_reporte()` (SQL) corre al recibir cada reporte; las reglas están en `ValidacionReglas` (Dart). |
| Un reporte muy distinto al historial espera la confirmación de otro colaborador o del comercio | Implementado | Queda `pendiente` con `requiere_confirmacion`. Otro colaborador lo confirma estando en el local, o el comercio lo confirma o lo corrige. |
| Estados pendiente, validado y rechazado; el rechazo muestra el motivo | Implementado | `reporte_precio.motivo`; el historial del colaborador muestra el motivo bajo cada reporte. |
| Un reporte validado actualiza el precio con la fuente "Comunidad" y su fecha | Implementado | El trigger guarda `precio_producto` con fuente `colaborador` (la app la muestra como "Comunidad"); los triggers de la HU-11 anotan el historial. |
| Un reporte rechazado no cambia el precio | Implementado | Solo `validado` toca `precio_producto`. |
| La lista de reportes se carga por páginas | Implementado | `mis_reportes`, `reportes_por_confirmar` y `reportes_de_mi_comercio` reciben límite y desplazamiento. |

Escenarios 1 (validado), 2 (rechazado) y 3 (requiere confirmación) tienen prueba automática y prueba SQL.

### HU-16 · Puntos, niveles y reputación

| Criterio del backlog | Estado | Cómo se cumple |
|---|---|---|
| Los puntos solo se otorgan cuando el reporte es validado | Implementado | Solo el trigger de resultado inserta en `movimiento_puntos`, y solo al pasar a `validado`. |
| Más puntos por productos sin datos o desactualizados | Implementado | 10 base, +10 sin precio, +5 con precio de más de 7 días (ver supuestos). |
| Niveles Nuevo, Frecuente y Experto según los puntos acumulados | Implementado | `NivelColaborador` (Dart) y `nivel_para_puntos()` (SQL). |
| La reputación sube con reportes validados y baja con reportes falsos | Implementado | +1 por validado; −5 por rechazado por falso (ubicación o evidencia). |
| El colaborador ve su historial de puntos, por páginas | Implementado | Pantalla `MisPuntosPage` con `mis_movimientos_puntos()` paginado. |

## 3. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| "Muy distinto al historial" | Más de **30 %** de diferencia con el precio actual del producto | El backlog no da cifra. 30 % deja pasar cambios normales y frena errores de digitación (un cero de más). Constante `ValidacionReglas.diferenciaMaxima` y `c_diferencia` en SQL. |
| Producto sin precio | Se valida (no hay con qué comparar) | Es justo el caso que el backlog quiere incentivar. |
| Puntos | 10 base; +10 producto sin datos; +5 precio desactualizado (> 7 días) | El backlog no da cifras. Los 7 días son los de la HU-13 (`ConfianzaReglas.diasLimite`). |
| "Zonas sin datos" | Se interpreta a nivel de producto, no de zona geográfica | No existe el concepto de zona en el modelo. |
| Niveles | Nuevo 0–99, Frecuente 100–499, Experto 500+ puntos **acumulados** | Acumulados y no saldo, para que canjear puntos (HU-26) no baje el nivel. |
| Reputación | 0 a 100; +1 / −5 | Un reporte falso pesa más que uno bueno. |
| Qué es "falso" | Rechazo por ubicación o por foto inexistente | Es lo que el sistema puede demostrar. Que el comercio corrija un precio **no** penaliza. |
| Quién confirma | Otro colaborador **a menos de 150 m del local**, o el dueño del comercio | Confirmar sin estar ahí no aporta. El comercio puede además corregir. |
| Corregir | El reporte se rechaza (motivo con el precio del comercio) y el precio queda con fuente "comercio" | Cumple "lo confirme o lo corrija". |
| Premiar al que confirma | No da puntos | Fuera del backlog; se puede agregar. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint3_hu15_hu16.sql` | Columnas nuevas de `reporte_precio`; tablas `movimiento_puntos` y `confirmacion_reporte` con RLS; `nivel_para_puntos()`, `puntos_para_reporte()`, `revisar_reporte()`; triggers de revisión y de resultado; `confirmar_reporte_colaborador()`, `confirmar_reporte_comercio()`, `corregir_reporte_comercio()`; `mis_reportes()` (con motivo), `reportes_por_confirmar()`, `reportes_de_mi_comercio()`, `resumen_puntos()` y `mis_movimientos_puntos()`. Idempotente. |
| `docs/sql/pruebas_hu15_hu16_politicas.sql` | ~45 pruebas de la revisión, los puntos, la reputación, el nivel y los permisos. Termina en `ROLLBACK`. |
| `lib/features/puntos/` | Feature nueva (dominio, datos y presentación): `NivelColaborador`, `PuntosReglas`, `MovimientoPuntos`, `ResumenPuntos`, contrato `PuntosRepository`, 2 casos de uso, `SupabasePuntosDataSource`, `PuntosRepositoryImpl`, `ResumenPuntosBloc`, `MisPuntosPage` y `MovimientoPuntosItem`. |
| `lib/features/reportes/domain/validacion_reglas.dart` | `ValidacionReglas` y `RevisionReporte`: las reglas de revisión como funciones puras. |
| `lib/features/reportes/domain/entities/reporte_por_confirmar.dart` | Entidad del reporte que espera confirmación. |
| `lib/features/reportes/domain/repository/validacion_repository.dart` | Contrato de confirmar y corregir. |
| `lib/features/reportes/domain/usecases/validacion_usecases.dart` | 5 casos de uso: `GetReportesPorConfirmar`, `ConfirmarReporteColaborador`, `GetReportesDeMiComercio`, `ConfirmarReporteComercio` y `CorregirReporteComercio`. |
| `lib/features/reportes/data/source/supabase_validacion_data_source.dart`, `.../repository/validacion_repository_impl.dart` | Datos de las confirmaciones. |
| `lib/features/reportes/presentation/bloc/accion_reporte_bloc.dart` | Bloc de confirmar y corregir. |
| `lib/features/reportes/presentation/pages/reportes_por_confirmar_page.dart` | Pantalla de reportes por confirmar (colaborador y comercio). |
| `test/validacion/`, `test/puntos/`, `test/support/fakes_validacion.dart` | 86 pruebas nuevas. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/reportes/domain/entities/mi_reporte.dart`, `.../data/source/supabase_reportes_data_source.dart` | `MiReporte` trae `motivo` y `requiereConfirmacion`. |
| `lib/features/reportes/presentation/widgets/reporte_historial_item.dart`, `lib/features/colaborador/presentation/widgets/colaborador_widgets.dart` | El historial muestra el motivo bajo cada reporte (`ReporteItem.detalle`). |
| `lib/features/colaborador/presentation/pages/colaborador_home_screen.dart` | La tarjeta de puntos usa los datos reales (antes mostraba "2.450 · Nivel Plata" de ejemplo) y abre `MisPuntosPage`. |
| `lib/features/colaborador/presentation/pages/colaborador_perfil_screen.dart` | El nivel se muestra con su nombre; accesos a "Mis puntos", "Historial de reportes" y "Reportes por confirmar". |
| `lib/features/cliente/presentation/pages/cliente_perfil_screen.dart` | El nivel del modo Colaborador se muestra con su nombre. |
| `lib/features/comercio/presentation/pages/comercio_perfil_screen.dart` | Acceso a "Reportes de la comunidad". |
| `lib/features/home/presentation/pages/role_shell.dart` | Abre las pantallas nuevas y relee el perfil al volver (los puntos pudieron cambiar). |
| `lib/core/constants/supabase_tables.dart`, `lib/core/routes/app_routes.dart`, `lib/app_router.dart`, `lib/core/di/injector.dart` | Funciones, columnas, 3 rutas, y registros (125 en total). |
| `docs/sql/pruebas_hu14_politicas.sql` | A3 y A3b ya no esperan `pendiente`: desde la HU-15 el reporte se revisa al recibirlo. |
| `test/di/injector_test.dart`, `test/support/pump_helpers.dart`, `test/navigation/hu06_07_08_flows_test.dart` | Registros y rutas nuevas; el nivel ya se ve como "Frecuente" y no como "2". |

## 5. Páginas nuevas

`MisPuntosPage` (puntos, nivel, progreso, reputación e historial paginado) y `ReportesPorConfirmarPage` (la misma pantalla sirve al colaborador y, con `esComercio`, al dueño del comercio).

## 6. Arquitectura

Cada capa depende solo de la de adentro: la presentación pide casos de uso, los casos de uso hablan con contratos del dominio, y solo `Supabase*DataSource` conoce Supabase. Comprobado: ninguna carpeta `domain` importa Flutter, Supabase ni la capa de datos; el router y el inyector son los únicos que usan `sl<>`. Las reglas de negocio (`ValidacionReglas`, `PuntosReglas`, `NivelColaborador`) son Dart puro y están probadas.

La revisión, los puntos y el cambio de precio los hace **la base de datos** (triggers), no la app: así no dependen de que el cliente se porte bien, y todo ocurre en una transacción. La app repite las reglas en Dart para documentarlas, probarlas y calcular lo que muestran las pantallas (por ejemplo, el "+63 %" de un reporte dudoso).

## 7. Cómo probarlo

1. Ejecutar `docs/sql/sprint3_hu15_hu16.sql` en Supabase → SQL Editor.
2. Ejecutar `docs/sql/pruebas_hu15_hu16_politicas.sql`: debe devolver una tabla con todas las filas en `OK`. También conviene volver a correr `pruebas_hu14_politicas.sql` (se ajustó A3).
3. En la app, con un colaborador cerca de un comercio aprobado con ubicación:
   - Reportar el precio de un producto **sin precio**: queda **Verificado** al instante, gana 20 puntos y el producto muestra el precio con fuente Comunidad.
   - Reportar uno con un precio muy distinto (más de 30 %): queda **Pendiente** con el motivo "Espera la confirmación…".
   - Con otro colaborador, en el local: Perfil → **Reportes por confirmar** → Confirmar precio. El primero recibe los puntos.
   - Con el comercio: Perfil → **Reportes de la comunidad** → Confirmar o Corregir.
   - Perfil → **Mis puntos** (o tocar la tarjeta de puntos del Home): saldo, nivel, reputación e historial.

## 8. Pendientes y riesgos

- **No se ejecutó el SQL contra Supabase** (esta sesión no tiene acceso a la base). Las pruebas de Flutter usan repositorios simulados; las pruebas SQL son las que validan el servidor. La revisión comprueba que la foto exista en `storage.objects`, y la prueba SQL inserta filas ahí: si el esquema de Storage de tu proyecto difiere, ese insert puede fallar.
- `mis_reportes()` se borra y se recrea (cambia de columnas); mientras no se ejecute el SQL, la app nueva fallará al leerla.
- **Cambia el comportamiento de la HU-14:** un reporte ya no queda siempre `pendiente`; se revisa al recibirlo.
- **Los puntos del perfil** (`perfil_colaborador.puntos_saldo`) se leen al iniciar sesión; la app relee el perfil al volver de reportar o de ver los puntos.
- En el Home del colaborador, el progreso de la tarjeta se calcula con el saldo de puntos; hoy coincide con los acumulados, pero cuando exista el canje (HU-26) deberá leer los acumulados.
- La pantalla "por confirmar" no muestra la foto de la etiqueta (el bucket `reportes` es privado y falta una política de lectura para el confirmador).
- Una confirmación no da puntos a quien confirma, y no hay sanción por confirmar mal (la moderación es la HU-27).
- No hay notificación push: el aviso de validado o rechazado se guarda en `notificacion` y se ve al volver a entrar a la app (igual que la HU-24).
