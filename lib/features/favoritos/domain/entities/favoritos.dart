/// Qué se puede marcar como favorito: productos y comercios (HU-17).
enum TipoFavorito { producto, comercio }

/// Los ids que el cliente marcó como favoritos. Con ellos cada corazón sabe
/// si está activo sin pedir la lista completa.
class FavoritosIds {
  final Set<String> productos;
  final Set<String> comercios;

  const FavoritosIds({
    this.productos = const {},
    this.comercios = const {},
  });

  bool contiene(TipoFavorito tipo, String id) => switch (tipo) {
        TipoFavorito.producto => productos.contains(id),
        TipoFavorito.comercio => comercios.contains(id),
      };

  /// Copia con [id] agregado ([favorito] `true`) o quitado.
  FavoritosIds con(TipoFavorito tipo, String id, {required bool favorito}) {
    Set<String> ajustar(Set<String> actual) =>
        favorito ? {...actual, id} : ({...actual}..remove(id));
    return switch (tipo) {
      TipoFavorito.producto =>
        FavoritosIds(productos: ajustar(productos), comercios: comercios),
      TipoFavorito.comercio =>
        FavoritosIds(productos: productos, comercios: ajustar(comercios)),
    };
  }
}
