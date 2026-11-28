# SmartCart

> Compara menos, decide mejor y compra de forma inteligente.

Este es nuestro proyecto del curso **Aplicaciones Móviles** (Universidad Icesi). Es una app móvil hecha con **Flutter** y **Supabase**. Este README documenta el estado real del proyecto: la entrega del **Sprint 1** (registro, inicio de sesión y resumen del perfil para los cinco perfiles) y lo que llevamos del **Sprint 2** (2 al 17 de noviembre).

**Objetivo del Sprint 1.** Que una persona pueda crear su cuenta, iniciar sesión con credenciales válidas y llegar a la vista de resumen de su perfil. Lo hicimos para los cinco perfiles de la app.

**Objetivo del Sprint 2.** Que los comercios independientes se registren, sean aprobados y publiquen su catálogo; que el cliente busque productos y vea cada precio con su fuente y su confianza; y que los colaboradores reporten precios con foto.

### Estado del Sprint 2

| HU | Título | Estado |
|---|---|---|
| HU-06 | Onboarding del colaborador | Implementada (modo Colaborador desde el perfil del cliente) |
| HU-07 | Registro de comercio | Implementada (formulario y pantalla de estado) |
| HU-08 | Registro de repartidor | Implementada (pantalla de estado hasta que lo aprueben) |
| HU-24 | Aprobación de comercios y repartidores | Implementada. Ver [docs/CAMBIOS_SPRINT2_HU24.md](docs/CAMBIOS_SPRINT2_HU24.md) |
| **HU-10** | **Gestión del catálogo del comercio** | **Implementada y verificada. Probada con repositorios falsos (278 pruebas), con sus políticas RLS en Supabase (10 pruebas OK) y con la app corriendo contra esa base (prueba manual del equipo).** Ver [docs/HU10_informe_implementacion.md](docs/HU10_informe_implementacion.md) y [docs/HU10_informe_pruebas.md](docs/HU10_informe_pruebas.md) |
| **HU-11** | **Precios, disponibilidad y promociones** | **Implementada (rama `feat/hu11-precios`). Con el diseño del equipo para el catálogo y Editar Producto (stock, fotos, buscador, gráfica del historial). Probada con repositorios falsos (373 pruebas en total). Sus 16 pruebas de políticas en Supabase dan `OK` y el equipo la verificó en Android.** Ver [docs/HU11_informe_implementacion.md](docs/HU11_informe_implementacion.md) |
| **HU-12** | **Búsqueda de productos** | **Implementada (rama `feat/hu12-busqueda`). Búsqueda por nombre o marca y por código de barras con la cámara, rango de precios y establecimientos, paginada. Probada con repositorios falsos (413 pruebas en total). Sus 10 pruebas en Supabase dan `OK` y el equipo la verificó en Android.** Ver [docs/HU12_informe_implementacion.md](docs/HU12_informe_implementacion.md) |
| **HU-14** | **Reporte de precio por el colaborador** | **Implementada y probada con dobles (428 pruebas); el APK de depuración compila. El SQL ya se ejecutó en Supabase y sus 28 pruebas de políticas dan `OK` (incluido un hallazgo de seguridad heredado, ya corregido). El equipo la verificó en Android.** Ver [docs/HU14_informe_implementacion.md](docs/HU14_informe_implementacion.md) y [docs/HU14_informe_pruebas.md](docs/HU14_informe_pruebas.md) |
| **HU-17** | **Carrito de compras y favoritos** | **Implementada, probada con dobles (722 pruebas con `main` integrado), con el SQL ejecutado en Supabase (pruebas de políticas en `OK`, también tras integrar `main`) y probada en un dispositivo Android.** El "Explorar" del cliente es provisional: la búsqueda de la HU-12 ya existe y, desde la HU-13, su detalle del producto tiene los botones de carrito y favoritos. Ver [docs/HU17_informe_implementacion.md](docs/HU17_informe_implementacion.md) y [docs/HU17_informe_pruebas.md](docs/HU17_informe_pruebas.md) |
| **HU-13** | **Detalle del precio con fuente, fecha y confianza** | **Implementada (rama `feat/hu13-detalle-precio`) y probada con dobles (806 pruebas en total). El SQL ya se ejecutó en Supabase y sus 18 pruebas de políticas dan `OK` . El equipo la verificó en Android.** Con ella queda completo el Sprint 2. Ver [docs/HU13_informe_implementacion.md](docs/HU13_informe_implementacion.md) y [docs/HU13_informe_pruebas.md](docs/HU13_informe_pruebas.md) |

### Estado del Sprint 3

| HU | Título | Estado |
|---|---|---|
| **HU-18** | **Alternativas de carrito según el criterio** | **Implementada en la rama `feat/hu18-alternativas-carrito` y probada con dobles (981 pruebas en total). El SQL ya se ejecutó en Supabase y sus 10 pruebas dan `OK`. Falta probarla en Android. El criterio Calidad/precio queda listo y se cierra con las calificaciones de la HU-25.** Ver [docs/HU18_informe_implementacion.md](docs/HU18_informe_implementacion.md) y [docs/HU18_informe_pruebas.md](docs/HU18_informe_pruebas.md) |
| **HU-28** | **Estadísticas reales del panel del administrador** | **Implementada en la rama `feat/hu28-estadisticas-admin` y probada con dobles (1093 pruebas en total). El SQL ya se ejecutó en Supabase y sus 11 pruebas dan `OK`. Falta probarla en Android.** Ver [docs/HU28_informe_implementacion.md](docs/HU28_informe_implementacion.md) y [docs/HU28_informe_pruebas.md](docs/HU28_informe_pruebas.md) |
| **HU-20** | **Confirmación del carrito y generación de órdenes** | **Implementada e integrada con la HU-18 y la HU-19, probada con dobles. El SQL ya se ejecutó en Supabase y sus 48 pruebas dan `OK`. Falta probarla en Android.** Ver [docs/HU20_HU25_informe_implementacion.md](docs/HU20_HU25_informe_implementacion.md) |
| **HU-25** | **Calificaciones de comercios y repartidores** | **Implementada y probada con dobles; su SQL (el mismo de la HU-20) ya se ejecutó en Supabase y sus pruebas dan `OK`. Calificar necesita órdenes completadas (HU-21 y HU-22).** |
| **HU-19** | **Ubicación, radio de búsqueda y mapa** | **Implementada en la rama `feat/hu19-ubicacion-mapa` y probada con dobles (933 pruebas en total). El SQL ya se ejecutó en Supabase y sus 16 pruebas de políticas dan `OK`. Falta probarla en Android.** Ver [docs/HU19_informe_implementacion.md](docs/HU19_informe_implementacion.md) y [docs/HU19_informe_pruebas.md](docs/HU19_informe_pruebas.md) |

**Para probar las diez historias en orden**, seguir el [recorrido para probar el Sprint 2](#recorrido-para-probar-el-sprint-2).

## ¿Qué es SmartCart?

Es una aplicación para optimizar las compras de supermercado. El usuario arma un carrito y SmartCart lo compara entre supermercados de cadena, minimercados y comercios independientes, según precio, disponibilidad, promociones, calificación y distancia. No busca solo el producto más barato, sino la **combinación de compra que más le conviene**.

### Problema que resuelve

- Comparar precios exige revisar varios supermercados, apps o páginas.
- El mejor precio de un producto no siempre es la mejor opción para toda la compra.
- Los precios en línea suelen estar desactualizados, sobre todo en tiendas de barrio y fruver.
- Los comercios pequeños tienen poca visibilidad frente a las cadenas.

### Alternativas de compra

| Criterio | Qué hace |
|---|---|
| Ahorro | Compra cada producto donde sea más barato |
| Calidad/precio | Combina precio y calificación |
| Comodidad | Concentra la compra en pocos establecimientos |

### Fuentes de información

| Fuente | Descripción |
|---|---|
| Cadenas | Catálogo, precios y promociones cargados por API o integración autorizada |
| Comercios registrados | Administran sus propios productos, precios y promociones |
| Comunidad colaboradora | Personas que visitan tiendas y reportan precios a cambio de incentivos |

Cada precio se muestra con su fuente, fecha de actualización y nivel de confianza.

## Roles

| Rol | Qué hace |
|---|---|
| Cliente | Arma el carrito, compara alternativas, genera órdenes (recogida o entrega) y califica |
| Colaborador | Reporta y verifica precios en tiendas; gana puntos, niveles y reputación |
| Comercio | Registra su establecimiento, productos, precios y promociones; gestiona órdenes |
| Repartidor | Acepta solicitudes de entrega, recoge y entrega pedidos |
| Administrador | Supervisa la plataforma y aprueba comercios |

Un mismo usuario puede ser Cliente y Colaborador con una sola cuenta.

**El administrador lo creamos nosotros.** Nadie puede registrarse como administrador desde la app: en el registro esa opción aparece deshabilitada y, además, la política de seguridad de Supabase rechaza ese rol aunque alguien intente enviarlo. Esa cuenta la insertamos a mano en la base de datos (ver [Cómo asignamos un administrador](#configuración-de-supabase)).

## Cómo navegar los flujos

### Cuentas de prueba

Estas son las cuentas que tenemos creadas en nuestro proyecto de Supabase, una por perfil, para probar de inmediato:

| Correo | Nombre | Perfil | Contraseña |
|---|---|---|---|
| admin@gmail.com | Administrador SmartCart | Administrador | Adri7979 |
| adri@gmail.com | Adri | Cliente | Adri7979 |
| loira@gmail.com | Loira | Cliente | Loira123 |
| lina@gmail.com | Lina | Repartidor | Adri7979 |
| paila@gmail.com | La Paila | Comercio | Adri7979 |
| catalina@gmail.com | Catalina | Colaborador | Adri7979 |

El perfil **Colaborador** se prueba con `catalina@gmail.com`. Como un mismo correo puede ser Cliente y Colaborador, también sirve registrar una cuenta nueva y activarle el modo (ver [HU-06](#probar-el-modo-colaborador-hu-06)).

### Iniciar sesión

1. Al abrir la app vemos dos pantallas de bienvenida. En la segunda, el botón siguiente nos lleva a **Selecciona tu perfil**.
2. Tocamos el perfil con el que queremos entrar. Se abre el login de ese perfil (cambian el color, el ícono y el lema).
3. Escribimos correo y contraseña y entramos al **Home** del perfil. Desde la barra inferior abrimos **Perfil**, que es la pantalla de resumen: muestra el nombre y el correo reales de la cuenta.
4. Si la cuenta no tiene el perfil que elegimos, la app cierra la sesión y nos lo explica. Elegir un perfil en pantalla nunca da permisos por sí solo.

### Registrarse

1. En el login de cualquier perfil tocamos **Regístrate aquí**.
2. Llenamos nombre, correo, teléfono (opcional) y contraseña, y elegimos el perfil. El que venimos de elegir ya aparece seleccionado. Administrador está deshabilitado.
3. Al terminar entramos directo al Home del perfil elegido. Si elegimos Colaborador, la app también crea su fila inicial de puntos, nivel y reputación.

### Cerrar sesión y volver atrás

- En **Perfil**, el botón **Cerrar sesión** pide confirmación y nos devuelve a la primera pantalla de la app. Desde ahí podemos volver a entrar con otro perfil.
- Las pantallas de bienvenida (la segunda), la selección de perfil, el login y el registro tienen flecha para volver a la anterior.
- Si Supabase tiene una sesión guardada en el dispositivo, al abrir la app se recupera: con un solo perfil entramos directo a su Home y con varios entramos al que se toque si la cuenta lo tiene.

### Recorrido para probar el Sprint 2

Las diez historias del sprint se pueden probar **en este orden**, porque cada una deja listos los datos de la siguiente: primero se registran y se aprueban los negocios, el comercio publica su catálogo y sus precios, el cliente los busca y arma su carrito, y por último la comunidad reporta precios. Cada historia tiene abajo su sección con los pasos y el resultado esperado. Todo se prueba en **Android** (teléfono o emulador) con las [cuentas de prueba](#cuentas-de-prueba).

| Orden | Historia | Con qué cuenta | Sección |
|---|---|---|---|
| 1 | HU-07 · Registro del comercio | Una cuenta nueva con perfil Comercio | [Probar el registro del comercio](#probar-el-registro-del-comercio-hu-07) |
| 2 | HU-08 · Registro del repartidor | Una cuenta nueva con perfil Repartidor | [Probar el registro del repartidor](#probar-el-registro-del-repartidor-hu-08) |
| 3 | HU-24 · Aprobación de comercios y repartidores | `admin@gmail.com` | [Probar la aprobación](#probar-la-aprobación-de-comercios-y-repartidores-hu-24) |
| 4 | HU-10 · Catálogo del comercio | `paila@gmail.com` (o el comercio recién aprobado) | [Probar el catálogo](#probar-el-catálogo-del-comercio-hu-10) |
| 5 | HU-11 · Precios, disponibilidad y promociones | El mismo comercio | [Probar precios](#probar-precios-disponibilidad-y-promociones-hu-11) |
| 6 | HU-12 · Búsqueda de productos | `adri@gmail.com` (Cliente) | [Probar la búsqueda](#probar-la-búsqueda-de-productos-hu-12) |
| 7 | HU-13 · Detalle del precio con fuente, fecha y confianza | `adri@gmail.com` | [Probar el detalle del precio](#probar-el-detalle-del-precio-hu-13) |
| 8 | HU-17 · Carrito de compras y favoritos | `adri@gmail.com` | [Probar el carrito y los favoritos](#probar-el-carrito-y-los-favoritos-hu-17) |
| 9 | HU-06 · Modo Colaborador | Una cuenta Cliente que aún no lo tenga | [Probar el modo Colaborador](#probar-el-modo-colaborador-hu-06) |
| 10 | HU-14 · Reporte de precio por el colaborador | `catalina@gmail.com` (Colaborador) | [Probar el reporte de precios](#probar-el-reporte-de-precios-hu-14) |

**Antes de empezar:**

1. Ejecutar en Supabase los scripts de la [tabla de scripts](#configuración-de-supabase) en orden: 1, 2, 3, 5, 7, 9, 11 y 13 (los `pruebas_*` son opcionales: comprueban las políticas de seguridad y terminan en `ROLLBACK`).
2. Completar el `.env`, correr `flutter pub get` y lanzar la app en Android: `flutter run -d <id del dispositivo>`. Dar los permisos de cámara y ubicación cuando los pida (el escáner y la ubicación no funcionan en Windows).
3. Para que la búsqueda (HU-12) y el detalle (HU-13) tengan qué mostrar hace falta al menos un comercio **aprobado** con productos **con precio** (secciones HU-10 y HU-11). Si dos comercios tienen el mismo producto (mismo código de barras) se ve la comparación entre tiendas.

### Probar el registro del comercio (HU-07)

1. En **Selecciona tu perfil** tocamos **Comercio** → **Regístrate aquí**, llenamos nombre, correo (uno nuevo), teléfono y contraseña, y creamos la cuenta.
2. Se abre el formulario **Registra tu comercio**: nombre del establecimiento, teléfono, dirección, ciudad y barrio, **Apertura**, **Cierre** y tipo de servicio. Opcionalmente **Usar mi ubicación actual** (la necesita la HU-14; también se puede guardar después desde el Home). Los campos se validan antes de enviar.
3. Tocamos **Registrar**.

**Resultado esperado:** la pantalla **Mi comercio** dice "Tu registro está en revisión", muestra los datos enviados y tiene el botón **Actualizar estado**. Mientras esté pendiente no se puede abrir el catálogo. En el SQL Editor: `select nombre, estado from public.comercio;` muestra el comercio como `pendiente`.

### Probar el registro del repartidor (HU-08)

1. En **Selecciona tu perfil** tocamos **Repartidor** → **Regístrate aquí**, llenamos los datos (correo nuevo) y creamos la cuenta.

**Resultado esperado:** entramos a **Mi registro**: "Tu registro será revisado por el administrador", con nuestro nombre, correo y teléfono, y el botón **Actualizar estado**. Hasta que lo aprueben no puede activar su disponibilidad. En la base: `select * from public.perfil_repartidor;` lo muestra como `pendiente`.

### Probar la aprobación de comercios y repartidores (HU-24)

Necesita las dos solicitudes de las secciones anteriores. Entramos con `admin@gmail.com`.

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Ver las solicitudes pendientes | En el **Panel de control** tocar la pestaña **Aprobar** (o el acceso **Aprobaciones**) | **Solicitudes pendientes** con las pestañas **Comercios** y **Repartidores**, cargadas por páginas de 20 |
| 2. Aprobar | En **Comercios**, abrir el comercio → **Aprobar** → confirmar | "… fue aprobado. Se le notificó la decisión." y el comercio sale de la lista. Al entrar con esa cuenta aparece **"Tu comercio fue aprobado"** y su panel |
| 3. Rechazar con motivo | En **Repartidores**, abrir el repartidor → **Rechazar**. Probar sin escribir el motivo y luego con uno (de 10 a 300 caracteres) | Sin motivo no deja continuar. Con motivo: "… fue rechazado. Se le notificó el motivo." Al entrar con esa cuenta aparece **"Tu registro no fue aprobado"** con el **motivo** |

Solo el administrador puede decidir: una cuenta con otro perfil no ve estas pantallas (y la base rechaza el cambio de estado aunque se intente por fuera de la app). La decisión le llega a la persona cuando vuelve a entrar al Home.

### Probar el catálogo del comercio (HU-10)

1. Entramos con una cuenta de **Comercio aprobada** (por ejemplo la de la tabla de cuentas de prueba). Un comercio pendiente solo ve la pantalla de estado y no puede abrir el catálogo.
2. Abrimos el catálogo desde la pestaña **Catálogo**, el botón **+** o **Ir al Catálogo** del Home. Con **+** creamos un producto; al tocar uno de la lista lo editamos o eliminamos.
3. Para la carga por archivo tocamos el ícono de subir archivo de la barra del catálogo y elegimos un CSV. Dejamos dos de ejemplo en `docs/ejemplos/` (se abren en Excel; usan punto y coma como separador):

| Archivo | Qué contiene | Resultado esperado |
|---|---|---|
| `productos_validos.csv` | 45 productos de las seis categorías, sin errores. Como son más de 20 sirve para ver el paginado de la lista | "Se cargaron 45 productos." y ninguna fila fallida |
| `productos_con_errores.csv` | 11 filas con filas válidas y con errores (nombre corto, categoría inexistente, código inválido, código repetido, sin nombre, sin categoría, marca muy larga) | Cargado solo: 4 productos y 7 filas fallidas (3, 4, 5, 6, 8, 9 y 11). Cargado después del anterior: 3 productos y 8 filas fallidas, porque la fila 2 ya existe |

Para repetir la prueba desde cero hay que eliminar antes los productos cargados: un código de barras no se repite dentro del mismo comercio. El formato del CSV es `nombre;marca;codigo_barras;categoria` (`nombre` y `categoria` obligatorias; coma o punto y coma; máximo 500 filas). La prueba automática `test/catalog/csv_ejemplos_test.dart` comprueba que estos dos archivos den esos resultados.

### Probar precios, disponibilidad y promociones (HU-11)

1. Ejecutamos `docs/sql/sprint2_hu11.sql` en Supabase (pasos 5 y 6 de la tabla de scripts). Crea también el bucket `productos` de Storage para las fotos.
2. Con un **Comercio aprobado** abrimos el **Catálogo**: buscador, chips de categorías, resumen (total de productos, valor del stock y productos con stock bajo) y cada producto con su foto, precio, stock y si está **ACTIVO** o **INACTIVO** (disponible o agotado). Al tocar un producto se abre Editar Producto.
   - Si al guardar aparece "La base de datos no está actualizada", falta ejecutar la versión más reciente de `sprint2_hu11.sql` (por ejemplo, la columna `producto.stock`).
3. Al tocar un producto se abre **Editar Producto**: foto (botón de cámara), código, tienda, gráfica del historial de los últimos 4 meses, precio actual con su variación, stock, interruptor **Disponible/Agotado** y promoción. **Guardar Cambios** guarda el producto, la foto, el precio y la disponibilidad en un solo paso (para marcar agotado hace falta escribir el precio); el precio queda con la fecha, la hora y la fuente "Comercio". Si la promoción ya terminó, aparece como "Vencida" y rige el precio normal.

### Probar la búsqueda de productos (HU-12)

1. Ejecutamos `docs/sql/sprint2_hu12.sql` en Supabase (pasos 7 y 8 de la tabla de scripts) y corremos `flutter pub get` (se agregó `mobile_scanner`).
2. Entramos como **Cliente** y tocamos la lupa o escribimos en el buscador del Home. Cada resultado muestra el rango de precios ("$ 4.200 – $ 5.000") y en cuántos establecimientos está; si no hay coincidencias aparece "No encontramos productos".
3. Al tocar un resultado vemos el precio en cada tienda (el más barato primero, con promoción y fuente). Con **Escanear código de barras** abrimos la cámara; en el emulador, "Escribir el código" hace lo mismo.

### Probar el detalle del precio (HU-13)

1. Ejecutamos `docs/sql/sprint2_hu13.sql` en Supabase (paso 13 de la tabla de scripts; necesita los de HU-12 y HU-17) y `docs/sql/pruebas_hu13_politicas.sql` (paso 14: todas las filas deben decir `OK`).
2. Entramos como **Cliente**, buscamos un producto (lupa del Home) y tocamos un resultado. Cada establecimiento muestra:
   - **Fuente:** "Comercio" o "Comunidad" (lo que reportan los colaboradores).
   - **Fecha y hora** de la última actualización, con "hoy", "ayer" o "hace N días".
   - **Nivel de confianza** (alta, media o baja) y, si el precio tiene más de 7 días, la etiqueta **Desactualizado**.
3. Para ver los **tres escenarios** del backlog:

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Precio reciente de un comercio | Con un Comercio aprobado, guardamos o cambiamos el precio de un producto y lo abrimos como Cliente | "Fuente: Comercio", la fecha de hoy y **Confianza alta** |
| 2. Precio desactualizado | En Supabase → SQL Editor: `update public.precio_producto set actualizado_en = now() - interval '10 days' where id_producto = '<id del producto>';` (el trigger de la tabla fija la fecha en cada cambio, así que primero hay que apagarlo: `alter table public.precio_producto disable trigger precio_producto_fecha;`, y volver a encenderlo con `enable trigger` al terminar). Volver a abrir el detalle | **Desactualizado** y **Confianza baja** |
| 3. Reportar un precio incorrecto | Tocar **Reportar precio incorrecto** en un establecimiento, escribir (o no) el motivo y **Enviar reporte** | "Gracias, enviamos tu reporte para revisarlo", el botón pasa a "Reporte enviado" y en Supabase queda una fila `pendiente` en `reporte_precio_incorrecto` |

4. Si el detalle se abrió desde la búsqueda del Home, cada establecimiento tiene también el corazón de favoritos y el botón de agregar al carrito (HU-17).

### Probar el carrito y los favoritos (HU-17)

Se prueba con una cuenta de **Cliente** (por ejemplo `adri@gmail.com`) y necesita al menos un comercio **aprobado con productos con precio** (HU-10 y HU-11; sirven los CSV de `docs/ejemplos/`).

1. **Dejar lista la base.** Ejecutar `docs/sql/sprint2_hu17.sql` (ver el orden en [Configuración de Supabase](#configuración-de-supabase)).
2. **Abrir la exploración.** En el Home del cliente, tocar **Comenzar ahora**. Es una lista provisional con dos pestañas, **Productos** y **Comercios**, con buscador por nombre. La lupa y el buscador del Home abren la búsqueda de la HU-12, que todavía no trae los botones de carrito y favoritos.
3. **Recorrer los tres escenarios del backlog:**

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Agregar un producto | En **Productos**, tocar el ícono del carrito de un producto | "…" se agregó al carrito; en el carrito queda con cantidad **1**, y la pestaña **Carrito** muestra el número de productos. Agregarlo otra vez le suma 1 (no duplica la línea) |
| 2. Cambiar la cantidad | Pestaña **Carrito**: botones **−** y **+**, y el bote de basura para quitar | La cantidad y el resumen ("2 productos · 5 unidades") se actualizan al instante. Con 1 unidad no se puede bajar más; a las 99 no se puede subir |
| 3. Favoritos | Tocar el corazón de un producto o, en la pestaña **Comercios**, de un comercio | "Guardado en tus favoritos"; el corazón queda lleno. En **Perfil → Mis favoritos** aparecen en dos pestañas. Tocarlo otra vez lo quita |

4. **Comprobar que se guarda.** Cerrar la app por completo y volver a abrirla con la misma cuenta: el carrito y los favoritos siguen ahí.
5. **Ver lo guardado.** En el SQL Editor: `select * from public.carrito_item;`, `select * from public.favorito_producto;` y `select * from public.favorito_comercio;`.

Desde la HU-18 el carrito también muestra el precio de cada producto, su subtotal y el total (ver [Probar la comparación del carrito](#probar-la-comparación-del-carrito-hu-18)).

### Probar el modo Colaborador (HU-06)

Se prueba con una cuenta **Cliente que todavía no tenga el modo activo** (si su **Perfil** muestra puntos, nivel y reputación en vez de "Activar modo Colaborador", ya lo tiene: registrar otra cuenta Cliente). `catalina@gmail.com` ya lo tiene activado.

1. Entramos como **Cliente** → pestaña **Perfil** → **Activar modo Colaborador**.
2. Se abre el onboarding **Modo Colaborador** con "Así funciona reportar un precio" (tres pasos). Tocamos **Continuar**.
3. En **Condiciones de uso** intentamos **Activar** sin marcar la casilla: pide aceptarlas. Marcamos "Acepto las condiciones de uso del modo Colaborador" y tocamos **Activar**.

**Resultado esperado:** volvemos al **Perfil**, que ahora muestra los **puntos, el nivel y la reputación** en vez del botón de activar. Para usar el modo: **Cerrar sesión** → **Selecciona tu perfil** → **Colaborador** → entrar con la misma cuenta; se abre el Home del colaborador. Es una sola cuenta con los dos perfiles.

### Probar el reporte de precios (HU-14)

El reporte exige estar a menos de **150 m** del establecimiento, así que hay que preparar un comercio con ubicación. Se prueba en Android (teléfono o emulador); el escáner no funciona en Windows.

1. **Dejar lista la base.** Ejecutar `docs/sql/sprint2_hu14.sql` (ver el orden en [Configuración de Supabase](#configuración-de-supabase)).
2. **Ubicar el comercio.** Entrar con una cuenta de **Comercio aprobada** estando en el lugar donde se va a probar. En el Home aparece el aviso "Falta la ubicación de tu comercio"; tocar **Guardar ubicación** y aceptar el permiso. Un comercio nuevo también puede tomarla en el formulario de registro. Sin coordenadas el comercio no sale como lugar de reporte.
3. **Tener productos.** El comercio necesita productos en su catálogo (HU-10; sirven los CSV de `docs/ejemplos/`).
4. **Entrar como colaborador.** Con `catalina@gmail.com` (o cualquier cuenta con el modo **Colaborador** activo; ver [HU-06](#probar-el-modo-colaborador-hu-06)), tocar **Reportar precio**, **Escanear** o la pestaña **Reportar Precio**.
5. **Recorrer el flujo:** elegir el establecimiento (aparece con su distancia) → **la cámara del escáner se abre sola**: apuntar al código de barras del producto y, si está en el establecimiento, se pasa directo al formulario → precio, promoción opcional, agotado y **foto de la etiqueta** → **Enviar reporte**. Resultado esperado: "Reporte enviado", queda **pendiente**. Si se cancela el escáner o el código no está, se queda en la lista para buscar por nombre o marca (en Windows no hay escáner y empieza ahí).
6. **Ver el historial.** En el Home del colaborador, "Mis últimos reportes" muestra los 3 más recientes y **Historial** abre la lista completa. Un reporte recién enviado aparece como **Pendiente** aunque nadie lo haya revisado; al validarlo (HU-15) cambiará a Verificado o Rechazado.

Para ver los **tres escenarios del backlog**:

| Escenario | Cómo provocarlo | Resultado esperado |
|---|---|---|
| 1. Reporte exitoso | Los pasos de arriba, en el lugar donde se guardó la ubicación | "Reporte enviado" |
| 2. Fuera del establecimiento | Mover la ubicación del comercio con la consulta de abajo (o cambiar la ubicación del emulador en *Extended controls → Location*) y enviar | "Debes estar en el establecimiento para reportar el precio. Estás a N m." |
| 3. Sin foto | Llenar el precio y enviar sin tomar la foto | "La foto de la etiqueta es obligatoria." |

```sql
-- Mueve el comercio a otro lugar (para provocar el escenario 2). Cambiar el nombre.
update public.comercio set latitud = latitud + 0.01 where nombre = 'La Paila';
```

Para ver lo guardado, en el SQL Editor: `select * from public.reporte_precio order by creado_en desc;` (estado `pendiente`) y, en **Storage → reportes**, la foto en la carpeta del colaborador.

### Probar la comparación del carrito (HU-18)

1. Ejecutar `docs/sql/sprint3_hu18.sql` en Supabase (paso 17 de la tabla de scripts; necesita los de HU-12, HU-17 y HU-19) y `docs/sql/pruebas_hu18_ofertas.sql` (paso 18: todas las filas en `OK`).
2. Datos: dos o más comercios **aprobados con ubicación** que tengan el **mismo producto** (mismo código de barras, o mismo nombre y marca) a precios distintos. Sirve cargar `docs/ejemplos/productos_validos.csv` en dos comercios y cambiar algunos precios (HU-11).
3. Como **Cliente**: agregar varios de esos productos al carrito y abrir **Carrito**. Cada producto muestra su precio vigente (el de la promoción si está vigente) y su subtotal, y abajo el **Total estimado**.
4. Tocar **Comparar carrito** (o **Comparar** en el Home):

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Ahorro | Criterio **Mayor ahorro** | Cada producto en su comercio más barato; total estimado y "Ahorras $ …" frente al carrito actual |
| 2. Comodidad | Criterio **Comodidad** | El menor número de comercios; muestra cuántos y la distancia total |
| 3. Calidad/precio | Criterio **Calidad/precio** | Combina precio y calificación; en el detalle cada comercio muestra su calificación o "Sin calificaciones" (hasta que exista la HU-25) |
| 4. Distancia máxima | Con la ubicación guardada (HU-19), elegir **1 km** o **2 km** | Los comercios más lejanos no aparecen en ninguna alternativa |
| 5. Producto sin disponibilidad | Marcar agotado (HU-11) un producto del carrito en todos los comercios que lo tienen | "No encontramos disponible: …" y alternativas con el resto |
| 6. Carrito vacío | Vaciar el carrito y tocar **Comparar** | "Tu carrito está vacío" y el botón para explorar productos |

**Ver detalle** muestra el mapa con los comercios y, por comercio, cada producto con su precio, fuente, fecha y confianza (HU-13).

### Probar el panel del administrador (HU-28)

1. Ejecutar `docs/sql/sprint3_hu28.sql` en Supabase (paso 23 de la tabla de scripts; necesita los de HU-24, HU-14 y HU-20) y `docs/sql/pruebas_hu28_estadisticas.sql` (paso 24: todas las filas en `OK`).
2. Entrar con `admin@gmail.com`.

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Cifras de la base | Abrir el **Panel de control** y comparar con, por ejemplo, `select estado, count(*) from public.comercio group by estado;` | Usuarios registrados por rol, comercios por estado, repartidores aprobados y en línea, pendientes de revisión y órdenes coinciden con las tablas |
| 2. Actualización | Con un comercio pendiente, tocar **Aprobaciones**, aprobarlo y volver | Baja "Pendientes" y sube "Aprobados" |
| 3. Sin órdenes | Con una base sin órdenes | La sección de órdenes dice "No hay información disponible" |
| 4. Sin permiso | Lo comprueba `pruebas_hu28_estadisticas.sql` (E1 y E2) | La base rechaza a quien no es administrador |

Las cifras se vuelven a consultar al abrir el panel, al volver de Aprobaciones y al tocar la pestaña **Panel**.

### Probar la compra y las calificaciones (HU-20 y HU-25)

1. Ejecutar `docs/sql/sprint3_hu20_hu25.sql` en Supabase (paso 21 de la tabla de scripts; necesita antes los de HU-15/16, HU-17 y HU-19) y `docs/sql/pruebas_hu20_hu25_politicas.sql` (paso 22: todas las filas en `OK`).
2. Como **Cliente**, con productos de comercios aprobados en el carrito: en **Carrito**, **Confirmar compra** (compra el carrito tal cual) o **Comparar carrito** → **Ver detalle** → **Elegir esta alternativa** (HU-18).

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Varios comercios | Confirmar con productos de dos comercios | "Se generaron 2 órdenes", cada una en "Orden generada" con su lista de compra; los productos salen del carrito |
| 2. Entrega no disponible | Con un comercio cuyo servicio es solo recogida | Solo aparece "Recogida en tienda" |
| 3. Entrega sin ubicación | Elegir "Entrega a domicilio" sin ubicación guardada | Pide **Configurar ubicación** (mapa de la HU-19) y no deja confirmar hasta tenerla |
| 4. Carrito vacío | Intentar confirmar sin productos | No se generan órdenes |

3. **Mis órdenes** se abre en **Perfil → Historial de compras**. El botón para calificar aparece cuando una orden está **Recogida** o **Entregada**; mientras no existan las pantallas del comercio y del repartidor, se puede cambiar a mano para probar: `update public.orden set estado = 'recogida' where numero = <número>;`. El promedio se ve en el Perfil del comercio (al volver a entrar) y en el detalle de las alternativas.

### Probar la ubicación y el mapa (HU-19)

1. Ejecutar `docs/sql/sprint3_hu19.sql` en Supabase (paso 15 de la tabla de scripts) y correr `flutter pub get` (se agregaron `flutter_map`, `latlong2` y `geocoding`).
2. Necesita al menos un comercio **aprobado con ubicación guardada** (ver el paso 2 de la [HU-14](#probar-el-reporte-de-precios-hu-14)).
3. Entrar como **Cliente** y tocar el ícono de ubicación del Home (o **Perfil → Mi ubicación**).

| Escenario | Cómo probarlo | Resultado esperado |
|---|---|---|
| 1. Ubicación automática | Aceptar el permiso de ubicación | El mapa se centra en el teléfono con un círculo de 5 km; los comercios aprobados dentro aparecen marcados y en una lista con su distancia |
| 2. Sin permiso | Negar el permiso o apagar la ubicación del teléfono | "Escribe tu dirección"; al buscar, por ejemplo, "Calle 5 # 38-20, Cali" aparece el mapa centrado en esa dirección |
| 3. Cambio del radio | Tocar "10 km" o "20 km" | El círculo crece y aparecen los comercios que quedan dentro |

Al cerrar y volver a abrir la app, el mapa recupera la misma ubicación y el mismo radio (`select * from public.ubicacion_cliente;`).

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter / Dart | App multiplataforma (Android, iOS, Web y Windows en este repositorio) |
| Supabase (PostgreSQL + GoTrue) | Base de datos y autenticación |
| supabase_flutter | Cliente de Supabase |
| flutter_bloc | Gestión de estado con BLoC |
| get_it | Localizador de servicios (Service Locator) para la inyección de dependencias |
| file_picker | Selector de archivos del sistema para la carga del catálogo por CSV (HU-10) y la foto del producto (HU-11) |
| geolocator | Ubicación (GPS) para verificar que el colaborador está en el establecimiento y para guardar la ubicación del comercio (HU-14) |
| image_picker, permission_handler | Foto de la etiqueta con la cámara y su permiso (HU-14) |
| mobile_scanner | Escáner de códigos de barras con la cámara: reporte de precio (HU-14) y búsqueda (HU-12); solo Android, iOS y web |
| flutter_map, latlong2 | Mapa de OpenStreetMap (sin llave) con el radio y los comercios cercanos (HU-19) |
| geocoding | Convierte la dirección escrita por el cliente en coordenadas (HU-19); solo Android e iOS |
| flutter_dotenv | Variables de entorno desde `.env` |
| Clean Architecture por feature | Organización del código (presentación, dominio y datos) |

## Requisitos previos

- **Flutter 3.44.8 / Dart 3.12.2**: son las versiones con las que desarrollamos y comprobamos el proyecto. El `pubspec.yaml` exige Dart `>=3.4.0 <4.0.0`.
- Git y un proyecto de Supabase (ver [Configuración de Supabase](#configuración-de-supabase)).
- Según la plataforma:
  - **Windows**: Visual Studio con la carga de trabajo "Desarrollo para el escritorio con C++" y el *Modo de desarrollador* activado (los plugins necesitan enlaces simbólicos).
  - **Linux**: `clang cmake ninja-build pkg-config libgtk-3-dev`.
  - **Android**: Android Studio con el SDK y las licencias aceptadas (`flutter doctor --android-licenses`).
  - **Web**: Chrome.

Se puede comprobar el entorno con `flutter doctor`.

## Variables de entorno

La app lee `SUPABASE_URL` y `SUPABASE_ANON_KEY` de un archivo `.env` en la raíz (declarado como asset en el `pubspec.yaml` y cargado en `main.dart`). El `.env` está en `.gitignore`; la plantilla es `.env.example`.

**Windows (PowerShell)**

```powershell
Copy-Item .env.example .env
notepad .env
```

**Linux**

```bash
cp .env.example .env
nano .env
```

Hay que reemplazar los valores con los del proyecto propio (en el panel de Supabase: *Project Settings → API*):

```text
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_LLAVE_PUBLICA_ANON
```

> Usamos solo la llave pública (`anon` / *publishable*). **Nunca** hay que poner la `service_role`: el `.env` se empaqueta dentro de la app y cualquiera que la descomprima puede leerlo. La llave pública no protege los datos; lo hacen las políticas RLS.

## Configuración de Supabase

El repositorio **no incluye** `schema.sql` ni migraciones: la base de datos la administramos desde el panel de Supabase. La autenticación usa estas tablas y columnas (las verificamos contra `information_schema` de nuestro proyecto):

| Tabla | Columnas que usa la app |
|---|---|
| `usuario` | `id_usuario` (= `auth.users.id`), `nombre`, `correo`, `telefono` |
| `rol` | `id_rol`, `codigo` (`cliente`, `colaborador`, `comercio`, `repartidor`, `administrador`) |
| `usuario_rol` | `id_usuario`, `id_rol` |
| `perfil_colaborador` | `id_usuario`, `puntos_saldo` (0), `nivel` (1), `reputacion` (0) |

**Qué necesita el proyecto para que el registro y el login funcionen**

1. *Authentication → Providers → Email* habilitado y **"Confirm email" desactivado**. Con la confirmación activa Supabase crea la cuenta sin sesión y las políticas no dejan guardar el perfil; la app lo detecta y lo avisa.
2. La tabla `rol` con las cinco filas y los códigos de la tabla anterior.
3. Políticas RLS (las que ya tiene nuestro proyecto): `usuario` (insert/select/update propios), `usuario_rol` (select propio e insert propio **excluyendo** el rol `administrador`), `rol` (select para todos) y `perfil_colaborador` (insert propio con valores iniciales 0/1/0).
4. Las columnas `NOT NULL` de `usuario` que la app no envía (`estado`, `total_calificaciones`, `fecha_registro`) y `usuario_rol.fecha_asignacion` deben tener un valor por defecto. Para comprobarlo, en el *SQL Editor*:

```sql
select table_name, column_name, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('usuario', 'usuario_rol')
  and is_nullable = 'NO'
order by table_name, ordinal_position;
```

Si alguna sale con `column_default` vacío, el registro falla con un error de "no nulo" (se ve en la consola de depuración con el nombre `smartcart.auth`).

**Cómo asignamos un administrador.** La app no puede hacerlo (la política lo impide y la pantalla de registro lo deshabilita). Lo insertamos a mano desde el *SQL Editor* de Supabase, por ejemplo:

```sql
insert into usuario_rol (id_usuario, id_rol)
select '<uuid-del-usuario>', id_rol from rol where codigo = 'administrador';
```

Para ver quién tiene qué perfil usamos esta consulta:

```sql
select u.correo, u.nombre,
       coalesce(string_agg(r.codigo, ', '), '(sin perfil)') as perfiles
from usuario u
left join usuario_rol ur on ur.id_usuario = u.id_usuario
left join rol r on r.id_rol = ur.id_rol
group by u.correo, u.nombre
order by u.correo;
```

**Tablas del Sprint 2.** Los scripts están en `docs/sql/` y son idempotentes. Se ejecutan en el *SQL Editor* de Supabase, en este orden:

| Orden | Script | Qué crea |
|---|---|---|
| 1 | `sprint2_hu06_07_08.sql` | `perfil_repartidor` y `comercio` con sus políticas |
| 2 | `sprint2_hu24.sql` | `es_administrador()`, `notificacion` y `decidir_solicitud()` |
| 3 | `sprint2_hu10.sql` | `categoria` (con seis categorías), `producto`, `es_comercio_aprobado_propio()` y las políticas de producto |
| 4 | `pruebas_hu10_politicas.sql` | Prueba de las políticas de producto (termina en `ROLLBACK`). Se corrió de nuevo con HU-14 y HU-17 aplicadas: todo `OK` |
| 5 | `sprint2_hu11.sql` | `precio_producto`, `historial_precio` y `promocion`, sus triggers, `es_producto_propio()` y sus políticas; `producto.stock` y `producto.foto_url`, `resumen_catalogo()` y el bucket `productos` de Storage para las fotos |
| 6 | `pruebas_hu11_politicas.sql` | Prueba de las políticas y los triggers de precios (termina en `ROLLBACK`). Se corrió con HU-14 y HU-17 aplicadas: las 16 líneas en `OK` |
| 7 | `sprint2_hu12.sql` | Funciones de la búsqueda del cliente: `buscar_productos()` y `precios_de_producto()` |
| 8 | `pruebas_hu12_busqueda.sql` | Prueba de la búsqueda (termina en `ROLLBACK`) |
| 9 | `sprint2_hu14.sql` | Coordenadas en `comercio`, `comercios_cercanos()`, `reporte_precio` con `enviar_reporte_precio()`, `establecimiento_sugerido` y el bucket de Storage `reportes` |
| 10 | `pruebas_hu14_politicas.sql` | 28 pruebas de las políticas y funciones del reporte, incluido el historial (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 11 | `sprint2_hu17.sql` | `es_cliente()`, `carrito_item`, `favorito_producto`, `favorito_comercio` y las funciones `agregar_al_carrito()`, `mi_carrito()`, `mis_favoritos_*()` y `explorar_*()` |
| 12 | `pruebas_hu17_politicas.sql` | 34 pruebas de las políticas y funciones del carrito y los favoritos (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 13 | `sprint2_hu13.sql` | `reporte_precio_incorrecto` (con su política de lectura propia) y la función `reportar_precio_incorrecto()` |
| 14 | `pruebas_hu13_politicas.sql` | 18 pruebas de la fuente y la fecha que llegan con cada precio y de los reportes de precio incorrecto (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 15 | `sprint3_hu19.sql` | `ubicacion_cliente` (con RLS), `guardar_ubicacion_cliente()` y `comercios_en_radio()` |
| 16 | `pruebas_hu19_politicas.sql` | 16 pruebas de la ubicación del cliente, el radio y los permisos (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 17 | `sprint3_hu18.sql` | `ofertas_del_carrito()` y la fecha de Colombia en `ofertas_publicadas()` para las promociones |
| 18 | `pruebas_hu18_ofertas.sql` | 10 pruebas de las ofertas del carrito, las promociones y los permisos (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 19 | `sprint3_hu15_hu16.sql` | Validación de reportes, puntos, niveles y reputación (HU-15 y HU-16) |
| 20 | `pruebas_hu15_hu16_politicas.sql` | Pruebas de la validación y los puntos (termina en `ROLLBACK`) |
| 21 | `sprint3_hu20_hu25.sql` | `compra`, `orden`, `orden_item` y `calificacion` con RLS; `previsualizar_compra()`, `confirmar_compra()`, `mis_ordenes()`, `calificar_orden()` y la protección de la calificación en `usuario` |
| 22 | `pruebas_hu20_hu25_politicas.sql` | Pruebas de las órdenes, las calificaciones y los permisos (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 23 | `sprint3_hu28.sql` | `estadisticas_panel()`: las cifras del panel, solo para el administrador |
| 24 | `pruebas_hu28_estadisticas.sql` | 11 pruebas de las cifras y los permisos (termina en `ROLLBACK`; devuelve una tabla de resultados) |

Sin el paso 3 la app no encuentra las tablas del catálogo; sin el 5 la lista del catálogo falla porque también pide el precio de cada producto; sin el 7, la búsqueda del cliente; sin el 9, las del reporte de precios, sin el 11, las del carrito y los favoritos, y sin el 13, el reporte de precio incorrecto. Los demás archivos de `docs/sql/` (`perfiles_reales.sql`, `pruebas_hu24_politicas.sql`, `verificar_esquema.sql`, `sprint2_hu24_ajuste.sql`) son de apoyo a las historias anteriores.

## Instalación de dependencias

```powershell
flutter pub get
```

(el mismo comando en Linux). Si cambiamos de rama o de versión de Flutter y algo no resuelve, usamos `flutter clean` y luego `flutter pub get`.

## Ejecución

**Windows (PowerShell)**

```powershell
flutter run -d windows     # escritorio
flutter run -d chrome      # navegador
flutter devices            # lista dispositivos y emuladores
flutter run -d <id>        # Android: emulador o teléfono con depuración USB
```

**Linux**

El repositorio no trae la carpeta `linux/`. Se genera una vez (no toca `lib/` ni los demás archivos):

```bash
flutter create --platforms=linux .
flutter run -d linux       # escritorio
flutter run -d chrome      # navegador
flutter run -d <id>        # Android
```

## Pruebas y análisis

```powershell
flutter analyze
flutter test
```

Los mismos comandos sirven en Linux. Con la última versión (rama de la HU-13), `flutter analyze` no reporta problemas y `flutter test` pasa las **806 pruebas**. Las pruebas no usan Supabase: inyectan repositorios falsos (`test/support/fakes.dart`). Si el equipo tiene poca memoria libre y el compilador de las pruebas se queda sin memoria, `flutter test --concurrency=1` las corre una a la vez.

Lo que estas pruebas **no** comprueban: las políticas RLS reales de Supabase (para eso están los scripts `pruebas_*_politicas.sql`), el selector de archivos del sistema (eso lo probamos a mano) ni el GPS, la cámara y el escáner reales de la HU-14 (las pruebas usan dobles; hay que probarlos en un dispositivo).

| Carpeta | Qué comprueba |
|---|---|
| `test/auth/` | Validadores y casos de uso de inicio de sesión y registro (incluye el rechazo de perfiles que la cuenta no tiene y del administrador) |
| `test/login/`, `test/register/` | Blocs (estados, errores, doble envío) y pantallas (validaciones, carga, scroll con teclado, ancho máximo) |
| `test/session/` | Recuperar y cerrar la sesión |
| `test/navigation/`, `test/widget_test.dart` | Selección de perfil, navegación al login, sesión guardada, Home por perfil y cierre de sesión hacia la primera pantalla |
| `test/onboarding/` | La app arranca en la bienvenida, flechas de regreso y la imagen de la segunda pantalla |
| `test/di/` | Que el localizador de servicios registre y entregue cada dependencia |
| `test/pagination/` | La base de paginado: primera página, siguiente página, fin de la lista, errores y mensajes propios de error |
| `test/aprobaciones/`, `test/notificaciones/`, `test/comercio/`, `test/colaborador/` | HU-06, HU-07, HU-08 y HU-24 (registro, estado y aprobación) |
| `test/cart/`, `test/favoritos/`, `test/explorar/`, `test/cliente/` | HU-17: reglas y casos de uso del carrito, Blocs (cantidad, quitar, favoritos, recuperar lo guardado), pantallas del carrito, los favoritos y la exploración, y el carrito dentro del `RolShell` del cliente |
| `test/confianza/` | HU-13: cálculo de la confianza (tabla de días por fuente y los límites), el caso de uso y el Bloc del reporte, el componente de precio y el detalle completo con los tres escenarios, y los botones de agregar y favoritos desde el detalle |
| `test/reportes/` | HU-14: distancia y reglas, validadores, casos de uso (los tres escenarios del backlog), Blocs, el flujo completo en pantalla, la ubicación del comercio (HU-07) y los accesos del colaborador |
| `test/catalog/` | HU-10: validadores, lectura del CSV, casos de uso, Blocs, pantallas del catálogo y accesos desde el Home del comercio |
| `test/busqueda/` | HU-12: búsqueda por nombre y marca, código escaneado, paginado, detalle por establecimiento y accesos desde el Home del cliente |
| `test/comparacion/` | HU-18: algoritmo de las alternativas (los seis escenarios, empates y distancia máxima), Blocs, la comparación, el detalle y los precios del carrito (incluye 320 px) |
| `test/estadisticas/` | HU-28: lectura de las cifras, permiso del caso de uso, `EstadisticasBloc` y el panel (los escenarios, recarga al volver, error, carga y 320 px) |
| `test/ubicacion/` | HU-19: reglas del radio, casos de uso, `MapaComerciosBloc` (los tres escenarios, errores y doble toque) y la pantalla del mapa (incluye 320 px) |
| `test/prices/`, `test/catalog/catalogo_hu11_test.dart`, `test/catalog/catalogo_diseno_test.dart` | HU-11: formato COP y de fechas, validaciones, vigencia de promociones, casos de uso, Blocs, historial y las pantallas Catálogo y Editar Producto con el diseño (incluye 320 px) |

## Estructura

```text
lib/
├── main.dart                      carga .env, inicia Supabase y registra las dependencias
├── app.dart                       MaterialApp (ruta inicial y router)
├── app_router.dart                resuelve cada ruta y pide cada Bloc al localizador
├── components/                    widgets compartidos de login y registro
├── core/
│   ├── constants/                 tablas/columnas de Supabase, rutas de imágenes
│   ├── di/injector.dart           localizador de servicios (GetIt)
│   ├── domain/user_role.dart      los 5 perfiles (sin Flutter ni Supabase)
│   ├── pagination/                base de paginado (PageRequest, PagedResult, PaginatedBloc)
│   ├── routes/                    nombres de ruta y atajos de navegación
│   ├── ui/pagination/             PaginatedListView, lista reutilizable con paginado
│   ├── ui/roles/                  kit visual por perfil (TemaRol, botones, tarjetas, ...)
│   └── utils/
└── features/
    ├── auth/                      lo que comparten login y registro
    │   ├── domain/                entidades, contratos, casos de uso, validadores
    │   └── data/                  data sources de Supabase y repositorios
    ├── login/ui/                  LoginBloc + LoginScreen (los 5 perfiles)
    ├── register/ui/               RegisterBloc + RegisterScreen (común)
    ├── session/ui/                SessionBloc: recuperar y cerrar sesión
    ├── onboarding/                las dos pantallas de bienvenida
    ├── profile_selection/         pantalla "Selecciona tu perfil"
    ├── home/                      RolShell: Home y Perfil del perfil activo
    ├── catalog/                   HU-10: catálogo del comercio (domain, data, presentation)
    ├── prices/                    HU-11: precios, disponibilidad, promociones e historial (domain, data, presentation)
    ├── busqueda/                  HU-12: búsqueda del cliente, detalle por establecimiento y escáner
    ├── confianza/                 HU-13: confianza del precio (fuente, fecha, desactualizado) y reporte de precio incorrecto
    ├── reportes/                  HU-14: reporte de precio del colaborador (domain, data, presentation)
    ├── ubicacion/                 HU-14: ubicación (GPS) y distancia; HU-19: ubicación y radio del cliente y el mapa
    ├── aprobaciones/              HU-24: solicitudes pendientes y decisión del administrador
    ├── notificaciones/            HU-24: aviso al solicitante
    ├── cart/                      HU-17: carrito del cliente (domain, data, presentation)
    ├── comparacion/               HU-18: precios del carrito y alternativas según el criterio
    ├── orders/                    HU-20: confirmar la compra y las órdenes del cliente
    ├── calificaciones/            HU-25: calificar al comercio y al repartidor
    ├── estadisticas/              HU-28: cifras reales del panel del administrador
    ├── favoritos/                 HU-17: favoritos de productos y comercios
    ├── explorar/                  HU-17: lista provisional de productos y comercios para el cliente
    └── admin | cliente | colaborador | comercio | repartidor
        (notifications/ está vacía: es de HU futuras)
```

Reglas de capas (las mismas de los laboratorios 5 y 6, con la lección de Clean Architecture):

- **Presentación** (pantallas y Blocs): el Bloc hace una sola llamada a un caso de uso y convierte el resultado en estado. Ninguna pantalla toca Supabase.
- **Dominio**: el caso de uso decide el orden (`SignUpUseCase`: primero la cuenta y luego el perfil con el mismo id; `SignInUseCase`: sesión, perfil y verificación del perfil elegido). Trabaja contra contratos (`AuthRepository`, `ProfileRepository`) y no importa nada de la capa de datos.
- **Datos**: solo `SupabaseAuthDataSource` y `SupabaseProfileDataSource` usan el SDK. Traducen los errores de Supabase a `AuthFailure` con mensajes en español.
- **Dependencias**: cada clase recibe lo que necesita por el constructor. Quien las arma es `core/di/injector.dart`, el único archivo que conoce las clases concretas.

## Flujo de autenticación

1. Pantallas 1 y 2 de bienvenida → **Selección de perfil**. La selección se abre encima de la bienvenida, por eso tiene flecha para volver.
2. El perfil elegido abre el **Login** (una sola pantalla; cambian el color, el ícono y el lema). Desde ahí, "Regístrate aquí" abre el **Registro** común, que preselecciona ese perfil.
3. Tras autenticarse, `SignInUseCase` comprueba en `usuario_rol` que la cuenta tenga el perfil elegido; si no, cierra la sesión y lo explica.
4. Se entra al **Home** del perfil (`RolShell`). *Cerrar sesión* en el Perfil llama a `SignOutUseCase`, borra el historial de pantallas y vuelve a la primera pantalla de la app.
5. Supabase guarda la sesión en el dispositivo. Al abrir la app, `SessionBloc` la recupera.

## Informe de criterios de calidad

El profesor nos pidió revisar el Sprint 1 con una lista de criterios de calidad. Hicimos la revisión sobre el código y corregimos lo que no cumplía. Esta tabla resume qué pedía cada criterio y qué hicimos.

| Criterio | Qué hicimos | Dónde está |
|---|---|---|
| Clean Architecture | Separamos cada feature en presentación, dominio y datos. Los casos de uso reciben el repositorio abstracto por constructor y los repositorios reciben su data source por constructor. Ninguna clase del dominio importa la capa de datos. Los data sources reciben el `SupabaseClient` por constructor en vez de leer `Supabase.instance` por dentro. | `lib/features/auth/`, `lib/core/di/` |
| Inyección de dependencias con GetIt (patrón Service Locator) | Agregamos `get_it` y un único archivo, `injector.dart`, donde se registran el cliente de Supabase, los data sources, los repositorios, los casos de uso y los Blocs. `main.dart` lo llama una vez al arrancar y `app_router.dart` pide cada Bloc con `sl<...>()`. Con esto se acabó el armado manual de dependencias dentro del router. En el Sprint 2 las historias nuevas (HU-07, HU-24, HU-10, HU-11, HU-12, HU-14 y HU-17) se registran en el mismo archivo. Ver la [auditoría del Service Locator](#auditoría-del-service-locator-getit). | `lib/core/di/injector.dart`, `lib/main.dart`, `lib/app_router.dart`, `test/di/` |
| BLoC | Login, registro y sesión tienen su Bloc con eventos y estados. Las pantallas solo envían eventos y se redibujan según el estado; no tienen lógica de negocio. | `lib/features/login/ui/bloc/`, `register/ui/bloc/`, `session/ui/bloc/` |
| Reutilización de componentes | Sacamos a widgets compartidos lo que se repetía: `BotonAtras` (flecha de regreso), `mostrarProximamente` (aviso para botones sin función), campos y secciones de login y registro, y el kit visual por perfil (`TemaRol`, botones, tarjetas, menús). | `lib/core/ui/roles/widgets/`, `lib/components/` |
| Carpetas y convenciones | Organizamos por feature y por capa, con nombres en minúscula y guion bajo (`snake_case`) y clases en `PascalCase`. Los archivos compartidos viven en `core/`. Las constantes de tablas, columnas, funciones SQL, rutas e imágenes están en `core/constants/` y `core/routes/`; ningún data source ni pantalla escribe el nombre de una tabla o de una función como texto suelto. | `lib/core/`, `lib/features/` |
| Diseño | Los colores y estilos salen de `TemaRol` (por perfil), `ColoresEstado` (verde, ámbar, azul y rojo) y `ColoresUi` (semilla del tema, fondo de campos, etiqueta de oferta y azul de Google); fuera de `core/ui/roles/` ninguna pantalla escribe un `Color(0x…)`. Solo se usan los neutros de Material (`Colors.white`, `Colors.black` y `Colors.transparent`). Corregimos la selección de perfil, que los tenía fijos. Arreglamos los desbordes de texto en pantallas angostas y la imagen de la segunda pantalla de bienvenida se ajusta completa (`BoxFit.contain`). | `lib/core/ui/roles/`, `lib/features/onboarding/` |
| Navegación | Agregamos la flecha de regreso en la segunda pantalla de bienvenida y en la selección de perfil. Arreglamos que la app abría la selección de perfil como si fuera la primera pantalla; ahora arranca en la bienvenida. Al cerrar sesión volvemos a la primera pantalla y borramos el historial, así que no se puede regresar al Home con el botón atrás. | `lib/app.dart`, `lib/core/routes/`, `lib/features/home/` |
| Manejo de errores y experiencia de usuario | Los errores de Supabase se traducen a mensajes en español y se muestran al usuario. Los formularios validan antes de enviar, muestran carga y no dejan enviar dos veces. Los botones que todavía no tienen función muestran "Esta función estará disponible próximamente." en vez de quedar sin respuesta. | `lib/features/auth/domain/failures/`, `lib/core/ui/roles/widgets/varios.dart` |
| Calidad y pruebas | Con la última versión (rama de la HU-13), `flutter analyze` no reporta problemas y `flutter test` pasa las 806 pruebas (casos de uso, Blocs, pantallas, navegación, inyección de dependencias y paginado). Las pruebas usan repositorios falsos, no dependen de Supabase. | `test/` |
| Paginado | Base reutilizable: `PageRequest` y `PagedResult` para pedir páginas, `PaginatedBloc<T>` para cargar la siguiente página, detectar el final y reintentar, y `PaginatedListView<T>` como lista con carga al llegar al final. Ya está conectada a las listas con datos de Supabase: las solicitudes pendientes del administrador (HU-24), el catálogo del comercio (HU-10 y HU-11), la búsqueda de productos del cliente (HU-12), en la HU-14 los establecimientos cercanos, la búsqueda de productos del reporte y el historial de reportes, y en la HU-17 la exploración y los favoritos. `PaginatedBloc` acepta un `errorMessageFor` opcional para mostrar el mensaje propio de un error esperado en vez del genérico. | `lib/core/pagination/`, `lib/core/ui/pagination/`, `test/pagination/` |

## Auditoría del Service Locator (GetIt)

Revisamos que la app implemente el patrón Service Locator y dónde se aplica. **Conclusión: sí lo implementa**, con las observaciones del final. Esto es lo que comprobamos y cómo repetirlo.

### Dónde se aplica

| Pieza | Dónde | Qué hace |
|---|---|---|
| Contenedor | `lib/core/di/injector.dart` (`final GetIt sl`) | Es el único contenedor. No hay otro. |
| Registro | `setupDependencies()`, llamada una vez desde `lib/main.dart` | Registra, de adentro hacia afuera: `SupabaseClient` → data sources → repositorios (con el tipo del contrato) → casos de uso → Blocs. Es idempotente: llamarla de nuevo no duplica registros. |
| Consulta | `lib/app_router.dart` | Es el único lugar que pide dependencias con `sl<...>()`, para dárselas a cada pantalla con `BlocProvider`. Las pantallas y los Blocs no conocen el localizador. |
| Parámetros | `registerFactoryParam` | Los Blocs que necesitan un dato de la pantalla: `DecisionSolicitudBloc` y `PaginatedBloc<Solicitud>` (HU-24) `ProductoFormBloc` (HU-10, con `null` para crear), `PrecioProductoBloc` (HU-11, con el producto), y `PaginatedBloc<ResultadoBusqueda>` (con el texto del Home) y `DetalleProductoBloc` (con la consulta) de la HU-12, y `DisponibilidadBloc` (HU-08, con la disponibilidad guardada del repartidor). La lista del catálogo se registra como `PaginatedBloc<Producto>` pero es un `CatalogoListaBloc` (agrega búsqueda y filtro). |

Ciclo de vida: los data sources, repositorios y casos de uso son `registerLazySingleton` (sin estado); los Blocs son `registerFactory`, porque guardan estado y cada pantalla debe tener el suyo.

### Evidencia (revisión del 14 de noviembre de 2026, repetida el 15 con la HU-11 y el 16 con la HU-13)

| Comprobación | Resultado |
|---|---|
| `Supabase.instance` fuera del inyector | Una sola aparición: `injector.dart`. El resto recibe `SupabaseClient` por constructor |
| `sl<` o `GetIt` fuera del inyector | Solo `app_router.dart` |
| Data sources o repositorios construidos fuera del inyector | Ninguno |
| Imports de `flutter`, `supabase_flutter`, `get_it` o `file_picker` en las carpetas `domain/` | Ninguno |
| Registros en `injector.dart` | 110 (64 de `main` hasta la HU-12, 42 de HU-14 y HU-17, 3 de la HU-13 y 1 que pasó del router al inyector: `DisponibilidadBloc`) |
| `test/di/injector_test.dart` | Comprueba los registros (repositorios con el tipo del contrato, Bloc de fábrica, casos de uso únicos), que `setupDependencies` no duplica, y que la cadena completa del catálogo se arma con un cliente de Supabase sin conexión |

Para repetir las comprobaciones:

```bash
grep -rn "Supabase.instance" lib
grep -rn -E "\bsl<|GetIt\." lib | grep -v "lib/core/di/injector.dart"
grep -rln -E "package:(flutter|supabase_flutter|get_it|flutter_bloc|file_picker)/" lib/features/*/domain
flutter test test/di
# Ningún Bloc, caso de uso, repositorio ni data source se construye fuera del inyector (debe no mostrar nada):
grep -rn -E "(=>|=|return|\(|,|:)\s*(const )?[A-Z][A-Za-z]*(Bloc|UseCase|RepositoryImpl|DataSource)\(" lib --include=*.dart | grep -v "lib/core/di/injector.dart" | grep -v -E ":[0-9]+:\s*//"
```

## Decisiones de diseño

- **Fondo blanco** en login y registro; los campos conservan el gris claro del diseño. Los colores salen de `TemaRol`; no definimos otra paleta.
- **Administrador en el registro**: no aparece como opción porque lo asignamos nosotros; una persona no se puede registrar como admin.
- **Teléfono opcional**: la columna `usuario.telefono` admite nulos y el diseño no lo marca como obligatorio. Si se escribe, se valida el formato.
- **Colaborador** crea también su fila inicial en `perfil_colaborador` (los valores 0/1/0 los exige la política).
- **Lemas del login** por perfil: los tomamos de la tabla de roles de este README; el del colaborador es el del diseño.
- **Datos de ejemplo**: el nombre, el correo y el teléfono que se ven en el Perfil son los de la sesión. Quitamos la ciudad "Bogotá" y las etiquetas "Premium / Nivel Plata / aprobado" porque no existen en la base de datos. El resto de tarjetas (ofertas, misiones, estadísticas) sigue siendo contenido de ejemplo de la maqueta.
- **Imágenes**: ilustraciones propias en `assets/images/` (avatar de muestra por perfil, logo, imagen de la segunda bienvenida y banner del registro); si no cargan, se muestran las iniciales.

### Observaciones

- En las pruebas armamos los Blocs a mano con repositorios falsos (`TestEnv`) y no con `sl`: es a propósito, para no depender de Supabase.
- `lib/core/pagination/paginated_bloc.dart` importa `flutter_bloc` porque es un Bloc, no una clase de dominio.
- **Registro con nombre.** `PaginatedBloc<Producto>` existe dos veces: sin nombre (catálogo, HU-10) y con `InstanciasSl.busquedaProductos` (búsqueda del reporte, HU-14, con `param1` y `param2`). GetIt no admite el mismo tipo dos veces sin nombre. Una prueba de `test/di/` comprueba que conviven.
- **HU-17: cuatro nombres más.** `PaginatedBloc<ProductoConComercio>` y `PaginatedBloc<ComercioResumen>` se usan dos veces cada uno (exploración y favoritos), así que las cuatro listas llevan nombre (`InstanciasSl.explorarProductos`, `explorarComercios`, `favoritosProductos` y `favoritosComercios`). `CarritoBloc` y `FavoritosBloc` son fábricas, pero el `RolShell` del cliente crea **una sola instancia de cada uno** por sesión y la comparte con todas las pantallas (las rutas la reciben como argumento y el `AppRouter` la entrega con `BlocProvider.value`).
- **HU-13.** El reporte de precio incorrecto sigue el mismo camino que las demás historias: `SupabaseReporteIncorrectoDataSource` → `ReporteIncorrectoRepository` (registrado con el tipo del contrato) → `ReportarPrecioIncorrectoUseCase`, y `DetalleProductoBloc` lo recibe por constructor desde `registerFactoryParam`. El cálculo de la confianza (`ConfianzaReglas`) es una función pura de dominio y no necesita registro.
- **Nombres repetidos entre HU-12 y HU-14.** Al integrar `main` las dos historias tenían `BuscarProductosUseCase` y `ConsultaProducto`. Los de la HU-14 (reporte de precio) pasaron a llamarse `BuscarProductosReporteUseCase` y `ConsultaProductoReporte`; los de la HU-12 no cambiaron.
- Los plugins de la HU-14 (`geolocator`, `image_picker`, `permission_handler`) quedan detrás de los contratos `ServicioUbicacion` y `SelectorFoto`; `mobile_scanner` solo aparece en las dos pantallas del escáner, `EscanerPage` (HU-12) y `EscanerCodigoPage` (HU-14), porque es un widget de cámara y no lógica de datos.
- **Sin excepciones al patrón.** Todos los Blocs que usa la app se piden al localizador con `sl<...>()` desde `app_router.dart`; ya no se arma ninguno a mano (el último, `DisponibilidadBloc`, ahora es un `registerFactoryParam` con el valor guardado como `param1`). La comprobación 5 de abajo lo verifica.

## Limitaciones conocidas y pasos pendientes

- **Continuar con Google** y **¿Olvidaste tu contraseña?** están en el diseño pero no están implementados: muestran un aviso. Google requiere configurar el proveedor y los enlaces de retorno en Supabase.
- Varios botones de los Home y Perfil muestran "próximamente": son funciones de sprints siguientes. Siguen siendo **datos de ejemplo**: las ventas y órdenes del Home del comercio, los pedidos disponibles del repartidor, las "Misiones" del colaborador y las tarjetas "Ofertas cerca de ti" del cliente. Lo que sí es real en el Sprint 2: el registro y la aprobación de comercios y repartidores, el catálogo y los precios, la búsqueda y el detalle del precio, el carrito y los favoritos, y los reportes del colaborador.
- **HU-07, HU-08 y HU-24 (registro y aprobación):**
  - Un comercio o un repartidor rechazado no puede volver a enviar su registro desde la app.
  - La decisión del administrador le llega a la persona cuando vuelve a entrar al Home: no hay notificaciones push ni en tiempo real.
  - El administrador se asigna a mano en la base (ver [Configuración de Supabase](#configuración-de-supabase)); nadie se registra como administrador desde la app.
  - El repartidor aprobado solo tiene su disponibilidad real; los pedidos que ve son de ejemplo (órdenes: Sprint 3).
- **HU-06 (modo Colaborador):** se activa desde el Perfil del cliente y se usa volviendo a entrar con el perfil Colaborador y la misma cuenta. Los puntos, el nivel y la reputación se muestran, pero solo empezarán a cambiar cuando se validen los reportes (HU-15 y HU-16, Sprint 3).
- **HU-10 (catálogo del comercio):**
  - Las categorías son una lista fija (Super, Frutas, Lácteos, Aseo, Café, Panadería); el comercio no crea las suyas.
  - Eliminar un producto es definitivo.
  - El CSV lleva `nombre` y `categoria` (obligatorias) y `marca` y `codigo_barras` (opcionales), con un máximo de 500 filas. El selector de archivos lo probamos a mano con los CSV de `docs/ejemplos/`.
  - Los clientes ven los productos solo a través de la búsqueda (HU-12), que usa funciones de la base que devuelven únicamente lo publicado por comercios aprobados; no leen la tabla `producto`.
- **HU-11 (precios, disponibilidad y promociones):**
  - Una promoción por producto; guardar otra la reemplaza. Para marcar un producto como agotado, primero debe tener precio.
  - Precios en pesos enteros, sin centavos. La gráfica usa los últimos 60 cambios del historial (4 meses).
  - Stock y fotos se agregaron para seguir el diseño del equipo; no los pide la HU-11. "Stock bajo" es 10 unidades o menos. Las fotos (JPG, PNG o WEBP, hasta 5 MB) quedan públicas en el bucket `productos`; las fotos reemplazadas no se borran del bucket.
  - El aviso del diseño ("los cambios serán validados por colaboradores") se cambió por el comportamiento real de la HU-11: el precio del comercio se publica de inmediato con fuente "Comercio".
  - La vigencia de la promoción se compara con la fecha del teléfono.
  - Los clientes ven los precios con la HU-12 (búsqueda) y la HU-13 (detalle con fuente, fecha y confianza); tampoco leen las tablas de precios directamente.
- **HU-12 (búsqueda):**
  - "El mismo producto" en varias tiendas se reconoce por el código de barras o, si no tiene, por el nombre y la marca exactos.
  - Solo aparecen productos con precio de comercios aprobados. El nivel de confianza de cada precio lo calcula la HU-13 en el detalle.
  - En el emulador no hay cámara: el escáner ofrece "Escribir el código".
  - La lupa y el buscador del Home abren esta búsqueda. Desde la HU-18, el botón **Comparar** abre la comparación del carrito completo.
  - Las tarjetas de resultado muestran el rango de precios; la fuente, la fecha y la confianza se ven en el detalle (HU-13).
- **HU-13 (detalle del precio):**
  - Necesita `docs/sql/sprint2_hu13.sql` en Supabase (después de los de HU-12 y HU-17); `pruebas_hu13_politicas.sql` debe dar todas las líneas en `OK`; en nuestro Supabase ya se corrieron los dos y dieron las 18 líneas en `OK`. La primera ejecución reveló que `btrim` no quitaba los saltos de línea de un motivo en blanco; el script ya los quita. El equipo la verificó en Android.
  - **Las reglas de confianza las fijamos nosotros** (el backlog dice "depende de la fuente y de qué tan reciente es" y deja el límite al equipo): el comercio parte de *alta* y la comunidad de *media* (nunca llega a alta hasta que exista la validación de reportes, HU-15); hasta 3 días no baja; de 4 a 7 días baja un nivel; **más de 7 días** el precio se marca **Desactualizado** y baja dos niveles. Las constantes están en `ConfianzaReglas` (`diasReciente` y `diasLimite`) y la tabla completa en el informe de la HU.
  - La confianza se calcula en la app con la **fecha del teléfono**; si el reloj está mal puesto, los días se calculan mal (una fecha futura cuenta como "hoy").
  - Los reportes de precio incorrecto solo **quedan pendientes** (con el precio, la fuente y la fecha que el cliente veía, y un motivo opcional de hasta 300 caracteres). Revisarlos, corregir el precio o sancionar es de la moderación (HU-27, Sprint 3). Un cliente no puede tener dos reportes pendientes del mismo precio.
  - La fuente `colaborador` de la base se muestra como **Comunidad**, como pide el backlog. Hoy el único que escribe `precio_producto` es el comercio; los precios de la comunidad llegarán cuando se validen los reportes de colaborador (HU-15).
- **HU-14 (reporte de precio):**
  - Necesita `docs/sql/sprint2_hu14.sql` en Supabase (en nuestro proyecto ya se ejecutó y `pruebas_hu14_politicas.sql` dio las 28 líneas en `OK`, incluidas las del historial `mis_reportes()`). La primera ejecución de la prueba reveló una política antigua, `comercio_update_own`, que dejaba al dueño cambiar su propio estado de aprobación; el script la elimina (sección 8) y quien use otra base debe ejecutarlo también.
  - El GPS, la cámara, el permiso y el escáner reales los verificó el equipo en Android; las pruebas automáticas usan dobles.
  - Un comercio solo aparece como lugar de reporte si guardó su ubicación (registro o aviso del Home). Los comercios anteriores a esta historia no la tienen.
  - La distancia máxima es de 150 m (constante `ReporteReglas.radioMaximoM` y en la función SQL).
  - El escáner de códigos no funciona en Windows; ahí queda la búsqueda por nombre.
  - Solo guarda el reporte como pendiente: no cambia ningún precio. Validarlo y dar puntos son las HU-15 y HU-16 (Sprint 3).
  - Para elegir qué reportar, los colaboradores leen los productos de comercios aprobados (política `producto_select_colaborador`). Por eso `pruebas_hu10_politicas.sql` y `pruebas_hu11_politicas.sql` quitan el rol colaborador al "otro usuario" dentro de su transacción: prueban a alguien sin ese permiso.
- **HU-17 (carrito y favoritos):**
  - Necesita `docs/sql/sprint2_hu17.sql` en Supabase (sin él la app no encuentra el carrito, los favoritos ni la exploración). Después, `pruebas_hu17_politicas.sql` debe dar todas las líneas en `OK`; en nuestro Supabase, con `main` integrado, dieron todo `OK`. El carrito y los favoritos también los verificó el equipo en un dispositivo Android (las pruebas automáticas usan dobles).
  - Los precios, el total y la comparación del carrito los agregó la HU-18.
  - **"Explorar" es provisional.** Es la lista mínima desde la que el cliente agrega y marca favoritos (se abre con **Comenzar ahora**). La búsqueda de la HU-12 ya existe y es la que abren la lupa y el buscador del Home; desde la HU-13 su detalle del producto tiene los botones de carrito y favorito (con `AgregarCarritoBoton` y `FavoritoBoton`), pero sus tarjetas de resultado todavía no. Cuando el equipo decida retirar Explorar, esos dos botones se pueden poner también en las tarjetas.
  - Límites que fijamos nosotros (el backlog no los define): 99 unidades por producto y 100 productos distintos. El carrito se lee completo en una sola consulta; las listas de favoritos y de exploración sí se paginan.
  - Cada línea del carrito es un producto **de un comercio**. Cómo reconocer el mismo producto en varios comercios (para comparar el carrito, HU-18) es una decisión pendiente del equipo.
  - Las tarjetas de "Ofertas cerca de ti" del Home siguen siendo de ejemplo y su botón de agregar todavía avisa "próximamente".
- **HU-18 (alternativas de carrito):**
  - Necesita `docs/sql/sprint3_hu18.sql` en Supabase; en nuestro proyecto ya se ejecutó y `pruebas_hu18_ofertas.sql` dio las 10 líneas en `OK`. Falta probarla en un dispositivo Android.
  - **Calidad/precio depende de la HU-25.** Lee `calificacion_promedio` y `total_calificaciones` del dueño del comercio en `usuario`; mientras no existan, todos los comercios cuentan como neutros y se muestra "Sin calificaciones". La fórmula (`ComparacionReglas`): `precio × (1 + 0,20 × (5 − calificación) / 4)`, y un comercio sin calificaciones cuenta como 3.
  - El ahorro se calcula sobre los productos que tienen precio en el carrito actual y en la alternativa; nunca es negativo.
  - Una alternativa se elige en su detalle y se confirma con la HU-20. La distancia es en línea recta.
- **HU-28 (panel del administrador):**
  - Necesita `docs/sql/sprint3_hu28.sql` en Supabase; en nuestro proyecto ya se ejecutó y `pruebas_hu28_estadisticas.sql` dio las 11 líneas en `OK`. Falta probarla en un dispositivo Android.
  - "Reportes de precio" pendientes cuenta la tabla `reporte_precio`, como cita el backlog; los reportes de precio incorrecto de los clientes (HU-13) se revisan en la HU-27 y no se suman.
  - "Usuarios registrados" va por rol: una cuenta con dos perfiles cuenta en ambos, por eso no se muestra un total.
  - Las cifras no se actualizan solas mientras el panel está abierto; se consultan al abrirlo o volver a él.
- **HU-20 y HU-25 (órdenes y calificaciones):**
  - Necesitan `docs/sql/sprint3_hu20_hu25.sql` en Supabase (después del de la HU-19); en nuestro proyecto ya se ejecutó y `pruebas_hu20_hu25_politicas.sql` dio las 48 líneas en `OK`. Falta probarlas en un dispositivo Android.
  - La entrega usa como destino la ubicación guardada del cliente (HU-19). "Confirmar compra" del carrito compra el carrito tal cual; las alternativas se confirman desde su detalle.
  - Los estados de la orden solo cambian cuando existan la gestión del comercio (HU-21) y la entrega (HU-22); avisar al comercio de una orden nueva es de la HU-21.
  - Si una cuenta fuera a la vez dueña de un comercio y repartidora, sus dos promedios se mezclarían (se guardan en `usuario`).
- **HU-19 (ubicación, radio y mapa):**
  - Necesita `docs/sql/sprint3_hu19.sql` en Supabase; en nuestro proyecto ya se ejecutó y `pruebas_hu19_politicas.sql` dio las 16 líneas en `OK`. La primera ejecución reveló que `comercio.latitud` y `longitud` son `numeric` en nuestra base; `comercios_en_radio()` ya las convierte. Falta probarla en un dispositivo Android.
  - El radio va de 1 a 20 km (`RadioReglas` y el SQL); empieza en 5 km.
  - Buscar una dirección usa el geocodificador del teléfono: no funciona en Windows y puede fallar en emuladores sin Google Play.
  - El mapa descarga las teselas de OpenStreetMap: sin internet se ven el círculo y los puntos, pero no las calles.
- La app declara el permiso `INTERNET` en el manifiesto de Android: sin él, una versión *release* no se conecta a Supabase.
- `pubspec.lock` se regenera con `flutter pub get` (se agregaron `flutter_bloc`, `get_it`, `file_picker` en la HU-10, `mobile_scanner` en la HU-12 y `geolocator`, `image_picker` y `permission_handler` en la HU-14).

## Equipo

- Adri Jhoanny Martinez Murillo
- Daniel Trujillo Marin
- Carol Andrea Mosquera
- Angy Maria Hurtado Osorio
- Laura Isabella Coral Garcia
