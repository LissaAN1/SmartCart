# Sprint 3 · HU-20 y HU-25 · Confirmación del carrito, órdenes y calificaciones

Informe de implementación. Rama: `feature/hu20-hu25`. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> **HU-20.** Como cliente, quiero confirmar mi carrito eligiendo recogida o entrega por comercio, para que se generen mis órdenes.
> **HU-25.** Como cliente, quiero calificar al comercio y al repartidor de una orden completada, para que otros conozcan su servicio.

## 2. Alcance implementado

### HU-20

| Criterio | Estado | Cómo se cumple |
|---|---|---|
| Elegir recogida o entrega por comercio; entrega solo donde se ofrece | Implementado | `ConfirmarCompraPage`: la opción "Entrega a domicilio" solo aparece en comercios cuyo `servicio` es entrega o ambos. Se valida en `ComprasReglas`, en `ConfirmarCompraUseCase` y en `confirmar_compra()` (base). |
| Confirmar genera una compra con una orden por comercio registrado | Implementado | `confirmar_compra()` crea la `compra` y una `orden` por comercio, con sus `orden_item` y los precios de hoy. |
| Establecimientos sin registro → lista de compra | Implementado en la app | `PlanCompra.agrupar` los separa; `CompraConfirmadaPage` muestra su lista. Ver supuesto 3. |
| Cada orden nace "Orden generada" | Implementado | `orden.estado` por defecto y `OrdenGenerada.estado`. |
| No se confirma un carrito vacío | Implementado | `GetPlanCompraUseCase`, `ComprasReglas` y la función SQL. |
| Pantallas de recogida/entrega y de confirmación con lista de compra | Implementado | `ConfirmarCompraPage` y `CompraConfirmadaPage`; botón "Confirmar compra" en `CarritoPage`. |
| Tablas con RLS | Implementado | `compra`, `orden`, `orden_item` (solo lectura propia; las escrituras pasan por la función). |
| Caso de uso que divide el carrito por comercio | Implementado | `GetPlanCompraUseCase` + `PlanCompra.agrupar` (dominio puro). |

### HU-25

| Criterio | Estado | Cómo se cumple |
|---|---|---|
| Solo el cliente de una orden completada califica | Implementado | `Orden.puedeCalificar*` (la lista solo ofrece el botón en órdenes recogidas/entregadas) y `calificar_orden()` (base). |
| 1 a 5 estrellas y comentario opcional | Implementado | `CalificacionReglas` (rango y máximo 500 caracteres), `CalificarOrdenPage`, `check` en la tabla. |
| Una vez por orden | Implementado | Restricción única `(id_orden, tipo)` y mensaje "Ya calificaste esta orden." |
| Promedio visible en el perfil del comercio; "Sin calificaciones" si no hay | Implementado | `ComercioPerfilScreen` muestra `profile.rating` / `ratingCount`. |
| Tabla con restricción de una por orden | Implementado | `calificacion` (ver `docs/sql/sprint3_hu20_hu25.sql`). |

## 3. Supuestos que tomamos (el backlog no los define)

1. **Qué se confirma.** El carrito tal cual (cada producto de su comercio) o la alternativa elegida en la comparación (HU-18), desde el botón "Elegir esta alternativa" de su detalle.
2. **Estados de la orden.** `EstadoOrden` define los ocho estados; las transiciones (aceptar, preparar, entregar...) son de la HU-21. Las órdenes de esta HU solo nacen "Orden generada".
3. **Establecimientos sin registro.** El carrito de hoy solo contiene productos de comercios registrados, así que ninguna fuente de datos los produce todavía. La lógica (división, lista de compra y su pantalla) está en el dominio y probada, pero sin una fuente real hasta que HU-18/19 los traigan.
4. **Repartidor.** `orden.id_repartidor` es nulo hasta que la HU-22 lo asigne. La calificación al repartidor existe y se ofrece solo cuando la orden tiene uno.
5. **"Mis órdenes" mínima.** Se creó una lista paginada simple (`MisOrdenesPage`, accesible desde "Historial de compras" del Perfil) para que calificar sea alcanzable. Se solapa con la HU-23; allí se puede ampliar (filtros, detalle).
6. **Dónde se guarda el promedio.** En `usuario.calificacion_promedio` y `total_calificaciones`, que la app ya leía como `Profile.rating`. Limitación: una cuenta que sea a la vez dueña de comercio y repartidora mezclaría ambas calificaciones.
7. **Notificar al comercio** de la nueva orden es de la HU-21.
8. **Destino de la entrega.** La ubicación guardada del cliente (HU-19), como pide el criterio de aceptación; la orden guarda sus coordenadas y la dirección, si la escribió. Sin ubicación no se puede pedir entrega.

## 4. Arquitectura

```
lib/features/orders/
  domain/   entities (EstadoOrden, TipoEntrega, PlanCompra, Orden...), ComprasReglas,
            ComprasRepository, GetPlanCompra/ConfirmarCompra/GetMisOrdenes usecases
  data/     SupabaseComprasDataSource (único que conoce Supabase), ComprasRepositoryImpl
  presentation/ ConfirmarCompraBloc, ConfirmarCompraPage, CompraConfirmadaPage, MisOrdenesPage
lib/features/calificaciones/
  domain/   CalificacionReglas, TipoCalificacion, ResumenCalificaciones,
            CalificacionesRepository, CalificarOrdenUseCase
  data/     SupabaseCalificacionesDataSource, CalificacionesRepositoryImpl
  presentation/ CalificarOrdenBloc, CalificarOrdenPage, CalificarOrdenArgs
```

- El dominio es Dart puro; los casos de uso usan `GetClienteActivoUseCase` y `GetCarritoUseCase`.
- Los errores de Supabase se traducen a `AuthFailure` en el data source; los mensajes de la base van en español y se muestran tal cual.
- Las reglas (`ComprasReglas`, `CalificacionReglas`) están en Dart y en SQL con los mismos textos: **si cambias una, cámbiala en los dos lados.**
- Solo `injector.dart` y `app_router.dart` usan `sl<>`; los Blocs son fábricas; la lista de órdenes usa `PaginatedBloc<Orden>`.
- Rutas nuevas: `confirmarCompra`, `misOrdenes`, `calificarOrden` (esta devuelve `bool`).

## 5. Base de datos

1. Ejecutar `docs/sql/sprint3_hu20_hu25.sql` en el SQL Editor de Supabase. Crea `compra`, `orden`, `orden_item`, `calificacion`, sus políticas RLS y las funciones `previsualizar_compra`, `confirmar_compra`, `mis_ordenes` y `calificar_orden` (SECURITY DEFINER, con `execute` solo para `authenticated`).
2. Después, `docs/sql/pruebas_hu20_hu25_politicas.sql`: simula roles dentro de una transacción con `rollback` y devuelve una tabla de resultados; todas las filas deben decir OK. En nuestro proyecto se ejecutaron el 28 de noviembre y las 48 pruebas dieron `OK`.

## 6. Pruebas

| Comando | Resultado |
|---|---|
| `dart analyze lib test` | Sin problemas |
| `flutter test` | 984 pruebas, todas pasan (901 antes de estas HU) |

Pruebas nuevas (83): `test/orders/compras_dominio_test.dart` (reglas, división por comercio, generación de órdenes, entrega, lista de compra, carrito vacío), `test/orders/confirmar_compra_flow_test.dart` (Bloc y pantallas), `test/calificaciones/calificaciones_dominio_test.dart` (rango de estrellas y promedio), `test/calificaciones/calificar_orden_flow_test.dart` (Bloc, pantalla, Mis órdenes y perfil del comercio), más DI y navegación. Una de las pruebas de pantalla encontró un desborde real en una fila de Mis órdenes, ya corregido.

## 7. Revisión al integrar con `develop` (28 nov)

Al unir la rama con las HU-18 y HU-19 se resolvieron conflictos en `app_router.dart`, `app_routes.dart` y `role_shell.dart`, y se corrigió:

| Hallazgo | Corrección |
|---|---|
| La entrega pedía una dirección escrita; el backlog pide la ubicación guardada (HU-19) y bloquear sin ella (escenario 3) | `confirmar_compra()` toma el destino de `ubicacion_cliente`; la app muestra el destino o "Configurar ubicación" |
| La confirmación no mostraba la lista de compra por comercio | Cada orden lista sus productos |
| No había forma de confirmar una alternativa (precondición HU-18) | "Elegir esta alternativa" y `p_quitar_del_carrito` para sacar del carrito lo que cubre |
| La promoción se decidía con `current_date` (UTC) y podía diferir del precio de la comparación | Fecha de Colombia en `lineas_compra()` |
| Los precios se leían varias veces durante la confirmación | Se resuelven una sola vez por compra |
| Un comercio podía escribir su propia calificación en `usuario` | Trigger `usuario_proteger_calificacion` |
| Las columnas del promedio no se creaban si faltaban | `add column if not exists` |
| "Atrás" tras confirmar volvía a pantallas con el carrito anterior | Lleva al inicio |
| Una prueba montaba el carrito sin los precios de la HU-18 | Se actualizó su montaje |

**Pruebas tras la integración:** `flutter analyze` sin problemas y `flutter test --concurrency=1` con 1071 pruebas aprobadas y 0 fallidas. La sección 6 describe la medición anterior en la rama. El SQL con estos cambios se ejecutó en Supabase y `pruebas_hu20_hu25_politicas.sql` dio las 48 filas en `OK`. **Falta la prueba en Android.**
