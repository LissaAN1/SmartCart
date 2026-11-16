import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/usecases/buscar_productos_usecase.dart';

/// La persona cambió el texto del buscador.
class BusquedaCambiada extends PaginatedEvent {
  final String texto;

  BusquedaCambiada(this.texto);
}

/// Guarda el texto vigente: la función que trae cada página se crea antes
/// que el Bloc y debe leer siempre el último texto.
class _TextoVigente {
  String valor;

  _TextoVigente(this.valor);
}

/// HU-12: resultados paginados de la búsqueda del cliente. Es un
/// `PaginatedBloc<ResultadoBusqueda>`, así que se muestra con
/// `PaginatedListView`; solo agrega [BusquedaCambiada].
class BusquedaBloc extends PaginatedBloc<ResultadoBusqueda> {
  final _TextoVigente _texto;

  factory BusquedaBloc({
    required BuscarProductosUseCase buscar,
    String textoInicial = '',
    int pageSize = PageRequest.defaultPageSize,
  }) =>
      BusquedaBloc._(_TextoVigente(textoInicial), buscar, pageSize);

  BusquedaBloc._(
    this._texto,
    BuscarProductosUseCase buscar,
    int pageSize,
  ) : super(
          fetchPage: (request) => buscar(_texto.valor, request),
          pageSize: pageSize,
          errorMessageFor: mensajeDeFallo,
        ) {
    on<BusquedaCambiada>(_onCambiada);
  }

  String get texto => _texto.valor;

  Future<void> _onCambiada(
    BusquedaCambiada event,
    Emitter<PaginatedState<ResultadoBusqueda>> emit,
  ) async {
    _texto.valor = event.texto;
    // Si hay una carga en curso, `PaginatedStarted` se ignoraría: esperamos a
    // que termine y buscamos con el texto nuevo.
    if (state.status == PaginatedStatus.loading) {
      await stream.firstWhere((s) => s.status != PaginatedStatus.loading);
    }
    add(PaginatedStarted());
  }
}
