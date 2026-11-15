import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_archivo_csv_usecase.dart';

abstract class CargaCsvEvent {}

/// La persona presionó "Elegir archivo".
class CargaCsvArchivoSolicitado extends CargaCsvEvent {}

enum CargaCsvStatus { initial, cargando, listo, failed }

class CargaCsvState {
  final CargaCsvStatus status;

  /// Nombre del archivo que se cargó.
  final String? archivo;
  final ResultadoCargaCsv? resultado;
  final String? errorMessage;

  const CargaCsvState({
    this.status = CargaCsvStatus.initial,
    this.archivo,
    this.resultado,
    this.errorMessage,
  });
}

/// Carga de productos por archivo: elige el CSV, lo procesa y deja el
/// resultado (cuántos se cargaron y qué filas fallaron) para mostrarlo.
class CargaCsvBloc extends Bloc<CargaCsvEvent, CargaCsvState> {
  final ElegirArchivoCsvUseCase _elegir;
  final CargarProductosCsvUseCase _cargar;

  CargaCsvBloc({
    required ElegirArchivoCsvUseCase elegir,
    required CargarProductosCsvUseCase cargar,
  })  : _elegir = elegir,
        _cargar = cargar,
        super(const CargaCsvState()) {
    on<CargaCsvArchivoSolicitado>(_onArchivoSolicitado);
  }

  Future<void> _onArchivoSolicitado(
    CargaCsvArchivoSolicitado event,
    Emitter<CargaCsvState> emit,
  ) async {
    if (state.status == CargaCsvStatus.cargando) return;
    emit(const CargaCsvState(status: CargaCsvStatus.cargando));
    try {
      final archivo = await _elegir();
      if (archivo == null) {
        // Cancelar el selector no es un error: se queda como estaba.
        emit(const CargaCsvState());
        return;
      }
      final resultado = await _cargar(archivo.contenido);
      emit(CargaCsvState(
        status: CargaCsvStatus.listo,
        archivo: archivo.nombre,
        resultado: resultado,
      ));
    } on AuthFailure catch (e) {
      emit(CargaCsvState(
          status: CargaCsvStatus.failed, errorMessage: e.message));
    } catch (_) {
      emit(const CargaCsvState(
        status: CargaCsvStatus.failed,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
