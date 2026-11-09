import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';
import 'package:smartcart/features/comercio/presentation/pages/comercio_estado_page.dart';
import 'package:smartcart/features/comercio/presentation/pages/comercio_registro_page.dart';

/// Decide qué ve el dueño de un comercio al entrar (HU-07):
///
/// * sin comercio registrado: el formulario de registro;
/// * comercio pendiente o rechazado: la pantalla de estado;
/// * comercio aprobado: el Home de siempre ([child]).
///
/// Necesita un `ComercioBloc` arriba en el árbol (lo provee `AppRouter`).
class ComercioGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onCerrarSesion;

  const ComercioGate({super.key, required this.child, this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComercioBloc, ComercioState>(
      builder: (context, state) {
        final comercio = state.comercio;

        // La primera lectura aún no termina.
        if (comercio == null &&
            (state.status == ComercioStatus.initial ||
                state.status == ComercioStatus.loading)) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (comercio == null && state.status == ComercioStatus.loadFailed) {
          return _ErrorCarga(
            mensaje: state.errorMessage,
            onReintentar: () =>
                context.read<ComercioBloc>().add(ComercioStarted()),
            onCerrarSesion: onCerrarSesion,
          );
        }
        if (comercio == null) {
          return ComercioRegistroPage(onCerrarSesion: onCerrarSesion);
        }
        if (comercio.estado == ApprovalStatus.aprobado) return child;
        return ComercioEstadoPage(
          comercio: comercio,
          actualizando: state.status == ComercioStatus.loading,
          onActualizar: () =>
              context.read<ComercioBloc>().add(ComercioStarted()),
          onCerrarSesion: onCerrarSesion,
        );
      },
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String? mensaje;
  final VoidCallback onReintentar;
  final VoidCallback? onCerrarSesion;

  const _ErrorCarga({
    required this.mensaje,
    required this.onReintentar,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(
                mensaje ?? 'No pudimos cargar tu comercio.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
              if (onCerrarSesion != null)
                TextButton(
                  onPressed: onCerrarSesion,
                  child: const Text('Cerrar sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
