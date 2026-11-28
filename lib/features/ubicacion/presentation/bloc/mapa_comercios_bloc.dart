import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';

abstract class MapaComerciosEvent {}

/// Al abrir el mapa: lo guardado o, si no hay nada, el GPS.
class MapaIniciado extends MapaComerciosEvent {}

/// El cliente pidió usar su ubicación actual (GPS).
class MapaUbicacionActualSolicitada extends MapaComerciosEvent {}

/// El cliente escribió su dirección (escenario 2).
class MapaDireccionBuscada extends MapaComerciosEvent {
  final String texto;

  MapaDireccionBuscada(this.texto);
}

/// El cliente eligió otro radio (escenario 3).
class MapaRadioCambiado extends MapaComerciosEvent {
  final int radioM;

  MapaRadioCambiado(this.radioM);
}

enum MapaStatus {
  initial,
  cargando,
  listo,

  /// No hay ubicación guardada y el GPS no la dio: hay que escribir la
  /// dirección.
  sinUbicacion,
  falloCarga,
}

class MapaComerciosState {
  final MapaStatus status;
  final PreferenciaUbicacion? preferencia;
  final List<EstablecimientoCercano> comercios;

  /// Por qué no hay ubicación ([MapaStatus.sinUbicacion]) o por qué falló la
  /// carga ([MapaStatus.falloCarga]).
  final String? errorMessage;

  /// Se está pidiendo el GPS, buscando la dirección o guardando: la pantalla
  /// muestra que trabaja y no acepta otro cambio.
  final bool ocupado;

  final AvisoUi? aviso;

  const MapaComerciosState({
    this.status = MapaStatus.initial,
    this.preferencia,
    this.comercios = const [],
    this.errorMessage,
    this.ocupado = false,
    this.aviso,
  });

  int get radioM => preferencia?.radioM ?? RadioReglas.porDefectoM;

  /// El error y el aviso no se arrastran salvo que se indiquen.
  MapaComerciosState copyWith({
    MapaStatus? status,
    PreferenciaUbicacion? preferencia,
    List<EstablecimientoCercano>? comercios,
    String? errorMessage,
    bool? ocupado,
    AvisoUi? aviso,
  }) {
    return MapaComerciosState(
      status: status ?? this.status,
      preferencia: preferencia ?? this.preferencia,
      comercios: comercios ?? this.comercios,
      errorMessage: errorMessage,
      ocupado: ocupado ?? this.ocupado,
      aviso: aviso,
    );
  }
}

/// HU-19: la ubicación y el radio del cliente, y los comercios aprobados que
/// quedan dentro. Cada cambio se guarda en la cuenta antes de mostrarse, así
/// lo que ve la persona es lo que queda guardado.
class MapaComerciosBloc extends Bloc<MapaComerciosEvent, MapaComerciosState> {
  final GetMiUbicacionUseCase _miUbicacion;
  final GuardarMiUbicacionUseCase _guardar;
  final GetComerciosEnRadioUseCase _comercios;
  final ObtenerUbicacionUseCase _gps;
  final BuscarDireccionUseCase _buscarDireccion;

  int _avisos = 0;

  MapaComerciosBloc({
    required GetMiUbicacionUseCase miUbicacion,
    required GuardarMiUbicacionUseCase guardar,
    required GetComerciosEnRadioUseCase comercios,
    required ObtenerUbicacionUseCase gps,
    required BuscarDireccionUseCase buscarDireccion,
  })  : _miUbicacion = miUbicacion,
        _guardar = guardar,
        _comercios = comercios,
        _gps = gps,
        _buscarDireccion = buscarDireccion,
        super(const MapaComerciosState()) {
    on<MapaIniciado>(_onIniciado);
    on<MapaUbicacionActualSolicitada>(_onUbicacionActual);
    on<MapaDireccionBuscada>(_onDireccion);
    on<MapaRadioCambiado>(_onRadio);
  }

  AvisoUi _aviso(String texto, {bool esError = false}) =>
      AvisoUi(id: ++_avisos, texto: texto, esError: esError);

  static String _mensaje(Object e) => e is AuthFailure
      ? e.message
      : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  Future<void> _onIniciado(
    MapaIniciado event,
    Emitter<MapaComerciosState> emit,
  ) async {
    if (state.status == MapaStatus.cargando) return;
    emit(state.copyWith(status: MapaStatus.cargando));

    PreferenciaUbicacion? guardada;
    try {
      guardada = await _miUbicacion();
    } catch (e) {
      emit(state.copyWith(
          status: MapaStatus.falloCarga, errorMessage: _mensaje(e)));
      return;
    }

    if (guardada == null) {
      // Escenario 1 la primera vez: pedimos el GPS (y con él el permiso). Si
      // no lo da, escenario 2: que escriba su dirección.
      try {
        final ubicacion = await _gps();
        guardada = PreferenciaUbicacion(
          ubicacion: ubicacion,
          radioM: RadioReglas.porDefectoM,
        );
        await _guardar(guardada);
      } on AuthFailure catch (e) {
        emit(state.copyWith(
            status: MapaStatus.sinUbicacion, errorMessage: e.message));
        return;
      } catch (e) {
        emit(state.copyWith(
            status: MapaStatus.sinUbicacion, errorMessage: _mensaje(e)));
        return;
      }
    }

    try {
      final comercios = await _comercios(guardada);
      emit(state.copyWith(
        status: MapaStatus.listo,
        preferencia: guardada,
        comercios: comercios,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: MapaStatus.falloCarga, errorMessage: _mensaje(e)));
    }
  }

  Future<void> _onUbicacionActual(
    MapaUbicacionActualSolicitada event,
    Emitter<MapaComerciosState> emit,
  ) =>
      _cambiar(
        emit,
        () async => PreferenciaUbicacion(
          ubicacion: await _gps(),
          radioM: state.radioM,
        ),
        exito: 'Usamos tu ubicación actual.',
      );

  Future<void> _onDireccion(
    MapaDireccionBuscada event,
    Emitter<MapaComerciosState> emit,
  ) =>
      _cambiar(
        emit,
        () async {
          final encontrada = await _buscarDireccion(event.texto);
          return PreferenciaUbicacion(
            ubicacion: encontrada.ubicacion,
            radioM: state.radioM,
            direccion: encontrada.direccion,
          );
        },
        exito: 'Guardamos tu dirección.',
      );

  Future<void> _onRadio(
    MapaRadioCambiado event,
    Emitter<MapaComerciosState> emit,
  ) async {
    final actual = state.preferencia;
    if (actual == null || actual.radioM == event.radioM) return;
    await _cambiar(emit, () async => actual.conRadio(event.radioM));
  }

  /// Arma la nueva preferencia, la guarda y trae los comercios de su radio.
  /// Si algo falla, todo queda como estaba y se avisa.
  Future<void> _cambiar(
    Emitter<MapaComerciosState> emit,
    Future<PreferenciaUbicacion> Function() nueva, {
    String? exito,
  }) async {
    if (state.ocupado) return;
    emit(state.copyWith(ocupado: true, errorMessage: state.errorMessage));
    try {
      final preferencia = await nueva();
      await _guardar(preferencia);
      final comercios = await _comercios(preferencia);
      emit(state.copyWith(
        status: MapaStatus.listo,
        preferencia: preferencia,
        comercios: comercios,
        ocupado: false,
        aviso: exito == null ? null : _aviso(exito),
      ));
    } catch (e) {
      emit(state.copyWith(
        ocupado: false,
        errorMessage: state.errorMessage,
        aviso: _aviso(_mensaje(e), esError: true),
      ));
    }
  }
}
