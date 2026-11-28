# Sprint 3 · HU-18 · Informe de pruebas y criterios de calidad

Rama `feat/hu18-alternativas-carrito`. Rutas relativas a la raíz del proyecto.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| `flutter test --concurrency=1` | 981 aprobadas, 0 fallidas (933 de `develop` con la HU-19 + 48 nuevas) |

| `sprint3_hu18.sql` + `pruebas_hu18_ofertas.sql` en Supabase (28 nov) | Las 10 pruebas en `OK` a la primera |

**No ejecutado:** la prueba en Android con datos reales.

## 2. Escenarios del backlog y su verificación

| Escenario | Prueba automática | Prueba SQL |
|---|---|---|
| 1. Ahorro | `comparador_carrito_test` (elección por producto, total, ahorro, distancia), Bloc y pantalla | A1, A2 |
| 2. Comodidad | `comparador_carrito_test` (un comercio, empate por costo, par más barato, método rápido), pantalla | — |
| 3. Calidad/precio | `comparador_carrito_test` (calificación gana con diferencias pequeñas y pierde con grandes, "Sin calificaciones"), detalle | A3 (la calificación llega aunque falten las columnas de la HU-25) |
| 4. Distancia máxima | Comparador (5 km, comercio sin ubicación), Bloc, pantalla | A3 (coordenadas) |
| 5. Producto sin disponibilidad | Comparador (agotado, sin ofertas, fuera del radio, ninguno disponible), pantalla | A4, A5 |
| 6. Carrito vacío | Caso de uso, Bloc y pantalla | B1 |
| Precios del carrito (primer criterio) | `carrito_precios_test` (precio vigente, promoción, subtotal, total, agotado, cantidad, producto nuevo) | A2 |
| Permisos | — | A6, A7, C1, D1 |

## 3. Pruebas implementadas (48 nuevas)

| Archivo | Pruebas | Qué comprueba |
|---|---|---|
| `test/comparacion/comparador_carrito_test.dart` | 22 | Fórmula de Calidad/precio, los seis escenarios, empates, método rápido de Comodidad, agotadas, ofertas repetidas, `ValorCarrito` y `PrecioLinea` |
| `test/comparacion/comparacion_bloc_test.dart` | 10 | Carga, orden por criterio sin volver a la red, distancia máxima, sin ubicación, ubicación recargada, ubicación ilegible, carrito vacío, error y reintento; `PreciosCarritoBloc` |
| `test/comparacion/comparacion_pantallas_test.dart` | 10 | Tarjetas con total, ahorro, comercios y distancia; cambio de criterio y de distancia; aviso de faltantes; carrito vacío; "Configurar ubicación"; "Ver detalle"; detalle con fuente, fecha, confianza y calificación; 320 px |
| `test/comparacion/carrito_precios_test.dart` | 5 | Precio, subtotal y total del carrito; cambio de cantidad; producto nuevo; "Comparar carrito"; 320 px |
| `test/di/injector_test.dart` | 1 | Repositorio real, casos de uso únicos y Blocs de fábrica |

Además cambió una prueba existente, con el requisito: en `cliente_integracion_test.dart`, "Comparar" del Home ahora debe abrir la comparación del carrito (antes abría la búsqueda porque la HU-18 no existía). Y `carrito_page_test.dart` monta el `PreciosCarritoBloc` que ahora necesita el carrito; sus aserciones no cambiaron y siguen pasando.

### Pruebas SQL (`docs/sql/pruebas_hu18_ofertas.sql`, 10)

A1 mismo producto por código de barras y solo en comercios aprobados; A2 promoción que termina hoy en Colombia y orden por precio; A3 cantidad, coordenadas y calificación; A4 reconocimiento por nombre y marca con oferta agotada marcada; A5 producto sin ofertas; A6 solo las líneas propias; A7 `ofertas_publicadas()` sigue siendo interna; B1 carrito vacío; C1 sin rol cliente; D1 sin sesión.

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `comparacion/` con `domain`, `data` y `presentation`; el algoritmo es Dart puro | `grep` del README sobre `lib/features/*/domain` sin resultados |
| Service Locator (GetIt) | 6 registros nuevos (139 en total); el router pide los Blocs con `sl<...>()` | `test/di/injector_test.dart`; los 5 comandos del README sin hallazgos |
| BLoC | `ComparacionBloc` (carga, lista, vacía, fallo) y `PreciosCarritoBloc`; la pantalla no calcula alternativas | Pruebas de Bloc |
| Reutilización | `clave_producto` y `ofertas_publicadas` (HU-12), `ConfianzaDelPrecio` (HU-13), `GetMiUbicacionUseCase`, `Ubicacion.distanciaA` y `MapaEstablecimientos` (HU-14 y HU-19), `ClienteBlocs` (HU-17), `formatoCop` (HU-11) | Revisión del código |
| Convenciones | Función y columnas en `SupabaseFunctions` y `SupabaseColumns` | `grep` de `.rpc('` sin resultados |
| Diseño | Colores de `TemaRol` y `ColoresEstado`; sin desbordes en 320 px | Pruebas de 320 px |
| Manejo de errores | Mensajes en español; reintento; la comparación sigue sin ubicación | Pruebas de Bloc y pantalla |
| Seguridad e integridad | Solo el carrito propio, solo clientes, sin acceso anónimo; solo comercios aprobados; fecha de Colombia para la promoción | `pruebas_hu18_ofertas.sql` |
| Pruebas y análisis | 48 pruebas nuevas; `flutter analyze` sin problemas | Sección 1 |

## 5. Pendientes y limitaciones

Ver la sección 7 de [HU18_informe_implementacion.md](HU18_informe_implementacion.md).
