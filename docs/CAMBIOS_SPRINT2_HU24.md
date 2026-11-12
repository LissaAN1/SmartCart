# Cambios del Sprint 2 · HU-24 · Aprobación de comercios y repartidores

El administrador revisa las solicitudes pendientes de comercios (HU-07) y
repartidores (HU-08), las aprueba o las rechaza con un motivo, y el solicitante
recibe una notificación con la decisión. Rutas relativas a la raíz del proyecto.

## 1. Verificación

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | Sin problemas |
| `flutter test` | **167 pruebas, todas pasan** (antes 127; se agregaron 40) |
| Probado contra Supabase real | **No.** El `.env` está vacío. Ver sección 5 |

## 2. Criterios de aceptación

| Criterio | Cómo se cumple |
|---|---|
| El administrador ve la lista de solicitudes pendientes | `AdminSolicitudesPage`: pestañas Comercios y Repartidores. Se abre desde la pestaña "Aprobar", el acceso rápido "Aprobaciones" y el aviso "Acción requerida" del panel. |
| Aprobar o rechazar; al rechazar debe indicar un motivo | `SolicitudDetallePage` con los botones Aprobar (pide confirmación) y Rechazar (diálogo con el motivo obligatorio). El motivo lo valida `AprobacionValidators` en la UI, en el caso de uso y en la función SQL. |
| El solicitante recibe una notificación con la decisión | `decidir_solicitud` inserta en `notificacion` en la misma transacción. Al entrar a la app, `AvisoNotificaciones` muestra las no leídas y las marca como leídas. |
| Solo el administrador cambia el estado (RLS) | Políticas `*_admin` basadas en `es_administrador()`. El dueño ya no tenía permiso para cambiar el estado (HU-07/08). El caso de uso también lo comprueba para dar un mensaje claro. |
| La lista se carga por páginas | Reutiliza `PaginatedBloc` y `PaginatedListView` (20 por página, con `range`). |

## 3. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu24.sql` | `es_administrador()`, columnas `creado_en`/`decidido_en`/`motivo_rechazo`, políticas del administrador, tabla `notificacion` con su RLS y la función `decidir_solicitud`. |
| `docs/sql/pruebas_hu24_politicas.sql` | Prueba de las políticas de permisos (escenarios 1, 2 y 3) simulando sesiones. Termina en `ROLLBACK`, así que no deja datos. |
| `lib/features/aprobaciones/domain/entities/solicitud.dart` | `Solicitud` y `TipoSolicitud`. |
| `lib/features/aprobaciones/domain/repository/solicitudes_repository.dart` | Contrato. |
| `lib/features/aprobaciones/domain/validators/aprobacion_validators.dart` | Motivo obligatorio (10 a 300 caracteres). |
| `lib/features/aprobaciones/domain/usecases/get_solicitudes_pendientes_usecase.dart` | Página de pendientes por tipo. |
| `lib/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart` | `aprobar` / `rechazar`: valida el motivo y que quien decide sea administrador. |
| `lib/features/aprobaciones/data/source/supabase_solicitudes_data_source.dart` | Lee `comercio` y `perfil_repartidor` pendientes, más los datos de `usuario`, y llama al RPC `decidir_solicitud`. |
| `lib/features/aprobaciones/data/repository/solicitudes_repository_impl.dart` | Implementación. |
| `lib/features/aprobaciones/presentation/bloc/decision_solicitud_*.dart` | Bloc del detalle (evita el doble envío). |
| `lib/features/aprobaciones/presentation/pages/admin_solicitudes_page.dart` | Lista paginada con pestañas. |
| `lib/features/aprobaciones/presentation/pages/solicitud_detalle_page.dart` | Detalle con Aprobar/Rechazar. |
| `lib/features/aprobaciones/presentation/widgets/solicitud_card.dart` | Fila de la lista. |
| `lib/features/aprobaciones/presentation/widgets/motivo_rechazo_dialog.dart` | Diálogo del motivo. |
| `lib/features/notificaciones/**` | Entidad, contrato, data source, repositorio, 2 casos de uso, `NotificacionesBloc` y `AvisoNotificaciones`. |
| `test/aprobaciones/decidir_solicitud_test.dart` | Validador, caso de uso (los 3 escenarios, incluyendo cada rol que no es administrador), Bloc y paginación. |
| `test/aprobaciones/aprobaciones_flow_test.dart` | Pantallas: lista, pestañas, vacío, reintento, aprobar, cancelar, rechazar sin motivo y con motivo, sin permiso, y acceso desde el panel. |
| `test/notificaciones/notificaciones_test.dart` | Aviso al entrar, motivo, varias notificaciones, marcar como leídas y errores. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/constants/supabase_tables.dart` | Tabla `notificacion`, sus columnas, `creado_en` y `SupabaseFunctions.decidirSolicitud`. |
| `lib/core/routes/app_routes.dart` | Rutas `adminSolicitudes` y `adminSolicitudDetalle`. |
| `lib/app_router.dart` | Las dos rutas nuevas (el detalle es `MaterialPageRoute<ApprovalStatus>`), y el Home envuelto en `AvisoNotificaciones` con su `NotificacionesBloc`. |
| `lib/core/di/injector.dart` | Registros nuevos. Los Bloc que necesitan un dato usan `registerFactoryParam` (`sl<DecisionSolicitudBloc>(param1: solicitud)`). |
| `lib/features/auth/data/source/supabase_error_mapper.dart` | Mensajes para `P0002` (ya decidida) y `22023` (dato inválido). |
| `lib/features/comercio/data/source/supabase_comercio_data_source.dart` | La conversión fila → `Comercio` pasó a ser la función pública `comercioFromRow` para reutilizarla. Mismo comportamiento. |
| `lib/features/home/presentation/pages/role_shell.dart` | La pestaña "Aprobar" del administrador abre las solicitudes. |
| `lib/features/admin/presentation/pages/admin_home_screen.dart` | "Aprobaciones" y "Acción requerida" abren las solicitudes. Se quitaron los contadores falsos ("12") porque ya existe la lista real. |
| `lib/features/admin/presentation/pages/admin_perfil_screen.dart` | Sin el contador falso en la barra. |
| `test/support/fakes.dart`, `test/support/pump_helpers.dart`, `test/di/injector_test.dart` | Dobles y registros nuevos. |

## 4. Decisiones de diseño

- **Una función SQL para decidir.** `decidir_solicitud` cambia el estado y crea
  la notificación en una sola transacción: no puede quedar un comercio aprobado
  sin aviso. Es `security invoker`, así que las políticas RLS se aplican igual.
- **Solo decide lo pendiente.** Si otro administrador ya decidió la solicitud,
  la función responde `P0002` y la app muestra "Esta solicitud ya fue revisada".
- **El notificado no puede editar sus avisos**: solo la columna `leida`
  (`grant update (leida)`).
- **Las notificaciones se muestran al entrar al Home.** Si una lectura falla, no
  bloquea a la persona y el error queda en el log.

## 5. Pendientes y riesgos

- **Ejecutar en Supabase**, en orden: `sprint2_hu06_07_08.sql` (si no se ha
  hecho), luego `sprint2_hu24.sql` y después `pruebas_hu24_politicas.sql` para
  comprobar las políticas.
- **Completar el `.env`**: hoy está vacío y la app no puede conectarse.
- El administrador se asigna a mano en `usuario_rol` (no se puede auto-registrar).
- La decisión llega cuando el solicitante vuelve a entrar al Home. No hay
  notificaciones push ni en tiempo real.
- Un comercio rechazado no puede volver a enviar su registro desde la app
  (fuera del alcance de esta HU).

## 6. Cómo probarlo a mano

1. Registra un comercio y un repartidor (quedan pendientes).
2. Entra como administrador, pestaña **Aprobar** → pestaña **Comercios** → abre el
   comercio → **Aprobar** → confirma. Vuelve a la lista y el comercio ya no está.
3. Pestaña **Repartidores** → abre el repartidor → **Rechazar** → presiona
   Rechazar sin motivo (pide el motivo) → escribe el motivo → Rechazar.
4. Entra como el comercio: aparece "Tu comercio fue aprobado" y luego su panel.
   Entra como el repartidor: aparece el rechazo con el motivo.
