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
| **HU-11** | **Precios, disponibilidad y promociones** | **Implementada (rama `feat/hu11-precios`). Con el diseño del equipo para el catálogo y Editar Producto (stock, fotos, buscador, gráfica del historial). Probada con repositorios falsos (373 pruebas en total). Falta ejecutar sus pruebas de políticas en Supabase.** Ver [docs/HU11_informe_implementacion.md](docs/HU11_informe_implementacion.md) |
| **HU-12** | **Búsqueda de productos** | **Implementada (rama `feat/hu12-busqueda`). Búsqueda por nombre o marca y por código de barras con la cámara, rango de precios y establecimientos, paginada. Probada con repositorios falsos (413 pruebas en total). Falta ejecutar sus pruebas en Supabase.** Ver [docs/HU12_informe_implementacion.md](docs/HU12_informe_implementacion.md) |
| **HU-14** | **Reporte de precio por el colaborador** | **Implementada y probada con dobles (428 pruebas); el APK de depuración compila. El SQL ya se ejecutó en Supabase y sus 28 pruebas de políticas dan `OK` (incluido un hallazgo de seguridad heredado, ya corregido). Falta probar la app en un dispositivo Android.** Ver [docs/HU14_informe_implementacion.md](docs/HU14_informe_implementacion.md) y [docs/HU14_informe_pruebas.md](docs/HU14_informe_pruebas.md) |
| **HU-17** | **Carrito de compras y favoritos** | **Implementada, probada con dobles (722 pruebas con `main` integrado), con el SQL ejecutado en Supabase (pruebas de políticas en `OK`, también tras integrar `main`) y probada en un dispositivo Android.** El "Explorar" del cliente es provisional: la búsqueda de la HU-12 ya existe, pero aún no trae los botones de carrito y favoritos. Ver [docs/HU17_informe_implementacion.md](docs/HU17_informe_implementacion.md) y [docs/HU17_informe_pruebas.md](docs/HU17_informe_pruebas.md) |
| HU-13 | Detalle del precio | **Todavía no implementada** |

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

Estas son las cuentas que tenemos creadas en nuestro proyecto de Supabase, una por perfil que se puede probar de inmediato:

| Correo | Nombre | Perfil | Contraseña |
|---|---|---|---|
| admin@gmail.com | Administrador SmartCart | Administrador | Adri7979 |
| adri@gmail.com | Adri | Cliente | Adri7979 |
| loira@gmail.com | Loira | Cliente | Loira123 |
| lina@gmail.com | Lina | Repartidor | Adri7979 |
| paila@gmail.com | La Paila | Comercio | Adri7979 |

Para probar el perfil **Colaborador** hay que crear la cuenta desde el registro (ver el paso a paso de abajo). Como un mismo correo puede ser Cliente y Colaborador, también sirve registrar una cuenta nueva con los dos perfiles.

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

### Probar el carrito y los favoritos (HU-17)

Se prueba con una cuenta de **Cliente** (por ejemplo la de `adri@gmail.com` de las cuentas de prueba) y necesita al menos un comercio **aprobado con productos** (HU-10; sirven los CSV de `docs/ejemplos/`).

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

El carrito muestra productos y cantidades, sin precios ni totales: la HU-11 ya guarda los precios, pero esta historia no los lee (el total y la comparación son de la HU-18).

### Probar el reporte de precios (HU-14)

El reporte exige estar a menos de **150 m** del establecimiento, así que hay que preparar un comercio con ubicación. Se prueba en Android (teléfono o emulador); el escáner no funciona en Windows.

1. **Dejar lista la base.** Ejecutar `docs/sql/sprint2_hu14.sql` (ver el orden en [Configuración de Supabase](#configuración-de-supabase)).
2. **Ubicar el comercio.** Entrar con una cuenta de **Comercio aprobada** estando en el lugar donde se va a probar. En el Home aparece el aviso "Falta la ubicación de tu comercio"; tocar **Guardar ubicación** y aceptar el permiso. Un comercio nuevo también puede tomarla en el formulario de registro. Sin coordenadas el comercio no sale como lugar de reporte.
3. **Tener productos.** El comercio necesita productos en su catálogo (HU-10; sirven los CSV de `docs/ejemplos/`).
4. **Entrar como colaborador.** Con una cuenta que tenga el modo **Colaborador** activo, tocar **Reportar precio**, **Escanear** o la pestaña **Reportar Precio**.
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
| 4 | `pruebas_hu10_politicas.sql` | Prueba de las políticas de producto (termina en `ROLLBACK`) |
| 5 | `sprint2_hu11.sql` | `precio_producto`, `historial_precio` y `promocion`, sus triggers, `es_producto_propio()` y sus políticas; `producto.stock` y `producto.foto_url`, `resumen_catalogo()` y el bucket `productos` de Storage para las fotos |
| 6 | `pruebas_hu11_politicas.sql` | Prueba de las políticas y los triggers de precios (termina en `ROLLBACK`) |
| 7 | `sprint2_hu12.sql` | Funciones de la búsqueda del cliente: `buscar_productos()` y `precios_de_producto()` |
| 8 | `pruebas_hu12_busqueda.sql` | Prueba de la búsqueda (termina en `ROLLBACK`) |
| 9 | `sprint2_hu14.sql` | Coordenadas en `comercio`, `comercios_cercanos()`, `reporte_precio` con `enviar_reporte_precio()`, `establecimiento_sugerido` y el bucket de Storage `reportes` |
| 10 | `pruebas_hu14_politicas.sql` | 28 pruebas de las políticas y funciones del reporte, incluido el historial (termina en `ROLLBACK`; devuelve una tabla de resultados) |
| 11 | `sprint2_hu17.sql` | `es_cliente()`, `carrito_item`, `favorito_producto`, `favorito_comercio` y las funciones `agregar_al_carrito()`, `mi_carrito()`, `mis_favoritos_*()` y `explorar_*()` |
| 12 | `pruebas_hu17_politicas.sql` | 34 pruebas de las políticas y funciones del carrito y los favoritos (termina en `ROLLBACK`; devuelve una tabla de resultados) |

Sin el paso 3 la app no encuentra las tablas del catálogo; sin el 5 la lista del catálogo falla porque también pide el precio de cada producto; sin el 7, la búsqueda del cliente; sin el 9, las del reporte de precios, y sin el 11, las del carrito y los favoritos. Los demás archivos de `docs/sql/` (`perfiles_reales.sql`, `pruebas_hu24_politicas.sql`, `verificar_esquema.sql`, `sprint2_hu24_ajuste.sql`) son de apoyo a las historias anteriores.

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

Los mismos comandos sirven en Linux. Con la última versión (rama de la HU-17, con `main` integrado), `flutter analyze` no reporta problemas y `flutter test` pasa las **722 pruebas**. Las pruebas no usan Supabase: inyectan repositorios falsos (`test/support/fakes.dart`). Si el equipo tiene poca memoria libre y el compilador de las pruebas se queda sin memoria, `flutter test --concurrency=1` las corre una a la vez.

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
| `test/reportes/` | HU-14: distancia y reglas, validadores, casos de uso (los tres escenarios del backlog), Blocs, el flujo completo en pantalla, la ubicación del comercio (HU-07) y los accesos del colaborador |
| `test/catalog/` | HU-10: validadores, lectura del CSV, casos de uso, Blocs, pantallas del catálogo y accesos desde el Home del comercio |
| `test/busqueda/` | HU-12: búsqueda por nombre y marca, código escaneado, paginado, detalle por establecimiento y accesos desde el Home del cliente |
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
    ├── reportes/                  HU-14: reporte de precio del colaborador (domain, data, presentation)
    ├── ubicacion/                 HU-14: ubicación (GPS) y distancia; la usan el comercio y los reportes
    ├── aprobaciones/              HU-24: solicitudes pendientes y decisión del administrador
    ├── notificaciones/            HU-24: aviso al solicitante
    ├── cart/                      HU-17: carrito del cliente (domain, data, presentation)
    ├── favoritos/                 HU-17: favoritos de productos y comercios
    ├── explorar/                  HU-17: lista provisional de productos y comercios para el cliente
    └── admin | cliente | colaborador | comercio | repartidor
        (orders/ y notifications/ están vacías: son de HU futuras)
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
| Carpetas y convenciones | Organizamos por feature y por capa, con nombres en minúscula y guion bajo (`snake_case`) y clases en `PascalCase`. Los archivos compartidos viven en `core/`. Las constantes de tablas, columnas, rutas e imágenes están en `core/constants/` y `core/routes/`, sin textos sueltos en las pantallas. | `lib/core/`, `lib/features/` |
| Diseño | Los colores y estilos salen de `TemaRol`, sin colores escritos a mano en las pantallas; corregimos la selección de perfil, que los tenía fijos. Arreglamos los desbordes de texto en pantallas angostas y la imagen de la segunda pantalla de bienvenida se ajusta completa (`BoxFit.contain`). | `lib/core/ui/roles/`, `lib/features/onboarding/` |
| Navegación | Agregamos la flecha de regreso en la segunda pantalla de bienvenida y en la selección de perfil. Arreglamos que la app abría la selección de perfil como si fuera la primera pantalla; ahora arranca en la bienvenida. Al cerrar sesión volvemos a la primera pantalla y borramos el historial, así que no se puede regresar al Home con el botón atrás. | `lib/app.dart`, `lib/core/routes/`, `lib/features/home/` |
| Manejo de errores y experiencia de usuario | Los errores de Supabase se traducen a mensajes en español y se muestran al usuario. Los formularios validan antes de enviar, muestran carga y no dejan enviar dos veces. Los botones que todavía no tienen función muestran "Esta función estará disponible próximamente." en vez de quedar sin respuesta. | `lib/features/auth/domain/failures/`, `lib/core/ui/roles/widgets/varios.dart` |
| Calidad y pruebas | Con la última versión (rama de la HU-17, con `main` integrado), `flutter analyze` no reporta problemas y `flutter test` pasa las 722 pruebas (casos de uso, Blocs, pantallas, navegación, inyección de dependencias y paginado). Las pruebas usan repositorios falsos, no dependen de Supabase. | `test/` |
| Paginado | Base reutilizable: `PageRequest` y `PagedResult` para pedir páginas, `PaginatedBloc<T>` para cargar la siguiente página, detectar el final y reintentar, y `PaginatedListView<T>` como lista con carga al llegar al final. Ya está conectada a las listas con datos de Supabase: las solicitudes pendientes del administrador (HU-24), el catálogo del comercio (HU-10 y HU-11), la búsqueda de productos del cliente (HU-12), en la HU-14 los establecimientos cercanos, la búsqueda de productos del reporte y el historial de reportes, y en la HU-17 la exploración y los favoritos. `PaginatedBloc` acepta un `errorMessageFor` opcional para mostrar el mensaje propio de un error esperado en vez del genérico. | `lib/core/pagination/`, `lib/core/ui/pagination/`, `test/pagination/` |

## Auditoría del Service Locator (GetIt)

Revisamos que la app implemente el patrón Service Locator y dónde se aplica. **Conclusión: sí lo implementa**, con las observaciones del final. Esto es lo que comprobamos y cómo repetirlo.

### Dónde se aplica

| Pieza | Dónde | Qué hace |
|---|---|---|
| Contenedor | `lib/core/di/injector.dart` (`final GetIt sl`) | Es el único contenedor. No hay otro. |
| Registro | `setupDependencies()`, llamada una vez desde `lib/main.dart` | Registra, de adentro hacia afuera: `SupabaseClient` → data sources → repositorios (con el tipo del contrato) → casos de uso → Blocs. Es idempotente: llamarla de nuevo no duplica registros. |
| Consulta | `lib/app_router.dart` | Es el único lugar que pide dependencias con `sl<...>()`, para dárselas a cada pantalla con `BlocProvider`. Las pantallas y los Blocs no conocen el localizador. |
| Parámetros | `registerFactoryParam` | Los Blocs que necesitan un dato de la pantalla: `DecisionSolicitudBloc` y `PaginatedBloc<Solicitud>` (HU-24) `ProductoFormBloc` (HU-10, con `null` para crear), `PrecioProductoBloc` (HU-11, con el producto), y `PaginatedBloc<ResultadoBusqueda>` (con el texto del Home) y `DetalleProductoBloc` (con la consulta) de la HU-12. La lista del catálogo se registra como `PaginatedBloc<Producto>` pero es un `CatalogoListaBloc` (agrega búsqueda y filtro). |

Ciclo de vida: los data sources, repositorios y casos de uso son `registerLazySingleton` (sin estado); los Blocs son `registerFactory`, porque guardan estado y cada pantalla debe tener el suyo.

### Evidencia (revisión del 14 de noviembre de 2026, repetida el 15 con la HU-11)

| Comprobación | Resultado |
|---|---|
| `Supabase.instance` fuera del inyector | Una sola aparición: `injector.dart`. El resto recibe `SupabaseClient` por constructor |
| `sl<` o `GetIt` fuera del inyector | Solo `app_router.dart` |
| Data sources o repositorios construidos fuera del inyector | Ninguno |
| Imports de `flutter`, `supabase_flutter`, `get_it` o `file_picker` en las carpetas `domain/` | Ninguno |
| Registros en `injector.dart` | 106 (64 de `main` hasta la HU-12 y 42 de HU-14 y HU-17) |
| `test/di/injector_test.dart` | Comprueba los registros (repositorios con el tipo del contrato, Bloc de fábrica, casos de uso únicos), que `setupDependencies` no duplica, y que la cadena completa del catálogo se arma con un cliente de Supabase sin conexión |

Para repetir las comprobaciones:

```bash
grep -rn "Supabase.instance" lib
grep -rn -E "\bsl<|GetIt\." lib | grep -v "lib/core/di/injector.dart"
grep -rln -E "package:(flutter|supabase_flutter|get_it|flutter_bloc|file_picker)/" lib/features/*/domain
flutter test test/di
```

### Observaciones

- `app_router.dart` arma `DisponibilidadBloc` a mano con `sl<CambiarDisponibilidadUseCase>()` y el valor inicial del perfil, en vez de registrarlo con `registerFactoryParam`. Usa el localizador, pero es la única excepción al patrón. No la cambiamos porque está fuera de la HU-10.
- En las pruebas armamos los Blocs a mano con repositorios falsos (`TestEnv`) y no con `sl`: es a propósito, para no depender de Supabase.
- `lib/core/pagination/paginated_bloc.dart` importa `flutter_bloc` porque es un Bloc, no una clase de dominio.
- **Registro con nombre.** `PaginatedBloc<Producto>` existe dos veces: sin nombre (catálogo, HU-10) y con `InstanciasSl.busquedaProductos` (búsqueda del reporte, HU-14, con `param1` y `param2`). GetIt no admite el mismo tipo dos veces sin nombre. Una prueba de `test/di/` comprueba que conviven.
- **HU-17: cuatro nombres más.** `PaginatedBloc<ProductoConComercio>` y `PaginatedBloc<ComercioResumen>` se usan dos veces cada uno (exploración y favoritos), así que las cuatro listas llevan nombre (`InstanciasSl.explorarProductos`, `explorarComercios`, `favoritosProductos` y `favoritosComercios`). `CarritoBloc` y `FavoritosBloc` son fábricas, pero el `RolShell` del cliente crea **una sola instancia de cada uno** por sesión y la comparte con todas las pantallas (las rutas la reciben como argumento y el `AppRouter` la entrega con `BlocProvider.value`).
- Los plugins de la HU-14 (`geolocator`, `image_picker`, `permission_handler`) quedan detrás de los contratos `ServicioUbicacion` y `SelectorFoto`; `mobile_scanner` solo aparece en `EscanerCodigoPage` (presentación).

## Decisiones de diseño

- **Fondo blanco** en login y registro; los campos conservan el gris claro del diseño. Los colores salen de `TemaRol`; no definimos otra paleta.
- **Administrador en el registro**: no aparece como opción porque lo asignamos nosotros; una persona no se puede registrar como admin.
- **Teléfono opcional**: la columna `usuario.telefono` admite nulos y el diseño no lo marca como obligatorio. Si se escribe, se valida el formato.
- **Colaborador** crea también su fila inicial en `perfil_colaborador` (los valores 0/1/0 los exige la política).
- **Lemas del login** por perfil: los tomamos de la tabla de roles de este README; el del colaborador es el del diseño.
- **Datos de ejemplo**: el nombre, el correo y el teléfono que se ven en el Perfil son los de la sesión. Quitamos la ciudad "Bogotá" y las etiquetas "Premium / Nivel Plata / aprobado" porque no existen en la base de datos. El resto de tarjetas (ofertas, misiones, estadísticas) sigue siendo contenido de ejemplo de la maqueta.
- **Imágenes**: ilustraciones propias en `assets/images/` (avatar de muestra por perfil, logo, imagen de la segunda bienvenida y banner del registro); si no cargan, se muestran las iniciales.

## Limitaciones conocidas y pasos pendientes

- **Continuar con Google** y **¿Olvidaste tu contraseña?** están en el diseño pero no están implementados: muestran un aviso. Google requiere configurar el proveedor y los enlaces de retorno en Supabase.
- Varios botones de los Home y Perfil muestran "próximamente": son funciones de sprints siguientes. El Home del comercio todavía muestra ventas y órdenes de ejemplo; el catálogo, en cambio, es real.
- **HU-10 (catálogo del comercio):**
  - Las categorías son una lista fija (Super, Frutas, Lácteos, Aseo, Café, Panadería); el comercio no crea las suyas.
  - Eliminar un producto es definitivo.
  - El CSV lleva `nombre` y `categoria` (obligatorias) y `marca` y `codigo_barras` (opcionales), con un máximo de 500 filas. El selector de archivos lo probamos a mano con los CSV de `docs/ejemplos/`.
  - Los clientes todavía no pueden ver los productos: la lectura y la búsqueda llegan con la HU-12.
- **HU-11 (precios, disponibilidad y promociones):**
  - Una promoción por producto; guardar otra la reemplaza. Para marcar un producto como agotado, primero debe tener precio.
  - Precios en pesos enteros, sin centavos. La gráfica usa los últimos 60 cambios del historial (4 meses).
  - Stock y fotos se agregaron para seguir el diseño del equipo; no los pide la HU-11. "Stock bajo" es 10 unidades o menos. Las fotos (JPG, PNG o WEBP, hasta 5 MB) quedan públicas en el bucket `productos`; las fotos reemplazadas no se borran del bucket.
  - El aviso del diseño ("los cambios serán validados por colaboradores") se cambió por el comportamiento real de la HU-11: el precio del comercio se publica de inmediato con fuente "Comercio".
  - La vigencia de la promoción se compara con la fecha del teléfono.
  - Los clientes todavía no ven los precios: la lectura llega con la HU-12.
- **HU-12 (búsqueda):**
  - "El mismo producto" en varias tiendas se reconoce por el código de barras o, si no tiene, por el nombre y la marca exactos.
  - Solo aparecen productos con precio de comercios aprobados. El nivel de confianza del precio llega con la HU-13.
  - En el emulador no hay cámara: el escáner ofrece "Escribir el código".
- **HU-14 (reporte de precio):**
  - Necesita `docs/sql/sprint2_hu14.sql` en Supabase (en nuestro proyecto ya se ejecutó y `pruebas_hu14_politicas.sql` dio las 28 líneas en `OK`, incluidas las del historial `mis_reportes()`). La primera ejecución de la prueba reveló una política antigua, `comercio_update_own`, que dejaba al dueño cambiar su propio estado de aprobación; el script la elimina (sección 8) y quien use otra base debe ejecutarlo también.
  - El GPS, la cámara, el permiso y el escáner reales **no se han probado en un dispositivo**: las pruebas usan dobles. Se prueba en Android.
  - Un comercio solo aparece como lugar de reporte si guardó su ubicación (registro o aviso del Home). Los comercios anteriores a esta historia no la tienen.
  - La distancia máxima es de 150 m (constante `ReporteReglas.radioMaximoM` y en la función SQL).
  - El escáner de códigos no funciona en Windows; ahí queda la búsqueda por nombre.
  - Solo guarda el reporte como pendiente. Validarlo y dar puntos son las HU-15 y HU-16 (Sprint 3).
- **HU-17 (carrito y favoritos):**
  - Necesita `docs/sql/sprint2_hu17.sql` en Supabase (sin él la app no encuentra el carrito, los favoritos ni la exploración). Después, `pruebas_hu17_politicas.sql` debe dar todas las líneas en `OK`. Con `main` integrado se volvieron a correr `sprint2_hu17.sql` y sus pruebas en nuestro Supabase y dieron todo `OK`; la app se probó en un dispositivo Android y funcionó (carrito, favoritos y exploración).
  - El carrito y los favoritos se probaron con dobles; falta probarlos en un dispositivo.
  - **El carrito no muestra precios ni totales.** La HU-11 ya guarda los precios, pero la HU-17 no los lee; el total y la comparación son de la HU-18.
  - **"Explorar" es provisional.** Es la lista mínima desde la que el cliente agrega y marca favoritos (se abre con **Comenzar ahora**). La búsqueda de la HU-12 ya existe y es la que abren la lupa y el buscador del Home, pero sus resultados y su detalle todavía no tienen los botones de carrito y favorito. Cuando el equipo los ponga con `AgregarCarritoBoton` y `FavoritoBoton`, Explorar se puede retirar.
  - Límites que fijamos nosotros (el backlog no los define): 99 unidades por producto y 100 productos distintos. El carrito se lee completo en una sola consulta; las listas de favoritos y de exploración sí se paginan.
  - Cada línea del carrito es un producto **de un comercio**. Cómo reconocer el mismo producto en varios comercios (para comparar el carrito, HU-18) es una decisión pendiente del equipo.
  - Las tarjetas de "Ofertas cerca de ti" del Home siguen siendo de ejemplo y su botón de agregar todavía avisa "próximamente".
- La app declara el permiso `INTERNET` en el manifiesto de Android: sin él, una versión *release* no se conecta a Supabase.
- `pubspec.lock` se regenera con `flutter pub get` (se agregaron `flutter_bloc`, `get_it`, `file_picker` en la HU-10, `mobile_scanner` en la HU-12 y `geolocator`, `image_picker` y `permission_handler` en la HU-14).

## Equipo

- Adri Jhoanny Martinez Murillo
- Daniel Trujillo Marin
- Carol Andrea Mosquera
- Angy Maria Hurtado Osorio
- Laura Isabella Coral Garcia
