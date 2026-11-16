import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

/// El carrito y los favoritos del cliente (HU-17): una sola instancia de cada
/// uno, que el `RolShell` crea al entrar y comparten el Home, la exploración,
/// el carrito y los favoritos. Así el número del carrito y los corazones
/// siempre coinciden entre pantallas.
///
/// Las pantallas se abren con rutas, que no cuelgan del árbol del `RolShell`,
/// por eso este par viaja como argumento de la ruta y el `AppRouter` lo
/// entrega con `BlocProvider.value` (sin cerrarlo: lo cierra quien lo creó).
class ClienteBlocs {
  final CarritoBloc carrito;
  final FavoritosBloc favoritos;

  const ClienteBlocs({required this.carrito, required this.favoritos});

  /// Lee lo guardado del carrito y de los favoritos.
  void iniciar() {
    carrito.add(CarritoStarted());
    favoritos.add(FavoritosStarted());
  }

  Future<void> cerrar() async {
    await carrito.close();
    await favoritos.close();
  }
}

/// Argumento de ruta que acompaña al argumento propio de una pantalla (el
/// texto de la búsqueda, qué producto abrir) con el carrito y los favoritos del
/// cliente (HU-13). Las pantallas de la búsqueda se abrieron antes sin ellos;
/// así los reciben cuando vienen del Home del cliente y, sin ellos (por
/// ejemplo en las pruebas), siguen funcionando sin los botones de carrito y
/// favoritos.
class ConBlocsDelCliente {
  final Object? argumento;
  final ClienteBlocs blocs;

  const ConBlocsDelCliente(this.argumento, this.blocs);
}

/// Separa el argumento propio de una ruta de los blocs del cliente, si los
/// trae.
(Object?, ClienteBlocs?) desempacarArgumentos(Object? args) => args
        is ConBlocsDelCliente
    ? (args.argumento, args.blocs)
    : (args, null);

/// El carrito y los favoritos del cliente, si esta pantalla los tiene en su
/// árbol; `null` si no (por ejemplo, una pantalla abierta sin ellos).
ClienteBlocs? clienteBlocsOrNull(BuildContext context) {
  try {
    return ClienteBlocs(
      carrito: context.read<CarritoBloc>(),
      favoritos: context.read<FavoritosBloc>(),
    );
  } catch (_) {
    // `flutter_bloc` no exporta la excepción de "no hay proveedor": cualquier
    // fallo al leerlos significa que esta pantalla no los tiene.
    return null;
  }
}

/// Atajos para abrir las pantallas del cliente desde otra pantalla que ya
/// tiene el carrito y los favoritos en su árbol (por ejemplo, desde el
/// carrito se abre la exploración).
extension NavegacionCliente on BuildContext {
  ClienteBlocs get _clienteBlocs => ClienteBlocs(
        carrito: read<CarritoBloc>(),
        favoritos: read<FavoritosBloc>(),
      );

  Future<void> abrirCarrito() =>
      Navigator.of(this).pushNamed(AppRoutes.carrito, arguments: _clienteBlocs);

  Future<void> abrirFavoritos() => Navigator.of(this)
      .pushNamed(AppRoutes.favoritos, arguments: _clienteBlocs);

  Future<void> abrirExplorar() => Navigator.of(this)
      .pushNamed(AppRoutes.explorar, arguments: _clienteBlocs);
}
