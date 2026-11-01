import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';

/// Fuente falsa de 45 elementos que responde como `range(from, to)`.
Future<PagedResult<int>> _fuente(PageRequest request) async {
  final todos = List<int>.generate(45, (i) => i);
  final filas =
      todos.skip(request.from).take(request.pageSize + 1).toList();
  return PagedResult.fromRows(filas, request);
}

Future<PaginatedState<int>> _esperarExito(PaginatedBloc<int> bloc) =>
    bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);

void main() {
  test('PageRequest calcula el rango de cada página', () {
    const request = PageRequest(page: 2, pageSize: 10);
    expect(request.from, 20);
    expect(request.to, 30);
    expect(request.next.page, 3);
  });

  test('fromRows recorta la fila de más e indica que hay otra página', () {
    const request = PageRequest(pageSize: 3);
    final lleno = PagedResult.fromRows([1, 2, 3, 4], request);
    expect(lleno.items, [1, 2, 3]);
    expect(lleno.hasMore, isTrue);

    final ultimo = PagedResult.fromRows([1, 2], request);
    expect(ultimo.items, [1, 2]);
    expect(ultimo.hasMore, isFalse);
  });

  test('carga la primera página y luego agrega las siguientes', () async {
    final bloc = PaginatedBloc<int>(fetchPage: _fuente, pageSize: 20);

    bloc.add(PaginatedStarted());
    var state = await _esperarExito(bloc);
    expect(state.items.length, 20);
    expect(state.hasMore, isTrue);

    bloc.add(NextPageRequested());
    state = await bloc.stream.firstWhere((s) => s.items.length == 40);
    expect(state.hasMore, isTrue);

    bloc.add(NextPageRequested());
    state = await bloc.stream.firstWhere((s) => s.items.length == 45);
    expect(state.hasMore, isFalse);
    expect(state.items.last, 44);

    await bloc.close();
  });

  test('sin más páginas no vuelve a pedir datos', () async {
    var pedidos = 0;
    final bloc = PaginatedBloc<int>(
      fetchPage: (request) async {
        pedidos++;
        return PagedResult.fromRows([1, 2], request);
      },
    );

    bloc.add(PaginatedStarted());
    await _esperarExito(bloc);
    bloc.add(NextPageRequested());
    await Future<void>.delayed(Duration.zero);

    expect(pedidos, 1);
    await bloc.close();
  });

  test('una lista vacía queda marcada como vacía', () async {
    final bloc = PaginatedBloc<int>(
      fetchPage: (request) async => const PagedResult(items: [], hasMore: false),
    );

    bloc.add(PaginatedStarted());
    final state = await _esperarExito(bloc);

    expect(state.isEmpty, isTrue);
    await bloc.close();
  });

  test('si falla la primera carga muestra el error y permite reintentar',
      () async {
    var falla = true;
    final bloc = PaginatedBloc<int>(
      fetchPage: (request) async {
        if (falla) throw Exception('sin red');
        return _fuente(request);
      },
    );

    bloc.add(PaginatedStarted());
    var state =
        await bloc.stream.firstWhere((s) => s.status == PaginatedStatus.failure);
    expect(state.errorMessage, isNotNull);

    falla = false;
    bloc.add(PaginatedStarted());
    state = await _esperarExito(bloc);
    expect(state.items, isNotEmpty);
    await bloc.close();
  });

  test('si falla una página adicional conserva la lista y el error', () async {
    var llamadas = 0;
    final bloc = PaginatedBloc<int>(
      fetchPage: (request) async {
        llamadas++;
        if (llamadas == 2) throw Exception('sin red');
        return _fuente(request);
      },
    );

    bloc.add(PaginatedStarted());
    await _esperarExito(bloc);
    bloc.add(NextPageRequested());
    final state = await bloc.stream
        .firstWhere((s) => !s.loadingMore && s.errorMessage != null);

    expect(state.items.length, 20);
    expect(state.status, PaginatedStatus.success);
    await bloc.close();
  });
}
