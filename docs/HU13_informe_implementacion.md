# Sprint 2 · HU-13 · Detalle del precio con fuente, fecha y confianza

Informe de implementación. Rama: `feat/hu13-detalle-precio`, creada desde `feat/hu17-carrito-compras-favoritos` porque necesita los precios (HU-11), el detalle del producto (HU-12) y el carrito y los favoritos (HU-17). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como cliente, quiero ver, en cada precio, su fuente, su fecha de actualización y su nivel de confianza, para saber qué tan confiable es la información con la que decido. (Product Backlog, HU-13, 3 puntos.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| Cada precio muestra su fuente: Comercio o Comunidad | Implementado | `ConfianzaDelPrecio` escribe "Fuente: Comercio" o "Fuente: Comunidad". La base guarda `colaborador`; `FuentePrecio.colaborador.etiqueta` es "Comunidad" (antes decía "Colaborador"). |
| Se muestra la fecha y hora de la última actualización | Implementado | "Actualizado 15 nov 2026 · 09:30 (hoy)". Junto a la fecha va "hoy", "ayer" o "hace N días". |
| El nivel de confianza (alto, medio o bajo) depende de la fuente y de qué tan reciente es el precio | Implementado | `ConfianzaReglas.calcular` (sección 3). Se ve como "Confianza alta", "media" o "baja". |
| Un precio con más días que el límite se marca como desactualizado | Implementado | Más de 7 días: etiqueta **Desactualizado** y la confianza baja dos niveles. El límite es `ConfianzaReglas.diasLimite`. |
| Desde el detalle se puede reportar un precio incorrecto | Implementado | Botón "Reportar precio incorrecto" en cada establecimiento → hoja con el motivo (opcional) → función SQL `reportar_precio_incorrecto`. |

Escenarios: 1 (precio de comercio de hoy → fuente Comercio, fecha de hoy, confianza alta), 2 (precio con más de 7 días → desactualizado y confianza baja) y 3 (reportar → queda un reporte pendiente) tienen prueba automática de dominio, de Bloc y de pantalla.

**Aprovechamos la HU para cerrar un criterio de la HU-17:** "agregar al carrito desde el detalle del producto". Cada establecimiento del detalle tiene ahora el corazón de favoritos y el botón de agregar (los widgets `FavoritoBoton` y `AgregarCarritoBoton` de la HU-17), siempre que el detalle se abra desde el Home del cliente.

**Fuera de alcance:** revisar los reportes de precio incorrecto, corregir el precio o sancionar (moderación, HU-27); validar los precios de la comunidad (HU-15); mostrar la confianza en las tarjetas de resultado de la búsqueda (hoy solo está en el detalle) y en las alternativas de carrito (HU-18, que puede reutilizar `ConfianzaDelPrecio`).

## 3. Reglas de confianza (decisión nuestra)

El backlog dice que la confianza "depende de la fuente y de qué tan reciente es" y que el límite de días lo define el equipo. Decidimos:

* **Punto de partida por fuente.** El comercio es quien conoce su precio: empieza en *alta*. Un precio de la comunidad lo reporta cualquier colaborador con una foto y todavía no lo revisa nadie: empieza en *media* y no llega a *alta*.
* **Cuánto baja con los días** (días de calendario en la hora local):
  hasta 3 días no baja; de 4 a 7 baja un nivel; más de 7 baja dos niveles y se marca **desactualizado**.

| Fuente | 0 a 3 días | 4 a 7 días | Más de 7 días (desactualizado) |
|---|---|---|---|
| Comercio | alta | media | baja |
| Comunidad | media | baja | baja |

Constantes: `ConfianzaReglas.diasReciente = 3` y `ConfianzaReglas.diasLimite = 7`. Cambiarlas cambia el cálculo en toda la app y no toca la base de datos.

Detalles que fijamos:
* Se cuentan **días de calendario**, no períodos de 24 horas: un precio de ayer a las 23:59 es "ayer" aunque hayan pasado dos minutos.
* Una fecha en el futuro (reloj del teléfono atrasado) cuenta como "hoy".
* La confianza se calcula **en la app**, con la fecha del teléfono, no en la base. Así es una función pura y fácil de probar, y la reutilizan el detalle y la HU-18.

## 4. Otros supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| ¿Qué se reporta? | El precio de **un establecimiento** (un `id_producto`), no el producto en general. | Cada comercio tiene su precio; quien lo revisa necesita saber de cuál hablan. |
| ¿Qué guarda el reporte? | El precio vigente (el de la promoción, si la había), su fuente, su fecha, un motivo opcional y el estado `pendiente`. | Aunque el comercio cambie el precio después, quien revise sabe qué veía el cliente. |
| Motivo | Opcional, hasta 300 caracteres. Uno en blanco se guarda como vacío. | Basta con tocar el botón; el texto ayuda sin estorbar. |
| Reportes repetidos | Un cliente tiene **un solo reporte pendiente por precio**. Si vuelve a reportar, la app dice "Ya reportaste este precio; lo estamos revisando". Cuando el reporte se resuelve puede reportar de nuevo. | Evita llenar la revisión con el mismo aviso. |
| Quién reporta | Solo cuentas con rol **cliente**. | Es una acción del cliente (HU-13). |
| Qué se puede reportar | Precios publicados: de comercios aprobados y con precio (los mismos que ve el cliente, `ofertas_publicadas()`). | No se reporta lo que el cliente no puede ver. |
| Seguridad | Nadie escribe la tabla directo: solo la función `security definer`. Cada cliente lee solo sus reportes. | Misma regla que el carrito (HU-17). |
| Agregar al carrito desde el detalle | Solo en los establecimientos **disponibles** (los agotados se muestran atenuados). El favorito se puede guardar siempre. | Un producto agotado no se compra, pero puede interesar guardarlo. |

## 5. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu13.sql` | Tabla `reporte_precio_incorrecto` (estado, motivo de máximo 300 caracteres, un reporte pendiente por cliente y producto, RLS de lectura propia) y la función `reportar_precio_incorrecto()`. Idempotente. |
| `docs/sql/pruebas_hu13_politicas.sql` | 18 pruebas en una transacción con `rollback` (ver el informe de pruebas). |
| `lib/features/confianza/domain/` | `NivelConfianza`, `ConfianzaPrecio`, `ConfianzaReglas` (el cálculo), el contrato `ReporteIncorrectoRepository` y `ReportarPrecioIncorrectoUseCase`. |
| `lib/features/confianza/data/` | `SupabaseReporteIncorrectoDataSource` (RPC) y `ReporteIncorrectoRepositoryImpl`. |
| `lib/features/confianza/presentation/widgets/` | `ConfianzaDelPrecio` (el componente de precio con fuente, fecha, confianza y el botón de reporte) y `pedirMotivoDeReporte` (la hoja del motivo). |
| `test/confianza/` | Pruebas del cálculo, del caso de uso y el Bloc, del componente y del detalle. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/busqueda/presentation/bloc/detalle_producto_bloc.dart` | Nuevo evento `PrecioIncorrectoReportado`; el estado lleva los precios en envío, los ya reportados y el aviso. Mismo patrón de avisos de la HU-17 (`AvisoUi`). |
| `lib/features/busqueda/presentation/pages/detalle_producto_page.dart` | Cada establecimiento usa `ConfianzaDelPrecio`; nota sobre cómo se mide la confianza; botones de favoritos y de agregar al carrito si recibió los blocs del cliente. |
| `lib/features/busqueda/presentation/pages/busqueda_page.dart` | Al abrir un producto le pasa al detalle el carrito y los favoritos, si los tiene. |
| `lib/features/cliente/presentation/cliente_blocs.dart` | `ConBlocsDelCliente` (argumento de ruta que lleva esos dos blocs junto al argumento propio), `desempacarArgumentos` y `clienteBlocsOrNull`. |
| `lib/features/cliente/presentation/pages/cliente_home_screen.dart`, `lib/features/home/presentation/pages/role_shell.dart` | El Home abre la búsqueda con una función que da el `RolShell`, para que la búsqueda lleve el carrito y los favoritos del cliente. Sin ella, igual que antes. |
| `lib/app_router.dart` | La búsqueda y su detalle aceptan `ConBlocsDelCliente` y entregan los blocs con `BlocProvider.value`. Con el argumento de antes (un `String` o una `ConsultaProducto`) funcionan igual. |
| `lib/core/di/injector.dart` | Data source, repositorio y caso de uso de la HU-13; `DetalleProductoBloc` recibe `reportar`. |
| `lib/core/constants/supabase_tables.dart` | Tabla y función de la HU-13. |
| `lib/features/prices/domain/entities/precio.dart` | `FuentePrecio.colaborador` se muestra como "Comunidad". |
| `lib/features/cliente/domain/usecases/get_cliente_activo_usecase.dart` | Los mensajes ya no hablan solo del carrito ("Inicia sesión para continuar", "Inicia sesión como cliente para usar esta función"), porque ahora también lo usa el reporte. |
| `test/support/fakes.dart`, `test/busqueda/busqueda_pantallas_test.dart`, `test/cliente/cliente_integracion_test.dart`, `test/di/injector_test.dart` | Dobles y pruebas que se ajustaron (ver el informe de pruebas). |

## 6. Cómo se usa el componente en otra pantalla (HU-18)

```dart
ConfianzaDelPrecio(
  fuente: oferta.fuente,
  actualizadoEn: oferta.actualizadoEn,
  ahora: DateTime.now(),
  onReportar: () { ... },   // opcional: sin él no se muestra el botón
)
```

Solo necesita la fuente y la fecha del precio; calcula la confianza con `ConfianzaReglas`.

## 7. Dónde se aplica el Service Locator (GetIt)

Todo lo nuevo se registra en `lib/core/di/injector.dart`, sin otro contenedor:

* `SupabaseReporteIncorrectoDataSource` y `ReporteIncorrectoRepository` (con el tipo del contrato) como `registerLazySingleton`.
* `ReportarPrecioIncorrectoUseCase` como `registerLazySingleton`, con `GetClienteActivoUseCase` (la misma puerta de entrada que el carrito).
* `DetalleProductoBloc`, que ya era `registerFactoryParam` (recibe la consulta como `param1`), ahora recibe también `reportar: sl()`.

`app_router.dart` sigue siendo el único lugar que pide dependencias con `sl<...>()`. Registros en `injector.dart`: 110 (eran 106; uno más porque `DisponibilidadBloc`, que el router armaba a mano, ahora es un `registerFactoryParam`). `test/di/injector_test.dart` comprueba los registros nuevos y que el detalle se arma con el repositorio real.

## 8. Cómo probarla

1. En Supabase → SQL Editor, ejecutar `docs/sql/sprint2_hu13.sql` (después de `sprint2_hu12.sql` y `sprint2_hu17.sql`).
2. Ejecutar `docs/sql/pruebas_hu13_politicas.sql`: todas las filas deben decir `OK` (el único `AVISO` esperado es el de los datos de prueba).
3. En la app, entrar como **Cliente**, buscar un producto (lupa del Home) y abrir un resultado. Pasos y resultados esperados de los tres escenarios en el README, sección "Probar el detalle del precio (HU-13)".
4. `flutter analyze` sin problemas y `flutter test --concurrency=1` en verde.

## 9. Riesgos y pendientes

* **Supabase:** `sprint2_hu13.sql` y `pruebas_hu13_politicas.sql` **ya se ejecutaron en nuestro proyecto y las 18 pruebas dieron `OK`.** La primera corrida encontró un defecto real: `btrim` solo quitaba espacios, así que un motivo en blanco con saltos de línea se guardaba; ahora quita también tabuladores y saltos de línea. En cualquier otra base hay que correr los dos scripts (sin el primero, el botón de reporte falla con "La base de datos no está actualizada").
* **Probado en Android** (informado por el equipo): abrir un detalle, tocar "Reportar precio incorrecto", enviar, y comprobar la fila en `reporte_precio_incorrecto`.
* **Los precios de la comunidad todavía no existen en la base** (hoy solo el comercio escribe `precio_producto`; la HU-15 los traerá). La regla de la comunidad está implementada y probada, pero en una base real solo se verán precios de comercio.
* **Las reglas de confianza (3 y 7 días) son una propuesta nuestra.** Si el profesor o el equipo prefieren otros límites, se cambian en `ConfianzaReglas` y en la tabla de la sección 3.
* La confianza usa el reloj del teléfono.
* **Coordinar con la HU-18:** reutiliza `ConfianzaDelPrecio` junto a cada precio de las alternativas de carrito.
* **Disco:** durante este trabajo el disco del equipo estuvo casi lleno (llegó a menos de 2 GB libres); si `flutter run` falla con "Espacio en disco insuficiente", conviene liberar espacio (por ejemplo `flutter clean`, que borra `build/`).
