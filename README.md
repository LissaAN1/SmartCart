# SmartCart

> Compara menos, decide mejor y compra de forma inteligente.

Este es nuestro proyecto del curso **Aplicaciones Móviles** (Universidad Icesi). Es una app móvil hecha con **Flutter** y **Supabase**. Este README documenta la entrega del **Sprint 1**: registro, inicio de sesión y pantalla de resumen del perfil para cada tipo de usuario.

**Objetivo del sprint.** Que una persona pueda crear su cuenta, iniciar sesión con credenciales válidas y llegar a la vista de resumen de su perfil. Lo hicimos para los cinco perfiles de la app.

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

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter / Dart | App multiplataforma (Android, iOS, Web y Windows en este repositorio) |
| Supabase (PostgreSQL + GoTrue) | Base de datos y autenticación |
| supabase_flutter | Cliente de Supabase |
| flutter_bloc | Gestión de estado con BLoC |
| get_it | Localizador de servicios para la inyección de dependencias |
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

Los mismos comandos sirven en Linux. Con la última versión, `flutter analyze` no reporta problemas y `flutter test` pasa las 82 pruebas. Las pruebas no usan Supabase: inyectan repositorios falsos (`test/support/fakes.dart`).

| Carpeta | Qué comprueba |
|---|---|
| `test/auth/` | Validadores y casos de uso de inicio de sesión y registro (incluye el rechazo de perfiles que la cuenta no tiene y del administrador) |
| `test/login/`, `test/register/` | Blocs (estados, errores, doble envío) y pantallas (validaciones, carga, scroll con teclado, ancho máximo) |
| `test/session/` | Recuperar y cerrar la sesión |
| `test/navigation/`, `test/widget_test.dart` | Selección de perfil, navegación al login, sesión guardada, Home por perfil y cierre de sesión hacia la primera pantalla |
| `test/onboarding/` | La app arranca en la bienvenida, flechas de regreso y la imagen de la segunda pantalla |
| `test/di/` | Que el localizador de servicios registre y entregue cada dependencia |
| `test/pagination/` | La base de paginado: primera página, siguiente página, fin de la lista y errores |

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
    └── admin | cliente | colaborador | comercio | repartidor
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
| Inyección de dependencias con GetIt (patrón Service Locator) | Agregamos `get_it` y un único archivo, `injector.dart`, donde se registran el cliente de Supabase, los data sources, los repositorios, los casos de uso y los Blocs. `main.dart` lo llama una vez al arrancar y `app_router.dart` pide cada Bloc con `sl<...>()`. Con esto se acabó el armado manual de dependencias dentro del router. | `lib/core/di/injector.dart`, `lib/main.dart`, `lib/app_router.dart` |
| BLoC | Login, registro y sesión tienen su Bloc con eventos y estados. Las pantallas solo envían eventos y se redibujan según el estado; no tienen lógica de negocio. | `lib/features/login/ui/bloc/`, `register/ui/bloc/`, `session/ui/bloc/` |
| Reutilización de componentes | Sacamos a widgets compartidos lo que se repetía: `BotonAtras` (flecha de regreso), `mostrarProximamente` (aviso para botones sin función), campos y secciones de login y registro, y el kit visual por perfil (`TemaRol`, botones, tarjetas, menús). | `lib/core/ui/roles/widgets/`, `lib/components/` |
| Carpetas y convenciones | Organizamos por feature y por capa, con nombres en minúscula y guion bajo (`snake_case`) y clases en `PascalCase`. Los archivos compartidos viven en `core/`. Las constantes de tablas, columnas, rutas e imágenes están en `core/constants/` y `core/routes/`, sin textos sueltos en las pantallas. | `lib/core/`, `lib/features/` |
| Diseño | Los colores y estilos salen de `TemaRol`, sin colores escritos a mano en las pantallas; corregimos la selección de perfil, que los tenía fijos. Arreglamos los desbordes de texto en pantallas angostas y la imagen de la segunda pantalla de bienvenida se ajusta completa (`BoxFit.contain`). | `lib/core/ui/roles/`, `lib/features/onboarding/` |
| Navegación | Agregamos la flecha de regreso en la segunda pantalla de bienvenida y en la selección de perfil. Arreglamos que la app abría la selección de perfil como si fuera la primera pantalla; ahora arranca en la bienvenida. Al cerrar sesión volvemos a la primera pantalla y borramos el historial, así que no se puede regresar al Home con el botón atrás. | `lib/app.dart`, `lib/core/routes/`, `lib/features/home/` |
| Manejo de errores y experiencia de usuario | Los errores de Supabase se traducen a mensajes en español y se muestran al usuario. Los formularios validan antes de enviar, muestran carga y no dejan enviar dos veces. Los botones que todavía no tienen función muestran "Esta función estará disponible próximamente." en vez de quedar sin respuesta. | `lib/features/auth/domain/failures/`, `lib/core/ui/roles/widgets/varios.dart` |
| Calidad y pruebas | Con la última versión, `flutter analyze` no reporta problemas y `flutter test` pasa las 82 pruebas (casos de uso, Blocs, pantallas, navegación, inyección de dependencias y paginado). Las pruebas usan repositorios falsos, no dependen de Supabase. | `test/` |
| Paginado | Dejamos lista una base reutilizable: `PageRequest` y `PagedResult` para pedir páginas, `PaginatedBloc<T>` para cargar la siguiente página, detectar el final y reintentar, y `PaginatedListView<T>` como lista con carga al llegar al final. Está probada, pero **todavía no la conectamos a una pantalla**: las listas de este sprint son datos de ejemplo. La conectamos cuando existan listas con datos reales de Supabase. | `lib/core/pagination/`, `lib/core/ui/pagination/`, `test/pagination/` |

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
- El paginado está como base y falta conectarlo a una lista real (ver el informe de calidad).
- Varios botones de los Home y Perfil muestran "próximamente": son funciones de sprints siguientes.
- `pubspec.lock` se regenera con `flutter pub get` (se agregaron `flutter_bloc` y `get_it`).

## Equipo

- Adri Jhoanny Martinez Murillo
- Daniel Trujillo Marin
- Carol Andrea Mosquera
- Angy Maria Hurtado Osorio
- Laura Isabella Coral Garcia
