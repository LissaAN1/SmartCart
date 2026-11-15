import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Una fila de la lista del catálogo del comercio (HU-10).
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;

  /// Ícono del extremo derecho: lápiz al editar (HU-10) o flecha al elegir
  /// el producto de un reporte (HU-14).
  final IconData icono;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.icono = Icons.edit_outlined,
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
                ],
              ),
            ),
            Icon(icono, size: 20, color: t.textoGris),
          ],
        ),
      ),
    );
  }
}
