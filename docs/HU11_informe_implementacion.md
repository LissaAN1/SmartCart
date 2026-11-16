# Sprint 2 · HU-11 · Actualización de precios, disponibilidad y promociones

Informe de implementación. Rama: `feat/hu11-precios`, creada desde `feat/hu10-catalogo-comercio` porque necesita los productos de la HU-10. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como comercio, quiero actualizar el precio, la disponibilidad y las promociones de mis productos para mantener mi información al día. (Product Backlog, HU-11, 5 puntos.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| El precio es un valor positivo en pesos colombianos (COP) | Implementado | `PrecioValidators` (mayor a cero, sin centavos, tope de $ 100.000.000) y `check` en `precio_producto`. Se muestra con `formatoCop` ("$ 2.500"). |
| Cada producto se puede marcar como disponible o agotado | Implementado | Interruptor Disponible/Agotado en Editar Producto, que se guarda con "Guardar Cambios" (`GuardarProductoUseCase`, junto con el precio). El catálogo muestra ACTIVO/INACTIVO y la etiqueta "Agotado" en la foto. |
| Una promoción tiene precio promocional y fechas de inicio y fin | Implementado | Tabla `promocion` (una por producto) + `GuardarPromocionUseCase`. El precio promocional debe ser menor que el normal y el fin no puede ser anterior al inicio. |
| Cada cambio guarda la fecha y hora, con la fuente "Comercio" | Implementado | Trigger `precio_producto_fecha` fija `actualizado_en = now()`; la política solo acepta `fuente = 'comercio'`. La pantalla muestra "Actualizado 15 nov 2026 · 14:05 · Fuente: Comercio". |
| Se conserva el historial de precios | Implementado | Trigger `precio_producto_historial` escribe en `historial_precio` cada cambio de precio o disponibilidad. La app solo lo lee (últimos 10 cambios). |
| Una promoción vencida deja de mostrarse | Implementado | `Promocion.vigenteEn` y `FichaPrecio.precioMostrado`: fuera de sus fechas se muestra el precio normal. |

Escenarios: 1 (actualizar un precio con fecha, hora y fuente), 2 (marcar agotado) y 3 (promoción vencida: se muestra el precio normal) tienen prueba automática de caso de uso y de pantalla.

**Fuera de alcance** (no se implementó a propósito): que los clientes lean los precios y la búsqueda (HU-12, que agregará su propia política de lectura); el detalle con fuente y confianza para el cliente (HU-13).

### Diseño del equipo (catálogo y Editar Producto)

Las pantallas siguen las maquetas del equipo (`nosubir/catalogo.png`, `detallesprooducto.png`, `detallesproducto1.png`):

| Pantalla | Qué tiene |
|---|---|
| Catálogo | Buscador (nombre o marca), chips de categorías, resumen (TOTAL ITEMS, VALOR STOCK, BAJO STOCK), "Inventario Activo" y tarjetas con foto, precio, stock (verde o rojo si es bajo), etiqueta "Agotado" y ACTIVO/INACTIVO. Toda la tarjeta abre Editar Producto (allí se cambia la disponibilidad y se elimina). |
| Editar Producto | Foto con botón de cámara, nombre, SKU (código de barras) y tienda; tarjeta "Historial de Precios" con gráfica de área de los últimos 4 meses y "Bajó/Subió un X % este mes"; precio actual con la variación del último cambio; stock; "Tienda / Sucursal"; aviso; disponibilidad; promoción; "Eliminar producto" y "Guardar Cambios". |

Para eso se agregaron `producto.stock`, `producto.foto_url`, la función `resumen_catalogo()` y el bucket `productos` de Storage (sección 7 y 8 de `sprint2_hu11.sql`). "Guardar Cambios" usa `GuardarProductoUseCase`, que compone los casos de uso de la HU-10 (crear y editar), sube la foto y guarda el precio, validando todo antes de escribir.

Diferencias con la maqueta: el aviso dice "El nuevo precio se publica de inmediato con la fuente Comercio y queda guardado en el historial" (en la HU-11 el precio del comercio no pasa por colaboradores); la barra del catálogo conserva el botón de carga por CSV en vez de la campana y la foto de perfil; las categorías son las seis de la base.

## 3. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| Moneda | Pesos enteros (`integer`), sin centavos. Se aceptan "2500", "2.500" y "$ 2.500". | En la práctica el COP no usa centavos. |
| Precio actual | Uno por producto (`precio_producto`, 1 a 1 con `producto`). | Cada producto ya pertenece a un solo comercio (HU-10). |
| Promociones | Una por producto; guardar otra la reemplaza. Fechas sin hora, ambas incluidas. Se puede programar una a futuro. | Es lo que piden los criterios y simplifica la consulta de la HU-12. |
| Disponibilidad | Exige que el producto tenga precio. | Un producto sin precio todavía no se muestra a los clientes. |
| Historial | Lo escribe la base (trigger), no la app; guardar el mismo precio no agrega fila. | Así no se puede saltar ni falsear desde la app. |
| Fecha de vigencia | Se compara con la fecha del teléfono. | Suficiente para el alcance del sprint; la HU-12 puede filtrar también en la consulta. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu11.sql` | Tablas `precio_producto`, `historial_precio` y `promocion` con sus `check`, triggers de fecha e historial, función `es_producto_propio()` y políticas RLS. Idempotente. |
| `docs/sql/pruebas_hu11_politicas.sql` | Prueba de las políticas y los triggers en una transacción con `rollback` (13 pruebas). |
| `lib/features/prices/domain/` | Entidades (`PrecioProducto`, `Promocion`, `FichaPrecio`), contrato `PreciosRepository`, `PrecioValidators` y cinco casos de uso. Los que escriben devuelven la ficha ya actualizada, así el Bloc hace una sola llamada por evento (regla de capas del README). |
| `lib/features/prices/data/` | `SupabasePreciosDataSource` y `PreciosRepositoryImpl`. |
| `lib/features/prices/presentation/` | `PrecioProductoBloc` (historial, disponibilidad y promoción) y los widgets `HistorialPreciosCard` (gráfica) y `SeccionPrecioProducto`, que usa Editar Producto. `GuardarProductoUseCase` está en `prices/domain`. |
| `test/prices/` | Pruebas de formato, validaciones, vigencia, casos de uso, Bloc y pantalla. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/utils/format_helpers.dart` | `formatoCop`, `formatoMiles`, `fechaCorta`, `fechaHora`, `soloFecha`. |
| `lib/core/ui/roles/widgets/botones.dart` | `BotonPrimario` deja pasar el texto a dos líneas en pantallas angostas (antes se desbordaba a 320 px). |
| `lib/core/utils/json_helpers.dart` | `toSqlDate` y `parseSqlDate` para columnas `date`. |
| `lib/core/constants/supabase_tables.dart` | Tablas y columnas de la HU-11. |
| `lib/features/catalog/...` | `Producto` trae `precio`, `disponible`, `stock` y `fotoUrl`; la consulta incluye `precio_producto`, búsqueda y categoría; `resumen` y `subirFoto` en el repositorio; `CatalogoListaBloc`, `InventarioBloc` y el `ProductoFormBloc` con foto; pantallas Catálogo y Editar Producto con el diseño. |
| `lib/core/di/injector.dart`, `lib/app_router.dart`, `lib/core/routes/app_routes.dart` | Registro de dependencias y ruta `/comercio/catalogo/precio`. |
| `test/support/fakes.dart`, `test/di/injector_test.dart` | `FakePreciosRepository` y pruebas de registro. |

## 5. Cómo probarla

1. En Supabase → SQL Editor, ejecutar `docs/sql/sprint2_hu11.sql` (después de `sprint2_hu10.sql`). **Sin este script la lista del catálogo falla**, porque ahora pide también el precio de cada producto.
2. Ejecutar `docs/sql/pruebas_hu11_politicas.sql`: todas las filas deben decir "OK".
3. En la app, entrar con un comercio aprobado → **Catálogo** → tocar un producto. En **Editar Producto** cambiar el precio, el stock y la foto y tocar **Guardar Cambios**; marcarlo agotado con el interruptor y guardar; crear y quitar una promoción. Si aparece "La base de datos no está actualizada", falta ejecutar la versión más reciente de `sprint2_hu11.sql`.
4. `flutter analyze` sin problemas y `flutter test` con 373 pruebas en verde.
