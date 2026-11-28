# Sprint 3 · HU-19 · Ubicación, radio de búsqueda y mapa

Informe de implementación. Rama: `feat/hu19-ubicacion-mapa`, creada desde `develop` (`462d085`). Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como cliente, quiero configurar mi ubicación y mi radio de búsqueda y ver los establecimientos cercanos en un mapa, para comparar solo los que me quedan a mano. (Sprint Backlog 3, HU-19, 3 puntos, Must.)

## 2. Alcance implementado

| Criterio de aceptación | Estado | Cómo se cumple |
|---|---|---|
| La app pide permiso de ubicación | Implementado | La primera vez que se abre el mapa sin ubicación guardada se pide el GPS con `ObtenerUbicacionUseCase` (HU-14), que pide el permiso. |
| Si no se da el permiso, el cliente puede escribir su dirección | Implementado | Si el GPS falla, la pantalla pide la dirección (`FormularioDireccion`); `BuscarDireccionUseCase` la convierte en coordenadas con `GeocodingGeocodificador`. También se puede escribir en cualquier momento con "Escribir dirección". |
| El radio de búsqueda es configurable | Implementado | Chips de 1, 2, 5, 10 y 20 km (`RadioReglas`). |
| El mapa muestra los establecimientos aprobados dentro del radio | Implementado | `comercios_en_radio()` (SQL) devuelve solo comercios aprobados con ubicación dentro del radio; `MapaEstablecimientos` los marca con el círculo del radio, y abajo van en una lista con su distancia. |
| La ubicación y el radio quedan guardados en la cuenta y se recuperan | Implementado | Tabla `ubicacion_cliente` con RLS; cada cambio se guarda antes de mostrarse y `MapaIniciado` lee lo guardado sin volver a pedir el GPS. |
| La comparación del carrito (HU-18) usa la ubicación guardada | Preparado | `GetMiUbicacionUseCase` y `Ubicacion.distanciaA` quedan listos para la HU-18, que es la que calcula las distancias de las alternativas. |

Escenarios 1 (ubicación automática), 2 (sin permiso) y 3 (cambio del radio): prueba automática del Bloc, de la pantalla y prueba SQL. Ver `docs/HU19_informe_pruebas.md`.

## 3. Decisiones (el backlog no las define)

| Tema | Decisión | Por qué |
|---|---|---|
| Mapa | `flutter_map` con teselas de OpenStreetMap | No necesita llave ni facturación (Google Maps sí). Sus condiciones de uso piden el crédito "© OpenStreetMap", que va en el mapa, y un `User-Agent` propio (`userAgentPackageName`). |
| Dirección escrita | Paquete `geocoding` (geocodificador del teléfono), con el idioma `es_CO` | No necesita llave. Solo funciona en Android e iOS: en Windows avisa que no está disponible. |
| Radio | De 1 a 20 km; empieza en 5 km | Menos de 1 km casi nunca muestra comercios y más de 20 km ya no es "a la mano". Igual en `RadioReglas` y en el SQL. |
| Dirección | Opcional (vacía si vino del GPS), de 5 a 200 caracteres | Lo suficiente para "Calle 5 # 38-20, Cali" sin aceptar textos absurdos. |
| Lista del mapa | Sin páginas, hasta 200 comercios del más cercano al más lejano | Un mapa muestra todos los puntos a la vez; el radio máximo de 20 km mantiene la consulta acotada. |
| Escritura | Solo con `guardar_ubicacion_cliente()`; la tabla no se escribe directo | La función valida los mismos límites que la app y siempre guarda la fila de quien llama (`auth.uid()`). Mismo patrón que `fijar_ubicacion_comercio` de la HU-14. |
| Tipo de las coordenadas del comercio | `comercios_en_radio()` convierte `comercio.latitud/longitud` a `double precision` | En nuestra base esas columnas ya existían como `numeric(9,6)` antes de la HU-14, y `return query` exige el tipo exacto. La primera ejecución de las pruebas SQL lo reveló (error 42804 en B1). |
| `comercios_cercanos()` de la HU-14 | No se tocó | Sigue siendo solo para colaboradores y paginada; el cliente usa `comercios_en_radio()`, que reutiliza `distancia_metros()`. |

## 4. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint3_hu19.sql` | Tabla `ubicacion_cliente` con restricciones y RLS de lectura propia; `guardar_ubicacion_cliente()` y `comercios_en_radio()`. Idempotente. |
| `docs/sql/pruebas_hu19_politicas.sql` | 16 pruebas de la escritura, los límites, el radio, los permisos y la privacidad. Termina en `ROLLBACK`. |
| `lib/features/ubicacion/domain/radio_reglas.dart` | Límites del radio y de la dirección. |
| `lib/features/ubicacion/domain/entities/preferencia_ubicacion.dart` | Ubicación, radio y dirección del cliente. |
| `lib/features/ubicacion/domain/entities/establecimiento_cercano.dart` | Comercio con su distancia. Antes estaba en `reportes/`; se movió porque ahora lo usan la HU-14 y la HU-19 (`reporte.dart` lo reexporta y los imports de la HU-14 no cambian). |
| `lib/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart`, `geocodificador.dart` | Contratos. |
| `lib/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart` | `GetMiUbicacionUseCase`, `GuardarMiUbicacionUseCase`, `BuscarDireccionUseCase` y `GetComerciosEnRadioUseCase`. |
| `lib/features/ubicacion/data/source/supabase_ubicacion_cliente_data_source.dart`, `.../repository/ubicacion_cliente_repository_impl.dart` | Datos de Supabase. |
| `lib/features/ubicacion/data/source/geocoding_geocodificador.dart` | Única clase que conoce `geocoding`. |
| `lib/features/ubicacion/data/source/establecimiento_cercano_mapper.dart` | Convierte las filas de `comercios_cercanos` y `comercios_en_radio` (antes era un método privado del data source de reportes). |
| `lib/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart` | Estados `cargando`, `listo`, `sinUbicacion` y `falloCarga`; `ocupado` evita dos cambios a la vez; avisos con `AvisoUi`. |
| `lib/features/ubicacion/presentation/pages/mapa_comercios_page.dart` | Pantalla "Comercios cercanos" y `FormularioDireccion`. |
| `lib/features/ubicacion/presentation/widgets/mapa_establecimientos.dart` | Componente de mapa reutilizable (centro, radio y puntos). Lo pueden usar la HU-18 y la HU-22. |
| `lib/features/ubicacion/presentation/formato_distancia.dart` | `formatoDistancia` (antes en `reporte_args.dart`, que ahora la reexporta) y `formatoRadio`. |
| `test/ubicacion/`, `test/support/fakes_ubicacion.dart` | Pruebas y dobles. |

### Modificados

| Archivo | Cambio |
|---|---|
| `pubspec.yaml`, `pubspec.lock`, `windows/flutter/generated_plugins.cmake` | `flutter_map`, `latlong2` y `geocoding`. |
| `lib/core/constants/supabase_tables.dart` | Tabla, dos funciones y cuatro columnas. |
| `lib/core/di/injector.dart` | 8 registros: data source, geocodificador, repositorio, 4 casos de uso y el Bloc (fábrica). |
| `lib/core/routes/app_routes.dart`, `lib/app_router.dart` | Ruta `/cliente/mapa`. |
| `lib/features/home/presentation/pages/role_shell.dart` | Abre el mapa desde el Home y desde el Perfil del cliente. |
| `lib/features/cliente/presentation/pages/cliente_home_screen.dart` | Botón de ubicación en el encabezado. |
| `lib/features/cliente/presentation/pages/cliente_perfil_screen.dart` | "Mi ubicación" en Preferencias. |
| `lib/features/reportes/domain/entities/reporte.dart`, `.../presentation/pages/reporte_args.dart`, `.../data/source/supabase_reportes_data_source.dart` | Reexportan la entidad y el formato que pasaron a `ubicacion/` y usan el mapeador común. Sin cambio de comportamiento. |
| `test/support/pump_helpers.dart`, `test/di/injector_test.dart`, `test/cliente/cliente_integracion_test.dart` | Ruta de apoyo del mapa, registros y accesos. |

## 5. Arquitectura

Presentación → caso de uso → contrato → repositorio → data source, como en el resto del proyecto. El dominio no importa Flutter, Supabase ni los paquetes de mapa y geocodificación; `flutter_map` solo aparece en el componente de mapa y `geocoding` solo en `GeocodingGeocodificador`. Las validaciones (radio y dirección) están en los casos de uso y se repiten en la base, que es la garantía real.

## 6. Cómo probarlo

1. Ejecutar `docs/sql/sprint3_hu19.sql` en Supabase (después de los de HU-14 y HU-17) y luego `docs/sql/pruebas_hu19_politicas.sql`: todas las filas deben decir `OK`.
2. `flutter pub get` (paquetes nuevos) y `flutter run` en Android.
3. Necesita al menos un comercio aprobado con ubicación guardada (HU-14: "Guardar ubicación" en el Home del comercio).
4. Entrar como cliente (`adri@gmail.com`) y tocar el ícono de ubicación del Home (o Perfil → **Mi ubicación**):

| Escenario | Cómo | Resultado esperado |
|---|---|---|
| 1. Ubicación automática | Aceptar el permiso | Mapa centrado en el teléfono con el círculo de 5 km y los comercios dentro, también en la lista con su distancia |
| 2. Sin permiso | Negar el permiso (o desactivar la ubicación del teléfono) | "Escribe tu dirección"; al buscar una dirección válida aparece el mapa centrado en ella |
| 3. Cambio del radio | Tocar "10 km" o "20 km" | El círculo crece y aparecen los comercios del nuevo radio |
| Guardado | Cerrar la app y volver al mapa | Se recupera la misma ubicación y el mismo radio sin pedir el GPS |

En el SQL Editor: `select * from public.ubicacion_cliente;`.

## 7. Pendientes y limitaciones

- El SQL ya se ejecutó en Supabase y sus 16 pruebas dan `OK`. **Falta probarla en un dispositivo Android**: las pruebas de Flutter usan dobles para el GPS, el geocodificador y el mapa.
- La geocodificación depende del servicio del teléfono: en emuladores sin Google Play puede no encontrar direcciones, y en Windows no está disponible.
- El mapa necesita internet para las teselas; sin conexión se ve el fondo, el círculo y los puntos, sin calles.
- El encabezado del Home todavía no muestra la dirección guardada (lo haría leer la ubicación al abrir el Home).
