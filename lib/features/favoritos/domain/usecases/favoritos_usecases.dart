import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/domain/repository/favoritos_repository.dart';

/// Los ids de los favoritos del cliente, para pintar los corazones.
class GetFavoritosIdsUseCase {
  final GetClienteActivoUseCase _cliente;
  final FavoritosRepository _favoritos;

  GetFavoritosIdsUseCase({
    required GetClienteActivoUseCase cliente,
    required FavoritosRepository favoritos,
  })  : _cliente = cliente,
        _favoritos = favoritos;

  Future<FavoritosIds> call() async {
    await _cliente();
    return _favoritos.ids();
  }
}

/// Una página de los productos favoritos del cliente.
class GetFavoritosProductosUseCase {
  final GetClienteActivoUseCase _cliente;
  final FavoritosRepository _favoritos;

  GetFavoritosProductosUseCase({
    required GetClienteActivoUseCase cliente,
    required FavoritosRepository favoritos,
  })  : _cliente = cliente,
        _favoritos = favoritos;

  Future<PagedResult<ProductoConComercio>> call(PageRequest request) async {
    await _cliente();
    return _favoritos.productos(request);
  }
}

/// Una página de los comercios favoritos del cliente.
class GetFavoritosComerciosUseCase {
  final GetClienteActivoUseCase _cliente;
  final FavoritosRepository _favoritos;

  GetFavoritosComerciosUseCase({
    required GetClienteActivoUseCase cliente,
    required FavoritosRepository favoritos,
  })  : _cliente = cliente,
        _favoritos = favoritos;

  Future<PagedResult<ComercioResumen>> call(PageRequest request) async {
    await _cliente();
    return _favoritos.comercios(request);
  }
}

/// HU-17, escenario 3: el cliente presiona el corazón de un producto o de un
/// comercio y queda guardado (o se quita) en sus favoritos.
class CambiarFavoritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final FavoritosRepository _favoritos;

  CambiarFavoritoUseCase({
    required GetClienteActivoUseCase cliente,
    required FavoritosRepository favoritos,
  })  : _cliente = cliente,
        _favoritos = favoritos;

  Future<void> call(
    TipoFavorito tipo,
    String id, {
    required bool favorito,
  }) async {
    if (id.trim().isEmpty) {
      throw const AuthFailure('Elige qué quieres guardar en tus favoritos.');
    }
    await _cliente();
    await _favoritos.cambiar(tipo, id, favorito: favorito);
  }
}
