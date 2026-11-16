import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';

/// HU-11: la persona escribió en el buscador o eligió un chip de categoría.
class FiltroCatalogoCambiado extends PaginatedEvent {
  final FiltroCatalogo filtro;

  FiltroCatalogoCambiado(this.filtro);
}

/// Guarda el filtro vigente. Es un objeto aparte porque la función que trae
/// cada página se crea antes que el Bloc y debe leer siempre el último filtro.
class _FiltroVigente {
  FiltroCatalogo valor = const FiltroCatalogo();
}

/// Lista paginada del catálogo (HU-10) con búsqueda y filtro por categoría
/// (HU-11). Es un `PaginatedBloc<Producto>`, así que la lista y las pruebas
/// existentes lo usan igual; solo agrega [FiltroCatalogoCambiado].
class CatalogoListaBloc extends PaginatedBloc<Producto> {
  final _FiltroVigente _filtro;

  factory CatalogoListaBloc({
    required GetProductosUseCase getProductos,
    int pageSize = PageRequest.defaultPageSize,
  }) =>
      CatalogoListaBloc._(_FiltroVigente(), getProductos, pageSize);

  CatalogoListaBloc._(
    this._filtro,
    GetProductosUseCase getProductos,
    int pageSize,
  ) : super(
          fetchPage: (request) => getProductos(request, filtro: _filtro.valor),
          pageSize: pageSize,
          // El aviso "tu comercio está pendiente de aprobación" debe llegar
          // a la pantalla, no un error genérico.
          errorMessageFor: mensajeDeFallo,
        ) {
    on<FiltroCatalogoCambiado>(_onFiltro);
  }

  FiltroCatalogo get filtro => _filtro.valor;

  Future<void> _onFiltro(
    FiltroCatalogoCambiado event,
    Emitter<PaginatedState<Producto>> emit,
  ) async {
    _filtro.valor = event.filtro;
    // Si hay una carga en curso, `PaginatedStarted` se ignoraría: esperamos a
    // que termine y recargamos con el filtro nuevo.
    if (state.status == PaginatedStatus.loading) {
      await stream.firstWhere((s) => s.status != PaginatedStatus.loading);
    }
    add(PaginatedStarted());
  }
}
