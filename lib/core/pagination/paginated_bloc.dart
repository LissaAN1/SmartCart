import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paged_result.dart';

/// Función que trae una página. Cada funcionalidad la entrega con su caso de
/// uso, por ejemplo `(page) => getOrders(page)`.
typedef PageFetcher<T> = Future<PagedResult<T>> Function(PageRequest request);

abstract class PaginatedEvent {}

/// Cargar la primera página. También sirve para recargar la lista.
class PaginatedStarted extends PaginatedEvent {}

/// Cargar la página siguiente (la lista llegó al final).
class NextPageRequested extends PaginatedEvent {}

enum PaginatedStatus { initial, loading, success, failure }

/// Estado único de una lista paginada.
class PaginatedState<T> {
  final PaginatedStatus status;
  final List<T> items;

  /// Si existen más páginas después de las ya cargadas.
  final bool hasMore;

  /// Se está trayendo una página adicional (la lista sigue visible).
  final bool loadingMore;

  /// Última página cargada (empieza en 0).
  final int page;

  /// Error de la primera carga ([PaginatedStatus.failure]) o de una página
  /// adicional (la lista se conserva y se puede reintentar).
  final String? errorMessage;

  PaginatedState({
    this.status = PaginatedStatus.initial,
    List<T>? items,
    this.hasMore = false,
    this.loadingMore = false,
    this.page = 0,
    this.errorMessage,
  }) : items = items ?? <T>[];

  /// La carga terminó bien pero no hay ningún elemento.
  bool get isEmpty => status == PaginatedStatus.success && items.isEmpty;

  PaginatedState<T> copyWith({
    PaginatedStatus? status,
    List<T>? items,
    bool? hasMore,
    bool? loadingMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Bloc genérico de listas paginadas: carga la primera página, agrega las
/// siguientes y no repite pedidos mientras hay uno en curso. No sabe de
/// dónde vienen los datos: solo conoce el [PageFetcher] que recibe.
class PaginatedBloc<T> extends Bloc<PaginatedEvent, PaginatedState<T>> {
  final PageFetcher<T> _fetchPage;
  final int pageSize;

  PaginatedBloc({
    required PageFetcher<T> fetchPage,
    this.pageSize = PageRequest.defaultPageSize,
  })  : _fetchPage = fetchPage,
        super(PaginatedState<T>()) {
    on<PaginatedStarted>(_onStarted);
    on<NextPageRequested>(_onNextPage);
  }

  Future<void> _onStarted(
    PaginatedStarted event,
    Emitter<PaginatedState<T>> emit,
  ) async {
    if (state.status == PaginatedStatus.loading) return;
    emit(PaginatedState<T>(status: PaginatedStatus.loading));
    try {
      final result = await _fetchPage(PageRequest(pageSize: pageSize));
      emit(
        PaginatedState<T>(
          status: PaginatedStatus.success,
          items: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (_) {
      emit(
        PaginatedState<T>(
          status: PaginatedStatus.failure,
          errorMessage: 'No pudimos cargar la información. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> _onNextPage(
    NextPageRequested event,
    Emitter<PaginatedState<T>> emit,
  ) async {
    // Sin primera carga exitosa, sin más páginas o con un pedido en curso no
    // hay nada que hacer: así un doble desplazamiento no repite la página.
    if (state.status != PaginatedStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final nextPage = state.page + 1;
      final result = await _fetchPage(
        PageRequest(page: nextPage, pageSize: pageSize),
      );
      emit(
        state.copyWith(
          items: [...state.items, ...result.items],
          hasMore: result.hasMore,
          loadingMore: false,
          page: nextPage,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingMore: false,
          errorMessage: 'No pudimos cargar más resultados.',
        ),
      );
    }
  }
}
