# Sprint 2 · HU-10 · Informe de pruebas y criterios de calidad

Resultados reales de las verificaciones hechas el 14 de noviembre de 2026 sobre la rama `feat/hu10-catalogo-comercio`.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter pub get` (antes de empezar, línea base) | Correcto |
| `flutter analyze` (línea base, antes de la HU-10) | Sin problemas |
| `flutter test` (línea base, antes de la HU-10) | **184 pruebas, todas pasan** |
| `flutter pub add file_picker` | Correcto, agrega `file_picker ^13.3.3` |
| `flutter analyze` (final) | **No issues found** |
| `flutter test --concurrency=1` (final) | **275 pruebas, todas pasan** (91 nuevas) |
| `docs/sql/sprint2_hu10.sql` en el SQL Editor de nuestro proyecto de Supabase | Ejecutado por el equipo; creó las tablas (las pruebas de abajo las usan) |
| `docs/sql/pruebas_hu10_politicas.sql` en el SQL Editor (14 de noviembre de 2026) | **10 pruebas OK, 0 saltadas, 0 fallos** (A1 a A4, B1, C1 a C3, D1 y E1) |

Nota: el equipo tenía menos de 1 GB de memoria libre. Con la concurrencia por defecto, el compilador de `flutter test` se quedó sin memoria; con `--concurrency=1` corre completo. No cambia lo que se prueba.

**Diferencia entre ejecutado, aprobado y pendiente**

- Ejecutadas y aprobadas: las 275 pruebas de Dart/Flutter.
- Ejecutadas con fallos que se corrigieron durante el desarrollo: 9 pruebas de pantalla del catálogo fallaron en la primera corrida. Dos fallos reales del código explicaban 7 de ellas (el aviso del comercio pendiente no llegaba a la pantalla, y un `TypeError` al abrir la carga por CSV) y se corrigieron en el código. Las otras 2 eran detalles de las pruebas (texto de ejemplo del campo repetido en pantalla).
- Ejecutadas por el equipo contra Supabase: el SQL de la HU-10 y el script de pruebas de las políticas (ver sección 2). Yo no tengo acceso a Supabase; los resultados son los que el equipo copió del SQL Editor.
- **Pendientes, no ejecutadas:** la app corriendo contra Supabase en un dispositivo o emulador (el `.env` del repositorio está vacío en este entorno) y el selector de archivos real.

## 2. Criterios de aceptación y su verificación

| Criterio / escenario | Verificación automática | Archivo |
|---|---|---|
| Crear productos con nombre, marca, código y categoría | Caso de uso (guarda en el comercio correcto, normaliza, valida), Bloc y pantalla (formulario completo → aparece en la lista) | `catalogo_usecases_test`, `catalogo_blocs_test`, `catalogo_flow_test` |
| Editar | Caso de uso, Bloc (actualiza en vez de crear otro) y pantalla (abre con los datos, guarda y la lista cambia) | ídem |
| Eliminar | Caso de uso, Bloc (`deleted`, y el error se conserva), pantalla (pide confirmación, cancelar no borra) | ídem |
| Cargar varios desde un CSV | Parser (12 pruebas), caso de uso (8 pruebas con CSV) y pantalla de carga | `csv_productos_parser_test`, `catalogo_usecases_test`, `catalogo_flow_test` |
| Solo ve y modifica los productos de su comercio | Caso de uso `GetProductos`: con productos de otro comercio en el doble, solo devuelve los suyos | `catalogo_usecases_test` |
| **Escenario 2:** comercio pendiente | Caso de uso (pendiente y rechazado fallan en crear, editar, eliminar, listar y cargar CSV), Bloc de lista (mensaje de espera) y pantalla (se ve el aviso con "Reintentar") | los tres archivos anteriores |
| La lista se carga por páginas | Bloc (primera página, siguiente, fin de lista), caso de uso (`hasMore`) y pantalla (al desplazarse llega el producto 45) | `catalogo_blocs_test`, `catalogo_usecases_test`, `catalogo_flow_test` |
| **Escenario 3:** CSV con filas inválidas | Caso de uso y pantalla: se cargan las válidas y se muestran "Fila N: motivo" para las demás | `catalogo_usecases_test`, `catalogo_flow_test` |
| Accesos desde el Home del comercio | Pestaña "Catálogo", botón "+" y "Ir al Catálogo" abren las rutas correctas | `comercio_entradas_test` |

**Políticas RLS en la base real.** Las pruebas de Dart usan dobles que reproducen la regla; la garantía real vive en Supabase. Por eso el equipo ejecutó `docs/sql/pruebas_hu10_politicas.sql`, que simula sesiones reales y termina en `ROLLBACK`. Resultado:

| Prueba | Qué demuestra | Resultado |
|---|---|---|
| A1 a A3 | El dueño de un comercio aprobado crea, ve y edita sus productos | OK |
| A4 | No puede mover un producto a otro comercio (`with check`) | OK |
| B1 | **Escenario 2:** un comercio pendiente no puede crear productos | OK |
| C1 a C3 | Otro usuario no ve, no edita y no elimina productos ajenos | OK |
| D1 | Sin sesión no se leen productos | OK |
| E1 | El dueño elimina su producto | OK |

Para B1 y A4 el script creó un comercio pendiente temporal dentro de la transacción, porque la base no tenía ninguno; el `ROLLBACK` lo eliminó. La primera ejecución dejó B1 saltada por esa razón y se corrigió el script.

## 3. Pruebas implementadas

| Archivo | Pruebas | Qué cubre |
|---|---|---|
| `test/catalog/producto_validators_test.dart` | 6 | Nombre, marca, código de barras, categoría y `datos` |
| `test/catalog/csv_productos_parser_test.dart` | 12 | Coma y punto y coma, comillas, BOM y `\r\n`, columnas en otro orden, líneas en blanco, numeración, archivo vacío, sin columnas obligatorias, tope de 500 filas |
| `test/catalog/catalogo_usecases_test.dart` | 26 | `GetComercioAprobado` (5 estados), crear, editar, eliminar, listar con páginas, categorías y carga CSV (válidas e inválidas, categoría sin distinguir mayúsculas, código repetido en el archivo, código ya existente, ninguna válida, formato inválido, comercio pendiente, falla de la base) |
| `test/catalog/catalogo_blocs_test.dart` | 18 | `ProductoFormBloc` (categorías, error y reintento, crear, doble toque, error de guardado, error inesperado, editar, eliminar), lista paginada y `CargaCsvBloc` (éxito, cancelar, formato inválido, error de lectura, comercio pendiente, doble toque) |
| `test/catalog/catalogo_flow_test.dart` | 20 | Pantallas: lista, vacío, pendiente, error y reintento, paginado, formulario (validaciones, crear, error al guardar, categorías con reintento), editar, eliminar con confirmación, carga por CSV |
| `test/catalog/comercio_entradas_test.dart` | 3 | Accesos desde el Home del comercio |
| `test/di/injector_test.dart` (agregadas) | 4 | Registros del catálogo; la cadena completa se arma con el localizador; Bloc de fábrica y casos de uso únicos; el formulario acepta `null` |
| `test/pagination/paginated_bloc_test.dart` (agregadas) | 2 | `errorMessageFor` y el mensaje genérico |

No se modificó ninguna prueba existente.

## 4. Criterios de calidad del proyecto aplicados

El criterio de calidad de referencia es la tabla "Informe de criterios de calidad" del `README.md`. Así se aplica y se comprueba para la HU-10:

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `catalog/` con `domain`, `data` y `presentation`. El dominio no importa Flutter, Supabase, GetIt ni `file_picker`. | `grep` sobre `lib/features/*/domain` sin resultados (README, auditoría del Service Locator) |
| Service Locator (GetIt) | Todo registrado en `injector.dart`; el formulario usa `registerFactoryParam`. No hay constructores concretos fuera del inyector. | Pruebas de `test/di/injector_test.dart` y los `grep` del README |
| BLoC | `ProductoFormBloc`, `CargaCsvBloc` y `PaginatedBloc<Producto>` con estados de carga, éxito y error y guard contra doble envío. | `catalogo_blocs_test` |
| Reutilización | `PaginatedBloc`/`PaginatedListView`, `PantallaRol`, `BarraTituloRol`, `AuthTextField`, `ErrorMessage`, `BotonPrimario`, `TarjetaSuave`, `mapPostgrestException`. | Revisión del código |
| Convenciones | Nombres en español y `snake_case` como `aprobaciones`/`comercio`; constantes de tablas y rutas en `core/`. | Revisión del código |
| Manejo de errores | Errores de Supabase traducidos a mensajes en español (`AuthFailure`); error inesperado con mensaje genérico. | `catalogo_blocs_test`, `catalogo_flow_test` |
| Paginado | La lista del catálogo usa la base común. | `catalogo_flow_test` (paginado) |
| Pruebas | 91 pruebas nuevas; la suite completa pasa. | Sección 1 |
| Análisis estático | `flutter analyze` sin problemas. | Sección 1 |

## 5. Pendientes y limitaciones

1. ~~Ejecutar el SQL y las pruebas de las políticas~~: hecho, 10 pruebas OK (sección 2). Si cambia el SQL, hay que volver a correrlas.
2. Probar la carga por CSV con el selector real en Android y en el escritorio de Windows (`file_picker` solo se verificó por compilación).
3. Probar el flujo completo con una cuenta de comercio aprobada (por ejemplo `paila@gmail.com`, de las cuentas de prueba del README) cuando el `.env` tenga las credenciales.
4. Dos advertencias de `tap()` en `test/navigation/hu06_07_08_flows_test.dart` (líneas 263 y 270) existían antes de la HU-10 y no vienen de este cambio.
