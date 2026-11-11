import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_state.dart';
import 'package:smartcart/features/admin/presentation/pages/admin_aprobaciones_screen.dart';
import 'package:smartcart/features/admin/presentation/pages/solicitud_detalle_page.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.auth.current = const AppUser(id: 'u1', email: 'admin@correo.com');
    env.profiles.stored = profileWith({UserRole.administrador});
  });

  group('DecidirSolicitudUseCase', () {
    test('el administrador aprueba una solicitud', () async {
      final s = solicitudDe(1);

      await env.decidirSolicitud.aprobar(s);

      expect(env.aprobaciones.aprobadas, [s]);
    });

    test('el administrador rechaza con motivo y se guarda recortado', () async {
      final s = solicitudDe(1, tipo: TipoSolicitud.repartidor);

      await env.decidirSolicitud.rechazar(s, '  Documentos ilegibles ');

      expect(env.aprobaciones.rechazadas.single.$1, s);
      expect(env.aprobaciones.rechazadas.single.$2, 'Documentos ilegibles');
    });

    test('rechazar sin motivo pide el motivo y no rechaza', () async {
      for (final motivo in [null, '', '   ']) {
        await expectLater(
          env.decidirSolicitud.rechazar(solicitudDe(1), motivo),
          throwsA(isA<AuthFailure>()
              .having((e) => e.message, 'message', contains('motivo'))),
        );
      }
      expect(env.aprobaciones.rechazadas, isEmpty);
    });

    test('quien no es administrador no puede decidir', () async {
      env.profiles.stored = profileWith({UserRole.comercio});

      await expectLater(
        env.decidirSolicitud.aprobar(solicitudDe(1)),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('administrador'))),
      );
      await expectLater(
        env.decidirSolicitud.rechazar(solicitudDe(1), 'x'),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.aprobaciones.aprobadas, isEmpty);
      expect(env.aprobaciones.rechazadas, isEmpty);
    });

    test('exige una sesión iniciada', () async {
      env.auth.current = null;

      await expectLater(
        env.decidirSolicitud.aprobar(solicitudDe(1)),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('si la base de datos rechaza (RLS) el error llega tal cual', () async {
      env.aprobaciones.decideError =
          const AuthFailure('No tienes permiso para realizar esta acción.');

      await expectLater(
        env.decidirSolicitud.aprobar(solicitudDe(1)),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('permiso'))),
      );
    });
  });

  group('lista paginada', () {
    test('carga por páginas: la primera trae 20 y avisa que hay más', () async {
      env.aprobaciones.pendientes = [for (var i = 0; i < 25; i++) solicitudDe(i)];

      final primera = await env.getSolicitudes(const PageRequest());
      final segunda = await env.getSolicitudes(const PageRequest().next);

      expect(primera.items, hasLength(20));
      expect(primera.hasMore, isTrue);
      expect(segunda.items, hasLength(5));
      expect(segunda.hasMore, isFalse);
    });
  });

  group('DecisionSolicitudBloc', () {
    test('aprobar emite loading y success', () async {
      final bloc = env.decisionBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DecisionSolicitudState>()
              .having((s) => s.status, 'status', DecisionStatus.loading),
          isA<DecisionSolicitudState>()
              .having((s) => s.status, 'status', DecisionStatus.success)
              .having((s) => s.aprobada, 'aprobada', true),
        ]),
      );
      bloc.add(SolicitudAprobada(solicitudDe(1)));
      await expectation;
    });

    test('rechazar sin motivo emite failure con el mensaje', () async {
      final bloc = env.decisionBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DecisionSolicitudState>()
              .having((s) => s.status, 'status', DecisionStatus.loading),
          isA<DecisionSolicitudState>()
              .having((s) => s.status, 'status', DecisionStatus.failure)
              .having((s) => s.errorMessage, 'error', contains('motivo')),
        ]),
      );
      bloc.add(SolicitudRechazada(solicitudDe(1), ''));
      await expectation;
      expect(env.aprobaciones.rechazadas, isEmpty);
    });
  });

  group('pantallas', () {
    Future<void> pumpLista(WidgetTester tester) async {
      setScreenSize(tester, 420, 1000);
      Route<dynamic>? rutas(RouteSettings settings) {
        if (settings.name == AppRoutes.solicitudDetalle) {
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) => env.decisionBloc(),
              child: SolicitudDetallePage(
                solicitud: settings.arguments! as SolicitudAprobacion,
              ),
            ),
          );
        }
        return stubRoutes(settings);
      }

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: rutas,
          home: BlocProvider<PaginatedBloc<SolicitudAprobacion>>(
            create: (_) => PaginatedBloc<SolicitudAprobacion>(
              fetchPage: env.getSolicitudes.call,
            )..add(PaginatedStarted()),
            child: const AdminAprobacionesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la lista muestra comercios y repartidores pendientes',
        (tester) async {
      env.aprobaciones.pendientes = [
        solicitudDe(1),
        solicitudDe(2, tipo: TipoSolicitud.repartidor),
      ];
      await pumpLista(tester);

      expect(find.text('Solicitante 1'), findsOneWidget);
      expect(find.text('Solicitante 2'), findsOneWidget);
      expect(find.text('Comercio'), findsOneWidget);
      expect(find.text('Repartidor'), findsOneWidget);
    });

    testWidgets('sin solicitudes avisa que no hay pendientes', (tester) async {
      await pumpLista(tester);

      expect(find.text('No hay solicitudes pendientes'), findsOneWidget);
    });

    testWidgets('aprobar desde el detalle la quita de la lista', (tester) async {
      env.aprobaciones.pendientes = [solicitudDe(1), solicitudDe(2)];
      await pumpLista(tester);

      await tester.tap(find.text('Solicitante 1'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la solicitud'), findsOneWidget);

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(env.aprobaciones.aprobadas.single.id, 's1');
      expect(find.text('Solicitante 1'), findsNothing);
      expect(find.text('Solicitante 2'), findsOneWidget);
    });

    testWidgets('rechazar sin escribir el motivo lo pide y no rechaza',
        (tester) async {
      env.aprobaciones.pendientes = [solicitudDe(1)];
      await pumpLista(tester);
      await tester.tap(find.text('Solicitante 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe el motivo del rechazo'), findsOneWidget);
      expect(env.aprobaciones.rechazadas, isEmpty);
    });

    testWidgets('rechazar con motivo guarda el rechazo y vuelve a la lista',
        (tester) async {
      env.aprobaciones.pendientes = [solicitudDe(1)];
      await pumpLista(tester);
      await tester.tap(find.text('Solicitante 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Dirección falsa');
      await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
      await tester.pumpAndSettle();

      expect(env.aprobaciones.rechazadas.single.$2, 'Dirección falsa');
      expect(find.text('No hay solicitudes pendientes'), findsOneWidget);
    });

    testWidgets('si la decisión falla muestra el error y sigue en el detalle',
        (tester) async {
      env.aprobaciones.pendientes = [solicitudDe(1)];
      env.aprobaciones.decideError =
          const AuthFailure('Esta solicitud ya fue resuelta. Actualiza la lista.');
      await pumpLista(tester);
      await tester.tap(find.text('Solicitante 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ya fue resuelta'), findsOneWidget);
      expect(find.text('Detalle de la solicitud'), findsOneWidget);
    });

    testWidgets('en el shell la pestaña Aprobar abre la lista de pendientes',
        (tester) async {
      setScreenSize(tester, 420, 1000);
      env.aprobaciones.pendientes = [solicitudDe(1)];
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>(create: (_) => env.sessionBloc()),
              BlocProvider<PaginatedBloc<SolicitudAprobacion>>(
                create: (_) => PaginatedBloc<SolicitudAprobacion>(
                  fetchPage: env.getSolicitudes.call,
                )..add(PaginatedStarted()),
              ),
            ],
            child: RolShell(
              rol: UserRole.administrador,
              profile: profileWith({UserRole.administrador}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(find.text('Aprobaciones'), findsOneWidget);
      expect(find.text('Solicitante 1'), findsOneWidget);
    });
  });
}
