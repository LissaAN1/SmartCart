# Sprint 2 · HU-14 · Informe de pruebas y criterios de calidad

Resultados reales de las verificaciones hechas el 15 de noviembre de 2026 sobre la rama `feat/hu14-reporte-precio`.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter pub add geolocator image_picker mobile_scanner permission_handler` | Correcto |
| `flutter analyze` (final) | **No issues found** |
| `flutter test --concurrency=1` (línea base, al empezar la HU-14) | 278 pruebas, todas pasan |
| `flutter test --concurrency=1` (final) | **428 pruebas, todas pasan** (150 nuevas sobre las 278 de antes de la HU-14) |
| `flutter build apk --debug` (primer intento, con `permission_handler` 13) | **Falló**: `permission_handler_android` 14 exige Android SDK 37 y el proyecto (AGP 9.1) compila con 36 |
| `flutter build apk --debug` (con `permission_handler` 12) | **Correcto**: `build/app/outputs/flutter-apk/app-debug.apk` (197 s). Comprueba que los cuatro plugins y los permisos compilan en Android; no prueba que funcionen en un dispositivo |
| `docs/sql/sprint2_hu14.sql` y `docs/sql/pruebas_hu14_politicas.sql` en el SQL Editor de nuestro proyecto de Supabase (15 de noviembre de 2026) | Ejecutados por el equipo. Primera vez: **24 `OK` y 1 `ALERTA` (E3)**. Tras la corrección y la prueba nueva E5, segunda ejecución: 26 `OK`. Al agregar el historial (`mis_reportes()`, pruebas A3b y C1b), tercera ejecución: **28 `OK`, sin alertas**; ver la sección 2 |

Con la concurrencia por defecto, `flutter test` se quedó sin memoria en este equipo; con `--concurrency=1` corre completo. No cambia lo que se prueba.

**Diferencia entre ejecutado, aprobado y pendiente**

- Ejecutadas y aprobadas: las 428 pruebas de Dart/Flutter y `flutter analyze`.
- Falló y se corrigió: la compilación del APK con la primera versión de `permission_handler` (se fijó la versión 12, que compila contra una API menor).
- Durante el desarrollo, 3 pruebas de pantalla fallaron por textos que se desbordaban con la fuente de prueba y 3 por búsquedas en el árbol de widgets; se corrigieron en las etiquetas y en las pruebas.
- Ejecutadas por el equipo contra Supabase: el SQL de la HU-14 y su script de pruebas (sección 2). Yo no tengo acceso a Supabase; los resultados son los que el equipo copió del SQL Editor.
- Probada en un dispositivo Android: GPS, permiso y cámara, foto, escáner y envío reales funcionaron (informado por el equipo).

## 2. Criterios de aceptación y su verificación

| Criterio / escenario | Verificación automática | Archivo |
|---|---|---|
| Verifica por geolocalización que está en el establecimiento | Distancia haversine (valores conocidos), radio de 150 m (149 m pasa, 152 m no), caso de uso y Bloc | `reporte_dominio_test`, `reporte_blocs_test` |
| **Escenario 1:** reporte exitoso queda pendiente | Caso de uso (guarda precio, promoción, agotado, producto, foto y la ubicación *actual*), Bloc y pantalla: "Reporte enviado" y vuelve al inicio | `reporte_dominio_test`, `reporte_blocs_test`, `reporte_flow_test` |
| **Escenario 2:** fuera del establecimiento se rechaza y se explica | Caso de uso (mensaje con la distancia), Bloc (conserva la foto) y pantalla; no se guarda nada | los tres archivos anteriores |
| **Escenario 3:** sin foto muestra que es obligatoria | Caso de uso (y que **no se pide el GPS**), Bloc y pantalla | ídem |
| Identificar el producto por código de barras o por nombre | Caso de uso (nombre, marca, código exacto, sin texto, espacios) y pantalla (búsqueda, sin coincidencias, escaneo simulado, código inexistente, quitar la búsqueda) | `reporte_dominio_test`, `reporte_flow_test` |
| Precio y foto obligatorios; promoción y disponibilidad opcionales | Validadores, caso de uso y pantalla (promoción mayor al precio, precio vacío) | ídem |
| Marcar un producto como agotado | Pantalla y caso de uso (el reporte guarda `agotado`) | `reporte_flow_test`, `reporte_dominio_test` |
| *(Ajuste del equipo)* Escanear directo tras elegir el establecimiento | Pantalla: la cámara se abre sola; un código conocido abre el formulario; uno desconocido avisa; cancelar deja buscar por nombre; no se reabre al volver; sin cámara no se abre | `reporte_flow_test` |
| *(Ajuste del equipo)* Historial real de mis reportes, también los pendientes | Caso de uso, página, sección del Home, y el Home dentro del `RolShell` (el reporte nuevo aparece como Pendiente al volver) | `historial_test` |
| Sugerir un establecimiento nuevo | Validadores, caso de uso (guarda con la ubicación del colaborador), Bloc y pantalla | los tres archivos anteriores |
| Solo un colaborador reporta | Cada caso de uso falla sin sesión o sin el modo Colaborador; la pantalla muestra el aviso | `reporte_dominio_test`, `reporte_flow_test` |
| Permiso de cámara y de ubicación | El Bloc y la pantalla muestran el motivo cuando se niegan, y se puede reintentar | `reporte_blocs_test`, `reporte_flow_test` |
| Las listas se cargan por páginas | Caso de uso de establecimientos con páginas y `hasMore` | `reporte_dominio_test` |
| Ubicación del comercio (cambio a la HU-07) | Caso de uso, Bloc (registro y comercio existente, errores, doble toque), formulario de registro, aviso del Home y entidad | `comercio_ubicacion_test` |
| Accesos desde el Home del colaborador | Pestaña "Reportar Precio", "Reportar precio" y "Escanear" abren el flujo | `colaborador_entradas_test` |

### Políticas y funciones en la base real

El equipo ejecutó `docs/sql/pruebas_hu14_politicas.sql` (simula sesiones reales y termina en `ROLLBACK`), dos veces:

1. **Primera ejecución:** 24 líneas `OK` y 1 `ALERTA`. En **E3**, el dueño de un comercio aprobado (que no es administrador) pudo cambiar el estado de su comercio con un `update` directo. La causa, según `pg_policies`, era una política heredada que no está en los scripts del repositorio, `comercio_update_own` (detalle en el informe de implementación, sección 9).
2. **Corrección:** `sprint2_hu14.sql` ahora la elimina (sección 8) y se agregó la prueba **E5** (un dueño con comercio pendiente no puede aprobarse solo).
3. **Segunda ejecución, con el script corregido: las 26 líneas dicen `OK`** (A1 a A4, B1 a B6, C1 a C6, D1, E1 a E5 y F1 a F4), sin alertas.
4. **Tercera ejecución, con el historial (`mis_reportes()`): las 28 líneas dicen `OK`**. Se sumaron **A3b** (el reporte pendiente aparece en el historial del colaborador, con los nombres del producto y del establecimiento) y **C1b** (el historial de otro colaborador no muestra reportes ajenos). El único `AVISO` es el de los datos de prueba creados dentro de la transacción.

El script cubre:

| Grupo | Qué demuestra |
|---|---|
| A1 a A4 | Un colaborador ve el comercio cercano (≈ 33 m), lee sus productos, envía un reporte desde dentro (queda `pendiente`) y sugiere un establecimiento |
| B1 a B6 | Rechaza: lejos del establecimiento (escenario 2), sin foto (escenario 3), foto de otra carpeta, precio de cero, promoción no menor al precio e inserción directa saltándose la función |
| C1 a C6 | Otro colaborador no ve reportes ni sugerencias ajenas; quien no tiene el modo Colaborador no ve establecimientos ni productos y no envía reportes ni sugerencias |
| D1 | No se puede sugerir a nombre de otro usuario |
| E1 a E5 | El dueño guarda la ubicación de su comercio sin cambiar su estado, rechaza coordenadas imposibles, no cambia su estado con un `update` directo (E3), quien no tiene comercio no puede fijar ubicación y el dueño de un comercio pendiente no puede aprobarse solo (E5) |
| F1 a F4 | Storage: sube y ve su foto en su carpeta; no sube a la de otro ni ve fotos ajenas |

## 3. Pruebas implementadas

| Archivo | Pruebas | Qué cubre |
|---|---|---|
| `test/reportes/reporte_dominio_test.dart` | 41 | `Ubicacion.distanciaA`, `ReporteReglas`, `ReporteValidators`, `GetColaboradorActivo`, `EnviarReportePrecio` (los tres escenarios, el límite de 149 y 152 m, precio, promoción, GPS y base que fallan), `GetEstablecimientosCercanos`, `BuscarProductos`, `SugerirEstablecimiento` y `TomarFoto` |
| `test/reportes/reporte_blocs_test.dart` | 18 | `UbicacionBloc`, `ReporteFormBloc` (foto, cancelar, permiso, quitar, envío, sin foto, lejos, doble toque, error inesperado) y `SugerenciaBloc` |
| `test/reportes/reporte_flow_test.dart` | 32 | El flujo en pantalla de punta a punta con las mismas rutas del `AppRouter` (establecimiento, producto, formulario, sugerencia) y el **escaneo directo**: la cámara se abre sola, un código de un producto pasa directo al formulario, un código que no está avisa, cancelar el escáner deja buscar por nombre, volver atrás no reabre el formulario y sin cámara (escritorio) no se abre |
| `test/reportes/historial_test.dart` | 30 | El historial real: `EstadoReporte`, formato de pesos y fechas, `GetMisReportes` (pendientes incluidos, orden, páginas, exige modo Colaborador), la fila con su estado, `MisReportesPage` (reales, vacío, error, actualizar, paginado), la sección del Home y el Home dentro de `RolShell` (3 más recientes, recarga al volver de reportar, "Historial") |
| `test/reportes/comercio_ubicacion_test.dart` | 19 | La ubicación del comercio: caso de uso, `ComercioBloc`, formulario de registro y aviso del Home |
| `test/reportes/colaborador_entradas_test.dart` | 3 | Accesos desde el Home del colaborador |
| `test/di/injector_test.dart` (agregadas) | 7 | Registros del reporte; la cadena completa se arma con el localizador; el registro **con nombre** de `PaginatedBloc<Producto>` convive con el del catálogo; `param1` y `param2` |

**Dos pruebas existentes se modificaron** (sin cambiar lo que comprueban). El formulario de registro del comercio y el Home ahora son más largos, y el botón "Registrar" y "Ir al Catálogo" quedan fuera de lo que `ListView` construye de antemano, así que la prueba debe desplazarse hasta ellos antes de tocarlos:

- `test/navigation/hu06_07_08_flows_test.dart`, "dejar campos vacíos muestra los errores y no guarda".
- `test/catalog/comercio_entradas_test.dart` (HU-10), "Ir al Catálogo abre el catálogo".

Los dobles nuevos (`FakeServicioUbicacion`, `FakeSelectorFoto`, `FakeReportesRepository`) se agregaron a `test/support/fakes.dart`, y `FakeComercioRepository` implementa el método nuevo del contrato.

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `reportes/` y `ubicacion/` con `domain`, `data` y `presentation`. El dominio no importa Flutter, Supabase, GetIt ni ningún plugin. | `grep` sobre `lib/features/*/domain` sin resultados (README, auditoría del Service Locator) |
| Service Locator (GetIt) | Todo registrado en `injector.dart`; `registerFactoryParam` con `param1` y `param2`; registro con nombre donde el tipo choca. No hay constructores concretos fuera del inyector. | `test/di/injector_test.dart` y los `grep` del README |
| BLoC | `UbicacionBloc`, `ReporteFormBloc`, `SugerenciaBloc` y `PaginatedBloc` con estados de carga, éxito y error y guard contra doble envío. | `reporte_blocs_test` |
| Reutilización | `PaginatedBloc`/`PaginatedListView`, `PantallaRol`, `AuthTextField`, `ErrorMessage`, `BotonPrimario`, `TarjetaSuave`, `ProductoCard` (con un ícono configurable), `productoFromRow` y `mapPostgrestException`. | Revisión del código |
| Manejo de errores | Errores de Supabase y de los plugins traducidos a mensajes en español (`AuthFailure`); los de las funciones SQL llegan con su mensaje. | `reporte_blocs_test`, `reporte_flow_test` |
| Seguridad | La verificación de distancia está en el servidor; nadie inserta reportes directo; fotos en carpeta propia. | `pruebas_hu14_politicas.sql`: 28 `OK`; E3 reveló una política heredada que se corrigió y se reconfirmó |
| Paginado | Las dos listas nuevas usan la base común. | `reporte_dominio_test`, `reporte_flow_test` |
| Pruebas | 111 pruebas nuevas; la suite completa pasa. | Sección 1 |
| Análisis estático | `flutter analyze` sin problemas. | Sección 1 |

## 5. Pendientes y limitaciones

1. ~~Ejecutar el SQL y las pruebas de las políticas en Supabase~~: hecho, 28 pruebas `OK` (sección 2). Si cambia el SQL, hay que volver a correrlas.
2. **Hecho:** prueba manual en Android (ubicar el comercio, reporte exitoso, uno lejos y uno sin foto). Pasos en el README, sección "Probar el reporte de precios (HU-14)".
3. El escáner de códigos no se puede probar en Windows.
4. Las dos advertencias de `tap()` de `test/navigation/hu06_07_08_flows_test.dart` (líneas 263 y 270) existían antes y no vienen de este cambio.
