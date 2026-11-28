import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';
import 'package:smartcart/features/seguimiento/domain/usecases/seguimiento_usecases.dart';

abstract class PushEvent {}

/// Al entrar al Home del cliente: pide permiso y guarda el token.
class PushIniciado extends PushEvent {}

class _AvisoRecibido extends PushEvent {
  final AvisoPush aviso;

  _AvisoRecibido(this.aviso);
}

class _AvisoAbierto extends PushEvent {}

class _TokenRenovado extends PushEvent {
  final String token;

  _TokenRenovado(this.token);
}

class PushState {
  /// Las notificaciones push quedaron activas en este teléfono.
  final bool activas;

  /// Aviso que llegó con la app abierta: se muestra una vez dentro de la app.
  final AvisoPush? aviso;

  /// Cambia cada vez que llega un aviso (dos avisos iguales seguidos se
  /// muestran los dos).
  final int numeroAviso;

  /// Cambia cada vez que la persona toca un aviso de la barra del sistema:
  /// hay que abrir "Mis órdenes".
  final int abrirOrdenes;

  const PushState({
    this.activas = false,
    this.aviso,
    this.numeroAviso = 0,
    this.abrirOrdenes = 0,
  });
}

/// HU-23: las notificaciones push en el Home del cliente. Activa el push,
/// guarda el token (y sus renovaciones) y pasa a la pantalla los avisos que
/// llegan con la app abierta y los que la persona toca.
class PushBloc extends Bloc<PushEvent, PushState> {
  final ActivarNotificacionesPushUseCase _activar;
  final NotificacionesPush _push;
  final _suscripciones = <StreamSubscription<Object?>>[];

  PushBloc({
    required ActivarNotificacionesPushUseCase activar,
    required NotificacionesPush push,
  })  : _activar = activar,
        _push = push,
        super(const PushState()) {
    on<PushIniciado>(_onIniciado);
    on<_AvisoRecibido>((event, emit) => emit(PushState(
          activas: state.activas,
          aviso: event.aviso,
          numeroAviso: state.numeroAviso + 1,
          abrirOrdenes: state.abrirOrdenes,
        )));
    on<_AvisoAbierto>((event, emit) => emit(PushState(
          activas: state.activas,
          aviso: state.aviso,
          numeroAviso: state.numeroAviso,
          abrirOrdenes: state.abrirOrdenes + 1,
        )));
    on<_TokenRenovado>((event, emit) async {
      try {
        await _activar.renovar(event.token);
      } catch (_) {
        // Se volverá a intentar la próxima vez que entre.
      }
    });
  }

  Future<void> _onIniciado(PushIniciado event, Emitter<PushState> emit) async {
    if (_suscripciones.isEmpty) {
      _suscripciones
        ..add(_push.enPrimerPlano.listen((a) => add(_AvisoRecibido(a))))
        ..add(_push.avisoAbierto.listen((_) => add(_AvisoAbierto())))
        ..add(_push.tokenRenovado.listen((t) => add(_TokenRenovado(t))));
    }
    bool activas;
    try {
      activas = await _activar();
    } catch (_) {
      // Sin push la app sigue: el aviso también se ve dentro de la app.
      activas = false;
    }
    emit(PushState(
      activas: activas,
      aviso: state.aviso,
      numeroAviso: state.numeroAviso,
      abrirOrdenes: state.abrirOrdenes,
    ));
  }

  @override
  Future<void> close() async {
    for (final s in _suscripciones) {
      await s.cancel();
    }
    return super.close();
  }
}
