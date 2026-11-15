import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';

/// Las categorías entre las que el comercio elige al guardar un producto.
class GetCategoriasUseCase {
  final CatalogoRepository _catalogo;

  GetCategoriasUseCase({required CatalogoRepository catalogo})
      : _catalogo = catalogo;

  Future<List<Categoria>> call() => _catalogo.categorias();
}
