# Sprint 3 · HU-28 · Informe de pruebas y criterios de calidad

Rama `feat/hu28-estadisticas-admin`. Rutas relativas a la raíz del proyecto.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| `flutter test --concurrency=1` | 1093 aprobadas, 0 fallidas (1071 de `develop` + 22 nuevas) |

| `sprint3_hu28.sql` + `pruebas_hu28_estadisticas.sql` en Supabase (28 nov) | Las 11 pruebas en `OK` a la primera |

**No ejecutado:** la prueba en Android.

## 2. Escenarios del backlog y su verificación

| Escenario | Prueba automática | Prueba SQL |
|---|---|---|
| 1. Cifras que salen de la base | Lectura del JSON, caso de uso y panel | A1–A5, C1, C2 |
| 2. Las cifras se actualizan | Bloc y panel (volver de Aprobaciones y de Perfil) | B1 |
| 3. Sin órdenes | Lectura del JSON y panel | D1 |
| 4. Usuario sin permiso | Caso de uso rechaza cada otro perfil sin consultar | E1, E2 |
| Carga y error con reintento | Bloc y panel | — |

## 3. Pruebas implementadas (22 nuevas)

| Archivo | Pruebas | Qué comprueba |
|---|---|---|
| `test/estadisticas/estadisticas_test.dart` | 10 | Conversión del JSON (con claves ausentes y sin órdenes), permiso del caso de uso, estados del Bloc, recarga conservando cifras, respuesta atrasada ignorada, error y reintento |
| `test/estadisticas/panel_admin_test.dart` | 11 | Cifras en pantalla; ausencia de los datos de ejemplo; órdenes y sin órdenes; recarga al volver de Aprobaciones y de Perfil; insignias y aviso; carga; error; 320 px |
| `test/di/injector_test.dart` | 1 | Repositorio real, caso de uso único y Bloc de fábrica |

Las pruebas existentes del panel (`test/aprobaciones/`, accesos a Aprobaciones) siguen pasando sin cambios.

### Pruebas SQL (`docs/sql/pruebas_hu28_estadisticas.sql`, 11)

A1 usuarios por rol; A2 comercios por estado; A3 repartidores; A4 solicitudes; A5 reportes de precio; B1 aprobar un comercio actualiza las cifras; C1 pedidos de hoy; C2 órdenes por estado; D1 sin órdenes; E1 sin rol administrador; E2 sin sesión.

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `estadisticas/` con `domain`, `data` y `presentation` | `grep` del README sobre `domain/` sin resultados |
| Service Locator (GetIt) | 4 registros en `injector.dart`; el router entrega la fábrica del Bloc | `test/di`; comprobaciones del README sin hallazgos |
| BLoC | Estados de carga, lista y fallo; la pantalla no consulta ni calcula | Pruebas de Bloc |
| Reutilización | `TarjetaMetrica`, `TarjetaSuave`, `TituloSeccion`, `ErrorMessage`, `formatoMiles`, `UserRole`, `ApprovalStatus`, `EstadoOrden`, `es_administrador()` | Revisión del código |
| Convenciones | Función y claves en `core/constants` | `grep` de `.rpc('` sin resultados |
| Diseño | Colores de `TemaRol`; sin desbordes en 320 px | `grep` de `Color(0x` sin resultados; prueba de 320 px |
| Navegación | El panel se recarga al volver | Pruebas del panel |
| Manejo de errores | Mensajes en español y reintento | Pruebas de Bloc y panel |
| Seguridad | Solo el administrador; solo conteos | `pruebas_hu28_estadisticas.sql`: 11 `OK` en Supabase |
| Paginado | No aplica: son conteos, no listas | — |
| Pruebas y análisis | 22 pruebas nuevas; `flutter analyze` sin problemas | Sección 1 |

## 5. Pendientes y limitaciones

Ver la sección 7 de [HU28_informe_implementacion.md](HU28_informe_implementacion.md).
