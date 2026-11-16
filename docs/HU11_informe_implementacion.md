# Sprint 2 · HU-11 · Actualización de precios, disponibilidad y promociones

Informe de implementación. Rama: `feat/hu11-precios`, creada desde `feat/hu10-catalogo-comercio` porque necesita los productos de la HU-10. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como comercio, quiero actualizar el precio, la disponibilidad y las promociones de mis productos para mantener mi información al día. (Product Backlog, HU-11, 5 puntos.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| El precio es un valor positivo en pesos colombianos (COP) | Implementado | `PrecioValidators` (mayor a cero, sin centavos, tope de $ 100.000.000) y `check` en `precio_producto`. Se muestra con `formatoCop` ("$ 2.500"). |
| Cada producto se puede marcar como disponible o agotado | Implementado | Interruptor en `PrecioProductoPage` + `CambiarDisponibilidadProductoUseCase`. El catálogo muestra la etiqueta "Agotado". |
| Una promoción tiene precio promocional y fechas de inicio y fin | Implementado | Tabla `promocion` (una por producto) + `GuardarPromocionUseCase`. El precio promocional debe ser menor que el normal y el fin no puede ser anterior al inicio. |
| Cada cambio guarda la fecha y hora, con la fuente "Comercio" | Implementado | Trigger `precio_producto_fecha` fija `actualizado_en = now()`; la política solo acepta `fuente = 'comercio'`. La pantalla muestra "Actualizado 15 nov 2026 · 14:05 · Fuente: Comercio". |
| Se conserva el historial de precios | Implementado | Trigger `precio_producto_historial` escribe en `historial_precio` cada cambio de precio o disponibilidad. La app solo lo lee (últimos 10 cambios). |
| Una promoción vencida deja de mostrarse | Implementado | `Promocion.vigenteEn` y `FichaPrecio.precioMostrado`: fuera de sus fechas se muestra el precio normal. |

Escenarios: 1 (actualizar un precio con fecha, hora y fuente), 2 (marcar agotado) y 3 (promoción vencida: se muestra el precio normal) tienen prueba automática de caso de uso y de pantalla.

**Fuera de alcance** (no se implementó a propósito): que los clientes lean los precios y la búsqueda (HU-12, que agregará su propia política de lectura); el detalle con fuente y confianza para el cliente (HU-13).

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
| `lib/features/prices/presentation/` | `PrecioProductoBloc` y `PrecioProductoPage` (edición rápida). |
| `test/prices/` | Pruebas de formato, validaciones, vigencia, casos de uso, Bloc y pantalla. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/utils/format_helpers.dart` | `formatoCop`, `formatoMiles`, `fechaCorta`, `fechaHora`, `soloFecha`. |
| `lib/core/ui/roles/widgets/botones.dart` | `BotonPrimario` deja pasar el texto a dos líneas en pantallas angostas (antes se desbordaba a 320 px). |
| `lib/core/utils/json_helpers.dart` | `toSqlDate` y `parseSqlDate` para columnas `date`. |
| `lib/core/constants/supabase_tables.dart` | Tablas y columnas de la HU-11. |
| `lib/features/catalog/...` | `Producto` trae `precio` y `disponible`; la consulta del catálogo incluye `precio_producto`; la tarjeta muestra el precio, "Agotado" o "Sin precio", y un botón que abre la edición rápida. |
| `lib/core/di/injector.dart`, `lib/app_router.dart`, `lib/core/routes/app_routes.dart` | Registro de dependencias y ruta `/comercio/catalogo/precio`. |
| `test/support/fakes.dart`, `test/di/injector_test.dart` | `FakePreciosRepository` y pruebas de registro. |

## 5. Cómo probarla

1. En Supabase → SQL Editor, ejecutar `docs/sql/sprint2_hu11.sql` (después de `sprint2_hu10.sql`). **Sin este script la lista del catálogo falla**, porque ahora pide también el precio de cada producto.
2. Ejecutar `docs/sql/pruebas_hu11_politicas.sql`: todas las filas deben decir "OK".
3. En la app, entrar con un comercio aprobado → **Mi catálogo** → ícono de precio de un producto. Guardar un precio, marcarlo agotado, crear una promoción y quitarla. Al volver, la lista muestra el precio actualizado.
4. `flutter analyze` sin problemas y `flutter test` con 347 pruebas en verde.
