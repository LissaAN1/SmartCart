import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';

/// El botón "Agregar al carrito" de un producto. Reutilizable: la búsqueda
/// (HU-12) y el detalle (HU-13) pueden ponerlo en sus pantallas con solo
/// indicar el [idProducto].
///
/// Necesita un `CarritoBloc` arriba en el árbol.
class AgregarCarritoBoton extends StatelessWidget {
  final String idProducto;

  const AgregarCarritoBoton({super.key, required this.idProducto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return IconButton(
      tooltip: 'Agregar al carrito',
      icon: Icon(Icons.add_shopping_cart, color: t.primario),
      onPressed: () =>
          context.read<CarritoBloc>().add(CarritoProductoAgregado(idProducto)),
    );
  }
}
