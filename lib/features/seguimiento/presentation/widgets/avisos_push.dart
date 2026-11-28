import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/push_bloc.dart';

/// HU-23: envuelve el Home del cliente para las notificaciones push.
///
/// · Si llega un aviso con la app abierta (Firebase no lo muestra en ese
///   caso), se vuelven a leer los avisos sin leer: el diálogo de la HU-24
///   lo muestra dentro de la app y lo marca como leído.
/// · Si la persona toca un aviso de la barra del sistema, se abre "Mis
///   órdenes".
///
/// Necesita arriba un `PushBloc` y un `NotificacionesBloc` (los provee
/// `AppRouter`).
class AvisosPush extends StatelessWidget {
  final Widget child;

  const AvisosPush({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PushBloc, PushState>(
          listenWhen: (antes, ahora) => antes.numeroAviso != ahora.numeroAviso,
          listener: (context, _) =>
              context.read<NotificacionesBloc>().add(NotificacionesStarted()),
        ),
        BlocListener<PushBloc, PushState>(
          listenWhen: (antes, ahora) => antes.abrirOrdenes != ahora.abrirOrdenes,
          listener: (context, _) =>
              Navigator.of(context).pushNamed(AppRoutes.misOrdenes),
        ),
      ],
      child: child,
    );
  }
}
