import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';

Future<CarritoState> _hasta(CarritoBloc bloc, bool Function(CarritoState) cond) =>
    bloc.stream.firstWhere(cond);

Future<CarritoState> _cargado(CarritoBloc bloc) async {
  bloc.add(CarritoStarted());
  return _hasta(bloc, (s) => s.status == CarritoStatus.listo);
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv()..iniciarSesionComoCliente());

  group('CarritoBloc · cargar y recuperar', () {
    test('un carrito nuevo queda listo y vacío', () async {
      final bloc = env.carritoBloc();

      final state = await _cargado(bloc);

      expect(state.vacio, isTrue);
      expect(state.productos, 0);
      await bloc.close();
    });

    test('el carrito guardado se recupera al volver a abrir la app', () async {
      // Primera "sesión": el cliente agrega dos productos.
      final primero = env.carritoBloc();
      await _cargado(primero);
      primero.add(CarritoProductoAgregado('p1'));
      await _hasta(primero, (s) => s.productos == 1);
      primero.add(CarritoProductoAgregado('p1'));
      await _hasta(primero, (s) => s.unidades == 2);
      primero.add(CarritoProductoAgregado('p2'));
      await _hasta(primero, (s) => s.productos == 2);
      await primero.close();

      // Segunda "sesión": un Bloc nuevo, como al reabrir la app, lee la base.
      final segundo = env.carritoBloc();
      final state = await _cargado(segundo);

      expect(state.productos, 2);
      expect(state.unidades, 3);
      expect(state.items.firstWhere((i) => i.idProducto == 'p1').cantidad, 2);
      await segundo.close();
    });

    test('muestra la cantidad de productos', () async {
      env.cliente.carrito
        ..lineas.add(env.cliente.carrito.disponibles['p1']!.toLinea(3))
        ..lineas.add(env.cliente.carrito.disponibles['p2']!.toLinea(1));
      final bloc = env.carritoBloc();

      final state = await _cargado(bloc);

      expect(state.productos, 2);
      expect(state.unidades, 4);
      await bloc.close();
    });

    test('si no se puede leer deja el error y se puede reintentar', () async {
      env.cliente.carrito.obtenerError =
          const AuthFailure('No pudimos conectarnos.');
      final bloc = env.carritoBloc();

      bloc.add(CarritoStarted());
      final fallo =
          await _hasta(bloc, (s) => s.status == CarritoStatus.falloCarga);
      expect(fallo.errorMessage, 'No pudimos conectarnos.');

      env.cliente.carrito.obtenerError = null;
      bloc.add(CarritoStarted());
      final listo = await _hasta(bloc, (s) => s.status == CarritoStatus.listo);
      expect(listo.errorMessage, isNull);
      await bloc.close();
    });

    test('quien no es cliente recibe el aviso de que debe serlo', () async {
      env.iniciarSesionCon({UserRole.comercio});
      final bloc = env.carritoBloc();

      bloc.add(CarritoStarted());
      final state =
          await _hasta(bloc, (s) => s.status == CarritoStatus.falloCarga);

      expect(state.errorMessage, contains('como cliente'));
      await bloc.close();
    });
  });

  group('CarritoBloc · escenario 1: agregar un producto', () {
    test('queda con cantidad 1 y avisa', () async {
      final bloc = env.carritoBloc();
      await _cargado(bloc);

      bloc.add(CarritoProductoAgregado('p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.items.single.idProducto, 'p1');
      expect(state.items.single.cantidad, 1);
      expect(state.aviso!.texto, '"Arroz blanco 500 g" se agregó al carrito');
      expect(state.aviso!.esError, isFalse);
      await bloc.close();
    });

    test('si ya estaba suma 1 y lo dice', () async {
      final bloc = env.carritoBloc();
      await _cargado(bloc);
      bloc.add(CarritoProductoAgregado('p1'));
      await _hasta(bloc, (s) => s.aviso != null);

      bloc.add(CarritoProductoAgregado('p1'));
      final state = await _hasta(bloc, (s) => s.items.single.cantidad == 2);

      expect(state.productos, 1);
      expect(state.aviso!.texto, contains('ahora tienes 2'));
      await bloc.close();
    });

    test('cada aviso tiene un id distinto, aunque el texto se repita', () async {
      final bloc = env.carritoBloc();
      await _cargado(bloc);

      bloc.add(CarritoProductoAgregado('p-borrado'));
      final primero = await _hasta(bloc, (s) => s.aviso != null);
      bloc.add(CarritoProductoAgregado('p-borrado'));
      final segundo = await _hasta(
          bloc, (s) => s.aviso != null && s.aviso!.id != primero.aviso!.id);

      expect(segundo.aviso!.texto, primero.aviso!.texto);
      await bloc.close();
    });

    test('si no se puede agregar avisa el motivo y deja el carrito como estaba',
        () async {
      final bloc = env.carritoBloc();
      await _cargado(bloc);

      bloc.add(CarritoProductoAgregado('p-borrado'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.aviso!.esError, isTrue);
      expect(state.aviso!.texto, contains('ya no está disponible'));
      expect(state.vacio, isTrue);
      await bloc.close();
    });

    test('un error inesperado se avisa con un mensaje genérico', () async {
      env.cliente.carrito.agregarError = StateError('boom');
      final bloc = env.carritoBloc();
      await _cargado(bloc);

      bloc.add(CarritoProductoAgregado('p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.aviso!.texto, contains('error inesperado'));
      await bloc.close();
    });
  });

  group('CarritoBloc · escenario 2: cambiar la cantidad', () {
    late CarritoBloc bloc;

    setUp(() async {
      env.cliente.carrito.lineas
          .add(env.cliente.carrito.disponibles['p1']!.toLinea(2));
      bloc = env.carritoBloc();
      await _cargado(bloc);
    });

    tearDown(() => bloc.close());

    test('el carrito se actualiza al instante y se guarda', () async {
      bloc.add(CarritoCantidadCambiada('p1', 5));
      final state = await _hasta(bloc, (s) => s.items.single.cantidad == 5);
      await Future<void>.delayed(Duration.zero);

      expect(state.unidades, 5);
      expect(env.cliente.carrito.lineas.single.cantidad, 5);
    });

    test('se puede bajar la cantidad', () async {
      bloc.add(CarritoCantidadCambiada('p1', 1));
      await _hasta(bloc, (s) => s.items.single.cantidad == 1);
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.carrito.lineas.single.cantidad, 1);
    });

    test('la pantalla cambia antes de que responda la red', () async {
      env.cliente.carrito.gateCambiar = Completer<void>();

      bloc.add(CarritoCantidadCambiada('p1', 4));
      await _hasta(bloc, (s) => s.items.single.cantidad == 4);

      // La red todavía no respondió y la base sigue como estaba.
      expect(env.cliente.carrito.lineas.single.cantidad, 2);
      env.cliente.carrito.gateCambiar!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(env.cliente.carrito.lineas.single.cantidad, 4);
    });

    test('dos toques seguidos suman las dos veces', () async {
      bloc.add(CarritoCantidadCambiada('p1', 3));
      bloc.add(CarritoCantidadCambiada('p1', 4));
      await _hasta(bloc, (s) => s.items.single.cantidad == 4);
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.carrito.lineas.single.cantidad, 4);
    });

    test('la misma cantidad no manda nada', () async {
      bloc.add(CarritoCantidadCambiada('p1', 2));
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.carrito.cambiarCalls, 0);
    });

    test('un producto que no está en el carrito se ignora', () async {
      bloc.add(CarritoCantidadCambiada('p2', 3));
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.carrito.cambiarCalls, 0);
    });

    test('una cantidad fuera de rango no se muestra y se avisa', () async {
      bloc.add(CarritoCantidadCambiada('p1', 100));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.aviso!.esError, isTrue);
      expect(state.aviso!.texto, contains('99'));
      expect(state.items.single.cantidad, 2);
      expect(env.cliente.carrito.cambiarCalls, 0);
    });

    test('bajar de 1 avisa que se use "Quitar" y no borra nada', () async {
      bloc.add(CarritoCantidadCambiada('p1', 0));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.aviso!.texto, contains('Quitar'));
      expect(state.items.single.cantidad, 2);
    });

    test('si no se pudo guardar vuelve a lo que dice la base y avisa', () async {
      env.cliente.carrito.cambiarError =
          const AuthFailure('No pudimos guardar o leer tus datos.');

      bloc.add(CarritoCantidadCambiada('p1', 7));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.items.single.cantidad, 2);
      expect(state.aviso!.esError, isTrue);
      expect(state.aviso!.texto, contains('No pudimos guardar'));
    });

    test('si tampoco se puede releer, conserva lo que había antes', () async {
      env.cliente.carrito.cambiarError = StateError('boom');
      env.cliente.carrito.obtenerError = StateError('boom');

      bloc.add(CarritoCantidadCambiada('p1', 7));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.items.single.cantidad, 2);
    });
  });

  group('CarritoBloc · quitar', () {
    late CarritoBloc bloc;

    setUp(() async {
      env.cliente.carrito.lineas
        ..add(env.cliente.carrito.disponibles['p1']!.toLinea(2))
        ..add(env.cliente.carrito.disponibles['p2']!.toLinea(1));
      bloc = env.carritoBloc();
      await _cargado(bloc);
    });

    tearDown(() => bloc.close());

    test('el producto desaparece y se quita de la base', () async {
      bloc.add(CarritoProductoQuitado('p1'));
      final state = await _hasta(bloc, (s) => s.productos == 1);
      await Future<void>.delayed(Duration.zero);

      expect(state.items.single.idProducto, 'p2');
      expect(env.cliente.carrito.lineas.map((l) => l.idProducto), ['p2']);
    });

    test('quitar el último deja el carrito vacío', () async {
      bloc.add(CarritoProductoQuitado('p1'));
      bloc.add(CarritoProductoQuitado('p2'));
      final state = await _hasta(bloc, (s) => s.vacio);

      expect(state.productos, 0);
      expect(state.unidades, 0);
    });

    test('quitar algo que no está se ignora', () async {
      bloc.add(CarritoProductoQuitado('p3'));
      await Future<void>.delayed(Duration.zero);

      expect(env.cliente.carrito.quitarCalls, 0);
    });

    test('si no se pudo guardar, el producto vuelve y se avisa', () async {
      env.cliente.carrito.quitarError =
          const AuthFailure('No pudimos guardar o leer tus datos.');

      bloc.add(CarritoProductoQuitado('p1'));
      final state = await _hasta(bloc, (s) => s.aviso != null);

      expect(state.productos, 2);
      expect(state.aviso!.esError, isTrue);
    });
  });
}

