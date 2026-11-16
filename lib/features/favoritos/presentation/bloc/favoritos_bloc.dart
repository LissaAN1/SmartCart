import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/domain/usecases/favoritos_usecases.dart';

abstract class FavoritosEvent {}

/// Leer los favoritos guardados (al entrar al Home y al reintentar).
class FavoritosStarted extends FavoritosEvent {}

/// El cliente presionó el corazón de un producto o de un comercio: si era
/// favorito lo quita y si no, lo guarda.
class FavoritoAlternado extends FavoritosEvent {
  final TipoFavorito tipo;
  final String id;

  FavoritoAlternado(this.tipo, this.id);
}

enum FavoritosStatus { initial, cargando, listo, falloCarga }

class FavoritosState {
  final FavoritosStatus status;
  final FavoritosIds ids;
  final String? errorMessage;
  final AvisoUi? aviso;

  const FavoritosState({
    this.status = FavoritosStatus.initial,
    this.ids = const FavoritosIds(),
    this.errorMessage,
    this.aviso,
  });

  FavoritosState copyWith({
    FavoritosStatus? status,
    FavoritosIds? ids,
    String? errorMessage,
    AvisoUi? aviso,
  }) {
    return FavoritosState(
      status: status ?? this.status,
      ids: ids ?? this.ids,
      errorMessage: errorMessage,
      aviso: aviso,
    );
  }
}

/// Los favoritos del cliente (HU-17): qué productos y comercios marcó. Lo
/// comparten el Home, la exploración y la pantalla de favoritos, con una sola
/// instancia creada por el `RolShell` del cliente.
///
/// El corazón cambia al instante y luego se guarda; si guardar falla, vuelve
/// a como estaba y se avisa.
class FavoritosBloc extends Bloc<FavoritosEvent, FavoritosState> {
  final GetFavoritosIdsUseCase _obtener;
  final CambiarFavoritoUseCase _cambiar;

  int _avisos = 0;

  /// Los favoritos que se están guardando ahora, para que un segundo toque al
  /// mismo corazón mientras tanto no mande dos cambios opuestos a la vez.
  final _enCurso = <String>{};

  FavoritosBloc({
    required GetFavoritosIdsUseCase obtener,
    required CambiarFavoritoUseCase cambiar,
  })  : _obtener = obtener,
        _cambiar = cambiar,
        super(const FavoritosState()) {
    on<FavoritosStarted>(_onStarted);
    on<FavoritoAlternado>(_onAlternado);
  }

  AvisoUi _aviso(String texto, {bool esError = false}) =>
      AvisoUi(id: ++_avisos, texto: texto, esError: esError);

  String _mensaje(Object e) =>
      e is AuthFailure ? e.message : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  Future<void> _onStarted(
    FavoritosStarted event,
    Emitter<FavoritosState> emit,
  ) async {
    if (state.status == FavoritosStatus.cargando) return;
    emit(state.copyWith(status: FavoritosStatus.cargando));
    try {
      emit(state.copyWith(
        status: FavoritosStatus.listo,
        ids: await _obtener(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoritosStatus.falloCarga,
        errorMessage: _mensaje(e),
      ));
    }
  }

  /// Escenario 3: al presionar el corazón, el favorito queda guardado.
  Future<void> _onAlternado(
    FavoritoAlternado event,
    Emitter<FavoritosState> emit,
  ) async {
    final clave = '${event.tipo.name}:${event.id}';
    if (!_enCurso.add(clave)) return;
    final eraFavorito = state.ids.contiene(event.tipo, event.id);
    final ahoraEs = !eraFavorito;
    emit(state.copyWith(
      ids: state.ids.con(event.tipo, event.id, favorito: ahoraEs),
    ));
    try {
      await _cambiar(event.tipo, event.id, favorito: ahoraEs);
      emit(state.copyWith(
        aviso: _aviso(
          ahoraEs ? 'Guardado en tus favoritos' : 'Quitado de tus favoritos',
        ),
      ));
    } catch (e) {
      // No se pudo guardar: el corazón vuelve a como estaba.
      emit(state.copyWith(
        ids: state.ids.con(event.tipo, event.id, favorito: eraFavorito),
        aviso: _aviso(_mensaje(e), esError: true),
      ));
    } finally {
      _enCurso.remove(clave);
    }
  }
}
