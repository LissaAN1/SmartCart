/// Pedido de una página de resultados. Las páginas empiezan en 0.
class PageRequest {
  static const defaultPageSize = 20;

  final int page;
  final int pageSize;

  const PageRequest({this.page = 0, this.pageSize = defaultPageSize});

  /// Índice de la primera fila de la página.
  int get from => page * pageSize;

  /// Último índice (inclusive) para `query.range(from, to)` de Supabase. Pide
  /// una fila de más que [pageSize]: si llega, se sabe que hay otra página.
  int get to => from + pageSize;

  PageRequest get next => PageRequest(page: page + 1, pageSize: pageSize);
}

/// Una página ya recortada y si existen más después de ella.
class PagedResult<T> {
  final List<T> items;
  final bool hasMore;

  const PagedResult({required this.items, required this.hasMore});

  /// Arma el resultado con las filas que devolvió `range(from, to)`: las que
  /// sobran sobre [PageRequest.pageSize] solo indican que hay más páginas.
  factory PagedResult.fromRows(List<T> rows, PageRequest request) {
    final hasMore = rows.length > request.pageSize;
    return PagedResult(
      items: hasMore ? rows.sublist(0, request.pageSize) : rows,
      hasMore: hasMore,
    );
  }
}
