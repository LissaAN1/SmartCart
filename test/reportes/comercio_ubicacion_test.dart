import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';
import 'package:smartcart/features/comercio/presentation/pages/comercio_home_screen.dart';
import 'package:smartcart/features/comercio/presentation/pages/comercio_registro_page.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// HU-14 toca el registro del comercio (HU-07): ahora guarda coordenadas, que
/// los colaboradores usan para comprobar que están en el lugar.
void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  });

  group('FijarUbicacionComercioUseCase', () {
    test('guarda la ubicación actual y devuelve el comercio actualizado',
        () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);

      final comercio = await env.fijarUbicacionComercio();

      expect(env.comercios.ubicacionesFijadas.single, ubicacionColaborador);
      expect(comercio.tieneUbicacion, isTrue);
      expect(comercio.latitud, ubicacionColaborador.latitud);
      expect(comercio.longitud, ubicacionColaborador.longitud);
    });

    test('también funciona con el comercio ya aprobado', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);

      expect((await env.fijarUbicacionComercio()).estado, ApprovalStatus.aprobado);
    });

    test('sin comercio registrado no pide el GPS', () async {
      env.comercios.stored = null;

      await expectLater(
        env.fijarUbicacionComercio(),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('registra tu comercio'))),
      );

      expect(env.servicioUbicacion.llamadas, 0);
    });

    test('sin sesión pide iniciarla', () async {
      env.auth.current = null;

      await expectLater(env.fijarUbicacionComercio(), throwsA(isA<AuthFailure>()));
    });

    test('si el GPS falla, el comercio no cambia', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      env.servicioUbicacion.error = const AuthFailure('GPS apagado.');

      await expectLater(env.fijarUbicacionComercio(), throwsA(isA<AuthFailure>()));

      expect(env.comercios.ubicacionesFijadas, isEmpty);
      expect(env.comercios.stored!.tieneUbicacion, isFalse);
    });
  });

  group('Comercio.ubicacion', () {
    test('sin coordenadas no tiene ubicación', () {
      final c = comercioConEstado(ApprovalStatus.aprobado);

      expect(c.tieneUbicacion, isFalse);
      expect(c.ubicacion, isNull);
    });
  });

  group('ComercioBloc · ubicación', () {
    test('con el comercio registrado la guarda en él', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc.add(ComercioUbicacionSolicitada());
      final state = await bloc.stream.firstWhere(
          (s) => s.status == ComercioStatus.ready && s.comercio!.tieneUbicacion);

      expect(state.comercio!.latitud, ubicacionColaborador.latitud);
      await bloc.close();
    });

    test('mientras toma la ubicación avisa con el estado locating', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      env.servicioUbicacion.gate = Completer<void>();
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc.add(ComercioUbicacionSolicitada());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.locating);
      env.servicioUbicacion.gate!.complete();
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      await bloc.close();
    });

    test('en el registro (sin comercio) solo la conserva para enviarla',
        () async {
      env.comercios.stored = null;
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc.add(ComercioUbicacionSolicitada());
      final state = await bloc.stream.firstWhere((s) => s.ubicacion != null);

      expect(state.ubicacion, ubicacionColaborador);
      expect(state.comercio, isNull);
      expect(env.comercios.ubicacionesFijadas, isEmpty);
      await bloc.close();
    });

    test('si falla deja el motivo y conserva el comercio', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      env.servicioUbicacion.error = const AuthFailure('GPS apagado.');
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc.add(ComercioUbicacionSolicitada());
      final state = await bloc.stream
          .firstWhere((s) => s.status == ComercioStatus.locationFailed);

      expect(state.errorMessage, 'GPS apagado.');
      expect(state.comercio, isNotNull);
      await bloc.close();
    });

    test('un error inesperado se muestra con un mensaje genérico', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      env.servicioUbicacion.error = StateError('boom');
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc.add(ComercioUbicacionSolicitada());
      final state = await bloc.stream
          .firstWhere((s) => s.status == ComercioStatus.locationFailed);

      expect(state.errorMessage, contains('error inesperado'));
      await bloc.close();
    });

    test('un segundo toque mientras toma la ubicación no la repite', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
      env.servicioUbicacion.gate = Completer<void>();
      final bloc = env.comercioBloc();
      bloc.add(ComercioStarted());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      bloc
        ..add(ComercioUbicacionSolicitada())
        ..add(ComercioUbicacionSolicitada());
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.locating);
      env.servicioUbicacion.gate!.complete();
      await bloc.stream.firstWhere((s) => s.status == ComercioStatus.ready);

      expect(env.servicioUbicacion.llamadas, 1);
      await bloc.close();
    });

    test('registrar con ubicación la guarda en el comercio nuevo', () async {
      env.comercios.stored = null;
      final comercio = await env.registrarComercio(ComercioDatos(
        nombre: comercioDatosValidos.nombre,
        telefono: comercioDatosValidos.telefono,
        direccion: comercioDatosValidos.direccion,
        ciudad: comercioDatosValidos.ciudad,
        horaApertura: comercioDatosValidos.horaApertura,
        horaCierre: comercioDatosValidos.horaCierre,
        servicio: comercioDatosValidos.servicio,
        ubicacion: ubicacionColaborador,
      ));

      expect(comercio.tieneUbicacion, isTrue);
      expect(comercio.ubicacion, ubicacionColaborador);
    });

    test('registrar sin ubicación sigue funcionando (es opcional)', () async {
      env.comercios.stored = null;

      final comercio = await env.registrarComercio(comercioDatosValidos);

      expect(comercio.tieneUbicacion, isFalse);
    });
  });

  group('Pantallas', () {
    Future<void> pumpRegistro(WidgetTester tester) async {
      setScreenSize(tester, 420, 1100);
      env.comercios.stored = null;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ComercioBloc>(
            create: (_) => env.comercioBloc(),
            child: const ComercioRegistroPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el registro ofrece tomar la ubicación del local (opcional)',
        (tester) async {
      await pumpRegistro(tester);

      expect(find.text('Ubicación del establecimiento (opcional)'), findsOneWidget);

      final boton = find.text('Usar mi ubicación actual');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('Ubicación guardada · actualizar'), findsOneWidget);
      expect(env.servicioUbicacion.llamadas, 1);
    });

    testWidgets('si el GPS falla en el registro se muestra el motivo',
        (tester) async {
      env.servicioUbicacion.error =
          const AuthFailure('La ubicación del dispositivo está apagada.');
      await pumpRegistro(tester);

      final boton = find.text('Usar mi ubicación actual');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('La ubicación del dispositivo está apagada.'),
          findsOneWidget);
      expect(find.text('Usar mi ubicación actual'), findsOneWidget);
    });

    Future<void> pumpHome(
      WidgetTester tester, {
      required bool sinUbicacion,
      bool ubicando = false,
      String? error,
      VoidCallback? onFijar,
    }) async {
      setScreenSize(tester, 420, 1100);
      await tester.pumpWidget(
        MaterialApp(
          home: ComercioHomeScreen(
            nombreComercio: 'La Esquina',
            sinUbicacion: sinUbicacion,
            ubicando: ubicando,
            errorUbicacion: error,
            onFijarUbicacion: onFijar,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el Home avisa si el comercio no tiene ubicación y deja guardarla',
        (tester) async {
      var toques = 0;
      await pumpHome(tester, sinUbicacion: true, onFijar: () => toques++);

      expect(find.text('Falta la ubicación de tu comercio'), findsOneWidget);

      await tester.tap(find.text('Guardar ubicación'));
      await tester.pump();

      expect(toques, 1);
    });

    testWidgets('con ubicación guardada el aviso no aparece', (tester) async {
      await pumpHome(tester, sinUbicacion: false);

      expect(find.text('Falta la ubicación de tu comercio'), findsNothing);
    });

    testWidgets('el aviso muestra el error del GPS', (tester) async {
      await pumpHome(
        tester,
        sinUbicacion: true,
        error: 'Necesitamos el permiso de ubicación.',
      );

      expect(find.text('Necesitamos el permiso de ubicación.'), findsOneWidget);
    });
  });
}
