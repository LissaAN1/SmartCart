import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Una fila de la lista del catálogo del comercio (HU-10). Con la HU-11
/// muestra el precio y si está agotado, y [onPrecio] abre la edición rápida.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;
  final VoidCallback? onPrecio;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onPrecio,
  });

  String get _detalle {
    final marca = producto.marca;
    return marca == null || marca.isEmpty
        ? producto.categoria
        : '$marca · ${producto.categoria}';
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final codigo = producto.codigoBarras;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined, color: t.primarioOscuro),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textoGris),
                  ),
                  if (codigo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Código $codigo',
                      style: TextStyle(fontSize: 12, color: t.textoGris),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _ResumenPrecio(producto: producto),
                ],
              ),
            ),
            if (onPrecio != null)
              IconButton(
                tooltip: 'Precio y disponibilidad',
                onPressed: onPrecio,
                icon: Icon(Icons.price_change_outlined, color: t.primarioOscuro),
              ),
            Icon(Icons.edit_outlined, size: 20, color: t.textoGris),
          ],
        ),
      ),
    );
  }
}

/// "$ 2.500", "$ 2.500 · Agotado" o "Sin precio".
class _ResumenPrecio extends StatelessWidget {
  final Producto producto;

  const _ResumenPrecio({required this.producto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final precio = producto.precio;
    if (precio == null) {
      return Text(
        'Sin precio',
        style: TextStyle(fontSize: 12.5, color: t.textoGris),
      );
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          formatoCop(precio),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.primarioOscuro,
          ),
        ),
        if (!producto.disponible) const EtiquetaEstado.error('Agotado'),
      ],
    );
  }
}
