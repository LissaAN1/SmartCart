# Sprint 2 · HU-14 · Reporte de precio por el colaborador

Informe de implementación. Rama: `feat/hu14-reporte-precio`, creada desde `feat/hu10-catalogo-comercio` (no desde `main`: necesita las tablas de producto de la HU-10). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como colaborador, quiero reportar el precio que veo en un establecimiento, con la promoción, la disponibilidad y una foto de la etiqueta, para actualizar la información de la plataforma y ganar puntos. (Product Backlog, HU-14, 8 puntos, Must.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| La app verifica por geolocalización que el colaborador está en el establecimiento | Implementado | El caso de uso compara la ubicación actual con la del comercio; la función SQL `enviar_reporte_precio` lo vuelve a comprobar en el servidor (radio de 150 m). |
| El producto se identifica escaneando el código de barras o buscando por nombre | Implementado | `ReporteProductoPage`: búsqueda por nombre o marca y escáner con `mobile_scanner` (solo Android, iOS y web). |
| El precio y la foto de la etiqueta son obligatorios; promoción y disponibilidad son opcionales | Implementado | Validadores en el formulario, en el caso de uso y en la base. |
| Se puede marcar un producto como agotado | Implementado | Interruptor "El producto está agotado". |
| El reporte queda en estado pendiente | Implementado | `reporte_precio.estado` nace `pendiente`; solo la función SQL inserta. |
| Se puede sugerir un establecimiento que aún no está en la plataforma | Implementado | `SugerirEstablecimientoPage` y la tabla `establecimiento_sugerido`. |
| *(Ajuste pedido por el equipo, revisado el 23/11)* Elegir el producto primero | Implementado | Al elegir el establecimiento lo primero es la **lista de productos**; la cámara ya no se abre sola. El escáner queda como ícono en el buscador: si el código es de un producto del establecimiento, pasa directo al formulario. |
| *(Ajuste pedido por el equipo)* Foto: tomarla o subirla | Implementado | En el formulario hay dos opciones: **Tomar foto de la etiqueta** (cámara, solo en Android e iOS) y **Subir foto** (galería o archivo). En web, "Tomar foto" abre la cámara si se usa desde un navegador de celular; en un navegador de escritorio abre el selector de archivos (no hay webcam con este paquete). En las apps de escritorio solo se ofrece subir la imagen. |
| *(Ajuste pedido por el equipo)* Historial de mis reportes | Implementado | El Home del colaborador y `MisReportesPage` muestran los reportes reales, incluidos los pendientes. |

Escenarios 1 (reporte exitoso), 2 (fuera del establecimiento: se rechaza y se explica) y 3 (sin foto: se muestra que es obligatoria) tienen prueba automática. Ver `docs/HU14_informe_pruebas.md`.

**Fuera de alcance (a propósito):**
- Validar los reportes y actualizar el precio (HU-15, Sprint 3).
- **Dar puntos** (HU-16): el propio backlog dice "los puntos solo se otorgan cuando el reporte es validado". La HU-14 solo guarda el reporte.
- Validar o rechazar reportes y mostrar el motivo (HU-15). El historial ya muestra los reportes reales con su estado, pero hoy todos están pendientes.
- Búsqueda de productos para clientes (HU-12).

## 3. Cambios a la HU-07 (registro del comercio)

La verificación por ubicación necesita saber dónde queda cada comercio, y la HU-07 solo guardaba dirección y ciudad. Con el permiso del equipo de tocar lo que hiciera falta:

- `comercio` tiene dos columnas nuevas, `latitud` y `longitud` (van juntas o ninguna).
- El **formulario de registro** tiene un bloque opcional "Ubicación del establecimiento": el botón "Usar mi ubicación actual" toma el GPS y las coordenadas viajan con el registro. Es opcional para no bloquear el registro de quien no está en su local.
- Los comercios que ya estaban registrados (y los que no tomaron la ubicación) ven en su **Home** un aviso "Falta la ubicación de tu comercio" con el botón "Guardar ubicación". Funciona aunque el comercio ya esté aprobado.
- **Sin coordenadas un comercio no aparece como lugar de reporte.**
- Las políticas de `comercio` no cambiaron. El dueño guarda la ubicación con la función `fijar_ubicacion_comercio()`, que toca solo esas dos columnas: una política de `update` nueva le habría dejado cambiar también su estado de aprobación.

## 4. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| Distancia máxima | 150 metros | El backlog dice "dentro del establecimiento"; 150 m deja margen al error normal del GPS. Está como constante (`ReporteReglas.radioMaximoM`) y como constante de la función SQL: si se cambia, hay que cambiar los dos. |
| Precio | Pesos colombianos (COP) enteros, de 1 a 100 000 000 | El tope evita errores de digitación. Se aceptan separadores ("4.900", "$ 4900"). |
| Promoción | Opcional; si se escribe, debe ser menor que el precio normal | Una promoción mayor no tiene sentido. Sin fechas: las fechas son de la HU-11. |
| Agotado | Sigue pidiendo el precio | La etiqueta sigue en el estante aunque no haya existencias. |
| Lista de establecimientos | Comercios aprobados con ubicación, del más cerca al más lejos, hasta 20 km | El radio es amplio a propósito: el colaborador puede elegir un lugar lejano y el envío lo rechaza (escenario 2). |
| Sugerencia | Nombre, dirección y ciudad; se guarda con la ubicación del colaborador | Le sirve a quien la revise para encontrar el lugar. |
| Fotos | Bucket privado `reportes`, carpeta por usuario, máx. 5 MB, JPEG/PNG/WebP | La foto es evidencia que revisará el administrador (HU-15). |

## 5. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu14.sql` | `es_colaborador()`, `es_comercio_aprobado()`, coordenadas del comercio y `fijar_ubicacion_comercio()`, `distancia_metros()`, `comercios_cercanos()`, política de lectura de productos para colaboradores, `reporte_precio` con `enviar_reporte_precio()`, `establecimiento_sugerido` y el bucket `reportes` con sus políticas. Idempotente. |
| `lib/features/reportes/.../mis_reportes_page.dart`, `reporte_historial_item.dart`, `reporte_formato.dart`, `get_mis_reportes_usecase.dart`, `mi_reporte.dart` | Historial de reportes: pantalla completa paginada, fila con estado, formato de pesos y fechas, caso de uso y entidad. |
| `docs/sql/pruebas_hu14_politicas.sql` | 28 pruebas de las políticas y funciones (colaborador, no colaborador, otro colaborador, dueño, aprobación y Storage). Termina en `ROLLBACK` y devuelve una tabla con los resultados. |
| `lib/features/ubicacion/` | `Ubicacion` (con la distancia haversine), contrato `ServicioUbicacion`, `ObtenerUbicacionUseCase`, `GeolocatorServicioUbicacion` y `UbicacionBloc`. La usan el registro del comercio y el reporte. |
| `lib/features/reportes/domain/` | Entidades (`EstablecimientoCercano`, `ConsultaProducto`, `FotoReporte`, `ReporteDatos`, `SugerenciaDatos`), `ReporteReglas`, `ReporteValidators`, contratos `ReportesRepository` y `SelectorFoto`, y 6 casos de uso (`GetColaboradorActivo`, `GetEstablecimientosCercanos`, `BuscarProductos`, `TomarFoto`, `EnviarReportePrecio`, `SugerirEstablecimiento`). |
| `lib/features/reportes/data/` | `SupabaseReportesDataSource`, `ReportesRepositoryImpl` e `ImagePickerSelectorFoto`. |
| `lib/features/reportes/presentation/` | `ReporteFormBloc`, `SugerenciaBloc` y las pantallas `ReporteEstablecimientoPage`, `ReporteProductoPage`, `ReporteFormPage`, `SugerirEstablecimientoPage` y `EscanerCodigoPage`. |
| `lib/features/comercio/domain/usecases/fijar_ubicacion_comercio_usecase.dart` | Guarda la ubicación del comercio de la cuenta. |
| `test/reportes/*` | 143 pruebas nuevas (ver el informe de pruebas). |

### Modificados

| Archivo | Cambio |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Permisos de ubicación y cámara (HU-14) e `INTERNET`. Sin `INTERNET` la app no abre en modo *release* (el de depuración lo trae aparte). |
| `ios/Runner/Info.plist` | Textos de uso de cámara, ubicación y fotos. |
| `pubspec.yaml` / `pubspec.lock` y `windows/flutter/generated_plugin*` | Plugins `geolocator`, `image_picker`, `mobile_scanner` y `permission_handler`. Los dos archivos de `windows/` los genera Flutter al agregar plugins. |
| `lib/core/constants/supabase_tables.dart` | Tabla, bucket, funciones y columnas nuevas. |
| `lib/core/routes/app_routes.dart`, `lib/app_router.dart` | 6 rutas (el reporte y el historial). Los pasos devuelven `true` si se envió el reporte, para cerrar todo el flujo. |
| `lib/core/di/injector.dart` | Registros nuevos (ver sección 7). |
| `lib/features/comercio/**` | `Comercio` y `ComercioDatos` con coordenadas; el repositorio, el data source, `ComercioBloc` (evento `ComercioUbicacionSolicitada`), el formulario de registro y el Home. |
| `lib/features/auth/data/source/supabase_error_mapper.dart` | `P0001`: el mensaje en español de las funciones SQL se muestra tal cual. |
| `lib/features/catalog/**` | `productoFromRow` pasó a ser una función pública para reutilizarla; `ProductoCard` acepta otro ícono. Mismo comportamiento. |
| `lib/features/colaborador/.../colaborador_home_screen.dart`, `lib/features/home/.../role_shell.dart` | "Reportar precio", "Escanear" y la pestaña "Reportar Precio" abren el flujo. |
| `test/support/fakes.dart`, `pump_helpers.dart`, `test/di/injector_test.dart` | Dobles y casos nuevos. |
| `test/navigation/hu06_07_08_flows_test.dart`, `test/catalog/comercio_entradas_test.dart` | Ver sección 9: un cambio mínimo en cada una. |

## 6. Arquitectura

```text
presentation  ReporteEstablecimientoPage → ReporteProductoPage → ReporteFormPage
              SugerirEstablecimientoPage · EscanerCodigoPage
              UbicacionBloc · ReporteFormBloc · SugerenciaBloc · PaginatedBloc (listas)
                    │  (un caso de uso por acción)
domain        EnviarReportePrecio · SugerirEstablecimiento · GetEstablecimientosCercanos
              BuscarProductos · TomarFoto · ObtenerUbicacion
              GetColaboradorActivo  ← todos parten de aquí
              ReportesRepository · SelectorFoto · ServicioUbicacion   (contratos)
              ReporteValidators · ReporteReglas · Ubicacion.distanciaA   (Dart puro)
                    │
data          ReportesRepositoryImpl → SupabaseReportesDataSource
              ImagePickerSelectorFoto · GeolocatorServicioUbicacion
```

- El dominio no importa Flutter, Supabase, GetIt ni los plugins nuevos (`geolocator`, `image_picker`, `permission_handler`, `mobile_scanner`). Cada plugin está detrás de un contrato; `mobile_scanner` solo está en `EscanerCodigoPage`, que es presentación.
- El **escáner** es una pantalla propia que devuelve el código leído. El código escaneado se busca igual que un texto pero con coincidencia exacta (`ConsultaProducto.codigo`).
- Los Blocs no tienen lógica de negocio y siguen el mismo patrón de `ComercioBloc` (carga, éxito y error, y un guard contra el doble envío).

## 7. Integración con el Service Locator (GetIt)

Todo en `lib/core/di/injector.dart`, con el mecanismo y el orden existentes. No hay contenedor paralelo.

| Tipo | Registro |
|---|---|
| `SupabaseReportesDataSource` | `registerLazySingleton` |
| `ServicioUbicacion` (→ `GeolocatorServicioUbicacion`), `SelectorFoto` (→ `ImagePickerSelectorFoto`), `ReportesRepository` | `registerLazySingleton` con el tipo del contrato |
| 8 casos de uso nuevos | `registerLazySingleton` |
| `UbicacionBloc`, `ReporteFormBloc`, `SugerenciaBloc` | `registerFactory` |
| `PaginatedBloc<EstablecimientoCercano>` | `registerFactoryParam` con la ubicación (`param1`) |
| `PaginatedBloc<Producto>` de la búsqueda | `registerFactoryParam` con el establecimiento (`param1`) y la consulta (`param2`), **con nombre**: `InstanciasSl.busquedaProductos` |
| `ComercioBloc` | Recibe dos casos de uso más |

**Por qué el registro con nombre:** `PaginatedBloc<Producto>` ya estaba registrado sin parámetros por el catálogo (HU-10). GetIt no deja registrar dos veces el mismo tipo sin nombre, así que la versión de la búsqueda se pide con `sl<PaginatedBloc<Producto>>(instanceName: InstanciasSl.busquedaProductos, param1: ..., param2: ...)`. Una prueba comprueba que las dos conviven.

## 8. Reglas de negocio

- **Solo un colaborador reporta.** `GetColaboradorActivoUseCase` exige sesión y el rol colaborador (HU-06). En la base lo exigen `es_colaborador()` y la función.
- **La distancia se comprueba dos veces:** en la app, para avisar rápido (`Debes estar en el establecimiento para reportar el precio. Estás a N m.`), y en `enviar_reporte_precio`, que es la que no se puede saltar. Con el mismo radio y la misma fórmula (haversine, radio de la Tierra 6 371 000 m).
- **Orden de comprobaciones:** primero lo que no necesita GPS ni red (precio, promoción y foto), luego que sea colaborador y al final dónde está. Un reporte sin foto se rechaza sin pedir el GPS.
- **Nadie inserta un reporte directo:** se revocó `insert/update/delete` sobre `reporte_precio`; solo la función (que corre con permisos del propietario) escribe.
- **La foto debe estar en la carpeta de quien reporta** (`<id_usuario>/<archivo>`): lo exigen la política de Storage y la función.
- **Si el reporte falla después de subir la foto**, la app borra la foto para no dejarla huérfana.
- **El colaborador solo ve lo suyo**: reportes y sugerencias (más el administrador, para la HU-15).
- **Productos de solo lectura:** el colaborador lee los productos de comercios aprobados; no puede escribir.

## 9. Decisiones técnicas y dificultades

- **La función SQL como punto de seguridad.** Guardar el reporte directo con RLS dejaba la verificación de distancia solo en la app. `enviar_reporte_precio` es `security definer` (lee las coordenadas del comercio, que el colaborador no puede leer) pero comprueba todo explícitamente: rol, comercio aprobado, producto del comercio, foto en su carpeta, precio, promoción y distancia.
- **Mensajes de error de las funciones.** Los `raise exception` salen con `P0001`; el mapeador de errores ahora muestra ese mensaje, que ya viene en español. Las funciones de HU-24 usan códigos propios, así que no chocan.
- **Cámara y permiso en Android.** El escáner exige declarar `CAMERA` en el manifiesto. Con el permiso declarado, la cámara del sistema (la de `image_picker`) falla si el permiso no fue concedido. Por eso `ImagePickerSelectorFoto` pide el permiso con `permission_handler` antes de abrirla. En escritorio y web no hay cámara que abrir: deja elegir un archivo.
- **Dos pruebas existentes tuvieron que cambiar** (y ninguna aserción):
  - `test/navigation/hu06_07_08_flows_test.dart`, "dejar campos vacíos muestra los errores y no guarda": el formulario de registro ahora es más largo y el botón "Registrar" queda fuera de lo que `ListView` construye de antemano; la prueba ahora se desplaza hasta él antes de tocarlo.
  - `test/catalog/comercio_entradas_test.dart` (de la HU-10), "Ir al Catálogo": mismo motivo, por el aviso de ubicación en el Home.
- **Escaneo directo.** `ReporteProductoPage` abre el escáner en el primer cuadro (`escanearAlEntrar`, activo salvo que no haya cámara). Al leer un código se busca con coincidencia exacta y, si el resultado trae un único producto, abre su formulario sin que la persona lo toque (un código de barras no se repite dentro de un comercio, así que son 0 o 1). El indicador se apaga al abrirlo: volver atrás desde el formulario no lo vuelve a abrir. Si se cancela el escáner o el código no existe, la página queda lista para buscar por nombre. Esto reemplaza el comportamiento anterior, en el que había que tocar el ícono del escáner y luego el producto.
- **Historial real.** El Home del colaborador mostraba reportes de ejemplo fijos. Ahora lee `mis_reportes()`, una función SQL (el colaborador no puede leer la tabla `comercio`, así que el nombre del establecimiento no se puede traer con un `select` normal) que devuelve solo los reportes de quien llama, del más reciente al más antiguo y de **cualquier estado**. `RolShell` crea la lista (`crearMisReportes`), la recarga al volver del flujo de reporte y la cierra al salir; el Home muestra los 3 más recientes y **Historial** abre la lista completa, paginada. Un reporte sin revisar sale como "Pendiente" (antes el texto de ejemplo decía "En revisión"). Si un producto se elimina después, sus reportes se eliminan en cascada (la tabla enlaza con `on delete cascade`).
- **Hallazgo de seguridad en una política que ya existía (no de la HU-14).** La prueba E3 de `pruebas_hu14_politicas.sql` mostró que el dueño de un comercio aprobado podía hacer `update comercio set estado = ...`. Revisando `pg_policies` en el proyecto real apareció una política antigua, `comercio_update_own`, que los scripts del repositorio no crean: su `with check` mira la columna heredada `estado_registro` y no `estado`. Como las políticas permisivas se suman con OR, anulaba a `comercio_update_own_pendiente` (la de la HU-07) y un dueño con `estado_registro = 'pendiente'` podía aprobarse solo. La app no actualiza `comercio` directamente (solo inserta y llama a funciones), así que eliminarla no rompe nada: `sprint2_hu14.sql` ahora hace `drop policy if exists comercio_update_own` (sección 8) y se agregó la prueba E5 (un dueño pendiente no puede aprobarse). Las políticas duplicadas `comercio_admin_select` y `comercio_admin_update` repiten a las del administrador y son inofensivas; no se tocaron.
- **`permission_handler` fijado en la versión 12.** La 13 usa `permission_handler_android` 14, que exige compilar contra Android SDK 37; el proyecto usa AGP 9.1 (máximo recomendado: SDK 36) y el equipo tiene el SDK 36, así que `flutter build apk` fallaba en `checkDebugAarMetadata`. Con la 12 (`permission_handler_android` 13, SDK 35) el APK compila. Si algún día se sube el SDK de Android a 37, se puede volver a la 13.
- **Textos largos en botones.** Dos etiquetas se acortaron ("Guardar ubicación", "Sugerir establecimiento") porque en las pruebas, con la fuente de prueba, se desbordaban.
- **Memoria al correr las pruebas.** Igual que en la HU-10: `flutter test --concurrency=1`.

## 10. Pendientes y riesgos

- **SQL en Supabase: ejecutado y probado.** El equipo corrió `docs/sql/sprint2_hu14.sql` y su script de pruebas. La primera vez dio 24 líneas `OK` y 1 `ALERTA` (E3, ver la sección 9); con la corrección de `sprint2_hu14.sql` (sección 8) y la prueba nueva E5 se volvió a ejecutar y las 26 líneas dijeron `OK`; al agregar la función `mis_reportes()` (historial) y las pruebas A3b y C1b se ejecutó otra vez y **las 28 líneas dicen `OK`** (detalle en `docs/HU14_informe_pruebas.md`). Lo que sigue sin probarse es la app corriendo en un dispositivo.
- **Quien use otra base de datos** debe ejecutar `sprint2_hu14.sql` completo: la política heredada `comercio_update_own` también puede existir allí y el script la elimina.
- **Probado en Android** (la plataforma del equipo; informado por el equipo): ubicación, permiso de cámara, foto, escáner y envío. Además se verificó con pruebas automáticas (con dobles) y con la compilación del APK de depuración.
- **Cómo probar el escenario 2 sin caminar:** guardar la ubicación del comercio desde el mismo teléfono y luego moverla con SQL (ver el README, sección "Probar el reporte de precios"), o cambiar la ubicación del emulador en Android Studio.
- El escáner no funciona en Windows (no hay `mobile_scanner` para escritorio): ahí queda la búsqueda por nombre.
- En `AndroidManifest.xml` se agregó `INTERNET`, que corrige también un problema que no era de esta historia: sin ese permiso, la app compilada en modo *release* no se conecta a Supabase.
