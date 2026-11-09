import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/get_notificaciones_no_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/marcar_notificaciones_leidas_usecase.dart';

abstract class NotificacionesEvent {}

/// Al entrar al Home: busca las notificaciones sin leer.
class NotificacionesStarted extends NotificacionesEvent {}

/// La persona cerró el aviso: se marcan como leídas.
class NotificacionesVistas extends NotificacionesEvent {}

/// Notificaciones sin leer que todavía no se le han mostrado a la persona.
class NotificacionesState {
  final List<Notificacion> porMostrar;

  const NotificacionesState({this.porMostrar = const []});
}

/// Muestra una vez las notificaciones sin leer (por ejemplo, la decisión
/// del administrador, HU-24) y las marca como leídas al verlas.
///
/// Una notificación es un dato de apoyo: si no se puede leer o marcar, se
/// registra en el log y la persona sigue usando la app con normalidad.
class NotificacionesBloc
    extends Bloc<NotificacionesEvent, NotificacionesState> {
  final GetNotificacionesNoLeidasUseCase _noLeidas;
  final MarcarNotificacionesLeidasUseCase _marcarLeidas;

  NotificacionesBloc({
    required GetNotificacionesNoLeidasUseCase noLeidas,
    required MarcarNotificacionesLeidasUseCase marcarLeidas,
  })  : _noLeidas = noLeidas,
        _marcarLeidas = marcarLeidas,
        super(const NotificacionesState()) {
    on<NotificacionesStarted>(_onStarted);
    on<NotificacionesVistas>(_onVistas);
  }

  Future<void> _onStarted(
    NotificacionesStarted event,
    Emitter<NotificacionesState> emit,
  ) async {
    try {
      final pendientes = await _noLeidas();
      if (pendientes.isNotEmpty) {
        emit(NotificacionesState(porMostrar: pendientes));
      }
    } catch (e) {
      developer.log('No se pudieron leer: $e',
          name: 'smartcart.notificaciones');
    }
  }

  Future<void> _onVistas(
    NotificacionesVistas event,
    Emitter<NotificacionesState> emit,
  ) async {
    final vistas = state.porMostrar;
    if (vistas.isEmpty) return;
    emit(const NotificacionesState());
    try {
      await _marcarLeidas(vistas);
    } catch (e) {
      developer.log('No se pudieron marcar: $e',
          name: 'smartcart.notificaciones');
    }
  }
}
