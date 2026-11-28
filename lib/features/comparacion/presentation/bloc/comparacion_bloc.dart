import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';

abstract class ComparacionEvent {}

/// Leer el carrito con sus ofertas y la ubicación guardada, y comparar.
class ComparacionIniciada extends ComparacionEvent {}

/// El cliente eligió qué priorizar.
class ComparacionCriterioElegido extends ComparacionEvent {
  final CriterioCompra criterio;

  ComparacionCriterioElegido(this.criterio);
}

/// El cliente fijó una distancia máxima (o la quitó con `null`).
class ComparacionDistanciaElegida extends ComparacionEvent {
  final int? distanciaMaxM;

  ComparacionDistanciaElegida(this.distanciaMaxM);
}

/// Volver a leer la ubicación guardada (al volver del mapa de la HU-19).
class ComparacionUbicacionRecargada extends ComparacionEvent {}

enum ComparacionStatus { initial, cargando, lista, vacia, falloCarga }

class ComparacionState {
  final ComparacionStatus status;
  final List<LineaComparable> lineas;
  final PreferenciaUbicacion? ubicacion;
  final CriterioCompra criterio;
  final int? distanciaMaxM;
  final ResultadoComparacion? resultado;
  final String? errorMessage;

  const ComparacionState({
    this.status = ComparacionStatus.initial,
    this.lineas = const [],
    this.ubicacion,
    this.criterio = CriterioCompra.ahorro,
    this.distanciaMaxM,
    this.resultado,
    this.errorMessage,
  });

  /// La alternativa del criterio elegido primero y luego las demás.
  List<Alternativa> get alternativas {
    final todas = resultado?.alternativas ?? const {};
    return [
      if (todas[criterio] != null) todas[criterio]!,
      for (final c in CriterioCompra.values)
        if (c != criterio && todas[c] != null) todas[c]!,
    ];
  }

  ComparacionState copyWith({
    ComparacionStatus? status,
    List<LineaComparable>? lineas,
    PreferenciaUbicacion? ubicacion,
    CriterioCompra? criterio,
    int? Function()? distanciaMaxM,
    ResultadoComparacion? resultado,
    String? errorMessage,
  }) {
    return ComparacionState(
      status: status ?? this.status,
      lineas: lineas ?? this.lineas,
      ubicacion: ubicacion ?? this.ubicacion,
      criterio: criterio ?? this.criterio,
      distanciaMaxM:
          distanciaMaxM == null ? this.distanciaMaxM : distanciaMaxM(),
      resultado: resultado ?? this.resultado,
      errorMessage: errorMessage,
    );
  }
}

/// HU-18: la comparación del carrito completo. Lee una sola vez las ofertas
/// (el precio vigente al momento de comparar) y la ubicación guardada; al
/// cambiar el criterio o la distancia solo se recalcula, sin volver a la red.
class ComparacionBloc extends Bloc<ComparacionEvent, ComparacionState> {
  final GetOfertasCarritoUseCase _ofertas;
  final GetMiUbicacionUseCase _miUbicacion;
  final CompararCarritoUseCase _comparar;

  ComparacionBloc({
    required GetOfertasCarritoUseCase ofertas,
    required GetMiUbicacionUseCase miUbicacion,
    required CompararCarritoUseCase comparar,
  })  : _ofertas = ofertas,
        _miUbicacion = miUbicacion,
        _comparar = comparar,
        super(const ComparacionState()) {
    on<ComparacionIniciada>(_onIniciada);
    on<ComparacionCriterioElegido>(
        (e, emit) => emit(state.copyWith(criterio: e.criterio)));
    on<ComparacionDistanciaElegida>(_onDistancia);
    on<ComparacionUbicacionRecargada>(_onUbicacion);
  }

  static String _mensaje(Object e) => e is AuthFailure
      ? e.message
      : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  /// Sin ubicación la comparación sigue: la distancia sale como no
  /// disponible.
  Future<PreferenciaUbicacion?> _leerUbicacion() async {
    try {
      return await _miUbicacion();
    } catch (_) {
      return null;
    }
  }

  Future<void> _onIniciada(
    ComparacionIniciada event,
    Emitter<ComparacionState> emit,
  ) async {
    if (state.status == ComparacionStatus.cargando) return;
    emit(state.copyWith(status: ComparacionStatus.cargando));
    try {
      final lineas = await _ofertas();
      final ubicacion = await _leerUbicacion();
      if (lineas.isEmpty) {
        emit(state.copyWith(status: ComparacionStatus.vacia, lineas: lineas));
        return;
      }
      emit(_comparado(
        state.copyWith(lineas: lineas, ubicacion: ubicacion),
        state.distanciaMaxM,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: ComparacionStatus.falloCarga, errorMessage: _mensaje(e)));
    }
  }

  void _onDistancia(
    ComparacionDistanciaElegida event,
    Emitter<ComparacionState> emit,
  ) {
    if (state.status != ComparacionStatus.lista) return;
    emit(_comparado(state, event.distanciaMaxM));
  }

  Future<void> _onUbicacion(
    ComparacionUbicacionRecargada event,
    Emitter<ComparacionState> emit,
  ) async {
    if (state.status != ComparacionStatus.lista) return;
    final ubicacion = await _leerUbicacion();
    if (ubicacion == null) return;
    emit(_comparado(state.copyWith(ubicacion: ubicacion), state.distanciaMaxM));
  }

  /// Compara con [distanciaMaxM]; si no se puede (por ejemplo, sin
  /// ubicación), compara sin límite y deja el mensaje.
  ComparacionState _comparado(ComparacionState base, int? distanciaMaxM) {
    try {
      return base.copyWith(
        status: ComparacionStatus.lista,
        distanciaMaxM: () => distanciaMaxM,
        resultado: _comparar(
          lineas: base.lineas,
          cliente: base.ubicacion?.ubicacion,
          distanciaMaxM: distanciaMaxM,
        ),
      );
    } on AuthFailure catch (e) {
      return base.copyWith(
        status: ComparacionStatus.lista,
        distanciaMaxM: () => null,
        resultado: _comparar(
          lineas: base.lineas,
          cliente: base.ubicacion?.ubicacion,
        ),
        errorMessage: e.message,
      );
    }
  }
}
