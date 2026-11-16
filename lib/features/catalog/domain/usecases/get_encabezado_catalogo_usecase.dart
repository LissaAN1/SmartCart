import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';

/// HU-11: la parte de arriba del catálogo (chips de categorías y resumen del
/// inventario) en una sola llamada.
class GetEncabezadoCatalogoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final GetCategoriasUseCase _categorias;
  final CatalogoRepository _catalogo;

  GetEncabezadoCatalogoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required GetCategoriasUseCase categorias,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _categorias = categorias,
        _catalogo = catalogo;

  Future<EncabezadoCatalogo> call() async {
    final comercio = await _comercioAprobado();
    return EncabezadoCatalogo(
      categorias: await _categorias(),
      resumen: await _catalogo.resumen(comercio.id),
    );
  }
}
