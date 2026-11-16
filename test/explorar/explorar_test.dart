import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv()..iniciarSesionComoCliente());

  group('ExplorarProductosUseCase', () {
    test('sin texto devuelve todos los productos', () async {
      final pagina = await env.explorarProductos('', const PageRequest());

      expect(pagina.items.map((p) => p.id), ['p1', 'p2', 'p3']);
      expect(pagina.hasMore, isFalse);
    });

    test('filtra por nombre sin distinguir mayúsculas', () async {
      final pagina = await env.explorarProductos('LECHE', const PageRequest());

      expect(pagina.items.map((p) => p.id), ['p2']);
    });

    test('filtra por marca', () async {
      final pagina = await env.explorarProductos('diana', const PageRequest());

      expect(pagina.items.map((p) => p.id), ['p1']);
    });

    test('ignora los espacios de los bordes', () async {
      await env.explorarProductos('  leche  ', const PageRequest());

      expect(env.cliente.explorar.consultas.last, 'leche');
    });

    test('sin coincidencias devuelve una lista vacía', () async {
      final pagina = await env.explorarProductos('zzz', const PageRequest());

      expect(pagina.items, isEmpty);
    });

    test('se carga por páginas e indica si hay más', () async {
      final primera =
          await env.explorarProductos('', const PageRequest(pageSize: 2));
      expect(primera.items.length, 2);
      expect(primera.hasMore, isTrue);

      final ultima = await env
          .explorarProductos('', const PageRequest(page: 1, pageSize: 2));
      expect(ultima.items.length, 1);
      expect(ultima.hasMore, isFalse);
    });

    test('trae el nombre del comercio de cada producto', () async {
      final pagina = await env.explorarProductos('café', const PageRequest());

      expect(pagina.items.single.comercio, 'Tienda Doña Rosa');
    });

    test('quien no es cliente no puede explorar', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(
        env.explorarProductos('', const PageRequest()),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('ExplorarComerciosUseCase', () {
    test('lista los comercios', () async {
      final pagina = await env.explorarComercios('', const PageRequest());

      expect(pagina.items.map((c) => c.id), ['c1', 'c2']);
    });

    test('filtra por nombre o por ciudad', () async {
      final porNombre = await env.explorarComercios('rosa', const PageRequest());
      expect(porNombre.items.map((c) => c.id), ['c2']);

      final porCiudad = await env.explorarComercios('cali', const PageRequest());
      expect(porCiudad.items.map((c) => c.id), ['c1']);
    });

    test('quien no es cliente no puede explorar', () async {
      env.iniciarSesionCon({UserRole.colaborador});

      await expectLater(
        env.explorarComercios('', const PageRequest()),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('Listas paginadas de la exploración', () {
    test('la lista de productos carga y muestra el mensaje de espera si el '
        'cliente no es cliente', () async {
      env.iniciarSesionCon({UserRole.comercio});
      final bloc = env.explorarProductosBloc('');

      bloc.add(PaginatedStarted());
      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.failure);

      expect(state.errorMessage, contains('como cliente'));
      await bloc.close();
    });

    test('la lista de productos carga la primera página', () async {
      final bloc = env.explorarProductosBloc('arroz');

      bloc.add(PaginatedStarted());
      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.success);

      expect(state.items.single.id, 'p1');
      await bloc.close();
    });

    test('la lista de favoritos de productos trae lo marcado', () async {
      env.cliente.favoritos.precargar(productos: ['p3', 'p1']);
      final bloc = env.favoritosProductosBloc();

      bloc.add(PaginatedStarted());
      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.success);

      expect(state.items.map((p) => p.id), ['p3', 'p1']);
      await bloc.close();
    });

    test('la lista de favoritos de comercios trae lo marcado', () async {
      env.cliente.favoritos.precargar(comercios: ['c2']);
      final bloc = env.favoritosComerciosBloc();

      bloc.add(PaginatedStarted());
      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.success);

      expect(state.items.single.id, 'c2');
      await bloc.close();
    });
  });
}
