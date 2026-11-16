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
