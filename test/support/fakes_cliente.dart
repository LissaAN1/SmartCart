import 'dart:async';

import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cart/domain/usecases/agregar_al_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/cambiar_cantidad_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/get_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/quitar_del_carrito_usecase.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/domain/repository/explorar_repository.dart';
import 'package:smartcart/features/explorar/domain/usecases/explorar_usecases.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/domain/repository/favoritos_repository.dart';
import 'package:smartcart/features/favoritos/domain/usecases/favoritos_usecases.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

import 'fakes.dart';

// ───────────────────────── Datos de ejemplo ─────────────────────────

const arrozCliente = ProductoConComercio(
  producto: Producto(
    id: 'p1',
    nombre: 'Arroz blanco 500 g',
    marca: 'Diana',
    codigoBarras: '7701234567890',
    idCategoria: 'cat-super',
    categoria: 'Super',
  ),
  idComercio: 'c1',
  comercio: 'Minimercado La Esquina',
);

const lecheCliente = ProductoConComercio(
  producto: Producto(
    id: 'p2',
    nombre: 'Leche entera 1 L',
    marca: 'Alpina',
    codigoBarras: '7709990001112',
    idCategoria: 'cat-lacteos',
    categoria: 'Lácteos',
  ),
  idComercio: 'c1',
  comercio: 'Minimercado La Esquina',
);

const cafeCliente = ProductoConComercio(
  producto: Producto(
    id: 'p3',
    nombre: 'Café molido 500 g',
    idCategoria: 'cat-cafe',
    categoria: 'Café',
  ),
  idComercio: 'c2',
  comercio: 'Tienda Doña Rosa',
);

const tiendaLaEsquina = ComercioResumen(
  id: 'c1',
  nombre: 'Minimercado La Esquina',
  direccion: 'Calle 10 # 5-20',
  ciudad: 'Cali',
);

const tiendaDonaRosa = ComercioResumen(
  id: 'c2',
  nombre: 'Tienda Doña Rosa',
  direccion: 'Carrera 5 # 10-20',
  ciudad: 'Bogotá',
);

/// Ayuda de las pruebas: una línea del carrito con la cantidad indicada.
extension LineaDeProducto on ProductoConComercio {
  ItemCarrito toLinea(int cantidad) =>
      ItemCarrito(producto: this, cantidad: cantidad);
}

// ───────────────────────────── Dobles ─────────────────────────────

/// Carrito en memoria. Aplica las mismas reglas que `agregar_al_carrito` en la
/// base: una línea por producto, 99 unidades como máximo por producto y 100
/// productos distintos como máximo; solo se agrega lo que existe.
class FakeCarritoRepository implements CarritoRepository {
  /// Lo que existe en los comercios aprobados.
  final disponibles = <String, ProductoConComercio>{};

  /// Las líneas, de la modificada más recientemente a la más antigua.
  final lineas = <ItemCarrito>[];

  Object? obtenerError;
  Object? agregarError;
  Object? cambiarError;
  Object? quitarError;
  int obtenerCalls = 0;
  int agregarCalls = 0;
  int cambiarCalls = 0;
  int quitarCalls = 0;

  /// Si se asigna, `cambiarCantidad` espera a que se complete (simula la red).
  Completer<void>? gateCambiar;

  /// Si se asigna, `obtener` espera a que se complete (simula la lectura).
  Completer<void>? gateObtener;

  int _indiceDe(String idProducto) =>
      lineas.indexWhere((i) => i.idProducto == idProducto);

  @override
  Future<List<ItemCarrito>> obtener() async {
    obtenerCalls++;
    await gateObtener?.future;
    if (obtenerError != null) throw obtenerError!;
    return List.of(lineas);
  }

  @override
  Future<int> agregar(String idProducto) async {
    agregarCalls++;
    if (agregarError != null) throw agregarError!;
    final producto = disponibles[idProducto];
    if (producto == null) {
      throw const AuthFailure('Ese producto ya no está disponible.');
    }
    final i = _indiceDe(idProducto);
    if (i >= 0) {
      final actual = lineas[i].cantidad;
      if (actual >= 99) {
        throw const AuthFailure(
          'Ya tienes 99 unidades de este producto, el máximo por producto.',
        );
      }
      final nueva = ItemCarrito(producto: producto, cantidad: actual + 1);
      lineas
        ..removeAt(i)
        ..insert(0, nueva);
      return nueva.cantidad;
    }
    if (lineas.length >= 100) {
      throw const AuthFailure(
        'Tu carrito está lleno: el máximo es de 100 productos distintos.',
      );
    }
    lineas.insert(0, ItemCarrito(producto: producto, cantidad: 1));
    return 1;
  }

  @override
  Future<void> cambiarCantidad(String idProducto, int cantidad) async {
    cambiarCalls++;
    await gateCambiar?.future;
    if (cambiarError != null) throw cambiarError!;
    final i = _indiceDe(idProducto);
    if (i < 0) throw const AuthFailure('Ese producto ya no está en tu carrito.');
    lineas[i] = lineas[i].conCantidad(cantidad);
  }

  @override
  Future<void> quitar(String idProducto) async {
    quitarCalls++;
    if (quitarError != null) throw quitarError!;
    lineas.removeWhere((i) => i.idProducto == idProducto);
  }
}

/// Favoritos en memoria. Guarda el orden en que se marcaron (el más reciente
/// primero), como la base.
class FakeFavoritosRepository implements FavoritosRepository {
  final productosDisponibles = <String, ProductoConComercio>{};
  final comerciosDisponibles = <String, ComercioResumen>{};

  final _productos = <String>[];
  final _comercios = <String>[];

  Object? idsError;
  Object? listError;
  Object? cambiarError;
  int cambiarCalls = 0;

  /// Si se asigna, `cambiar` espera a que se complete (simula la red).
  Completer<void>? gateCambiar;

  /// Marca favoritos sin pasar por el caso de uso.
  void precargar({List<String> productos = const [], List<String> comercios = const []}) {
    _productos.insertAll(0, productos);
    _comercios.insertAll(0, comercios);
  }

  List<String> get idsDeProductos => List.of(_productos);
  List<String> get idsDeComercios => List.of(_comercios);

  @override
  Future<FavoritosIds> ids() async {
    if (idsError != null) throw idsError!;
    return FavoritosIds(
      productos: _productos.toSet(),
      comercios: _comercios.toSet(),
    );
  }

  @override
  Future<PagedResult<ProductoConComercio>> productos(PageRequest request) async {
    if (listError != null) throw listError!;
    final filas = [
      for (final id in _productos)
        if (productosDisponibles[id] != null) productosDisponibles[id]!,
    ].skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<PagedResult<ComercioResumen>> comercios(PageRequest request) async {
    if (listError != null) throw listError!;
    final filas = [
      for (final id in _comercios)
        if (comerciosDisponibles[id] != null) comerciosDisponibles[id]!,
    ].skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<void> cambiar(
    TipoFavorito tipo,
    String id, {
    required bool favorito,
  }) async {
    cambiarCalls++;
    await gateCambiar?.future;
    if (cambiarError != null) throw cambiarError!;
    final lista = tipo == TipoFavorito.producto ? _productos : _comercios;
    lista.remove(id);
    if (favorito) lista.insert(0, id);
  }
}

/// Exploración en memoria: filtra por nombre o marca (productos) y por nombre
/// o ciudad (comercios), sin distinguir mayúsculas.
class FakeExplorarRepository implements ExplorarRepository {
  final productosLista = <ProductoConComercio>[];
  final comerciosLista = <ComercioResumen>[];
  final consultas = <String>[];
  Object? listError;

  @override
  Future<PagedResult<ProductoConComercio>> productos(
    String texto,
    PageRequest request,
  ) async {
    if (listError != null) throw listError!;
    consultas.add(texto);
    final t = texto.toLowerCase();
    final filas = productosLista
        .where((p) =>
            t.isEmpty ||
            p.producto.nombre.toLowerCase().contains(t) ||
            (p.producto.marca ?? '').toLowerCase().contains(t))
        .skip(request.from)
        .take(request.pageSize + 1)
        .toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<PagedResult<ComercioResumen>> comercios(
    String texto,
    PageRequest request,
  ) async {
    if (listError != null) throw listError!;
    final t = texto.toLowerCase();
    final filas = comerciosLista
        .where((c) =>
            t.isEmpty ||
            c.nombre.toLowerCase().contains(t) ||
            c.ciudad.toLowerCase().contains(t))
        .skip(request.from)
        .take(request.pageSize + 1)
        .toList();
    return PagedResult.fromRows(filas, request);
  }
}

/// Los dobles del cliente de un [TestEnv].
class ClienteFakes {
  final carrito = FakeCarritoRepository();
  final favoritos = FakeFavoritosRepository();
  final explorar = FakeExplorarRepository();
}

final _fakesDeCliente = Expando<ClienteFakes>('fakesDeCliente');

/// Casos de uso y Blocs del cliente (HU-17) construidos con los dobles del
/// entorno. Los dobles viven aparte de `TestEnv` para no tocar su archivo.
extension EntornoCliente on TestEnv {
  ClienteFakes get cliente => _fakesDeCliente[this] ??= ClienteFakes();

  /// Deja la sesión iniciada como cliente y siembra lo que existe en los
  /// comercios: tres productos y dos comercios.
  void iniciarSesionComoCliente() {
    iniciarSesionCon({UserRole.cliente});
    final productos = {
      for (final p in [arrozCliente, lecheCliente, cafeCliente]) p.id: p,
    };
    final comercios = {
      for (final c in [tiendaLaEsquina, tiendaDonaRosa]) c.id: c,
    };
    cliente.carrito.disponibles.addAll(productos);
    cliente.favoritos.productosDisponibles.addAll(productos);
    cliente.favoritos.comerciosDisponibles.addAll(comercios);
    cliente.explorar.productosLista.addAll(productos.values);
    cliente.explorar.comerciosLista.addAll(comercios.values);
  }

  GetClienteActivoUseCase get clienteActivo =>
      GetClienteActivoUseCase(auth: auth, profiles: profiles);

  GetCarritoUseCase get getCarrito =>
      GetCarritoUseCase(cliente: clienteActivo, carrito: cliente.carrito);
  AgregarAlCarritoUseCase get agregarAlCarrito => AgregarAlCarritoUseCase(
      cliente: clienteActivo, carrito: cliente.carrito);
  CambiarCantidadCarritoUseCase get cambiarCantidadCarrito =>
      CambiarCantidadCarritoUseCase(
          cliente: clienteActivo, carrito: cliente.carrito);
  QuitarDelCarritoUseCase get quitarDelCarrito => QuitarDelCarritoUseCase(
      cliente: clienteActivo, carrito: cliente.carrito);

  GetFavoritosIdsUseCase get getFavoritosIds => GetFavoritosIdsUseCase(
      cliente: clienteActivo, favoritos: cliente.favoritos);
  GetFavoritosProductosUseCase get getFavoritosProductos =>
      GetFavoritosProductosUseCase(
          cliente: clienteActivo, favoritos: cliente.favoritos);
  GetFavoritosComerciosUseCase get getFavoritosComercios =>
      GetFavoritosComerciosUseCase(
          cliente: clienteActivo, favoritos: cliente.favoritos);
  CambiarFavoritoUseCase get cambiarFavorito => CambiarFavoritoUseCase(
      cliente: clienteActivo, favoritos: cliente.favoritos);

  ExplorarProductosUseCase get explorarProductos => ExplorarProductosUseCase(
      cliente: clienteActivo, explorar: cliente.explorar);
  ExplorarComerciosUseCase get explorarComercios => ExplorarComerciosUseCase(
      cliente: clienteActivo, explorar: cliente.explorar);

  CarritoBloc carritoBloc() => CarritoBloc(
        obtener: getCarrito,
        agregar: agregarAlCarrito,
        cambiarCantidad: cambiarCantidadCarrito,
        quitar: quitarDelCarrito,
      );

  FavoritosBloc favoritosBloc() =>
      FavoritosBloc(obtener: getFavoritosIds, cambiar: cambiarFavorito);

  /// El carrito y los favoritos ya iniciados, como los entrega el `RolShell`.
  ClienteBlocs clienteBlocs() =>
      ClienteBlocs(carrito: carritoBloc(), favoritos: favoritosBloc())..iniciar();

  PaginatedBloc<ProductoConComercio> explorarProductosBloc(String texto) =>
      PaginatedBloc<ProductoConComercio>(
        fetchPage: (request) => explorarProductos(texto, request),
        errorMessageFor: mensajeDeFallo,
      );

  PaginatedBloc<ComercioResumen> explorarComerciosBloc(String texto) =>
      PaginatedBloc<ComercioResumen>(
        fetchPage: (request) => explorarComercios(texto, request),
        errorMessageFor: mensajeDeFallo,
      );

  PaginatedBloc<ProductoConComercio> favoritosProductosBloc() =>
      PaginatedBloc<ProductoConComercio>(
        fetchPage: getFavoritosProductos.call,
        errorMessageFor: mensajeDeFallo,
      );

  PaginatedBloc<ComercioResumen> favoritosComerciosBloc() =>
      PaginatedBloc<ComercioResumen>(
        fetchPage: getFavoritosComercios.call,
        errorMessageFor: mensajeDeFallo,
      );
}

/// Espera a que un Bloc de aviso emita uno con [texto].
Future<AvisoUi> esperarAviso(
  Stream<AvisoUi?> avisos,
  String texto,
) async {
  final aviso = await avisos
      .where((a) => a != null && a.texto.contains(texto))
      .first;
  return aviso!;
}
