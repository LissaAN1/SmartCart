import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/domain/repository/explorar_repository.dart';

/// Una página de los productos de comercios aprobados, filtrados por nombre o
/// marca.
class ExplorarProductosUseCase {
  final GetClienteActivoUseCase _cliente;
  final ExplorarRepository _explorar;

  ExplorarProductosUseCase({
    required GetClienteActivoUseCase cliente,
    required ExplorarRepository explorar,
  })  : _cliente = cliente,
        _explorar = explorar;

  Future<PagedResult<ProductoConComercio>> call(
    String texto,
    PageRequest request,
  ) async {
    await _cliente();
    return _explorar.productos(texto.trim(), request);
  }
}

/// Una página de los comercios aprobados, filtrados por nombre o ciudad.
class ExplorarComerciosUseCase {
  final GetClienteActivoUseCase _cliente;
  final ExplorarRepository _explorar;

  ExplorarComerciosUseCase({
    required GetClienteActivoUseCase cliente,
    required ExplorarRepository explorar,
  })  : _cliente = cliente,
        _explorar = explorar;

  Future<PagedResult<ComercioResumen>> call(
    String texto,
    PageRequest request,
  ) async {
    await _cliente();
    return _explorar.comercios(texto.trim(), request);
  }
}
