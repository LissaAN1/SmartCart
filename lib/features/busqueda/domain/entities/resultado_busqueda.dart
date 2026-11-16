/// Un producto en los resultados de la búsqueda del cliente (HU-12). Agrupa
/// el mismo producto de varios comercios: por código de barras o, si no
/// tiene, por nombre y marca.
class ResultadoBusqueda {
  /// Identifica el grupo; se usa para abrir el detalle.
  final String clave;
  final String nombre;
  final String? marca;
  final String? codigoBarras;
  final String categoria;
  final String? fotoUrl;

  /// Rango del precio vigente (con la promoción si está vigente) entre los
  /// establecimientos donde está disponible. `null` si está agotado en todos.
  final int? precioMin;
  final int? precioMax;

  /// En cuántos establecimientos está disponible.
  final int establecimientos;

  const ResultadoBusqueda({
    required this.clave,
    required this.nombre,
    required this.categoria,
    this.marca,
    this.codigoBarras,
    this.fotoUrl,
    this.precioMin,
    this.precioMax,
    this.establecimientos = 0,
  });

  /// Agotado en todos los establecimientos que lo venden.
  bool get agotado => precioMin == null;

  /// Un solo precio (o un solo establecimiento): no hay rango que mostrar.
  bool get precioUnico => precioMin != null && precioMin == precioMax;
}
