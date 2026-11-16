# Sprint 2 · HU-17 · Informe de pruebas y criterios de calidad

Resultados reales de las verificaciones hechas el 15 de noviembre de 2026 sobre la rama `feat/hu17-carrito-compras-favoritos`.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter test --concurrency=1` (línea base, al empezar la HU-17) | 428 pruebas, todas pasan |
| `flutter analyze` (final) | **No issues found** |
| `flutter test --concurrency=1` (final) | **587 pruebas, todas pasan** (159 nuevas) |
| `docs/sql/sprint2_hu17.sql` y `docs/sql/pruebas_hu17_politicas.sql` en Supabase | **Ejecutados** en el SQL Editor de Supabase: `pruebas_hu17_politicas.sql` dio **34 líneas `OK`** (más el `AVISO` esperado de los datos de prueba); ver sección 2 |
| `flutter build apk --debug` | **No se volvió a ejecutar en esta historia.** No agrega plugins ni permisos nativos; el último APK que compiló es el de la HU-14 |

Con la concurrencia por defecto, `flutter test` se queda sin memoria en este equipo; con `--concurrency=1` corre completo.

**Diferencia entre ejecutado, aprobado y pendiente**

- Ejecutadas y aprobadas: las 587 pruebas de Dart/Flutter y `flutter analyze`.
- Ejecutadas y aprobadas en Supabase: `sprint2_hu17.sql` y sus 34 pruebas de políticas y funciones.
- **Pendiente, no ejecutada:** la app en un dispositivo Android.

## 2. Criterios de aceptación y su verificación

| Criterio / escenario | Verificación automática | Archivo |
|---|---|---|
| **Escenario 1:** agregar un producto lo deja con cantidad 1 | Caso de uso (queda en 1; otra vez suma 1 sin duplicar la línea), Bloc (con aviso) y pantalla de exploración (carrito de la barra con el número) | `carrito_dominio_test`, `carrito_bloc_test`, `explorar_page_test` |
| **Escenario 2:** cambiar la cantidad actualiza el carrito | Caso de uso (1 y 99 válidos; 0 y 100 rechazados), Bloc (al instante, dos toques seguidos, fuera de rango, falla de guardado que vuelve a la base) y pantalla (aumentar, disminuir, extremos deshabilitados, error) | `carrito_dominio_test`, `carrito_bloc_test`, `carrito_page_test` |
| Quitar productos | Caso de uso, Bloc (al instante y con falla), pantalla (quitar uno, quitar el último → carrito vacío, falla) | los tres anteriores |
| El carrito se guarda y se recupera al volver a abrir la app | Un Bloc nuevo sobre el mismo repositorio, como al reabrir la app, lee lo guardado con sus cantidades; la pantalla y el `RolShell` lo muestran apenas abren | `carrito_bloc_test`, `carrito_page_test`, `cliente_integracion_test` |
| **Escenario 3:** el ícono de favorito guarda el producto o el comercio | Caso de uso (producto y comercio, quitar, sin duplicar), Bloc (al instante, falla que revierte, doble toque ignorado) y pantallas (exploración y favoritos) | `favoritos_test`, `explorar_page_test`, `favoritos_page_test` |
| Se pueden guardar productos **y comercios** | Pestañas Productos y Comercios en la exploración y en favoritos | `explorar_page_test`, `favoritos_page_test` |
| El carrito muestra la cantidad de productos | `ResumenCarrito` (productos y unidades), resumen de la pantalla (singular y plural), número de la pestaña (cambia al agregar y quitar; agregar el mismo producto no lo cambia) y de la barra de la exploración | `carrito_dominio_test`, `carrito_page_test`, `cliente_integracion_test`, `explorar_page_test` |
| Agregar desde los resultados | Lista de exploración con buscador, y desde los favoritos | `explorar_page_test`, `favoritos_page_test` |
| Agregar desde el detalle del producto | **No verificable: el detalle es la HU-13.** El botón `AgregarCarritoBoton` es reutilizable | — |
| Solo un cliente | Todos los casos de uso fallan sin sesión o sin perfil de cliente | `carrito_dominio_test`, `favoritos_test`, `explorar_test` |
| Las listas se cargan por páginas | Favoritos y exploración (casos de uso y Bloc) | `favoritos_test`, `explorar_test` |
| Integración con el Home y el Perfil del cliente | Pestaña "Carrito", lupa, buscador, "Comenzar ahora" y "Mis favoritos"; "Comparar" sigue avisando "próximamente"; sin `crearCliente` todo se comporta como antes | `cliente_integracion_test` |

### Políticas y funciones en la base real

**Ejecutado y aprobado (34 `OK`).** `docs/sql/pruebas_hu17_politicas.sql` tiene 34 pruebas que simulan sesiones reales y terminan en `ROLLBACK`. Antes de pasar, la base real nos obligó a corregir tres cosas del SQL y del script (ninguna cambió el comportamiento de la app):

- Las columnas de texto de las funciones se devuelven con `::text`, porque en la base real `comercio.nombre` y otras son `varchar(255)` y plpgsql exige el tipo exacto.
- Un `%` literal en un mensaje del script se escribe `%%`.
- Las pruebas de exploración piden una página grande (`'', 100000, 0`): por defecto la función devuelve 21 filas y la base real tiene más productos.

| Grupo | Qué demuestra |
|---|---|
| A1 a A5 | Un cliente explora productos y comercios **solo de comercios aprobados**, el filtro por nombre y el escape de comodines, y lee productos solo de comercios aprobados |
| B1 a B11 | Escenarios 1 y 2: agregar deja cantidad 1, agregar otra vez suma sin duplicar, `mi_carrito` trae los datos, cambiar la cantidad, la cantidad debe ir de 1 a 99, no se cambia el producto de una línea ni se inserta saltándose la función, tope de 99, un producto de un comercio pendiente o inexistente no se agrega, y quitar |
| C1 y C2 | Otro cliente no ve ni modifica carritos ajenos |
| D1 a D4 | Quien no tiene el rol cliente no agrega, no explora, no lee productos ajenos y no marca favoritos |
| E1 a E8 | Escenario 3: guarda un producto y un comercio, no se duplican, no se marcan productos o comercios pendientes ni a nombre de otro usuario, un favorito no se edita, otro cliente no ve ni borra los ajenos, y quitar |
| F1 | Sin sesión no se leen carritos |

## 3. Pruebas implementadas

| Archivo | Pruebas | Qué cubre |
|---|---|---|
| `test/cart/carrito_dominio_test.dart` | 31 | Reglas, resumen del carrito, conversión de las filas SQL, `GetClienteActivo` y los 4 casos de uso del carrito (los escenarios 1 y 2, los topes de 99 y de 100 productos) |
| `test/cart/carrito_bloc_test.dart` | 24 | `CarritoBloc`: cargar y recuperar, agregar, cambiar la cantidad (al instante, doble toque, rango, falla) y quitar |
| `test/cart/carrito_page_test.dart` | 18 | Pantalla del carrito: estados, lo que muestra, escenario 2, quitar y recuperación |
| `test/favoritos/favoritos_test.dart` | 23 | `FavoritosIds`, casos de uso (escenario 3) y `FavoritosBloc` |
| `test/favoritos/favoritos_page_test.dart` | 9 | Pantalla de favoritos: productos y comercios, quitar, agregar al carrito, error |
| `test/explorar/explorar_test.dart` | 15 | Casos de uso de la exploración y las listas paginadas |
| `test/explorar/explorar_page_test.dart` | 20 | Pantalla de exploración: lista, búsqueda, agregar al carrito (escenario 1), favoritos (escenario 3) y comercios |
| `test/cliente/cliente_integracion_test.dart` | 13 | El carrito y los favoritos dentro del `RolShell` del cliente: número de la pestaña, accesos y comportamiento sin `crearCliente` |
| `test/di/injector_test.dart` (agregadas) | 6 | Registros nuevos; la cadena completa se arma con el localizador; los nombres de las listas; `param1` |

No se modificó ninguna prueba existente. Los dobles nuevos (`FakeCarritoRepository`, `FakeFavoritosRepository`, `FakeExplorarRepository`) están en `test/support/fakes_cliente.dart`, aparte de `fakes.dart`, y aplican las mismas reglas que la base (una línea por producto, 99 unidades, 100 productos).

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `cart/`, `favoritos/` y `explorar/` con `domain`, `data` y `presentation`. El dominio no importa Flutter, Supabase ni GetIt. | `grep` sobre `lib/features/*/domain` sin resultados (README, auditoría del Service Locator) |
| Service Locator (GetIt) | Todo registrado en `injector.dart`; listas con nombre donde el tipo choca; `registerFactoryParam` con `param1`. No hay constructores concretos fuera del inyector. | `test/di/injector_test.dart` y los `grep` del README |
| BLoC | `CarritoBloc`, `FavoritosBloc` y `PaginatedBloc` con estados de carga, éxito y error, respuesta inmediata con vuelta atrás si falla, y protección contra el doble toque. | `carrito_bloc_test`, `favoritos_test` |
| Reutilización | `PaginatedBloc`/`PaginatedListView`, `PantallaRol`, `TarjetaSuave`, `BotonPrimario`, `ErrorMessage`, `traducirErroresSupabase`, y los botones `AgregarCarritoBoton` y `FavoritoBoton` pensados para la HU-12 y la HU-13. | Revisión del código |
| Manejo de errores | Errores de Supabase traducidos a mensajes en español; los de las funciones SQL llegan con su mensaje; error inesperado con mensaje genérico. | `carrito_bloc_test`, `favoritos_test`, pruebas de pantallas |
| Seguridad | Cada cliente solo toca lo suyo; no se inserta en el carrito saltándose la función; solo se agrega lo disponible. | Demostrado en Supabase con `pruebas_hu17_politicas.sql` (34 `OK`) |
| Paginado | Favoritos y exploración usan la base común. | `favoritos_test`, `explorar_test` |
| Pruebas | 159 pruebas nuevas; la suite completa pasa. | Sección 1 |
| Análisis estático | `flutter analyze` sin problemas. | Sección 1 |

## 5. Pendientes y limitaciones

1. **Hecho:** `sprint2_hu17.sql` y `pruebas_hu17_politicas.sql` corridos en Supabase; las 34 líneas dieron `OK`. Quien despliegue en otra base debe correr los dos scripts en ese orden, después de `sprint2_hu14.sql`.
2. **Probar en un teléfono o emulador Android**: agregar, cambiar la cantidad, quitar, marcar favoritos, y cerrar y volver a abrir la app para comprobar que todo se recupera. Pasos en el README, sección "Probar el carrito y los favoritos (HU-17)".
3. Dejar evidencia para la sustentación: capturas del carrito con el número en la pestaña, de los favoritos, y de las tablas `carrito_item` y `favorito_*`.
4. "Agregar desde el detalle" depende de la HU-13.
5. Las dos advertencias de `tap()` de `test/navigation/hu06_07_08_flows_test.dart` (líneas 263 y 270) existían antes y no vienen de este cambio.
