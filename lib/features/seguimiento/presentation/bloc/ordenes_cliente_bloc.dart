import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/domain/usecases/seguimiento_usecases.dart';

/// La persona cambió de pestaña: "En curso" o "Historial".
class PestanaOrdenesCambiada extends PaginatedEvent {
  final bool enCurso;

  PestanaOrdenesCambiada({required this.enCurso});
}

/// Guarda la pestaña vigente: la función que trae cada página se crea antes
/// que el Bloc y debe leer siempre la última.
class _PestanaVigente {
  bool enCurso = true;
}

/// HU-23: "Mis órdenes" paginada, con las pestañas "En curso" e
/// "Historial". Es un `PaginatedBloc<Orden>`, así que se muestra con
/// `PaginatedListView`; solo agrega [PestanaOrdenesCambiada].
class OrdenesClienteBloc extends PaginatedBloc<Orden> {
  final _PestanaVigente _pestana;

  factory OrdenesClienteBloc({
    required GetOrdenesClienteUseCase ordenes,
    int pageSize = PageRequest.defaultPageSize,
  }) =>
      OrdenesClienteBloc._(_PestanaVigente(), ordenes, pageSize);

  OrdenesClienteBloc._(
    this._pestana,
    GetOrdenesClienteUseCase ordenes,
    int pageSize,
  ) : super(
          fetchPage: (request) =>
              ordenes(enCurso: _pestana.enCurso, request: request),
          pageSize: pageSize,
          errorMessageFor: mensajeDeFallo,
        ) {
    on<PestanaOrdenesCambiada>(_onPestana);
  }

  bool get enCurso => _pestana.enCurso;

  Future<void> _onPestana(
    PestanaOrdenesCambiada event,
    Emitter<PaginatedState<Orden>> emit,
  ) async {
    if (event.enCurso == _pestana.enCurso &&
        state.status != PaginatedStatus.initial) {
      return;
    }
    _pestana.enCurso = event.enCurso;
    // Si hay una carga en curso, `PaginatedStarted` se ignoraría: esperamos a
    // que termine y cargamos la pestaña nueva.
    if (state.status == PaginatedStatus.loading) {
      await stream.firstWhere((s) => s.status != PaginatedStatus.loading);
    }
    add(PaginatedStarted());
  }
}

abstract class ConteoOrdenesEvent {}

class ConteoOrdenesPedido extends ConteoOrdenesEvent {}

/// HU-23: cuántas órdenes hay en curso, para el número de la pestaña. Si no
/// se puede leer, simplemente no se muestra (la lista ya explica el error).
class ConteoOrdenesBloc extends Bloc<ConteoOrdenesEvent, int?> {
  final ContarOrdenesEnCursoUseCase _contar;

  ConteoOrdenesBloc({required ContarOrdenesEnCursoUseCase contar})
      : _contar = contar,
        super(null) {
    on<ConteoOrdenesPedido>((event, emit) async {
      try {
        emit(await _contar());
      } catch (_) {
        emit(null);
      }
    });
  }
}
