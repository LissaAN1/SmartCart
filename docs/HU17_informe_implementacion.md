# Sprint 2 · HU-17 · Carrito de compras y favoritos

Informe de implementación. Rama: `feat/hu17-carrito-compras-favoritos`, creada con los cambios de la HU-14. Rutas relativas a la raíz del proyecto.

## 1. Objetivo

> Como cliente, quiero agregar productos a un carrito, ajustar las cantidades y guardar mis favoritos, para preparar mi compra y volver a ella después. (Product Backlog, HU-17, 3 puntos, Must.)

## 2. Alcance implementado

| Criterio de aceptación del backlog | Estado | Cómo se cumple |
|---|---|---|
| Se puede agregar un producto al carrito desde los resultados o desde su detalle | Implementado desde la lista de resultados | `ExplorarPage` lista productos y cada uno tiene el botón de agregar. **El detalle del producto es la HU-13 (de otra persona) y todavía no existe**: el botón `AgregarCarritoBoton` es reutilizable para ponerlo ahí. |
| Se puede cambiar la cantidad y quitar productos | Implementado | `CarritoPage`: botones − y +, y quitar. |
| El carrito se guarda y se recupera al volver a abrir la app | Implementado | Se guarda en Supabase (`carrito_item`); `CarritoBloc` lo lee al entrar al Home del cliente. |
| Se pueden guardar productos y comercios como favoritos | Implementado | Tablas `favorito_producto` y `favorito_comercio`; `FavoritosPage` con una pestaña por tipo. |
| El carrito muestra la cantidad de productos | Implementado | El número de la pestaña "Carrito", el resumen de la pantalla del carrito y el ícono de la exploración. |

Escenarios 1 (agregar con cantidad 1), 2 (cambiar la cantidad) y 3 (favoritos) tienen prueba automática. Ver `docs/HU17_informe_pruebas.md`.

**Fuera de alcance (a propósito):**
- Precios y totales (HU-11): el carrito muestra productos y cantidades.
- La búsqueda por nombre, marca y código de barras con rango de precios (HU-12) y el detalle (HU-13).
- Comparar el carrito (HU-18) y confirmarlo (HU-20).

## 3. La pantalla "Explorar" es provisional

El backlog dice "desde los resultados o desde su detalle", pero la búsqueda (HU-12) y el detalle (HU-13) los hacen otras personas y no están en el repositorio. Sin una lista de productos para el cliente no habría desde dónde agregar nada, así que hicimos la mínima: dos pestañas (**Productos** y **Comercios**) con buscador por nombre, de solo comercios aprobados.

Los botones son reutilizables (`AgregarCarritoBoton(idProducto)` y `FavoritoBoton(tipo, id)`): quien haga la HU-12 o la HU-13 los pone en sus pantallas y la exploración se puede retirar. Si la HU-12 también agrega una política de lectura de productos para clientes, convive con la nuestra (`producto_select_cliente`) sin conflicto: las políticas permisivas se suman.

## 4. Supuestos que tomamos (el backlog no los define)

| Tema | Decisión | Por qué |
|---|---|---|
| Una línea por producto | Agregar un producto que ya está **suma 1** a la cantidad; no crea otra línea | Mantiene una sola referencia por producto (clave primaria `(cliente, producto)`). El escenario 1 dice "cantidad 1" para el primer agregado. |
| Límites | 1 a 99 unidades por producto y 100 productos distintos | No están en el backlog. Evitan cantidades absurdas y mantienen pequeña la consulta que lee el carrito completo. Están como constantes (`CarritoReglas`) y en la base (`check` y `agregar_al_carrito`). |
| "Cantidad de productos" | El número de la pestaña son los productos **distintos** (líneas); el resumen de la pantalla muestra también las unidades ("3 productos · 7 unidades") | El criterio es ambiguo; mostramos las dos. |
| Bajar de 1 | No borra: el botón − se deshabilita con 1 unidad y para sacar el producto se usa "Quitar" | Evita borrados accidentales. |
| Carrito sin paginar | Se lee completo (máx. 100 líneas). Las listas de favoritos y de exploración **sí** se paginan | Editar cantidades necesita todas las líneas; el límite de 100 mantiene la consulta acotada. |
| Un producto = un producto **de un comercio** | Cada línea es una fila de `producto`, que pertenece a un comercio | Es como está el modelo (HU-10). Reconocer el mismo producto en varios comercios para comparar (HU-18) queda como decisión del equipo. |
| Comercio que deja de estar aprobado | Lo que ya estaba en el carrito sigue ahí y se puede quitar; no se puede agregar nada nuevo | La persona nunca queda con algo que no puede sacar. |
| Favoritos | Dos tablas, una para productos y otra para comercios | Cada una con su clave foránea y su `on delete cascade`. |

## 5. Archivos

### Creados

| Archivo | Qué hace |
|---|---|
| `docs/sql/sprint2_hu17.sql` | `es_cliente()`, `producto_disponible()`, política de lectura de productos para clientes, `carrito_item`, `favorito_producto`, `favorito_comercio` con su RLS, y las funciones `agregar_al_carrito()`, `mi_carrito()`, `mis_favoritos_productos()`, `mis_favoritos_comercios()`, `explorar_productos()` y `explorar_comercios()`. Idempotente. |
| `docs/sql/pruebas_hu17_politicas.sql` | 34 pruebas de las políticas y funciones. Termina en `ROLLBACK` y devuelve una tabla con los resultados. **Ejecutado en Supabase: 34 `OK`.** |
| `lib/features/cart/` | Carrito: `ItemCarrito`, `CarritoReglas`, contrato `CarritoRepository`, 4 casos de uso, `SupabaseCarritoDataSource`, `CarritoBloc`, `CarritoPage` y `AgregarCarritoBoton`. |
| `lib/features/favoritos/` | Favoritos: `TipoFavorito`, `FavoritosIds`, contrato `FavoritosRepository`, 4 casos de uso, `SupabaseFavoritosDataSource`, `FavoritosBloc`, `FavoritosPage` y `FavoritoBoton`. |
| `lib/features/explorar/` | Exploración: contrato `ExplorarRepository`, 2 casos de uso, `SupabaseExplorarDataSource` y `ExplorarPage`. |
| `lib/features/cliente/domain/usecases/get_cliente_activo_usecase.dart` | Exige sesión y perfil de cliente; todos los casos de uso de la HU-17 parten de él. |
| `lib/features/cliente/presentation/cliente_blocs.dart` | `ClienteBlocs` (el carrito y los favoritos, una instancia por sesión) y atajos para abrir las pantallas. |
| `lib/features/cliente/presentation/widgets/` | `ProductoClienteCard` y `ComercioClienteCard`. |
| `lib/features/catalog/domain/entities/producto_con_comercio.dart`, `lib/features/comercio/domain/entities/comercio_resumen.dart`, `lib/features/catalog/data/source/producto_con_comercio_mapper.dart` | Entidades que el cliente necesita (el producto con el nombre de su comercio) y la conversión de las filas de las funciones SQL. |
| `lib/core/ui/aviso_ui.dart` | `AvisoUi` y `mostrarAviso`: el mensaje corto ("Agregado al carrito") que el Bloc deja en su estado y la pantalla muestra una vez. |
| `test/cart/`, `test/favoritos/`, `test/explorar/`, `test/cliente/`, `test/support/fakes_cliente.dart` | 153 pruebas nuevas y los dobles del cliente. |

### Modificados

| Archivo | Cambio |
|---|---|
| `lib/core/constants/supabase_tables.dart` | Tablas, funciones y columnas de la HU-17. |
| `lib/core/routes/app_routes.dart`, `lib/app_router.dart` | Rutas `carrito`, `favoritos` y `explorar`. Reciben los Blocs ya creados como argumento y los entregan con `BlocProvider.value`. |
| `lib/core/di/injector.dart` | Registros nuevos (ver sección 7). |
| `lib/features/home/presentation/pages/role_shell.dart` | Para el cliente crea y cierra el carrito y los favoritos (parámetro opcional `crearCliente`), abre el carrito desde la pestaña y muestra el número en la barra. |
| `lib/features/cliente/presentation/pages/cliente_home_screen.dart` y `cliente_perfil_screen.dart` | El número del carrito en la pestaña; la lupa, el buscador y "Comenzar ahora" abren la exploración; "Mis favoritos" en el Perfil. "Comparar" sigue avisando "próximamente" (Sprint 3). |
| `lib/features/auth/data/source/supabase_error_mapper.dart` | `traducirErroresSupabase`: ejecuta una operación y traduce lo que falle a `AuthFailure` (lo usan los tres data sources nuevos, en vez de repetir el mismo `try/catch`). |
| `test/support/pump_helpers.dart`, `test/di/injector_test.dart` | Rutas de apoyo y 6 pruebas de registros. No se cambió ninguna prueba existente. |

## 6. Arquitectura

```text
presentation  CarritoPage · FavoritosPage · ExplorarPage
              CarritoBloc · FavoritosBloc · PaginatedBloc (listas)
              AgregarCarritoBoton · FavoritoBoton (reutilizables)
                    │  (un caso de uso por acción)
domain        GetCarrito · AgregarAlCarrito · CambiarCantidadCarrito · QuitarDelCarrito
              GetFavoritosIds · GetFavoritosProductos/Comercios · CambiarFavorito
              ExplorarProductos · ExplorarComercios
              GetClienteActivo  ← todos parten de aquí
              CarritoRepository · FavoritosRepository · ExplorarRepository   (contratos)
              CarritoReglas · ResumenCarrito · FavoritosIds                 (Dart puro)
                    │
data          *RepositoryImpl → Supabase{Carrito,Favoritos,Explorar}DataSource
```

El dominio no importa Flutter, Supabase ni GetIt (comprobado con `grep`; ver el README, auditoría del Service Locator).

## 7. Integración con el Service Locator (GetIt)

Todo en `lib/core/di/injector.dart`, con el mecanismo y el orden existentes. No hay contenedor paralelo.

| Tipo | Registro |
|---|---|
| 3 data sources | `registerLazySingleton` |
| `CarritoRepository`, `FavoritosRepository`, `ExplorarRepository` | `registerLazySingleton` con el tipo del contrato |
| 11 casos de uso | `registerLazySingleton` |
| `CarritoBloc`, `FavoritosBloc` | `registerFactory`; el `RolShell` del cliente crea **uno de cada uno** por sesión |
| Listas de exploración (con el texto como `param1`) y de favoritos | `registerFactoryParam` / `registerFactory` **con nombre** (`InstanciasSl`) |

**Por qué los nombres:** `PaginatedBloc<ProductoConComercio>` y `PaginatedBloc<ComercioResumen>` se necesitan dos veces cada uno (exploración y favoritos), y GetIt no deja registrar el mismo tipo dos veces sin nombre.

## 8. Reglas de negocio

- **Solo un cliente usa el carrito y los favoritos.** `GetClienteActivoUseCase` da un mensaje claro; en la base lo exigen `es_cliente()`, las políticas RLS y las funciones.
- **Cada cliente solo ve y toca lo suyo** (RLS por `id_usuario = auth.uid()`).
- **No se inserta en el carrito directo:** `agregar_al_carrito()` aplica los límites y suma si ya existe. Una línea solo permite actualizar la **cantidad** (permiso por columna).
- **Solo se agrega lo disponible:** el producto debe existir y su comercio estar aprobado. Lo mismo para marcar un favorito.
- **Los productos y comercios que ve el cliente** son solo los de comercios aprobados (política de lectura y funciones de exploración).
- **Cantidades:** 1 a 99; fuera de rango se rechaza en el caso de uso, en la base y en la interfaz (los botones se deshabilitan).

## 9. Decisiones técnicas y dificultades

- **El carrito y los favoritos son uno solo por sesión.** El Home, la exploración, el carrito y los favoritos deben mostrar el mismo número y los mismos corazones. Como las pantallas se abren con rutas, que no cuelgan del árbol del `RolShell`, el par viaja como argumento (`ClienteBlocs`) y el `AppRouter` lo entrega con `BlocProvider.value`, sin cerrarlo: lo cierra el `RolShell` al salir.
- **`crearCliente` es opcional en el `RolShell`.** Sin él, la pestaña del carrito avisa "Pantalla aún no disponible", como antes. Así las pruebas de navegación existentes siguen intactas.
- **Respuesta inmediata.** Cambiar la cantidad, quitar y marcar un corazón actualizan la pantalla primero y guardan después; si guardar falla, se vuelve a lo que dice la base (o el corazón a su estado) y se avisa. Agregar sí espera a la base, porque necesita traer los datos del producto.
- **Funciones SQL para leer.** El cliente no puede leer la tabla `comercio`, así que el nombre del comercio de cada producto sale de funciones (`mi_carrito`, `mis_favoritos_*`, `explorar_*`), igual que en la HU-14.
- **El mismo aviso dos veces.** Si dos errores iguales seguidos no se volvieran a mostrar, la persona creería que el toque no hizo nada. `AvisoUi` lleva un id que cambia en cada aviso, y la pantalla reacciona al id y no al texto. Solo la pantalla de arriba de la pila muestra el aviso (`esPantallaActual`).
- **`id_usuario` por defecto** (`default auth.uid()`) en las tablas de favoritos: la app inserta solo el id del producto o del comercio, y la política exige que el usuario sea el de la sesión.
- **Marcar un favorito que ya existía** (por ejemplo, desde otro dispositivo) no es un error: la base responde "duplicado" y la app lo trata como éxito.
- **`dart format`** reformateó algunos archivos del Home y del Perfil del cliente que tocamos; es ruido de formato en el diff, no de lógica.
- **Memoria al correr las pruebas.** Igual que antes: `flutter test --concurrency=1`.

## 10. Pendientes y riesgos

- **Ejecutar en Supabase**, después de `sprint2_hu14.sql`: `docs/sql/sprint2_hu17.sql` y luego `docs/sql/pruebas_hu17_politicas.sql`, y revisar que todas las líneas digan `OK` (ninguna `ALERTA` ni `SALTADA`). **Ya se ejecutaron en nuestro Supabase y las 34 pruebas dieron `OK`**; en cualquier otra base hay que correrlos igual, porque sin ellos la app no encuentra el carrito, los favoritos ni la exploración.
- **Probar en un dispositivo Android**: agregar, cambiar la cantidad, quitar, marcar favoritos y comprobar que todo sigue ahí al cerrar y volver a abrir la app. Solo se verificó con pruebas automáticas (con dobles).
- **Coordinar con la HU-12 y la HU-13:** ponen sus botones de agregar y de favorito con los widgets de esta historia, y la exploración provisional se retira.
- **Decisión pendiente para la HU-18:** cómo reconocer el mismo producto en varios comercios (por código de barras, por nombre…). El carrito de hoy guarda productos concretos de un comercio.
- Las tarjetas de "Ofertas cerca de ti" del Home son de ejemplo y su botón de agregar sigue avisando "próximamente".
- El README tiene contraseñas de las cuentas de prueba en texto plano; conviene decidir si se quedan antes de publicar el repositorio.
