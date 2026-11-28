import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/estadisticas/domain/usecases/get_estadisticas_usecase.dart';

abstract class EstadisticasEvent {}

/// Consultar las cifras: al abrir el panel, al volver a él y al reintentar.
class EstadisticasSolicitadas extends EstadisticasEvent {}

enum EstadisticasStatus { initial, cargando, lista, fallida }

class EstadisticasState {
  final EstadisticasStatus status;

  /// Mientras se vuelve a consultar se conservan las cifras anteriores.
  final EstadisticasPlataforma? datos;
  final String? errorMessage;

  const EstadisticasState({
    this.status = EstadisticasStatus.initial,
    this.datos,
    this.errorMessage,
  });
}

/// HU-28: las cifras del panel del administrador.
class EstadisticasBloc extends Bloc<EstadisticasEvent, EstadisticasState> {
  final GetEstadisticasUseCase _obtener;

  /// Número de la última consulta: si se pide otra antes de que responda la
  /// anterior, solo vale la más reciente.
  int _consulta = 0;

  EstadisticasBloc({required GetEstadisticasUseCase obtener})
      : _obtener = obtener,
        super(const EstadisticasState()) {
    on<EstadisticasSolicitadas>(_onSolicitadas);
  }

  Future<void> _onSolicitadas(
    EstadisticasSolicitadas event,
    Emitter<EstadisticasState> emit,
  ) async {
    final consulta = ++_consulta;
    emit(EstadisticasState(
      status: EstadisticasStatus.cargando,
      datos: state.datos,
    ));
    try {
      final datos = await _obtener();
      if (consulta != _consulta) return;
      emit(EstadisticasState(status: EstadisticasStatus.lista, datos: datos));
    } catch (e) {
      if (consulta != _consulta) return;
      // No dejamos cifras viejas junto a un error: podrían estar desactualizadas.
      emit(EstadisticasState(
        status: EstadisticasStatus.fallida,
        errorMessage: e is AuthFailure
            ? e.message
            : 'No pudimos cargar las estadísticas. Inténtalo de nuevo.',
      ));
    }
  }
}
