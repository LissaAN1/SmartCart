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
| Flutter | App móvil |
| Supabase (PostgreSQL + GoTrue) | Base de datos y autenticación |
| supabase_flutter | Cliente de Supabase |
| flutter_dotenv | Variables de entorno desde `.env` |
| Clean Architecture por feature | Organización del código |

## Puesta en marcha

| Paso | Acción |
|---|---|
| 1 | Clonar el repositorio |
| 2 | `flutter create . --project-name smartcart --platforms=android,ios` (agregar `windows,web` si se quiere probar en escritorio o Chrome) |
| 3 | `flutter pub get` |
| 4 | Crear `.env` desde `.env.example` con `SUPABASE_URL` y `SUPABASE_ANON_KEY` |
| 5 | Supabase → SQL Editor → pegar y ejecutar `supabase/schema.sql` |
| 6 | `flutter run` (el home debe decir "Conectado a Supabase") |

`.env` está en `.gitignore`: no se sube al repositorio. Usar solo la llave pública (anon/publishable), nunca `service_role`.

## Estructura

```
lib/
├── main.dart                 carga .env e inicia Supabase
├── app.dart                  MaterialApp
├── core/
│   ├── constants/            supabase_tables.dart
│   └── utils/                json_helpers.dart
└── features/
    ├── home/presentation/pages/
    ├── auth/                 registro + login + sesión
    │   ├── data/             datasources, models, repositories
    │   ├── domain/           entities, repositories, usecases
    │   └── presentation/     cubit, pages, widgets
    └── profile/              onboarding por rol + resumen del perfil
        ├── data/             datasources, models, repositories
        ├── domain/           entities, repositories, usecases
        └── presentation/     cubit, pages, widgets
```

| Feature | Responsabilidad | Modelos listos |
|---|---|---|
| auth | Crear cuenta, iniciar/cerrar sesión, asignar rol | UsuarioModel, RolModel, UsuarioRolModel |
| profile | Datos extra por rol y pantalla de resumen | PerfilColaboradorModel, ComercioModel |

En los repositorios se accede a Supabase con `Supabase.instance.client`.

## Base de datos (Sprint 1)

| Tabla | Para qué |
|---|---|
| usuario | Datos generales; `id_usuario` = `auth.users.id` |
| rol | cliente, colaborador, comercio, repartidor, administrador |
| usuario_rol | Roles de cada usuario |
| perfil_colaborador | Onboarding del colaborador |
| comercio | Onboarding del comercio (queda `pendiente` hasta que el admin lo apruebe) |

Todas las tablas tienen RLS activado. El rol `administrador` no se puede auto-asignar desde la app.

## Flujo de registro sugerido

1. `auth.signUp(email, password)` (GoTrue).
2. Insertar fila en `usuario` con el mismo id.
3. Insertar en `usuario_rol` el rol elegido.
4. Según el rol: `perfil_colaborador` (colaborador) o `comercio` (comercio). Cliente y repartidor no necesitan tabla extra.
5. Login → `profile` muestra el resumen.

## Navegación de la app

_Completar al terminar el Sprint 1 (pantallas de onboarding, login y resumen de perfil)._

## Equipo

- Adri Jhoanny Martinez Murillo 
-	Daniel Trujillo Marin
-	Carol Andrea Mosquera
-	 Angy Maria Hurtado Osorio 
-	Laura Isabella Coral Garcia
