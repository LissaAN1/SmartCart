import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';

/// Envuelve el Home: si la cuenta tiene notificaciones sin leer, las muestra
/// en un diálogo al entrar y, al cerrarlo, las marca como leídas. Así el
/// comercio o el repartidor se entera de la decisión del administrador
/// (HU-24).
///
/// Necesita un `NotificacionesBloc` arriba en el árbol (lo provee
/// `AppRouter`).
class AvisoNotificaciones extends StatelessWidget {
  final Widget child;

  const AvisoNotificaciones({super.key, required this.child});

  Future<void> _mostrar(
    BuildContext context,
    List<Notificacion> notificaciones,
  ) async {
    final bloc = context.read<NotificacionesBloc>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(notificaciones.length == 1
            ? notificaciones.first.titulo
            : 'Tienes ${notificaciones.length} notificaciones'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final n in notificaciones) ...[
                if (notificaciones.length > 1)
                  Text(n.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(n.mensaje),
                if (n != notificaciones.last) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    bloc.add(NotificacionesVistas());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificacionesBloc, NotificacionesState>(
      listenWhen: (previous, current) =>
          previous.porMostrar.isEmpty && current.porMostrar.isNotEmpty,
      listener: (context, state) => _mostrar(context, state.porMostrar),
      child: child,
    );
  }
}
