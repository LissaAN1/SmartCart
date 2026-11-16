import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

Future<FavoritosState> _hasta(
  FavoritosBloc bloc,
  bool Function(FavoritosState) cond,
) =>
    bloc.stream.firstWhere(cond);

Future<FavoritosState> _cargado(FavoritosBloc bloc) async {
  bloc.add(FavoritosStarted());
  return _hasta(bloc, (s) => s.status == FavoritosStatus.listo);
}

void main() {
  group('FavoritosIds', () {
    test('contiene distingue productos de comercios', () {
      const ids = FavoritosIds(productos: {'a'}, comercios: {'b'});

      expect(ids.contiene(TipoFavorito.producto, 'a'), isTrue);
      expect(ids.contiene(TipoFavorito.producto, 'b'), isFalse);
      expect(ids.contiene(TipoFavorito.comercio, 'b'), isTrue);
      expect(ids.contiene(TipoFavorito.comercio, 'a'), isFalse);
    });

    test('con agrega o quita sin tocar el original ni el otro tipo', () {
      const ids = FavoritosIds(productos: {'a'}, comercios: {'b'});

      final agregado = ids.con(TipoFavorito.producto, 'c', favorito: true);
      expect(agregado.productos, {'a', 'c'});
      expect(agregado.comercios, {'b'});

      final quitado = agregado.con(TipoFavorito.producto, 'a', favorito: false);
      expect(quitado.productos, {'c'});
      expect(ids.productos, {'a'});
    });

    test('quitar algo que no está no falla', () {
      const ids = FavoritosIds();

      expect(ids.con(TipoFavorito.comercio, 'x', favorito: false).comercios, isEmpty);
    });
  });

  group('Casos de uso · escenario 3: favoritos', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoCliente());

    test('un producto queda guardado en los favoritos', () async {
      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true);

      expect(env.cliente.favoritos.idsDeProductos, ['p1']);
      expect((await env.getFavoritosIds()).productos, {'p1'});
    });

    test('un comercio queda guardado en los favoritos', () async {
      await env.cambiarFavorito(TipoFavorito.comercio, 'c1', favorito: true);

      expect(env.cliente.favoritos.idsDeComercios, ['c1']);
      expect((await env.getFavoritosIds()).comercios, {'c1'});
    });

    test('productos y comercios son independientes', () async {
      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true);

      final ids = await env.getFavoritosIds();
      expect(ids.comercios, isEmpty);
    });

    test('desmarcarlo lo quita', () async {
      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true);

      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: false);

      expect(env.cliente.favoritos.idsDeProductos, isEmpty);
    });

    test('marcar dos veces el mismo no lo duplica', () async {
      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true);
      await env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true);

      expect(env.cliente.favoritos.idsDeProductos, ['p1']);
    });

    test('un id vacío se rechaza sin tocar nada', () async {
      await expectLater(
        env.cambiarFavorito(TipoFavorito.producto, ' ', favorito: true),
        _falla('Elige qué'),
      );

      expect(env.cliente.favoritos.cambiarCalls, 0);
    });

    test('quien no es cliente no puede marcar favoritos', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(
        env.cambiarFavorito(TipoFavorito.producto, 'p1', favorito: true),
        _falla('como cliente'),
      );
    });

    test('las listas salen del más reciente al más antiguo y por páginas',
        () async {
      for (final id in ['p1', 'p2', 'p3']) {
        await env.cambiarFavorito(TipoFavorito.producto, id, favorito: true);
      }

      final primera =
          await env.getFavoritosProductos(const PageRequest(pageSize: 2));
      expect(primera.items.map((p) => p.id), ['p3', 'p2']);
      expect(primera.hasMore, isTrue);

      final ultima = await env
          .getFavoritosProductos(const PageRequest(page: 1, pageSize: 2));
      expect(ultima.items.map((p) => p.id), ['p1']);
      expect(ultima.hasMore, isFalse);
    });

    test('la lista de comercios trae los datos del comercio', () async {
      await env.cambiarFavorito(TipoFavorito.comercio, 'c2', favorito: true);

      final pagina = await env.getFavoritosComercios(const PageRequest());

      expect(pagina.items.single.nombre, 'Tienda Doña Rosa');
      expect(pagina.items.single.ciudad, 'Bogotá');
    });

    test('las listas y los ids exigen ser cliente', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(env.getFavoritosIds(), _falla('como cliente'));
      await expectLater(
          env.getFavoritosProductos(const PageRequest()), _falla('como cliente'));
      await expectLater(
          env.getFavoritosComercios(const PageRequest()), _falla('como cliente'));
    });
  });

  group('FavoritosBloc', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoCliente());

    test('lee los favoritos guardados al iniciar', () async {
      env.cliente.favoritos.precargar(productos: ['p1'], comercios: ['c2']);
      final bloc = env.favoritosBloc();

      final state = await _cargado(bloc);

      expect(state.ids.productos, {'p1'});
      expect(state.ids.comercios, {'c2'});
      await bloc.close();
    });

    test('si no se pueden leer deja el error y se puede reintentar', () async {
      env.cliente.favoritos.idsError = const AuthFailure('No pudimos conectarnos.');
      final bloc = env.favoritosBloc();

      bloc.add(FavoritosStarted());
      final fallo =
          await _hasta(bloc, (s) => s.status == FavoritosStatus.falloCarga);
      expect(fallo.errorMessage, 'No pudimos conectarnos.');

      env.cliente.favoritos.idsError = null;
      bloc.add(FavoritosStarted());
      await _hasta(bloc, (s) => s.status == FavoritosStatus.listo);
      await bloc.close();
    });

    test('presionar el corazón de un producto lo guarda', () async {
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.producto, 'p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.ids.productos, {'p1'});
      expect(state.aviso!.texto, 'Guardado en tus favoritos');
      expect(env.cliente.favoritos.idsDeProductos, ['p1']);
      await bloc.close();
    });

    test('presionar el corazón de un comercio lo guarda', () async {
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.comercio, 'c1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.ids.comercios, {'c1'});
      expect(env.cliente.favoritos.idsDeComercios, ['c1']);
      await bloc.close();
    });

    test('presionarlo otra vez lo quita', () async {
      env.cliente.favoritos.precargar(productos: ['p1']);
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.producto, 'p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.ids.productos, isEmpty);
      expect(state.aviso!.texto, 'Quitado de tus favoritos');
      expect(env.cliente.favoritos.idsDeProductos, isEmpty);
      await bloc.close();
    });

    test('el corazón cambia antes de que responda la red', () async {
      env.cliente.favoritos.gateCambiar = Completer<void>();
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.producto, 'p1'));
      await _hasta(bloc, (s) => s.ids.productos.contains('p1'));

      expect(env.cliente.favoritos.idsDeProductos, isEmpty);
      env.cliente.favoritos.gateCambiar!.complete();
      await _hasta(bloc, (s) => s.aviso != null);
      expect(env.cliente.favoritos.idsDeProductos, ['p1']);
      await bloc.close();
    });

    test('si no se pudo guardar, el corazón vuelve a como estaba y se avisa',
        () async {
      env.cliente.favoritos.cambiarError =
          const AuthFailure('No tienes permiso para realizar esta acción.');
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.producto, 'p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.ids.productos, isEmpty);
      expect(state.aviso!.esError, isTrue);
      expect(state.aviso!.texto, contains('No tienes permiso'));
      await bloc.close();
    });

    test('si no se pudo quitar, el favorito se conserva', () async {
      env.cliente.favoritos.precargar(comercios: ['c1']);
      env.cliente.favoritos.cambiarError = StateError('boom');
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc.add(FavoritoAlternado(TipoFavorito.comercio, 'c1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.ids.comercios, {'c1'});
      expect(state.aviso!.texto, contains('error inesperado'));
      await bloc.close();
    });

    test('un segundo toque mientras se guarda el primero se ignora', () async {
      env.cliente.favoritos.gateCambiar = Completer<void>();
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc
        ..add(FavoritoAlternado(TipoFavorito.producto, 'p1'))
        ..add(FavoritoAlternado(TipoFavorito.producto, 'p1'));
      await _hasta(bloc, (s) => s.ids.productos.contains('p1'));
      env.cliente.favoritos.gateCambiar!.complete();
      await _hasta(bloc, (s) => s.aviso != null);

      expect(env.cliente.favoritos.cambiarCalls, 1);
      expect(bloc.state.ids.productos, {'p1'});
      await bloc.close();
    });

    test('dos corazones distintos a la vez se guardan los dos', () async {
      final bloc = env.favoritosBloc();
      await _cargado(bloc);

      bloc
        ..add(FavoritoAlternado(TipoFavorito.producto, 'p1'))
        ..add(FavoritoAlternado(TipoFavorito.producto, 'p2'));
      await _hasta(bloc, (s) => s.ids.productos.length == 2);
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.favoritos.cambiarCalls, 2);
      await bloc.close();
    });
  });
}
