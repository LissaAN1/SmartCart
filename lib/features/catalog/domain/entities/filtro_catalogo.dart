/// Búsqueda y categoría elegidas en el catálogo del comercio (HU-11).
class FiltroCatalogo {
  /// Texto del buscador: se busca en el nombre y la marca.
  final String texto;

  /// Categoría del chip elegido; `null` es "Todos".
  final String? idCategoria;

  const FiltroCatalogo({this.texto = '', this.idCategoria});

  bool get vacio => texto.trim().isEmpty && idCategoria == null;
}
