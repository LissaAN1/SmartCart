import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/repository/busqueda_repository.dart';

/// HU-12 · escenarios 1 y 3: busca productos por nombre o marca. Cada
/// resultado trae el rango de precios y en cuántos establecimientos está.
class BuscarProductosUseCase {
  /// Con menos letras la búsqueda devuelve demasiado y no ayuda.
  static const minimoLetras = 2;

  final AuthRepository _auth;
  final BusquedaRepository _busqueda;

  BuscarProductosUseCase({
    required AuthRepository auth,
    required BusquedaRepository busqueda,
  })  : _auth = auth,
        _busqueda = busqueda;

  /// Sin texto (o muy corto) devuelve una página vacía sin consultar.
  Future<PagedResult<ResultadoBusqueda>> call(
    String texto,
    PageRequest request,
  ) async {
    if (_auth.currentUser() == null) {
      throw const AuthFailure('Inicia sesión para buscar productos.');
    }
    final limpio = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.length < minimoLetras) {
      return const PagedResult(items: [], hasMore: false);
    }
    return _busqueda.buscar(limpio, request);
  }
}
