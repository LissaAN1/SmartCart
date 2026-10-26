# SmartCart

> Compara menos, decide mejor y compra de forma inteligente.

Proyecto del curso **Aplicaciones Móviles** (Universidad Icesi). App móvil hecha con **Flutter** y **Supabase**.

## ¿Qué es SmartCart?

Aplicación para optimizar las compras de supermercado. El usuario arma un carrito y SmartCart lo compara entre supermercados de cadena, minimercados y comercios independientes, según precio, disponibilidad, promociones, calificación y distancia. No busca solo el producto más barato, sino la **combinación de compra que más le conviene**.

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
| Administrador | Supervisa la plataforma y aprueba comercios (se asigna a mano en Supabase) |

Un mismo usuario puede ser Cliente y Colaborador con una sola cuenta.

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter / Dart | App multiplataforma (Android, iOS, Web y Windows en este repositorio) |
| Supabase (PostgreSQL + GoTrue) | Base de datos y autenticación |
| supabase_flutter | Cliente de Supabase |
| flutter_bloc | Gestión de estado con BLoC |
| flutter_dotenv | Variables de entorno desde `.env` |
| Clean Architecture por feature | Organización del código (presentación, dominio y datos) |

## Requisitos previos

- **Flutter 3.44.8 / Dart 3.12.2**: son las versiones con las que se desarrolló y comprobó el proyecto. El `pubspec.yaml` exige Dart `>=3.4.0 <4.0.0`.
- Git y un proyecto de Supabase (ver [Configuración de Supabase](#configuración-de-supabase)).
- Según la plataforma:
  - **Windows**: Visual Studio con la carga de trabajo "Desarrollo para el escritorio con C++" y el *Modo de desarrollador* activado (los plugins necesitan enlaces simbólicos).
  - **Linux**: `clang cmake ninja-build pkg-config libgtk-3-dev`.
  - **Android**: Android Studio con el SDK y las licencias aceptadas (`flutter doctor --android-licenses`).
  - **Web**: Chrome.

Comprueba tu entorno con `flutter doctor`.

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

Reemplaza los valores con los de tu proyecto (en el panel de Supabase: *Project Settings → API*):

```text
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_LLAVE_PUBLICA_ANON
```

> Usa solo la llave pública (`anon` / *publishable*). **Nunca** pongas la `service_role`: el `.env` se empaqueta dentro de la app y cualquiera que la descomprima puede leerlo. La llave pública no protege los datos; lo hacen las políticas RLS.

## Configuración de Supabase

El repositorio **no incluye** `schema.sql` ni migraciones: la base de datos se administra desde el panel de Supabase. La autenticación usa estas tablas y columnas (verificadas contra `information_schema` del proyecto del equipo):

| Tabla | Columnas que usa la app |
|---|---|
| `usuario` | `id_usuario` (= `auth.users.id`), `nombre`, `correo`, `telefono` |
| `rol` | `id_rol`, `codigo` (`cliente`, `colaborador`, `comercio`, `repartidor`, `administrador`) |
| `usuario_rol` | `id_usuario`, `id_rol` |
| `perfil_colaborador` | `id_usuario`, `puntos_saldo` (0), `nivel` (1), `reputacion` (0) |

**Qué necesita el proyecto para que el registro y el login funcionen**

1. *Authentication → Providers → Email* habilitado y **"Confirm email" desactivado**. Con la confirmación activa Supabase crea la cuenta sin sesión y las políticas no dejan guardar el perfil; la app lo detecta y lo avisa.
2. La tabla `rol` con las cinco filas y los códigos de la tabla anterior.
3. Políticas RLS (las que ya tiene el proyecto): `usuario` (insert/select/update propios), `usuario_rol` (select propio e insert propio **excluyendo** el rol `administrador`), `rol` (select para todos) y `perfil_colaborador` (insert propio con valores iniciales 0/1/0).
4. Las columnas `NOT NULL` de `usuario` que la app no envía (`estado`, `total_calificaciones`, `fecha_registro`) y `usuario_rol.fecha_asignacion` deben tener un valor por defecto. Para comprobarlo, en el *SQL Editor*:

```sql
select table_name, column_name, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('usuario', 'usuario_rol')
  and is_nullable = 'NO'
order by table_name, ordinal_position;
```

Si alguna sale con `column_default` vacío, el registro fallará con un error de "no nulo" (se ve en la consola de depuración con el nombre `smartcart.auth`).

**Cómo se asigna un administrador.** La app no puede hacerlo (la política lo impide y la pantalla de registro lo deshabilita). Se inserta a mano desde el *SQL Editor* de Supabase, por ejemplo:

```sql
insert into usuario_rol (id_usuario, id_rol)
select '<uuid-del-usuario>', id_rol from rol where codigo = 'administrador';
```

## Instalación de dependencias

```powershell
flutter pub get
```

(el mismo comando en Linux). Si cambias de rama o de versión de Flutter y algo no resuelve, usa `flutter clean` y luego `flutter pub get`.

## Ejecución

**Windows (PowerShell)**

```powershell
flutter run -d windows     # escritorio
flutter run -d chrome      # navegador
flutter devices            # lista dispositivos y emuladores
flutter run -d <id>        # Android: emulador o teléfono con depuración USB
```

**Linux**

El repositorio no trae la carpeta `linux/`. Genérala una vez (no toca `lib/` ni tus archivos):

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

Los mismos comandos sirven en Linux. Las pruebas no usan Supabase: inyectan repositorios falsos (`test/support/fakes.dart`).

| Carpeta | Qué comprueba |
|---|---|
| `test/auth/` | Validadores y casos de uso de inicio de sesión y registro (incluye el rechazo de perfiles que la cuenta no tiene y del administrador) |
| `test/login/`, `test/register/` | Blocs (estados, errores, doble envío) y pantallas (validaciones, carga, scroll con teclado, ancho máximo) |
| `test/session/` | Recuperar y cerrar la sesión |
| `test/navigation/`, `test/widget_test.dart` | Selección de perfil, navegación al login, sesión guardada y Home por perfil |

## Estructura

```text
lib/
├── main.dart                      carga .env e inicia Supabase
├── app.dart                       MaterialApp (ruta inicial y router)
├── app_router.dart                resuelve cada ruta y le da su Bloc
├── components/                    widgets compartidos de login y registro
├── core/
│   ├── constants/                 tablas/columnas de Supabase, rutas de imágenes
│   ├── domain/user_role.dart      los 5 perfiles (sin Flutter ni Supabase)
│   ├── routes/                    nombres de ruta y atajos de navegación
│   ├── ui/roles/                  kit visual por perfil (TemaRol, PerfilVisual, ...)
│   └── utils/
└── features/
    ├── auth/                      lo que comparten login y registro
    │   ├── domain/                entidades, contratos, casos de uso, validadores
    │   └── data/                  data sources de Supabase y repositorios
    ├── login/ui/                  LoginBloc + LoginScreen (los 5 perfiles)
    ├── register/ui/               RegisterBloc + RegisterScreen (común)
    ├── session/ui/                SessionBloc: recuperar y cerrar sesión
    ├── profile_selection/         pantalla "Selecciona tu perfil"
    ├── home/                      RolShell: Home y Perfil del perfil activo
    ├── onboarding/                marcador de las pantallas 1 y 2
    └── admin | cliente | colaborador | comercio | repartidor
```

Reglas de capas (las mismas de los laboratorios 5 y 6):

- **Presentación** (pantallas y Blocs): el Bloc hace una sola llamada a un caso de uso y convierte el resultado en estado. Ninguna pantalla toca Supabase.
- **Dominio**: el caso de uso decide el orden (`SignUpUseCase`: primero la cuenta y luego el perfil con el mismo id; `SignInUseCase`: sesión, perfil y verificación del perfil elegido). Trabaja contra contratos (`AuthRepository`, `ProfileRepository`).
- **Datos**: solo `SupabaseAuthDataSource` y `SupabaseProfileDataSource` usan el SDK. Traducen los errores de Supabase a `AuthFailure` con mensajes en español.
- Como en el laboratorio 6, cada capa crea la siguiente; los parámetros opcionales de los constructores solo existen para inyectar dobles en las pruebas.

## Flujo de autenticación

1. Pantallas 1 y 2 (pendientes) → **Selección de perfil**.
2. El perfil elegido abre el **Login** (una sola pantalla; cambian el color, el ícono y el lema). Desde ahí, "Regístrate aquí" abre el **Registro** común, que preselecciona ese perfil.
3. Tras autenticarse, `SignInUseCase` comprueba en `usuario_rol` que la cuenta tenga el perfil elegido; si no, cierra la sesión y lo explica. Elegir un perfil en pantalla nunca autoriza nada.
4. Se entra al **Home** del perfil (`RolShell`). *Cerrar sesión* en el Perfil llama a `SignOutUseCase` y vuelve a la selección.
5. Supabase guarda la sesión en el dispositivo. Al abrir la app, `SessionBloc` la recupera: con un solo perfil se entra directo a su Home; con varios, se entra directo al que se toque si la cuenta lo tiene.

### Cómo integrar las pantallas 1 y 2

1. Reemplaza el builder de `AppRoutes.onboarding` en `app_router.dart` (hoy `OnboardingPlaceholderPage`) por las pantallas reales y borra el marcador.
2. En `core/routes/app_routes.dart` cambia `initial` a `AppRoutes.onboarding`.
3. Al terminar, navega con `Navigator.pushReplacementNamed(context, AppRoutes.profileSelection)`.

Login y registro no dependen de ellas: se pueden probar arrancando en la selección de perfil.

## Decisiones de diseño

- **Fondo blanco** en login y registro (pedido en el Word); los campos conservan el gris claro del diseño. Los colores salen de `TemaRol`; no se definió otra paleta.
- **Administrador en el registro**: No aparece porque lo asigna el equipo, una persona no se puede registrar como admin.
- **Teléfono opcional**: la columna `usuario.telefono` admite nulos y el diseño no lo marca como obligatorio. Si se escribe, se valida el formato.
- **Colaborador** crea también su fila inicial en `perfil_colaborador` (paso 4 del flujo de registro de este README; los valores 0/1/0 los exige la política).
- **Lemas del login** por perfil: tomados de la tabla de roles de este README; el del colaborador es el del diseño.
- **Datos de ejemplo**: el nombre, el correo y el teléfono del administrador son los de la sesión. Se quitó la ciudad "Bogotá" y las etiquetas "Premium / Nivel Plata / aprobado" porque no existen en la base de datos. El resto de tarjetas (ofertas, misiones, estadísticas) sigue siendo contenido de ejemplo de la maqueta.
- **Imágenes**: ilustraciones propias en `assets/images/` (avatar de muestra por perfil y banner del registro); si no cargan, se muestran las iniciales.

## Limitaciones conocidas y pasos pendientes

- **Continuar con Google** y **¿Olvidaste tu contraseña?** están en el diseño pero no están implementados: muestran un aviso. Google requiere configurar el proveedor y los enlaces de retorno en Supabase.
- El registro de **comercio** no crea la fila en `comercio` (exige `nombre` y `direccion`, que el diseño no pide). El onboarding por perfil sigue pendiente.
- Crear la cuenta y guardar el perfil son operaciones separadas: si falla la segunda, la cuenta queda sin perfil (la app cierra la sesión y lo avisa). No hay política para borrarla desde la app; se resuelve desde el panel de Supabase.
- Los datos propios del colaborador (puntos, nivel) y del comercio todavía no se leen de la base de datos.
- `pubspec.lock` se regenera con `flutter pub get` (se agregó `flutter_bloc`).

## Equipo

- Adri Jhoanny Martinez Murillo 
-	Daniel Trujillo Marin
-	Carol Andrea Mosquera
-	Angy Maria Hurtado Osorio 
-	Laura Isabella Coral Garcia
