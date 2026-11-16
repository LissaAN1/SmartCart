# Sprint 2 · HU-13 · Informe de pruebas y criterios de calidad

Resultados reales de las verificaciones hechas el 16 de noviembre de 2026 sobre la rama `feat/hu13-detalle-precio`.

## 1. Comandos ejecutados y resultados

| Comando | Resultado |
|---|---|
| `flutter test --concurrency=1` (línea base, al empezar la HU-13, con `main` integrado) | 722 pruebas, todas pasan |
| `flutter analyze` (final) | **No issues found** |
| `flutter test --concurrency=1` (final) | **806 pruebas, todas pasan** (84 más que la línea base) |
| `docs/sql/sprint2_hu13.sql` y `docs/sql/pruebas_hu13_politicas.sql` en Supabase | **Ejecutados:** `pruebas_hu13_politicas.sql` dio las **18 líneas `OK`** (más el `AVISO` esperado de los datos de prueba); ver sección 2 |
| `flutter build apk --debug` | **No se volvió a ejecutar en esta historia.** No agrega plugins ni permisos nativos |

Con la concurrencia por defecto, `flutter test` se queda sin memoria en este equipo; con `--concurrency=1` corre completo.

**Diferencia entre ejecutado, aprobado y pendiente**

- Ejecutadas y aprobadas: las 806 pruebas de Dart/Flutter y `flutter analyze`.
- Ejecutadas y aprobadas en Supabase: `sprint2_hu13.sql` y sus 18 pruebas de políticas y funciones.
- Probada en un dispositivo Android: funcionó (informado por el equipo).

## 2. Criterios de aceptación y su verificación

| Criterio / escenario | Verificación automática | Archivo |
|---|---|---|
| Cada precio muestra su fuente: Comercio o Comunidad | Componente y detalle: "Fuente: Comercio" / "Fuente: Comunidad" (y no "Colaborador"); `FuentePrecio.colaborador.etiqueta` | `confianza_widget_test`, `detalle_confianza_test`, `confianza_reglas_test` |
| Se muestra la fecha y hora de la última actualización | "Actualizado 15 nov 2026 · 09:30 (hoy)", "(ayer)", "(hace 5 días)" | `confianza_widget_test`, `detalle_confianza_test` |
| El nivel de confianza depende de la fuente y de qué tan reciente es | Tabla completa de días por fuente (0, 3, 4, 7 y 8 días), la comunidad nunca supera al comercio a igual antigüedad, días de calendario, fechas futuras, cambio de mes y de año | `confianza_reglas_test` |
| Más días que el límite = desactualizado | Con 7 días no, con 8 sí; en el componente y en el detalle ("Desactualizado" + "Confianza baja") | `confianza_reglas_test`, `confianza_widget_test`, `detalle_confianza_test` |
| **Escenario 1:** precio de un comercio de hoy | Dominio (alta, 0 días, "hoy"), componente y detalle (fuente Comercio, fecha de hoy, Confianza alta) | los tres anteriores |
| **Escenario 2:** precio desactualizado | Dominio (8 días: desactualizado y baja), componente (hace 12 días) y detalle (los tres desactualizados; solo el de 8 días el 18 de noviembre) | los tres anteriores |
| **Escenario 3:** reportar un precio incorrecto | Caso de uso (guarda pendiente, motivo opcional y recortado, 300 caracteres, no repite, solo cliente, sin sesión), Bloc (envío en curso, doble toque, ya reportado, falla y reintento, dos precios a la vez) y detalle (hoja del motivo, enviar, cancelar, "Reporte enviado", errores) | `reportar_precio_test`, `detalle_confianza_test` |
| Agregar al carrito y favoritos desde el detalle (criterio de la HU-17) | Con los blocs del cliente: favorito en los 3 establecimientos, agregar solo en los disponibles, agregar guarda en el carrito y avisa, favorito guarda y avisa; sin los blocs no aparecen | `detalle_confianza_test` |
| El Home lleva el carrito y los favoritos a la búsqueda | La lupa y el buscador abren la búsqueda con `ConBlocsDelCliente` (con lo escrito); sin el carrito del cliente se abre solo con el texto, como antes | `cliente_integracion_test` |
| Se ve bien en pantallas angostas | 320 px: componente, detalle con todo a la vez y hoja del motivo, sin desbordes | `confianza_widget_test`, `detalle_confianza_test` |

### Políticas y funciones en la base real

**Ejecutado y aprobado (18 `OK`).** La primera corrida en Supabase encontró un defecto real de la función (prueba B4): `btrim` solo quitaba espacios, así que un motivo como "espacios y salto de línea" se guardaba en vez de quedar vacío, distinto de lo que hace la app con `trim()`. Se corrigió en `sprint2_hu13.sql` (ahora quita también tabuladores y saltos de línea); con esa corrección las 18 pruebas dan `OK`. `docs/sql/pruebas_hu13_politicas.sql` tiene 18 pruebas que simulan sesiones reales y terminan en `ROLLBACK`:

| Grupo | Qué demuestra |
|---|---|
| A1, A2 | Lo que el cliente recibe de cada precio: la fuente, la fecha de hoy y el precio vigente (con la promoción) para un precio del comercio; la fuente comunidad y la fecha de hace 10 días para uno desactualizado |
| B1 a B7 | El reporte queda pendiente con el precio vigente y su fuente; no se duplica un reporte pendiente; se reporta también un precio de la comunidad con su fuente y su fecha vieja; un motivo en blanco no se guarda; el motivo tiene máximo 300 caracteres; un producto que no existe o de un comercio pendiente no se reporta |
| C1 a C3 | Cada cliente ve solo sus reportes; dos clientes pueden reportar el mismo precio |
| D1 a D3 | Nadie inserta, cambia ni borra reportes saltándose la función |
| E1 | Sin el rol cliente no se reporta |
| F1 | Un reporte resuelto permite reportar de nuevo |
| G1 | Sin sesión no se reporta |

## 3. Pruebas implementadas

| Archivo | Pruebas | Qué cubre |
|---|---|---|
| `test/confianza/confianza_reglas_test.dart` | 26 | `ConfianzaReglas`: los tres escenarios del backlog, la tabla por fuente y días, los límites, días de calendario y fechas futuras |
| `test/confianza/reportar_precio_test.dart` | 20 | `ReportarPrecioIncorrectoUseCase` y el reporte desde `DetalleProductoBloc` |
| `test/confianza/confianza_widget_test.dart` | 9 | `ConfianzaDelPrecio`: fuente, fecha, confianza, desactualizado y botón de reporte (incluye 320 px) |
| `test/confianza/detalle_confianza_test.dart` | 23 | El detalle completo: los tres escenarios en pantalla, los botones de carrito y favoritos, los argumentos de ruta y 320 px |
| `test/cliente/cliente_integracion_test.dart` (agregadas) | 3 | El Home lleva el carrito y los favoritos a la búsqueda |
| `test/di/injector_test.dart` (agregadas) | 3 | Registros nuevos; el detalle se arma con el repositorio real; `DisponibilidadBloc` se pide al localizador con `param1` (ajuste del Service Locator) |

**Pruebas existentes que ajustamos** (ninguna se borró):

- `test/busqueda/busqueda_pantallas_test.dart` · "el más barato va primero": con la fuente, la fecha y la confianza cada establecimiento ocupa más y la lista solo arma los que se ven; la prueba usa una pantalla más alta para ver los tres.
- `test/cliente/cliente_integracion_test.dart`: las cuatro pruebas de la lupa, el buscador y "Comparar" esperaban la exploración; después de integrar `main` (HU-12) abren la búsqueda, y las ajustamos en esa integración.
- `test/support/fakes.dart`: `TestEnv.detalleBloc` recibe el caso de uso de reporte; se agregó `FakeReporteIncorrectoRepository`.

## 4. Criterios de calidad del proyecto aplicados

El criterio de referencia es la tabla "Informe de criterios de calidad" del `README.md`.

| Criterio | Cómo se cumple | Evidencia |
|---|---|---|
| Clean Architecture | `confianza/` con `domain`, `data` y `presentation`. La regla de confianza es una función pura de dominio. El dominio no importa Flutter, Supabase ni GetIt. | `grep` sobre `lib/features/*/domain` sin resultados |
| Service Locator (GetIt) | Todo registrado en `injector.dart`; el Bloc recibe el caso de uso por constructor. | `test/di/injector_test.dart` y los `grep` del README |
| BLoC | `DetalleProductoBloc` con estados de envío, éxito y error, protección contra el doble toque y avisos con id (como en la HU-17). | `reportar_precio_test` |
| Reutilización | `ConfianzaDelPrecio` pensado para la HU-18; `FavoritoBoton` y `AgregarCarritoBoton` de la HU-17; `AvisoUi`, `EtiquetaEstado`, `BotonPrimario`, `traducirErroresSupabase`. | Revisión del código |
| Manejo de errores | Los mensajes de la función SQL llegan en español (código `P0001`); un error inesperado da un mensaje genérico. | `reportar_precio_test`, `detalle_confianza_test` |
| Seguridad | Nadie escribe la tabla directo; solo clientes; cada cliente ve lo suyo; solo se reporta un precio publicado. | Demostrado en Supabase con `pruebas_hu13_politicas.sql` (18 `OK`) |
| Pruebas | 84 pruebas nuevas; la suite completa pasa. | Sección 1 |
| Análisis estático | `flutter analyze` sin problemas. | Sección 1 |

## 5. Pendientes y limitaciones

1. **Hecho:** `sprint2_hu13.sql` y `pruebas_hu13_politicas.sql` corridos en Supabase; las 18 líneas dieron `OK`. Quien despliegue en otra base debe correr los dos scripts en ese orden, después de los de HU-12 y HU-17.
2. **Hecho:** prueba manual en Android (detalle del producto, fuente, fecha y confianza, reporte de un precio y la fila en `reporte_precio_incorrecto`). Pasos en el README, sección "Probar el detalle del precio (HU-13)".
3. Los precios de la comunidad todavía no existen en una base real; la regla está probada con datos de prueba.
4. Las dos advertencias de `tap()` de `test/navigation/hu06_07_08_flows_test.dart` existían antes y no vienen de este cambio.
