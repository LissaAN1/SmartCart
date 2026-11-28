# Sprint 3 · HU-23 · Seguimiento y notificaciones de órdenes

Informe de implementación. Rama: `feat/hu23-seguimiento-ordenes`, creada desde `develop` porque necesita las órdenes de la HU-20. Rutas relativas a la raíz del proyecto. El diseño sigue las pantallas 15 ("Mis órdenes") y 16 ("Detalle de orden") del prototipo del cliente en Visily.

## 1. Objetivo

> Como cliente, quiero consultar el estado de mis órdenes y recibir notificaciones cuando cambie para saber cuándo recoger o recibir mi compra. (Sprint Backlog 3, HU-23, 3 puntos.)

## 2. Alcance implementado

| Criterio de aceptación | Estado | Cómo se cumple |
|---|---|---|
| El cliente ve la lista de sus órdenes con su estado, incluidos "En camino" y "Entregada" cuando hay repartidor | Implementado | `MisOrdenesPage` con pestañas **En curso** (con el número de órdenes) e **Historial**; cada tarjeta muestra el estado y una barra de progreso (Preparando · Listo · Recogida, o Preparando · Listo · En camino · Entregada si es entrega). |
| Recibe una notificación cuando el estado cambia, en especial cuando está lista para recoger | Implementado | Trigger `orden_estado_historial` (sprint3_hu23.sql): cada cambio de `orden.estado` escribe un aviso en `notificacion` con un texto por estado ("¡Tu orden #105 está lista para recoger!"). Funciona con quien cambie el estado: el comercio (HU-21) o el repartidor (HU-22). |
| La notificación se envía como push y el aviso también se ve dentro de la app | Implementado (push requiere configurar Firebase, ver §5) | **Push:** la Edge Function `supabase/functions/enviar-push` envía el aviso por Firebase Cloud Messaging a los teléfonos del cliente (`dispositivo_push`). **Dentro de la app:** el diálogo de avisos de la HU-24 al entrar al Home, el mismo diálogo si el push llega con la app abierta, y el aviso destacado "¡Tu orden #105 está lista!" en Mis órdenes. Tocar la notificación del sistema abre Mis órdenes. |
| Puede confirmar la recogida o la recepción de la orden | Implementado | Botón **Confirmar recogida** (orden con recogida, lista para recoger) o **Confirmar recepción** (orden entregada) en el detalle; `confirmar_recepcion()` cierra la orden (`cerrada_en`) y la pasa al historial. |
| Si no tiene órdenes, se muestra un mensaje | Implementado | "Aún no tienes órdenes" (escenario 3). |
| La lista de órdenes se carga por páginas | Implementado | `OrdenesClienteBloc` (un `PaginatedBloc<Orden>`) + `ordenes_cliente()` con límite y desplazamiento. |

Los tres escenarios tienen prueba automática: 1 (aviso al cambiar a "Lista para recoger": `pruebas_hu23_politicas.sql` A2 y el diálogo dentro de la app), 2 (confirmar la recepción cierra la orden: casos de uso, Bloc, pantalla y B4/B9 en SQL) y 3 ("Aún no tienes órdenes").

## 3. Decisiones (el backlog no las define)

| Tema | Decisión | Por qué |
|---|---|---|
| ¿Quién escribe el aviso? | Un trigger en la base, no la app. | Así la HU-21 y la HU-22 no tienen que acordarse de avisar, y no se puede saltar. |
| Aviso por la propia acción | Si el cliente confirma la recogida, no se le avisa a sí mismo. | Sería ruido. |
| "En curso" vs. "Historial" | En curso: sin cerrar y no rechazada. Historial: cerrada por el cliente o rechazada. | Una orden entregada sigue "en curso" hasta que el cliente confirma, así el botón queda a la vista. |
| Confirmar la recogida | Pasa la orden a "Recogida" y la cierra. Una entrega solo se confirma cuando el repartidor la marcó "Entregada" (HU-22). | El backlog: "puede confirmar la recogida o la recepción". |
| Código de recogida | `SC-<número de la orden>`. | El comercio ve el mismo número en su lista (HU-21); no hace falta otra columna. |
| Historial de estados | Tabla `orden_estado` llenada por trigger, con la hora de cada paso. | El diseño muestra la línea de tiempo con horas. |
| Pantalla de Mis órdenes | Se rediseñó la de la HU-20 (no se creó otra), conservando los botones de calificar de la HU-25. | Evita dos pantallas de órdenes. |
| Push sin Firebase configurado | La app no falla: `activar()` devuelve `null` y quedan los avisos dentro de la app. | Firebase necesita archivos que cada equipo genera con su cuenta. |
| Token de Firebase | `getToken`/`onTokenRefresh` (marcados como obsoletos en favor de `register`/`onRegistered`). | La Edge Function usa la API HTTP v1 con el token de registro; la API nueva entrega otro identificador. Está comentado en el código. |

**Fuera de alcance:** "Repetir pedido" y "¿Problemas con la orden?" del prototipo (no son criterios de la HU-23); el botón "Ver en Google Maps" se reemplazó por el mapa de la HU-19 dentro de la tarjeta de la tienda.

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint3_hu23.sql` | `orden.cerrada_en`, `orden_estado` + trigger, aviso en `notificacion`, `confirmar_recepcion()`, `ordenes_cliente()`, `ordenes_en_curso()`, `detalle_orden()`, `dispositivo_push`, `registrar_dispositivo()` y `quitar_dispositivo()`. Idempotente. |
| `docs/sql/pruebas_hu23_politicas.sql` | Pruebas en una transacción con `rollback`: historial, avisos, confirmar (recogida y entrega), no confirmar dos veces, el cliente no cambia el estado a mano, tokens, otro usuario y sin sesión. |
| `supabase/functions/enviar-push/index.ts` | Edge Function: recibe el webhook de `notificacion`, firma el token de Google con la cuenta de servicio y envía por FCM HTTP v1; borra tokens vencidos. |
| `lib/features/seguimiento/domain/` | `SeguimientoReglas` (pasos, progreso, cuándo se puede confirmar, código), `DetalleOrden`, contratos `SeguimientoRepository`, `DispositivosRepository` y `NotificacionesPush`, y los casos de uso. |
| `lib/features/seguimiento/data/` | `SupabaseSeguimientoDataSource`, los repositorios y `FirebaseNotificacionesPush` (la única clase que conoce Firebase). |
| `lib/features/seguimiento/presentation/` | `OrdenesClienteBloc`, `ConteoOrdenesBloc`, `DetalleOrdenBloc`, `PushBloc`, `DetalleOrdenPage`, `AvisosPush` y los widgets de la tarjeta, la barra de pasos y el aviso. |
| `test/seguimiento/`, `test/support/fakes_seguimiento.dart` | Pruebas de reglas, casos de uso, Blocs y pantallas (incluye 320 px). |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/features/orders/presentation/pages/mis_ordenes_page.dart` | Rediseño con pestañas, aviso, tarjetas con progreso y acceso al detalle. Conserva calificar (HU-25). |
| `lib/features/orders/domain/entities/orden.dart` | Campos opcionales `actualizadoEn`, `cerradaEn` y `productos`. |
| `lib/app_router.dart`, `lib/core/routes/app_routes.dart`, `lib/core/di/injector.dart` | Ruta `/cliente/ordenes/detalle`, `PushBloc` en el Home del cliente y registro de dependencias. |
| `lib/core/constants/supabase_tables.dart` | Funciones, tablas y columnas de la HU-23. |
| `pubspec.yaml` | `firebase_core` y `firebase_messaging`. |
| `test/calificaciones/calificar_orden_flow_test.dart`, `test/di/injector_test.dart` | Textos de la tarjeta nueva y registro de la HU-23. |

## 5. Cómo ponerla en marcha

### Base de datos
1. En Supabase → SQL Editor, ejecutar `docs/sql/sprint3_hu23.sql` (después de `sprint3_hu20_hu25.sql`).
2. Ejecutar `docs/sql/pruebas_hu23_politicas.sql`: todas las filas deben decir "OK".

Con esto ya funcionan la lista, el detalle, la confirmación y los avisos dentro de la app.

### Notificaciones push (Firebase)
1. **Proyecto de Firebase:** en https://console.firebase.google.com crear un proyecto y agregar la app Android con el paquete `com.example.smartcart`. Lo más simple es correr `flutterfire configure` en la raíz del proyecto: descarga `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) y activa el plugin de Google Services en Gradle. Sin esos archivos la app compila y funciona, pero sin push.
2. **iOS:** subir la llave APNs a Firebase (Configuración del proyecto → Cloud Messaging) y activar *Push Notifications* y *Background Modes → Remote notifications* en Xcode.
3. **Cuenta de servicio:** Firebase → Configuración del proyecto → Cuentas de servicio → *Generar nueva clave privada* (un JSON). No se sube al repositorio.
4. **Edge Function:** con la CLI de Supabase,
   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat cuenta-servicio.json)" WEBHOOK_SECRET=<un-texto-secreto>
   supabase functions deploy enviar-push --no-verify-jwt
   ```
5. **Webhook:** Supabase → Database → Webhooks → *Create a new hook*: tabla `notificacion`, evento **Insert**, tipo **Supabase Edge Functions** → `enviar-push`, y el encabezado `x-webhook-secret` con el mismo texto del paso 4.
6. Entrar como cliente en un teléfono, aceptar el permiso de notificaciones y cambiar el estado de una orden (como lo hará la HU-21). Llega el push; tocarlo abre Mis órdenes.

### Probar sin la HU-21
Mientras no exista la pantalla del comercio, el estado se puede cambiar desde el SQL Editor, por ejemplo:
```sql
update public.orden set estado = 'lista_para_recoger' where numero = 105;
```

`flutter analyze` sin problemas y `flutter test` con todas las pruebas en verde.
