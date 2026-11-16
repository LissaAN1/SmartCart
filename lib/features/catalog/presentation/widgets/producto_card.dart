import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Ícono de reserva para un producto sin foto, según su categoría.
IconData iconoDeCategoria(String categoria) {
  return switch (categoria.toLowerCase()) {
    'frutas' => Icons.eco_outlined,
    'lácteos' || 'lacteos' => Icons.local_drink_outlined,
    'aseo' => Icons.cleaning_services_outlined,
    'café' || 'cafe' => Icons.coffee_outlined,
    'panadería' || 'panaderia' => Icons.bakery_dining_outlined,
    _ => Icons.shopping_basket_outlined,
  };
}

/// Una fila del catálogo del comercio, como en el diseño: foto, nombre,
/// categoría, precio, stock y si está ACTIVO o INACTIVO (HU-11, disponible o
/// agotado). Toda la tarjeta abre Editar Producto, donde se cambia todo.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;

  const ProductoCard({super.key, required this.producto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final precio = producto.precio;
    final activo = producto.disponible;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TarjetaSuave(
        radio: 22,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Foto(producto: producto),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
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
                  if (producto.codigoBarras != null)
                    Text(
                      'Código ${producto.codigoBarras}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: t.textoGris),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    precio == null ? 'Sin precio' : formatoCop(precio),
                    style: precio == null
                        ? TextStyle(fontSize: 13, color: t.textoGris)
                        : TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: t.primario,
                          ),
                  ),
                  const SizedBox(height: 4),
                  _Stock(producto: producto),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  activo ? 'ACTIVO' : 'INACTIVO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: activo ? ColoresEstado.verde : ColoresEstado.rojo,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(Icons.chevron_right, color: t.textoGris),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _detalle {
    final marca = producto.marca;
    return marca == null || marca.isEmpty
        ? producto.categoria
        : '$marca · ${producto.categoria}';
  }
}

/// Foto del producto (o el ícono de su categoría) con la etiqueta "Agotado"
/// encima cuando está inactivo.
class _Foto extends StatelessWidget {
  final Producto producto;

  const _Foto({required this.producto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borde),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ImagenPlaceholder(
              url: producto.fotoUrl,
              radio: 14,
              icono: iconoDeCategoria(producto.categoria),
            ),
          ),
          if (!producto.disponible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: ColoresEstado.rojo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Agotado',
                style: TextStyle(
                  color: t.superficie,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Stock: 45 uds" en verde, o en rojo con alerta si es stock bajo.
class _Stock extends StatelessWidget {
  final Producto producto;

  const _Stock({required this.producto});

  @override
  Widget build(BuildContext context) {
    final bajo = producto.stockBajo;
    final color = bajo ? ColoresEstado.rojo : ColoresEstado.verde;
    return Row(
      children: [
        Icon(
          bajo ? Icons.error_outline : Icons.check_circle_outline,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Stock: ${producto.stock} uds',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: color),
          ),
        ),
      ],
    );
  }
}
