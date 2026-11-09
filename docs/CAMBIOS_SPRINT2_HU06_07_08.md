# Cambios del Sprint 2 · HU-06, HU-07 y HU-08

Registro de todo lo que se creó o modificó para el onboarding del colaborador
(HU-06), el registro de comercio (HU-07) y el registro de repartidor (HU-08).
Rutas relativas a la raíz del proyecto. Rama de trabajo: `feat/register_Validation`.

## 1. Resultado de la verificación

| Comprobación | Resultado |
|---|---|
| `dart analyze lib test` | Sin problemas |
| `flutter test` | **127 pruebas, todas pasan** (antes eran 82; se agregaron 45) |
| Probado contra Supabase real | **No.** Ver "Pendientes y riesgos" |

### Hallazgos al revisar el registro existente

1. **El host de Supabase del `.env` no existe.** `SUPABASE_URL` apunta a un
   dominio que no resuelve (DNS: "el nombre no existe"). O el proyecto fue
   eliminado/pausado, o la URL tiene un error de digitación. Con ese `.env` la
   app no puede registrar ni iniciar sesión. Hay que confirmar la URL en
   Supabase → Project Settings → API.
2. **El flujo de registro existente es correcto** (`SignUpUseCase`: crea la
   cuenta, inserta `usuario` y `usuario_rol`, y `perfil_colaborador` si el rol es
   colaborador), pero **no cubría** HU-06, HU-07 ni HU-08: el cliente tenía un
   interruptor "Modo Colaborador" que solo cambiaba una variable local, el comercio
   no tenía formulario ni estado de aprobación, y el repartidor no tenía estado.
3. **Bug real encontrado por las pruebas:** `AppRouter` creaba todas las rutas
   como `MaterialPageRoute<void>`, lo que impide que una pantalla devuelva un
   resultado tipado (`Navigator.pop(context, profile)`). El onboarding del
   colaborador lo necesita; se corrigió (ver `lib/app_router.dart`).
4. El repositorio no incluye el esquema de la base de datos. Las columnas de
   `comercio` y la tabla `perfil_repartidor` se **definieron** (no se
   verificaron contra el proyecto real). Ver sección 4.

## 2. Componentes de página nuevos (aviso)

Pediste avisar cuando se necesitara un componente de página nuevo. Se crearon:

| Página / widget | Ruta | Para qué |
|---|---|---|
| `ColaboradorOnboardingPage` | `lib/features/colaborador/presentation/pages/colaborador_onboarding_page.dart` | HU-06. Guía corta de cómo reportar un precio + condiciones de uso con casilla y botón "Activar". Una sola pantalla con dos pasos. |
| `ComercioRegistroPage` | `lib/features/comercio/presentation/pages/comercio_registro_page.dart` | HU-07. Formulario: nombre, teléfono, dirección, ciudad/barrio, horario (apertura y cierre con selector de hora) y tipo de servicio. |
| `ComercioEstadoPage` | `lib/features/comercio/presentation/pages/comercio_estado_page.dart` | HU-07. Mensaje de "registro en revisión" (o rechazado, con motivo), datos enviados, botón "Actualizar estado" y cerrar sesión. |
| `ComercioGate` (widget) | `lib/features/comercio/presentation/widgets/comercio_gate.dart` | HU-07. Decide qué ve el comercio al entrar: formulario, estado o su panel. |

No se necesitó una pantalla nueva para HU-08: el estado del repartidor se
muestra dentro de su Home y su Perfil existentes.

## 3. Archivos creados y modificados

### HU-06 · Onboarding del colaborador

| Acción | Archivo | Qué hace / qué cambió |
|---|---|---|
| Creado | `lib/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart` | Caso de uso `ActivarModoColaboradorUseCase`: exige aceptar condiciones y sesión iniciada con rol cliente; si ya es colaborador no hace nada (no duplica); si no, crea `perfil_colaborador` (0 puntos, nivel 1, reputación 0) y agrega el rol `colaborador` conservando `cliente`. Devuelve el perfil actualizado. |
| Creado | `lib/features/auth/domain/entities/collaborator_stats.dart` | Entidad `CollaboratorStats` (puntos, nivel, reputación) con los valores iniciales. |
| Creado | `lib/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart` | `ColaboradorOnboardingBloc`. |
| Creado | `lib/features/colaborador/presentation/bloc/colaborador_onboarding_event.dart` | Eventos `TermsToggled` y `ActivationSubmitted`. |
| Creado | `lib/features/colaborador/presentation/bloc/colaborador_onboarding_state.dart` | Estado (`initial/loading/success/failure`, condiciones aceptadas, error). |
| Creado | `lib/features/colaborador/presentation/pages/colaborador_onboarding_page.dart` | Página nueva (ver sección 2). |
| Modificado | `lib/features/auth/domain/entities/profile.dart` | `Profile` ahora trae `collaborator` (`CollaboratorStats?`) y `courierStatus` (`ApprovalStatus?`). |
| Modificado | `lib/features/auth/domain/repository/profile_repository.dart` | Contrato: `activateCollaboratorMode` y `createCourierProfile`. |
| Modificado | `lib/features/auth/data/repository/profile_repository_impl.dart` | Delega los dos métodos nuevos. |
| Modificado | `lib/features/auth/data/source/supabase_profile_data_source.dart` | Implementa `activateCollaboratorMode` (comprueba antes de insertar, así se puede reintentar sin duplicar), `createCourierProfile`, y `getProfile` ahora lee puntos/nivel/reputación y el estado del repartidor. Si esas lecturas extra fallan no impiden entrar (el repartidor queda pendiente). |
| Modificado | `lib/features/cliente/presentation/pages/cliente_perfil_screen.dart` | El interruptor local fue reemplazado: si no es colaborador muestra "Activar modo Colaborador"; si ya lo es, oculta la opción y muestra Puntos, Nivel y Reputación. Pasó de `StatefulWidget` a `StatelessWidget`. |
| Modificado | `lib/features/colaborador/presentation/pages/colaborador_perfil_screen.dart` | Las estadísticas dejaron de ser datos de ejemplo fijos: ahora son Puntos, Nivel y Reputación reales. |

### HU-07 · Registro de comercio

| Acción | Archivo | Qué hace |
|---|---|---|
| Creado | `lib/features/comercio/domain/entities/comercio.dart` | `Comercio`, `ComercioDatos` y `ServicioComercio` (recogida / entrega / ambos). |
| Creado | `lib/features/comercio/domain/repository/comercio_repository.dart` | Contrato `ComercioRepository`. |
| Creado | `lib/features/comercio/domain/validators/comercio_validators.dart` | Validaciones del formulario (campos obligatorios, teléfono, formato HH:mm, cierre posterior a apertura, servicio elegido). |
| Creado | `lib/features/comercio/domain/usecases/registrar_comercio_usecase.dart` | `RegistrarComercioUseCase`: valida, guarda con estado `pendiente`; si ya tiene comercio devuelve ese. |
| Creado | `lib/features/comercio/domain/usecases/get_mi_comercio_usecase.dart` | `GetMiComercioUseCase`. |
| Creado | `lib/features/comercio/data/source/supabase_comercio_data_source.dart` | Único archivo que lee/escribe la tabla `comercio`; filtra siempre por el id del dueño. |
| Creado | `lib/features/comercio/data/repository/comercio_repository_impl.dart` | `ComercioRepositoryImpl`. |
| Creado | `lib/features/comercio/presentation/bloc/comercio_bloc.dart` | `ComercioBloc` (leer y registrar). |
| Creado | `lib/features/comercio/presentation/bloc/comercio_event.dart` | `ComercioStarted`, `ComercioSubmitted`. |
| Creado | `lib/features/comercio/presentation/bloc/comercio_state.dart` | Estado del comercio. |
| Creado | `lib/features/comercio/presentation/pages/comercio_registro_page.dart` | Página nueva (sección 2). |
| Creado | `lib/features/comercio/presentation/pages/comercio_estado_page.dart` | Página nueva (sección 2). |
| Creado | `lib/features/comercio/presentation/widgets/comercio_gate.dart` | Widget nuevo (sección 2). |

### HU-08 · Registro de repartidor

| Acción | Archivo | Qué hace / qué cambió |
|---|---|---|
| Creado | `lib/core/domain/approval_status.dart` | Enum `ApprovalStatus` (`pendiente`, `aprobado`, `rechazado`), compartido por comercio y repartidor (y por HU-24). |
| Modificado | `lib/features/auth/domain/usecases/sign_up_usecase.dart` | Al registrarse como repartidor crea su fila `perfil_repartidor` en estado pendiente; el `Profile` devuelto trae `courierStatus = pendiente`. También deja el colaborador con sus valores iniciales. |
| Modificado | `lib/features/repartidor/presentation/pages/repartidor_home_screen.dart` | Nuevo parámetro `estado`. Si no está aprobado, no muestra la disponibilidad ni los pedidos: muestra "Tu registro será revisado por el administrador" (o el aviso de rechazo). |
| Modificado | `lib/features/repartidor/presentation/pages/repartidor_perfil_screen.dart` | Nuevo parámetro `estado`; muestra la etiqueta Pendiente / Aprobado / Rechazado. No existe opción de disponibilidad en el perfil. |

### Integración común

| Acción | Archivo | Qué cambió |
|---|---|---|
| Modificado | `lib/core/constants/supabase_tables.dart` | Tabla `perfilRepartidor` y columnas de `perfil_repartidor` y `comercio`. |
| Modificado | `lib/core/routes/app_routes.dart` | Ruta `colaboradorOnboarding`. |
| Modificado | `lib/app_router.dart` | Ruta del onboarding (tipada `MaterialPageRoute<Profile>` para devolver el perfil), y la ruta Home ahora provee también `ComercioBloc` cuando el rol es comercio. |
| Modificado | `lib/core/di/injector.dart` | Registra el data source, repositorio, casos de uso y Blocs nuevos. |
| Modificado | `lib/features/home/presentation/pages/role_shell.dart` | Guarda su propia copia del perfil (cambia al activar el modo Colaborador), abre el onboarding y recibe su resultado, envuelve el Home del comercio en `ComercioGate`, y pasa el estado del repartidor y las estadísticas del colaborador a sus pantallas. |

### Base de datos

| Acción | Archivo | Qué hace |
|---|---|---|
| Creado | `docs/sql/sprint2_hu06_07_08.sql` | Crea `perfil_repartidor`, agrega las columnas de `comercio` que falten y define las políticas RLS (solo el dueño ve su comercio; nace pendiente; el dueño no puede cambiarse el estado). **No ejecutado.** |

### Pruebas

| Acción | Archivo | Cubre |
|---|---|---|
| Creado | `test/colaborador/activar_modo_colaborador_test.dart` | Caso de uso (activación, sin condiciones, ya activo, sin rol cliente, sin sesión, error de BD) y Bloc. |
| Creado | `test/comercio/registro_comercio_test.dart` | Validaciones, caso de uso (pendiente, campos vacíos, cierre antes de apertura, sin sesión, sin duplicar) y Bloc. |
| Creado | `test/navigation/hu06_07_08_flows_test.dart` | Pantallas: opción de activar visible/oculta, onboarding completo, formulario del comercio de punta a punta, estados pendiente/rechazado/aprobado, cerrar sesión desde la revisión, repartidor pendiente y aprobado. |
| Modificado | `test/support/fakes.dart` | Dobles para los repositorios nuevos y helpers. |
| Modificado | `test/support/pump_helpers.dart` | Ruta del onboarding con tipo `Profile`. |
| Modificado | `test/navigation/role_shell_test.dart` | El shell ahora necesita `ComercioBloc` (comercio) y el repartidor aprobado. |
| Modificado | `test/auth/sign_up_usecase_test.dart` | Repartidor pendiente y valores iniciales del colaborador. |
| Modificado | `test/di/injector_test.dart` | Registros nuevos. |

## 4. Esquema de base de datos asumido

El repositorio no trae el esquema, así que estas columnas son **definidas por
esta entrega** y deben coincidir con tu proyecto de Supabase (o se ajustan en
`SupabaseColumns`):

| Tabla | Columnas que usa la app |
|---|---|
| `perfil_repartidor` (nueva) | `id_usuario`, `estado` (`pendiente`/`aprobado`/`rechazado`), `disponible` |
| `comercio` | `id_comercio`, `id_usuario` (dueño), `nombre`, `telefono`, `direccion`, `ciudad`, `hora_apertura`, `hora_cierre` (texto `HH:mm`), `tipo_servicio` (`recogida`/`entrega`/`ambos`), `estado`, `motivo_rechazo` |

Decisiones de diseño: la "ubicación" del comercio se guarda como dirección y
ciudad/barrio en texto (sin mapa ni coordenadas), y el horario es un solo rango
apertura–cierre que no cruza la medianoche.

## 5. Pendientes y riesgos

- **No se probó contra Supabase real.** El host del `.env` no resuelve. Todo está
  verificado con pruebas unitarias y de widgets con repositorios simulados; falta
  una prueba manual cuando haya un proyecto accesible.
- **Ejecutar `docs/sql/sprint2_hu06_07_08.sql`** (revisándolo contra el esquema real).
  Sin la tabla `perfil_repartidor`, registrarse como repartidor mostrará un error
  de guardado. Si `comercio` ya tiene columnas `NOT NULL` que la app no llena, el
  registro del comercio fallará.
- **Verificar la política `usuario_rol_insert_own`:** HU-06 agrega el rol
  colaborador a una cuenta ya creada; la política debe permitirlo (solo debe
  bloquear `administrador`).
- Un repartidor sin fila en `perfil_repartidor` (por ejemplo, cuentas anteriores a
  esta entrega) se trata como **pendiente**; hay que crear su fila o aprobarlo a mano.
- **HU-24 (aprobación) no se implementó:** por ahora ningún comercio ni repartidor
  puede pasar a aprobado desde la app; se cambia en Supabase.
- Los Home y Perfil siguen mostrando datos de ejemplo en lo que no es de estas
  HU (por ejemplo, "Ganancias disponibles" del colaborador y las estadísticas del
  repartidor).
- Si un registro falla después de crear la cuenta, la cuenta queda sin perfil
  completo (limitación ya existente, documentada en `SignUpUseCase`).

## 6. Cómo probarlo a mano

1. Ejecuta el SQL y confirma que el `.env` apunta a un proyecto accesible.
2. **HU-06:** entra como cliente → Perfil → "Activar modo Colaborador" → Continuar →
   presiona "Activar" sin marcar la casilla (debe pedir aceptar) → marca y activa.
   Vuelve al perfil: ya no aparece la opción y se ven puntos 0, nivel 1, reputación 0.
3. **HU-07:** regístrate como Comercio → aparece el formulario → déjalo vacío
   (errores) → complétalo → "Tu registro está en revisión". Cierra sesión y vuelve
   a entrar: sigue en revisión. Cambia `estado` a `aprobado` en Supabase y
   "Actualizar estado": entra al panel.
4. **HU-08:** regístrate como Repartidor → el Home dice "Tu registro será revisado
   por el administrador" y no hay disponibilidad; el Perfil muestra "Pendiente de
   aprobación".
