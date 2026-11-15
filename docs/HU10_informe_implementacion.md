# Sprint 2 · HU-10 · Gestión del catálogo del comercio

Informe de implementación. Rama: `feat/hu10-catalogo-comercio`. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como comercio aprobado, quiero registrar y editar mis productos y categorías, de forma manual o con una lista, para mostrar mi catálogo a los clientes. (Product Backlog, HU-10, 5 puntos, Must.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| Crear, editar y eliminar productos con nombre, marca, código de barras y categoría | Implementado | `ProductoFormPage` (crear y editar) y botón "Eliminar producto" con confirmación. |
| Cargar varios productos desde un CSV | Implementado | `CatalogoCsvPage` + `CargarProductosCsvUseCase`. Opcional según el profesor, pero el backlog lo lista y quedó hecho. |
| Solo ve y modifica los productos de su propio establecimiento | Implementado | La app filtra por `id_comercio` y las políticas RLS de `producto` lo exigen en la base. |
| Un comercio pendiente no puede cargar productos | Implementado | `GetComercioAprobadoUseCase` en cada caso de uso, más RLS (`es_comercio_aprobado_propio`). |
| La lista se carga por páginas | Implementado | `PaginatedBloc<Producto>` + `PaginatedListView` (20 por página, con `range`). |

Escenarios: 1 (crear un producto), 2 (comercio pendiente: se le indica que espere la aprobación) y 3 (CSV con filas inválidas: carga las válidas y muestra cuáles fallaron y por qué) tienen prueba automática. Ver `docs/HU10_informe_pruebas.md`.

**Fuera de alcance** (no se implementó a propósito): precios, disponibilidad y promociones (HU-11); lectura de productos por los clientes y búsqueda (HU-12); detalle con fuente y confianza (HU-13); carrito y favoritos (HU-17).

## 3. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| Categorías | Lista fija y compartida (`categoria`), sembrada con las mismas seis del Home del cliente: Super, Frutas, Lácteos, Aseo, Café, Panadería. El comercio solo elige una. | Los criterios no piden gestionar categorías, solo asignar una. Si el equipo quiere categorías propias por comercio, cambia el modelo. |
| Obligatorios | Nombre (3 a 100 caracteres) y categoría. Marca (máx. 60) y código de barras son opcionales. | HU-12 busca por código, pero no todo producto de barrio lo trae. |
| Código de barras | Si se escribe, 8 a 14 dígitos; no se repite dentro del mismo comercio (índice único parcial). | Cubre EAN-8, UPC y EAN-13. |
| Eliminar | Borrado definitivo con confirmación. Las tablas futuras (precios, carrito, favoritos) se enlazarán con `on delete cascade`. | Es lo que pide el criterio; el borrado lógico complicaría todas las consultas siguientes. |
| Lectura por clientes | No incluida. HU-12 agrega su propia política de lectura. | Evita ampliar el alcance. |
| CSV | Encabezado obligatorio con `nombre` y `categoria` (`marca` y `codigo_barras` opcionales, en cualquier orden). Separador coma o punto y coma. Máximo 500 filas por archivo. | Excel en español guarda con punto y coma. El tope evita cargas enormes. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu10.sql` | Tablas `categoria` y `producto` con sus `check`, índices, función `es_comercio_aprobado_propio()` y políticas RLS. Idempotente. |
| `docs/sql/pruebas_hu10_politicas.sql` | Prueba de las políticas simulando sesiones (dueño aprobado, dueño pendiente, otro usuario, anónimo). Termina en `ROLLBACK`; devuelve una tabla con el resultado de cada prueba. Ejecutado: 10 pruebas OK. |
| `lib/features/catalog/domain/entities/` | `Producto`, `ProductoDatos`, `Categoria`, `ResultadoCargaCsv`, `ErrorFilaCsv`, `ArchivoCsv`. |
| `lib/features/catalog/domain/validators/producto_validators.dart` | Reglas del producto (formulario y filas del CSV). |
| `lib/features/catalog/domain/csv/csv_productos_parser.dart` | Lee el texto del CSV: separadores, comillas, BOM, líneas en blanco y numeración de filas. |
| `lib/features/catalog/domain/repository/` | Contratos `CatalogoRepository` y `SelectorArchivoCsv`. |
| `lib/features/catalog/domain/usecases/` | `GetComercioAprobadoUseCase`, `GetProductosUseCase`, `GetCategoriasUseCase`, `CrearProductoUseCase`, `EditarProductoUseCase`, `EliminarProductoUseCase`, `ElegirArchivoCsvUseCase`, `CargarProductosCsvUseCase`. |
| `lib/features/catalog/data/source/supabase_catalogo_data_source.dart` | Único archivo que lee y escribe `producto` y `categoria`. |
| `lib/features/catalog/data/source/file_picker_selector_csv.dart` | Único archivo que conoce `file_picker`. |
| `lib/features/catalog/data/repository/catalogo_repository_impl.dart` | Implementación del contrato. |
| `lib/features/catalog/presentation/bloc/` | `ProductoFormBloc` (crear, editar, eliminar) y `CargaCsvBloc`. |
| `lib/features/catalog/presentation/pages/` | `CatalogoPage`, `ProductoFormPage`, `CatalogoCsvPage`. |
| `lib/features/catalog/presentation/widgets/producto_card.dart` | Fila de la lista. |
| `test/catalog/*` | 88 pruebas nuevas (ver el informe de pruebas). |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/constants/supabase_tables.dart` | Tablas `producto`, `categoria` y sus columnas. |
| `lib/core/routes/app_routes.dart` | Rutas `catalogo`, `catalogoProducto`, `catalogoCsv`. |
| `lib/app_router.dart` | Las tres rutas; el formulario es `MaterialPageRoute<bool>` (devuelve si hubo cambios). |
| `lib/core/di/injector.dart` | Registros nuevos de la HU-10 (ver sección 6). |
| `lib/core/pagination/paginated_bloc.dart` | Parámetro opcional `errorMessageFor`. Sin él, el comportamiento es el de siempre. Ver sección 7. |
| `lib/features/auth/domain/failures/auth_failure.dart` | Función `mensajeDeFallo(error)`, que se usa como `errorMessageFor`. |
| `lib/features/home/presentation/pages/role_shell.dart` | La pestaña "Catálogo" del comercio (índice 2) abre el catálogo. |
| `lib/features/comercio/presentation/pages/comercio_home_screen.dart` | El botón "+" y "Ir al Catálogo" abren el formulario y el catálogo (callbacks opcionales; sin ellos siguen mostrando "próximamente"). |
| `pubspec.yaml`, `pubspec.lock` | Dependencia `file_picker ^13.3.3`. |
| `test/support/fakes.dart`, `pump_helpers.dart`, `test/di/injector_test.dart`, `test/pagination/paginated_bloc_test.dart` | Dobles y casos nuevos. No se cambió ninguna prueba existente. |

Se eliminó `lib/features/catalog/.gitkeep`, porque la carpeta ya tiene contenido.

## 5. Arquitectura

```text
presentation  CatalogoPage · ProductoFormPage · CatalogoCsvPage
              PaginatedBloc<Producto> · ProductoFormBloc · CargaCsvBloc
                    │  (un caso de uso por acción)
domain        GetProductos · Crear · Editar · Eliminar · GetCategorias · CargarProductosCsv
              GetComercioAprobado  ← todos parten de aquí
              CatalogoRepository · SelectorArchivoCsv   (contratos)
              ProductoValidators · CsvProductosParser   (Dart puro)
                    │
data          CatalogoRepositoryImpl → SupabaseCatalogoDataSource
              FilePickerSelectorCsv
```

- El dominio no importa Flutter, Supabase, GetIt ni `file_picker` (comprobado con `grep`; ver README, auditoría del Service Locator).
- `file_picker` queda detrás del contrato `SelectorArchivoCsv`: las pruebas usan un doble y el dominio no sabe cómo se abre el selector.
- Los Blocs no tienen lógica de negocio: llaman a un caso de uso y convierten el resultado en estado, con el mismo patrón de `ComercioBloc` (carga, éxito y error, y un guard contra el doble envío).

## 6. Integración con el Service Locator (GetIt)

Todo se registra en `lib/core/di/injector.dart`, con el mecanismo y el orden existentes (source → repositorio → casos de uso → Bloc). No se creó ningún contenedor paralelo.

| Tipo | Registro |
|---|---|
| `SupabaseCatalogoDataSource` | `registerLazySingleton` |
| `SelectorArchivoCsv` (→ `FilePickerSelectorCsv`) | `registerLazySingleton` con el tipo del contrato |
| `CatalogoRepository` (→ `CatalogoRepositoryImpl`) | `registerLazySingleton` con el tipo del contrato |
| 8 casos de uso | `registerLazySingleton` |
| `CargaCsvBloc`, `PaginatedBloc<Producto>` | `registerFactory` (uno nuevo por pantalla) |
| `ProductoFormBloc` | `registerFactoryParam<ProductoFormBloc, Producto?, void>`: `sl<ProductoFormBloc>(param1: producto)`, con `null` para crear |

`AppRouter` pide los Blocs con `sl<...>()`; ninguna pantalla construye dependencias a mano.

## 7. Reglas de negocio

- **Solo un comercio aprobado gestiona productos.** `GetComercioAprobadoUseCase` devuelve el comercio o lanza un mensaje claro (sin sesión, sin comercio, pendiente, rechazado). La garantía real está en la base: las políticas de `producto` usan `es_comercio_aprobado_propio(id_comercio)`, que exige que el comercio sea del usuario y esté aprobado.
- **Solo ve y modifica lo suyo.** La app consulta por el `id_comercio` del dueño; en la base, `using` y `with check` impiden leer, editar o mover productos ajenos.
- **Validación en tres lugares con las mismas reglas:** el formulario, el caso de uso y los `check` de la tabla.
- **Código de barras único por comercio:** índice único parcial; la app traduce el error `23505` a "Ya tienes un producto con ese código de barras."
- **CSV:** las filas válidas se guardan y las inválidas no detienen la carga; se reportan con número de fila y motivo. Una fila falla por: regla del producto incumplida, categoría inexistente (sin distinguir mayúsculas), código repetido en el archivo, o código que ya tiene otro producto del comercio. Si ninguna es válida no se escribe nada.

## 8. Decisiones técnicas y dificultades

- **`PaginatedBloc` mostraba siempre un mensaje genérico.** Sin cambios, el aviso del escenario 2 ("tu comercio está pendiente de aprobación") nunca habría llegado a la pantalla. Agregamos un parámetro opcional `errorMessageFor` en vez de importar `AuthFailure` en `core/`, así el Bloc compartido sigue sin depender de ninguna funcionalidad y la lista de HU-24 no cambia.
- **Error de tipos en la navegación (lo encontró una prueba).** `CatalogoPage` pedía `pushNamed<bool>` también para la ruta del CSV, que es `MaterialPageRoute<void>`, y eso lanza un `TypeError` en ejecución. Ahora pide `Object?`.
- **El `update`/`delete` de Supabase no falla cuando RLS oculta la fila**: simplemente afecta 0 filas. El data source usa `maybeSingle()` y `select()` para detectarlo y responder "No encontramos ese producto."
- **Lotes de 100** al enviar productos y al consultar códigos existentes, para no armar URLs ni cuerpos enormes.
- **Memoria al correr las pruebas.** En el equipo con poca memoria libre, `flutter test` se quedó sin heap; corriendo con `--concurrency=1` pasa sin problema.

## 9. Pendientes y riesgos

- **SQL en Supabase: ejecutado y probado.** El equipo corrió `docs/sql/sprint2_hu10.sql` y luego `docs/sql/pruebas_hu10_politicas.sql`: 10 pruebas OK, sin saltadas ni fallos (detalle en `docs/HU10_informe_pruebas.md`). El equipo también comprobó a mano que la app funciona contra esa base.
- **Selector de archivos real (`file_picker`):** el equipo lo probó a mano con los archivos de `docs/ejemplos/` y funcionó. No quedó registrado en qué plataforma, y no se probó en todas (Android, Windows, web). Las pruebas automáticas usan un doble.
- Yo no pude ejecutar la app contra Supabase en mi entorno (el `.env` del repositorio está vacío); la prueba con la base real la hizo el equipo.
- El README tiene contraseñas de las cuentas de prueba en texto plano; conviene decidir si se quedan antes de publicar el repositorio.
