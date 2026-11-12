import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/notificaciones/presentation/widgets/aviso_notificaciones.dart';

import '../support/fakes.dart';

const _aprobado = Notificacion(
  id: '1',
  titulo: 'Tu comercio fue aprobado',
  mensaje: 'Minimercado La Esquina ya puede publicar su catálogo.',
);
const _rechazado = Notificacion(
  id: '2',
  titulo: 'Tu registro de repartidor no fue aprobado',
  mensaje: 'Motivo: La foto del documento no se ve.',
);

Future<TestEnv> _pumpAviso(
  WidgetTester tester,
  List<Notificacion> notificaciones,
) async {
  final env = TestEnv()..iniciarSesionCon({UserRole.comercio});
  env.notificaciones.noLeidasList.addAll(notificaciones);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => env.notificacionesBloc()..add(NotificacionesStarted()),
        child: const AvisoNotificaciones(
          child: Scaffold(body: Text('HOME')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

void main() {
  group('El solicitante recibe la decisión', () {
    testWidgets('al entrar ve la notificación de la decisión', (tester) async {
      await _pumpAviso(tester, [_aprobado]);

      expect(find.text('Tu comercio fue aprobado'), findsOneWidget);
      expect(find.text(_aprobado.mensaje), findsOneWidget);
    });

    testWidgets('el rechazo incluye el motivo', (tester) async {
      await _pumpAviso(tester, [_rechazado]);

      expect(
          find.text('Motivo: La foto del documento no se ve.'), findsOneWidget);
    });

    testWidgets('varias notificaciones se muestran juntas', (tester) async {
      await _pumpAviso(tester, [_aprobado, _rechazado]);

      expect(find.text('Tienes 2 notificaciones'), findsOneWidget);
      expect(find.text(_aprobado.titulo), findsOneWidget);
      expect(find.text(_rechazado.titulo), findsOneWidget);
    });

    testWidgets('al cerrarla se marca como leída y no se repite',
        (tester) async {
      final env = await _pumpAviso(tester, [_aprobado]);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      expect(env.notificaciones.marcadas, ['1']);
      expect(env.notificaciones.noLeidasList, isEmpty);
    });

    testWidgets('sin notificaciones no muestra nada', (tester) async {
      await _pumpAviso(tester, const []);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('NotificacionesBloc', () {
    test('si no se pueden leer no interrumpe a la persona', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.repartidor});
      env.notificaciones.getError = const AuthFailure('sin conexión');
      final bloc = env.notificacionesBloc();

      bloc.add(NotificacionesStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.porMostrar, isEmpty);
      await bloc.close();
    });

    test('sin sesión no busca notificaciones', () async {
      final env = TestEnv();
      env.notificaciones.noLeidasList.add(_aprobado);
      final bloc = env.notificacionesBloc();

      bloc.add(NotificacionesStarted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.porMostrar, isEmpty);
      await bloc.close();
    });
  });
}
