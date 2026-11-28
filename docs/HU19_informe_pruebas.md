# Sprint 3 · HU-19 · Informe de pruebas y criterios de calidad

Rama `feat/hu19-ubicacion-mapa`. Rutas relativas a la raíz del proyecto.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter pub add flutter_map latlong2 geocoding` | `flutter_map 8.3.2`, `latlong2 0.10.1`, `geocoding 5.0.1` |
| `flutter analyze` | Sin problemas |
| `flutter test --concurrency=1` | 933 aprobadas, 0 fallidas (901 de `develop` + 32 nuevas) |

| `sprint3_hu19.sql` + `pruebas_hu19_politicas.sql` en Supabase (28 nov) | Las 16 pruebas en `OK`. La primera ejecución falló en B1 (error 42804: `comercio.latitud` es `numeric(9,6)` en nuestra base); se corrigió con una conversión en `comercios_en_radio()` y la segunda ejecución dio todo `OK` |

**No ejecutado:** `flutter build apk` y la prueba en un dispositivo Android (GPS, permiso, geocodificación y teselas reales).

## 2. Criterios de aceptación y su verificación

| Criterio | Prueba automática | Prueba SQL |
|---|---|---|
| Pide permiso de ubicación | Bloc: la primera vez usa el GPS (`ObtenerUbicacionUseCase`, que pide el permiso) | — |
| Sin permiso, escribe la dirección | Bloc y pantalla, escenario 2 | — |
| Radio configurable | Bloc y pantalla, escenario 3; `RadioReglas` | A3, B4 |
| El mapa muestra los aprobados dentro del radio | Casos de uso y pantalla, escenarios 1 y 3 | B1, B2, B3 |
| Ubicación y radio guardados y recuperados | Bloc: "con una ubicación guardada la recupera y no pide el GPS" | A1, A2, C1–C3 |
| Usado por la HU-18 | Pendiente de la HU-18 | — |

## 3. Pruebas implementadas (32 nuevas)

| Archivo | Pruebas | Qué comprueba |
|---|---|---|
| `test/ubicacion/ubicacion_cliente_test.dart` | 13 | Límites del radio, formatos de distancia y radio, `PreferenciaUbicacion`; casos de uso: guardar y recuperar, radio fuera de rango, dirección larga, cuenta sin perfil cliente, filtro por radio y orden, dirección limpia, dirección corta o no encontrada |
| `test/ubicacion/mapa_comercios_bloc_test.dart` | 9 | Escenarios 1, 2 y 3; ubicación guardada sin GPS; dirección no encontrada; fallo al guardar (conserva lo anterior); fallo de carga y reintento; "Usar mi ubicación" conserva el radio; un segundo cambio mientras guarda se ignora |
| `test/ubicacion/mapa_comercios_page_test.dart` | 7 | Los tres escenarios en pantalla, radio sin comercios, "Escribir dirección", error con reintento y 320 px sin desbordes |
| `test/cliente/cliente_integracion_test.dart` | 2 | El botón de ubicación del Home y "Mi ubicación" del Perfil abren el mapa |
| `test/di/injector_test.dart` | 1 | Repositorio y geocodificador reales con el tipo del contrato, casos de uso únicos y Bloc de fábrica |

Los dobles están en `test/support/fakes_ubicacion.dart`: el repositorio de mentira filtra con la misma fórmula de distancia que la base (`Ubicacion.distanciaA`), así que el filtro por radio se prueba con distancias reales (0,6 km, 3,3 km y 7,8 km). En las pruebas de pantalla el mapa no descarga teselas (`MapaEstablecimientos.cargarTeselas = false`): no hay red.

### Pruebas SQL (`docs/sql/pruebas_hu19_politicas.sql`, 16)

A1–A6: guardar, reemplazar, radio, coordenadas, dirección larga y que la tabla no se escribe directo. B1–B4: radio de 2 km y de 10 km, orden por distancia, comercio pendiente excluido y radio inválido. C1–C3: un cliente no ve ni cambia la ubicación de otro. D1–D2: una cuenta sin rol cliente no guarda ni consulta. E1: sin sesión no se guarda ni se consulta.

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `ubicacion/` con `domain`, `data` y `presentation`; las reglas del radio y la dirección en el dominio | `grep` del README sobre `lib/features/*/domain` sin resultados (también para `flutter_map`, `latlong2` y `geocoding`) |
| Service Locator (GetIt) | 8 registros nuevos en `injector.dart`; el router pide el Bloc con `sl<MapaComerciosBloc>()` | `test/di/injector_test.dart`; los 5 comandos del README sin hallazgos |
| BLoC | `MapaComerciosBloc` con estados de carga, listo, sin ubicación y fallo; `ocupado` contra el doble toque; avisos con `AvisoUi` | `mapa_comercios_bloc_test.dart` |
| Reutilización | `MapaEstablecimientos` para HU-18 y HU-22; `EstablecimientoCercano`, el mapeador y `formatoDistancia` compartidos con la HU-14; `ObtenerUbicacionUseCase`, `GetClienteActivoUseCase`, `PantallaRol`, `TarjetaSuave`, `BotonPrimario` | Revisión del código |
| Convenciones | Tabla, funciones y columnas en `SupabaseTables`, `SupabaseFunctions` y `SupabaseColumns` | `grep` de `.from('` y `.rpc('` sin resultados |
| Diseño | Colores de `TemaRol`; solo `Colors.white` (neutro) | `grep` de `Color(0x` sin resultados; prueba de 320 px |
| Manejo de errores | Mensajes en español del GPS, el geocodificador y la base; reintento | Pruebas de Bloc y pantalla |
| Seguridad | RLS de lectura propia, escritura solo por función, solo clientes, sin acceso anónimo | `pruebas_hu19_politicas.sql`: 16 `OK` en Supabase |
| Pruebas y análisis | 32 pruebas nuevas; `flutter analyze` sin problemas | Sección 1 |

## 5. Pendientes y limitaciones

Ver la sección 7 de [HU19_informe_implementacion.md](HU19_informe_implementacion.md).
