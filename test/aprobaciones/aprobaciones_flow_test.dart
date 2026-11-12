import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/admin_solicitudes_page.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/solicitud_detalle_page.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

const _motivo = 'La dirección registrada no existe.';

/// Monta la lista de pendientes con las rutas que le da el router real.
Future<TestEnv> _pumpLista(
  WidgetTester tester, {
  Set<UserRole> roles = const {UserRole.administrador},
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv()..iniciarSesionCon(roles);
  env.solicitudes.pendientesPorTipo[TipoSolicitud.comercio]!
      .add(solicitudComercio());
  env.solicitudes.pendientesPorTipo[TipoSolicitud.repartidor]!
      .add(solicitudRepartidor());
  prepare?.call(env);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        if (settings.name == AppRoutes.adminSolicitudDetalle &&
            args is Solicitud) {
          return MaterialPageRoute<ApprovalStatus>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) => env.decisionBloc(args),
              child: const SolicitudDetallePage(),
            ),
          );
        }
        return null;
      },
      home: AdminSolicitudesPage(crearLista: env.listaBloc),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Finder _enDialogo(String texto) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

Future<void> _abrirDetalle(WidgetTester tester, String nombre) async {
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
}

Future<void> _tocarRechazarEnPantalla(WidgetTester tester) async {
  final boton = find.widgetWithText(OutlinedButton, 'Rechazar');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  group('Lista de solicitudes pendientes', () {
    testWidgets('muestra los comercios pendientes en la primera pestaña',
        (tester) async {
      await _pumpLista(tester);

      expect(find.text('Solicitudes pendientes'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Enviada el 02/11/2026'), findsOneWidget);
      expect(find.text('Luis Torres'), findsNothing);
    });

    testWidgets('la pestaña Repartidores muestra los repartidores pendientes',
        (tester) async {
      await _pumpLista(tester);

      await tester.tap(find.text('Repartidores'));
      await tester.pumpAndSettle();

      expect(find.text('Luis Torres'), findsOneWidget);
      expect(find.text('luis@correo.com'), findsOneWidget);
    });

    testWidgets('sin pendientes lo dice', (tester) async {
      await _pumpLista(
        tester,
        prepare: (env) =>
            env.solicitudes.pendientesPorTipo[TipoSolicitud.comercio]!.clear(),
      );

      expect(find.text('No hay comercios pendientes de aprobación'),
          findsOneWidget);
    });

    testWidgets('si la carga falla deja reintentar', (tester) async {
      final env = await _pumpLista(
        tester,
        prepare: (env) => env.solicitudes.listError =
            const AuthFailure('No pudimos guardar o leer tus datos.'),
      );
      expect(find.text('Reintentar'), findsOneWidget);

      env.solicitudes.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Minimercado La Esquina'), findsOneWidget);
    });
  });

  group('Detalle · escenario 1: aprobar', () {
    testWidgets('muestra los datos del comercio', (tester) async {
      await _pumpLista(tester);
      await _abrirDetalle(tester, 'Minimercado La Esquina');

      expect(find.text('Solicitud de comercio'), findsOneWidget);
      expect(find.text('Calle 10 # 5-20, Cali, San Fernando'), findsOneWidget);
      expect(find.text('07:00 - 20:00'), findsOneWidget);
      expect(find.text('Recogida y entrega'), findsOneWidget);
      expect(find.text('Pedro Pérez'), findsOneWidget);
      expect(find.text('Pendiente de aprobación'), findsOneWidget);
    });

    testWidgets('aprobar pide confirmación, decide y vuelve a la lista',
        (tester) async {
      final env = await _pumpLista(tester);
      await _abrirDetalle(tester, 'Minimercado La Esquina');

      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Aprobar Minimercado La Esquina?'), findsOneWidget);

      await tester.tap(_enDialogo('Aprobar'));
      await tester.pumpAndSettle();

      expect(env.solicitudes.decisiones.single.aprobar, isTrue);
      // De vuelta en la lista, ya sin la solicitud decidida.
      expect(find.text('Solicitudes pendientes'), findsOneWidget);
      expect(find.text('No hay comercios pendientes de aprobación'),
          findsOneWidget);
      expect(find.textContaining('fue aprobado'), findsOneWidget);
    });

    testWidgets('cancelar la confirmación no aprueba', (tester) async {
      final env = await _pumpLista(tester);
      await _abrirDetalle(tester, 'Minimercado La Esquina');

      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
      await tester.pumpAndSettle();
      await tester.tap(_enDialogo('Cancelar'));
      await tester.pumpAndSettle();

      expect(env.solicitudes.decisiones, isEmpty);
      expect(find.text('Solicitud de comercio'), findsOneWidget);
    });
  });

  group('Detalle · escenario 2: rechazar', () {
    testWidgets('rechazar sin motivo pide el motivo y no decide',
        (tester) async {
      final env = await _pumpLista(tester);
      await _abrirDetalle(tester, 'Minimercado La Esquina');
      await _tocarRechazarEnPantalla(tester);

      await tester.tap(_enDialogo('Rechazar'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe el motivo del rechazo.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(env.solicitudes.decisiones, isEmpty);
    });

    testWidgets('con motivo rechaza y vuelve a la lista', (tester) async {
      final env = await _pumpLista(tester);
      await tester.tap(find.text('Repartidores'));
      await tester.pumpAndSettle();
      await _abrirDetalle(tester, 'Luis Torres');
      await _tocarRechazarEnPantalla(tester);

      await tester.enterText(find.byKey(const Key('motivo-rechazo')), _motivo);
      await tester.tap(_enDialogo('Rechazar'));
      await tester.pumpAndSettle();

      final decision = env.solicitudes.decisiones.single;
      expect(decision.aprobar, isFalse);
      expect(decision.motivo, _motivo);
      expect(decision.solicitud.tipo, TipoSolicitud.repartidor);
      expect(find.text('No hay repartidores pendientes de aprobación'),
          findsOneWidget);
      expect(find.textContaining('fue rechazado'), findsOneWidget);
    });
  });

  group('Detalle · escenario 3: sin permiso', () {
    testWidgets('una cuenta que no es administrador ve el error y no decide',
        (tester) async {
      final env = await _pumpLista(tester, roles: {UserRole.comercio});
      await _abrirDetalle(tester, 'Minimercado La Esquina');

      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
      await tester.pumpAndSettle();
      await tester.tap(_enDialogo('Aprobar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Solo el administrador puede aprobar o rechazar solicitudes.'),
        findsOneWidget,
      );
      expect(env.solicitudes.decisiones, isEmpty);
      // Se queda en el detalle.
      expect(find.text('Solicitud de comercio'), findsOneWidget);
    });
  });

  group('Acceso desde el panel del administrador', () {
    Future<void> pumpAdmin(WidgetTester tester) async {
      setScreenSize(tester, 420, 1400);
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: BlocProvider<SessionBloc>(
            create: (_) => env.sessionBloc(),
            child: RolShell(
              rol: UserRole.administrador,
              profile: profileWith({UserRole.administrador}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la pestaña Aprobar abre las solicitudes pendientes',
        (tester) async {
      await pumpAdmin(tester);

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(find.text('SOLICITUDES'), findsOneWidget);
    });

    testWidgets('el acceso rápido Aprobaciones abre las solicitudes',
        (tester) async {
      await pumpAdmin(tester);

      final acceso = find.text('Aprobaciones');
      await tester.ensureVisible(acceso);
      await tester.pumpAndSettle();
      await tester.tap(acceso);
      await tester.pumpAndSettle();

      expect(find.text('SOLICITUDES'), findsOneWidget);
    });
  });
}
