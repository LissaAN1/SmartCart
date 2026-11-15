/// Lo que escribe el comercio en el formulario de un producto. La marca y el
/// código de barras son opcionales: llegan en `null` cuando se dejan vacíos.
class ProductoDatos {
  final String nombre;
  final String? marca;
  final String? codigoBarras;
  final String idCategoria;

  const ProductoDatos({
    required this.nombre,
    required this.idCategoria,
    this.marca,
    this.codigoBarras,
  });
}

/// Producto ya guardado en el catálogo de un comercio.
class Producto {
  final String id;
  final String nombre;
  final String? marca;
  final String? codigoBarras;
  final String idCategoria;
  final String categoria;

  const Producto({
    required this.id,
    required this.nombre,
    required this.idCategoria,
    required this.categoria,
    this.marca,
    this.codigoBarras,
  });
}
