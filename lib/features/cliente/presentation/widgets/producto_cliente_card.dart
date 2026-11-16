import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/presentation/widgets/agregar_carrito_boton.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/presentation/widgets/favorito_boton.dart';

/// Una fila de producto para el cliente: nombre, marca y categoría, el
/// comercio que lo vende, el corazón de favoritos y el botón de agregar al
/// carrito. La usan la exploración y los favoritos.
///
/// Necesita un `CarritoBloc` y un `FavoritosBloc` arriba en el árbol.
class ProductoClienteCard extends StatelessWidget {
  final ProductoConComercio producto;

  const ProductoClienteCard({super.key, required this.producto});

  String get _detalle {
    final marca = producto.producto.marca;
    final categoria = producto.producto.categoria;
    return marca == null || marca.isEmpty ? categoria : '$marca · $categoria';
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                  if (_detalle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: t.textoGris),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Vende ${producto.comercio}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: t.textoGris),
                  ),
                ],
              ),
            ),
            FavoritoBoton(tipo: TipoFavorito.producto, id: producto.id),
            AgregarCarritoBoton(idProducto: producto.id),
          ],
        ),
      ),
    );
  }
}
