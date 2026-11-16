/// Lo que escribe el comercio en el formulario de un producto. La marca y el
/// código de barras son opcionales: llegan en `null` cuando se dejan vacíos.
class ProductoDatos {
  final String nombre;
  final String? marca;
  final String? codigoBarras;
  final String idCategoria;

  /// HU-11: unidades disponibles en la tienda.
  final int stock;

  const ProductoDatos({
    required this.nombre,
    required this.idCategoria,
    this.marca,
    this.codigoBarras,
    this.stock = 0,
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

  /// HU-11: precio actual en pesos, o `null` si todavía no tiene.
  final int? precio;

  /// HU-11: `false` si el comercio lo marcó como agotado.
  final bool disponible;

  /// HU-11: unidades en stock.
  final int stock;

  /// HU-11: foto en Supabase Storage, o `null` si no tiene.
  final String? fotoUrl;

  const Producto({
    required this.id,
    required this.nombre,
    required this.idCategoria,
    required this.categoria,
    this.marca,
    this.codigoBarras,
    this.precio,
    this.disponible = true,
    this.stock = 0,
    this.fotoUrl,
  });

  /// Stock bajo: 10 unidades o menos (igual que `resumen_catalogo` en la base).
  bool get stockBajo => stock <= stockBajoMaximo;

  static const stockBajoMaximo = 10;

  Producto copyWith({
    int? precio,
    bool? disponible,
    int? stock,
    String? fotoUrl,
  }) {
    return Producto(
      id: id,
      nombre: nombre,
      idCategoria: idCategoria,
      categoria: categoria,
      marca: marca,
      codigoBarras: codigoBarras,
      precio: precio ?? this.precio,
      disponible: disponible ?? this.disponible,
      stock: stock ?? this.stock,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
