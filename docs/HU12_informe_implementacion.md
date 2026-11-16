# Sprint 2 · HU-12 · Búsqueda de productos

Informe de implementación. Rama: `feat/hu12-busqueda`, creada desde `feat/hu11-precios` porque necesita los productos (HU-10) y los precios (HU-11). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como cliente, quiero buscar productos por nombre, marca o código de barras para ver rápido en cuánto está cada producto entre los establecimientos. (Product Backlog, HU-12, 5 puntos.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| Se puede buscar escribiendo el nombre o la marca | Implementado | `BusquedaPage` + `BuscarProductosUseCase` → función `buscar_productos` (sin distinguir mayúsculas; los comodines `%` y `_` se buscan como texto). |
| Se puede escanear el código de barras con la cámara | Implementado | `EscanerPage` con `mobile_scanner` (EAN-13, EAN-8, UPC-A y UPC-E). Pide permiso de cámara; si se niega, se puede escribir el código. |
| Cada resultado muestra el rango de precios y en cuántos establecimientos está | Implementado | `ResultadoCard`: "$ 4.200 – $ 5.000" y "En 2 establecimientos". El rango usa el precio de la promoción si está vigente (HU-11) y solo cuenta los establecimientos donde está disponible. |
| Si no hay resultados, se muestra un mensaje | Implementado | "No encontramos productos". |
| Los resultados se cargan por páginas | Implementado | `BusquedaBloc` (un `PaginatedBloc<ResultadoBusqueda>`) + `PaginatedListView`, 20 por página. |

Escenarios: 1 (buscar "arroz" muestra los productos y su rango), 2 (escanear un código abre ese producto con sus precios) y 3 (sin resultados: "No encontramos productos") tienen prueba automática de caso de uso y de pantalla.

**Fuera de alcance**: el nivel de confianza de cada precio y su detalle ampliado (HU-13). El detalle de la HU-12 ya muestra la fuente y la fecha de cada precio, que vienen de la HU-11.

## 3. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| ¿Qué es "el mismo producto" en varios comercios? | El mismo código de barras; si no tiene, el mismo nombre y marca (sin distinguir mayúsculas). Lo calcula `clave_producto()`. | Cada comercio crea sus propios productos (HU-10); el código de barras es lo único compartido. |
| Productos agotados | Aparecen en la búsqueda como "Agotado" si están agotados en todos lados; en el detalle se ven atenuados. No cuentan para el rango. | HU-11: "los clientes lo ven como no disponible". |
| Quién ve qué | Solo comercios **aprobados** y productos **con precio**. Solo cuentas con sesión. | Un producto sin precio no sirve para comparar. |
| Seguridad | El cliente no lee las tablas: usa dos funciones `security definer` que devuelven solo lo publicado. Las políticas de HU-10 y HU-11 no cambian. | Evita abrir la lectura de las tablas del comercio. |
| Mínimo de letras | 2. Con menos no se consulta. | Una letra devuelve casi todo. |
| Orden del detalle | Primero los disponibles, del más barato al más caro; el primero lleva "Mejor precio". | Es lo que ayuda a decidir. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu12.sql` | `clave_producto()`, `ofertas_publicadas()` (interna), `buscar_productos()` y `precios_de_producto()`. Idempotente. |
| `docs/sql/pruebas_hu12_busqueda.sql` | 10 pruebas en una transacción con `rollback`: nombre, marca, promoción vigente, agotado, sin resultados, comodines, comercios pendientes, detalle por código, sin acceso a las tablas ni a la función interna, sin sesión. |
| `lib/features/busqueda/domain/` | `ResultadoBusqueda`, `DetalleProducto` y `OfertaProducto`; contrato `BusquedaRepository`; `BuscarProductosUseCase` y `GetDetalleProductoUseCase` (por clave o por código). |
| `lib/features/busqueda/data/` | `SupabaseBusquedaDataSource` (RPC) y `BusquedaRepositoryImpl`. |
| `lib/features/busqueda/presentation/` | `BusquedaBloc`, `DetalleProductoBloc`, `BusquedaPage`, `DetalleProductoPage`, `EscanerPage` y `ResultadoCard`. |
| `test/busqueda/` | Pruebas de casos de uso, Blocs y pantallas. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/cliente/presentation/pages/cliente_home_screen.dart` | La lupa y el buscador del Home abren la búsqueda (antes decían "próximamente"). |
| `lib/core/routes/app_routes.dart`, `lib/app_router.dart`, `lib/core/di/injector.dart` | Rutas `/cliente/busqueda`, `/cliente/busqueda/producto` y `/cliente/escaner`, y sus dependencias. |
| `lib/core/constants/supabase_tables.dart` | Funciones y columnas de la HU-12. |
| `pubspec.yaml` | `mobile_scanner` para el escáner. |
| `android/app/src/main/AndroidManifest.xml` | Permisos de cámara y de Internet (el de Internet faltaba para la app instalada). |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription`. |

## 5. Cómo probarla

1. En Supabase → SQL Editor, ejecutar `docs/sql/sprint2_hu12.sql` (después de `sprint2_hu11.sql`).
2. Ejecutar `docs/sql/pruebas_hu12_busqueda.sql`: todas las filas deben decir "OK".
3. Para tener qué buscar: con un comercio aprobado, cargar productos con precio (HU-10 y HU-11). Si dos comercios usan el mismo código de barras, la búsqueda los agrupa.
4. En la app, entrar como **Cliente** → lupa o buscador del Home → escribir "arroz". Tocar un resultado para ver el precio en cada tienda. Con el botón de escanear, apuntar al código de barras (en el emulador no hay cámara: usar "Escribir el código").
5. `flutter pub get`, `flutter analyze` sin problemas y `flutter test` con 413 pruebas en verde.
