import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Totales del catálogo de un comercio (HU-11): se muestran arriba de la
/// lista. Los calcula la base con `resumen_catalogo`.
class ResumenCatalogo {
  final int totalProductos;

  /// Suma de precio × stock, en pesos.
  final int valorStock;

  /// Productos con 10 unidades o menos.
  final int bajoStock;

  const ResumenCatalogo({
    this.totalProductos = 0,
    this.valorStock = 0,
    this.bajoStock = 0,
  });
}

/// Lo que necesita la parte de arriba del catálogo: los chips de categorías
/// y el resumen.
class EncabezadoCatalogo {
  final List<Categoria> categorias;
  final ResumenCatalogo resumen;

  const EncabezadoCatalogo({required this.categorias, required this.resumen});
}

/// Lo que necesita el formulario de un producto: las categorías para elegir
/// y el comercio (su nombre se muestra como "Tienda / Sucursal").
class FormularioProducto {
  final List<Categoria> categorias;
  final Comercio comercio;

  const FormularioProducto({required this.categorias, required this.comercio});
}
