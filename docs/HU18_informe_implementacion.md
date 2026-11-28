# Sprint 3 · HU-18 · Alternativas de carrito según el criterio

Informe de implementación. Rama: `feat/hu18-alternativas-carrito`, creada desde `develop` (`3d6b790`, con la HU-19 integrada). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como cliente, quiero elegir qué priorizar (ahorro, calidad/precio o comodidad) y recibir alternativas para mi carrito completo, para decidir la combinación de compra que más me conviene. (Sprint Backlog 3, HU-18, 8 puntos, Must.)

Es la propuesta de valor de SmartCart. Todo sale de datos reales de la base: los productos del carrito, los precios publicados por los comercios aprobados (y por la comunidad, HU-15), sus promociones, su disponibilidad, la ubicación de los comercios y la del cliente (HU-19). No hay precios de ejemplo.

## 2. Alcance implementado

| Criterio de aceptación | Estado | Cómo se cumple |
|---|---|---|
| El carrito muestra el precio vigente (el de la promoción si está vigente), el subtotal de cada línea y el total en COP | Implementado | `PreciosCarritoBloc` lee el precio del producto de cada línea con `ofertas_del_carrito()`; `ValorCarrito` suma con las cantidades que se ven. Un producto sin precio o agotado lo dice y no se suma. |
| Desde el carrito y desde "Comparar" del Home se abre la comparación | Implementado | Botón "Comparar carrito" en el carrito y "Comparar" del Home → `AppRoutes.comparacion`. |
| El cliente elige un criterio y, opcionalmente, una distancia máxima | Implementado | Chips de criterio y de distancia (sin límite, 1, 2, 5, 10 y 20 km). |
| Analiza el carrito completo y reconoce el mismo producto con la regla de la HU-12 | Implementado | `ofertas_del_carrito()` agrupa con `clave_producto()` (código de barras o nombre y marca) y `ComparadorCarrito` decide sobre todas las líneas a la vez. |
| Solo ofertas disponibles de comercios aprobados, con el precio vigente al comparar | Implementado | La función reutiliza `ofertas_publicadas()` (solo aprobados); el comparador descarta las agotadas; las ofertas se leen al abrir la comparación. |
| Ahorro: cada producto donde es más barato. Comodidad: el menor número de establecimientos y, si hay empate, el menor costo | Implementado | `ComparadorCarrito` (búsqueda exacta por tamaño de grupo; ver sección 3). |
| Calidad/precio: combina el precio con la calificación promedio (fórmula en un solo lugar); "Sin calificaciones" | Implementado, **se cierra con la HU-25** | `ComparacionReglas.factorCalidad`. Lee `usuario.calificacion_promedio` y `total_calificaciones` del dueño del comercio, que llena la HU-25. Mientras no haya calificaciones, todos los comercios cuentan como neutros y el detalle dice "Sin calificaciones". |
| Cada alternativa muestra costo total, ahorro, número de establecimientos y distancia; ahorro mínimo $0 | Implementado | Tarjetas de `ComparacionPage`; `Alternativa.ahorro`. |
| Distancia total: suma en línea recta con la función de la HU-14; con distancia máxima solo entran los comercios dentro del radio y los sin ubicación quedan fuera | Implementado | `Ubicacion.distanciaA` (misma fórmula que `distancia_metros`). Sin ubicación del cliente: "No disponible". |
| El detalle muestra los productos por establecimiento con fuente, fecha y confianza (HU-13) | Implementado | `AlternativaDetallePage` con `ConfianzaDelPrecio`, el mapa de la HU-19 y la calificación de cada comercio. |
| Si un producto no está en ninguna alternativa, se avisa cuál y se calcula con los demás | Implementado | Aviso "No encontramos disponible: …". |
| Con el carrito vacío no se genera ninguna alternativa | Implementado | Estado `vacia` con "Explorar productos". |

Los seis escenarios tienen prueba automática y los de la base, prueba SQL. Ver `docs/HU18_informe_pruebas.md`.

**Confirmación:** al integrar la HU-20, el detalle ganó el botón **Elegir esta alternativa**: `Alternativa.seleccion` lleva a la confirmación los productos elegidos y los del carrito que cubre.

## 3. Decisiones (el backlog las deja al equipo)

| Tema | Decisión | Por qué |
|---|---|---|
| Fórmula de Calidad/precio | `precio × (1 + 0,20 × (5 − calificación) / 4)`; sin calificaciones cuenta como 3 | 5 estrellas pesa su precio y 1 estrella un 20 % más: un comercio bien calificado gana con diferencias de precio pequeñas, no con grandes. Un comercio nuevo no se castiga ni se premia. Constantes en `ComparacionReglas`. |
| Ahorro estimado | Total del carrito actual − costo de la alternativa, **sobre los mismos productos** (los que tienen precio en su comercio y la alternativa cubre); nunca negativo | Si un producto del carrito no tiene precio, compararlo inflaría o bajaría el ahorro sin razón. |
| Se muestran las tres alternativas | La del criterio elegido va primero y marcada "Tu criterio" | El cliente ve el contraste (como en el diseño del equipo), sin perder la que pidió. |
| Comodidad exacta | Prueba grupos de 1, 2, 3… comercios y se queda con el primer tamaño que cubre todo y el más barato de ese tamaño | Es exacto. Si un tamaño supera 20 000 grupos (muchos comercios y un carrito muy disperso) usa el método rápido de tomar el comercio que cubre más productos; puede usar un comercio de más y está documentado en el código. |
| Empates | Precio, luego cercanía y luego el comercio | El resultado no depende del orden en que llegan los datos. |
| Un comercio con el mismo producto dos veces | Cuenta la oferta más barata | Puede pasar si el comercio cargó el producto repetido sin código de barras. |
| Distancia máxima sin ubicación | No se deja elegir; se ofrece "Configurar ubicación" (mapa de la HU-19) y al volver se recalcula | El escenario 4 parte de una ubicación configurada. |
| Precios del momento | Las ofertas se leen al abrir la comparación; cambiar criterio o distancia solo recalcula | Es "el precio vigente al momento de comparar" sin volver a la red en cada toque. |
| Promoción vigente | `ofertas_publicadas()` ahora usa la fecha de Colombia | Con `current_date` (UTC) una promoción que terminaba hoy dejaba de valer a las 7:00 p. m. Mismas columnas: la búsqueda (HU-12) y el detalle (HU-13) no cambian. |
| Calificación | Se lee con `to_jsonb(usuario)` | La función funciona aunque las columnas de la HU-25 aún no existan en la base; cuando existan, se leen sin cambiar nada. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint3_hu18.sql` | Corrige la fecha de `ofertas_publicadas()` y crea `ofertas_del_carrito()`. Idempotente. |
| `docs/sql/pruebas_hu18_ofertas.sql` | 10 pruebas: reconocimiento por código y por nombre y marca, comercio pendiente excluido, promoción que termina hoy, orden, agotadas, producto sin ofertas, coordenadas, privacidad y permisos. Termina en `ROLLBACK`. |
| `lib/features/comparacion/domain/` | `OfertaComparable` y `LineaComparable`; `CriterioCompra`, `Alternativa`, `CompraEnComercio`, `ItemAlternativa` y `ResultadoComparacion`; `ComparacionReglas` y `ComparadorCarrito` (algoritmo puro); `PrecioLinea` y `ValorCarrito`; contrato `ComparacionRepository`; `GetOfertasCarritoUseCase` y `CompararCarritoUseCase`. |
| `lib/features/comparacion/data/` | `SupabaseComparacionDataSource` (agrupa las filas por línea) y `ComparacionRepositoryImpl`. |
| `lib/features/comparacion/presentation/` | `ComparacionBloc`, `PreciosCarritoBloc`, `ComparacionPage`, `AlternativaDetallePage` y los formatos de calificación y distancia. |
| `test/comparacion/`, `test/support/fakes_comparacion.dart` | Pruebas y dobles. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/cart/presentation/pages/carrito_page.dart` | Precio, subtotal, total y "Comparar carrito". Pide los precios de nuevo solo cuando entra un producto nuevo. |
| `lib/features/cliente/presentation/cliente_blocs.dart` | `abrirComparacion()`. |
| `lib/features/cliente/presentation/pages/cliente_home_screen.dart`, `lib/features/home/presentation/pages/role_shell.dart` | "Comparar" del Home abre la comparación (antes abría la búsqueda de la HU-12). |
| `lib/features/ubicacion/presentation/widgets/mapa_establecimientos.dart` | Sin radio, encuadra todos los puntos (los comercios de una alternativa). |
| `lib/core/constants/supabase_tables.dart`, `lib/core/routes/app_routes.dart`, `lib/app_router.dart`, `lib/core/di/injector.dart` | Función y columnas, 2 rutas, y 6 registros (139 en total). |
| `test/cart/carrito_page_test.dart` | Su montaje da el `PreciosCarritoBloc` que ahora necesita el carrito. Sus aserciones no cambiaron. |
| `test/cliente/cliente_integracion_test.dart` | La prueba de "Comparar" ahora espera la comparación del carrito, como pide la HU-18. |
| `test/support/pump_helpers.dart`, `test/di/injector_test.dart` | Rutas de apoyo y registros. |

## 5. Arquitectura

Presentación → caso de uso → contrato → repositorio → data source. El algoritmo es Dart puro en el dominio y no conoce Flutter, Supabase ni el mapa. La base entrega las ofertas (con RLS: solo el carrito propio, solo clientes) y la app decide la combinación; así cambiar el criterio no vuelve a la red.

## 6. Cómo probarlo

1. Ejecutar `docs/sql/sprint3_hu18.sql` y luego `docs/sql/pruebas_hu18_ofertas.sql` (todas las filas en `OK`).
2. Datos: dos o más comercios aprobados con ubicación y con el **mismo producto** (mismo código de barras, o mismo nombre y marca) a precios distintos. Sirve `docs/ejemplos/productos_validos.csv` cargado en dos comercios, cambiando algunos precios.
3. Como cliente: agregar varios de esos productos al carrito (desde la búsqueda) y abrir **Carrito** → se ven precios, subtotales y total → **Comparar carrito** (o "Comparar" del Home).

| Escenario | Cómo | Resultado esperado |
|---|---|---|
| 1. Ahorro | Criterio "Mayor ahorro" | Cada producto en su comercio más barato; total y "Ahorras $ …" |
| 2. Comodidad | Criterio "Comodidad" | El menor número de comercios y la distancia total |
| 3. Calidad/precio | Criterio "Calidad/precio" | Combina precio y calificación; el detalle muestra la calificación o "Sin calificaciones" (hasta que exista la HU-25) |
| 4. Distancia máxima | Con ubicación (HU-19), elegir 1 o 2 km | Los comercios más lejanos no aparecen en ninguna alternativa |
| 5. Producto sin disponibilidad | Agregar un producto que solo un comercio tiene y marcarlo agotado allí | "No encontramos disponible: …" y alternativas con el resto |
| 6. Carrito vacío | Vaciar el carrito y tocar "Comparar" | "Tu carrito está vacío" y "Explorar productos" |

## 7. Pendientes y limitaciones

- El SQL ya se ejecutó en Supabase y sus 10 pruebas dan `OK`. **Falta probarla en Android** con datos reales; las pruebas de Flutter usan dobles.
- **Calidad/precio depende de la HU-25** (calificaciones). Está implementado y probado con calificaciones de prueba; con datos reales se cierra cuando la HU-25 guarde `calificacion_promedio` y `total_calificaciones` en `usuario`. Si la HU-25 decide guardarlas en otro lugar, solo cambia la consulta de `ofertas_del_carrito()`.
- Confirmar la compra y generar las órdenes es de la HU-20.
- La distancia es en línea recta (como pide el backlog), no por calles.
- Dos líneas del carrito con el mismo producto de comercios distintos se comparan como líneas separadas.
