import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';

/// Lista que pide la siguiente página al acercarse al final. Maneja los
/// estados de carga, error, lista vacía y "cargando más".
///
/// Necesita un `PaginatedBloc<T>` arriba en el árbol (`BlocProvider`).
class PaginatedListView<T> extends StatefulWidget {
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Texto cuando la carga termina sin elementos.
  final String emptyMessage;

  final EdgeInsetsGeometry padding;

  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    this.emptyMessage = 'No hay información disponible',
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  /// Distancia al final (en píxeles) a la que se pide la siguiente página.
  static const double _umbral = 200;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _umbral) {
      _pedirSiguiente();
    }
  }

  void _pedirSiguiente() {
    final bloc = context.read<PaginatedBloc<T>>();
    final state = bloc.state;
    // Si la última página falló no se reintenta sola: lo decide la persona.
    if (state.errorMessage == null) bloc.add(NextPageRequested());
  }

  /// Si la primera página no llena la pantalla no hay desplazamiento que
  /// dispare la carga, así que se pide la siguiente hasta llenarla.
  void _llenarPantalla() {
    if (!mounted || !_controller.hasClients) return;
    if (_controller.position.maxScrollExtent <= 0) _pedirSiguiente();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedBloc<T>, PaginatedState<T>>(
      builder: (context, state) {
        if (state.status == PaginatedStatus.failure) {
          return _Reintentable(
            mensaje: state.errorMessage ?? 'No pudimos cargar la información.',
            onReintentar: () =>
                context.read<PaginatedBloc<T>>().add(PaginatedStarted()),
          );
        }
        if (state.status != PaginatedStatus.success) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isEmpty) {
          return Center(child: Text(widget.emptyMessage));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _llenarPantalla());
        final hayPie = state.loadingMore || state.errorMessage != null;
        return ListView.builder(
          controller: _controller,
          padding: widget.padding,
          itemCount: state.items.length + (hayPie ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < state.items.length) {
              return widget.itemBuilder(context, state.items[index]);
            }
            if (state.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _Reintentable(
              mensaje: state.errorMessage!,
              onReintentar: () =>
                  context.read<PaginatedBloc<T>>().add(NextPageRequested()),
            );
          },
        );
      },
    );
  }
}

/// Mensaje de error con botón para volver a intentar.
class _Reintentable extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _Reintentable({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorMessage(message: mensaje),
          const SizedBox(height: 8),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
