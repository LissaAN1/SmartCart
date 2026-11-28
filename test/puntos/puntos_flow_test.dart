import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_home_screen.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_perfil_screen.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/nivel_colaborador.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/puntos/presentation/pages/mis_puntos_page.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_validacion.dart';
import '../support/pump_helpers.dart';

/// HU-16: puntos, nivel, reputación e historial del colaborador.
void main() {
  group('casos de uso', () {
    late ValidacionEnv env;

    setUp(() {
      env = ValidacionEnv()..iniciarSesionComoColaborador();
      env.puntos.resumenActual = const ResumenPuntos(
        saldo: 35,
        acumulados: 120,
        nivel: NivelColaborador.frecuente,
        reputacion: 8,
      );
    });

    test('el resumen trae saldo, nivel y reputación', () async {
      final resumen = await env.getResumenPuntos();

      expect(resumen.saldo, 35);
      expect(resumen.nivel, NivelColaborador.frecuente);
      expect(resumen.reputacion, 8);
    });

    test('el historial se carga por páginas, del más reciente al más antiguo',
        () async {
      for (var i = 1; i <= 5; i++) {
        env.puntos.movimientosLista.add(movimiento(i));
      }

      final primera = await env.getMovimientosPuntos(const PageRequest(pageSize: 2));
      final ultima = await env
          .getMovimientosPuntos(const PageRequest(pageSize: 2, page: 2));

      expect(primera.items.map((m) => m.id), ['m1', 'm2']);
      expect(primera.hasMore, isTrue);
      expect(ultima.items.map((m) => m.id), ['m5']);
      expect(ultima.hasMore, isFalse);
    });

    test('quien no es colaborador no ve puntos', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(env.getResumenPuntos(), throwsA(isA<AuthFailure>()));
      await expectLater(env.getMovimientosPuntos(const PageRequest()),
          throwsA(isA<AuthFailure>()));
    });

    test('sin sesión tampoco', () async {
      env.auth.current = null;

      await expectLater(env.getResumenPuntos(), throwsA(isA<AuthFailure>()));
    });
  });

  group('movimientos', () {
    test('un canje resta y se distingue de un reporte validado', () {
      expect(movimiento(1, puntos: 10).suma, isTrue);
      expect(
          movimiento(2, puntos: -50, tipo: TipoMovimientoPuntos.canje).suma,
          isFalse);
    });

    test('un tipo desconocido cuenta como ajuste', () {
      expect(TipoMovimientoPuntos.fromDbName('reporte_validado'),
          TipoMovimientoPuntos.reporteValidado);
      expect(TipoMovimientoPuntos.fromDbName('canje'), TipoMovimientoPuntos.canje);
      expect(TipoMovimientoPuntos.fromDbName('raro'), TipoMovimientoPuntos.ajuste);
    });
  });

  group('ResumenPuntosBloc', () {
    late ValidacionEnv env;

    setUp(() => env = ValidacionEnv()..iniciarSesionComoColaborador());

    test('lee el resumen: loading y luego success', () async {
      final bloc = env.resumenPuntosBloc();
      addTearDown(bloc.close);

      final esperado = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ResumenPuntosState>()
              .having((s) => s.status, 'status', ResumenPuntosStatus.loading),
          isA<ResumenPuntosState>()
              .having((s) => s.status, 'status', ResumenPuntosStatus.success)
              .having((s) => s.resumen?.saldo, 'saldo', 0),
        ]),
      );
      bloc.add(ResumenPuntosStarted());
      await esperado;
    });

    test('si falla emite failure con el mensaje', () async {
      env.puntos.resumenError = const AuthFailure('No pudimos conectarnos.');
      final bloc = env.resumenPuntosBloc();
      addTearDown(bloc.close);

      final esperado = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ResumenPuntosState>()
              .having((s) => s.status, 'status', ResumenPuntosStatus.loading),
          isA<ResumenPuntosState>()
              .having((s) => s.status, 'status', ResumenPuntosStatus.failure)
              .having((s) => s.errorMessage, 'error', 'No pudimos conectarnos.'),
        ]),
      );
      bloc.add(ResumenPuntosStarted());
      await esperado;
    });

    test('al volver a leer conserva el resumen anterior mientras carga',
        () async {
      final bloc = env.resumenPuntosBloc();
      addTearDown(bloc.close);
      bloc.add(ResumenPuntosStarted());
      await bloc.stream.firstWhere((s) => s.status == ResumenPuntosStatus.success);

      bloc.add(ResumenPuntosStarted());
      final cargando = await bloc.stream.first;

      expect(cargando.status, ResumenPuntosStatus.loading);
      expect(cargando.resumen, isNotNull);
    });
  });

  group('MisPuntosPage', () {
    Future<ValidacionEnv> pump(
      WidgetTester tester, {
      void Function(ValidacionEnv env)? prepare,
      int pageSize = 20,
    }) async {
      setScreenSize(tester, 420, 1000);
      final env = ValidacionEnv()..iniciarSesionComoColaborador();
      env.puntos.resumenActual = const ResumenPuntos(
        saldo: 35,
        acumulados: 120,
        nivel: NivelColaborador.frecuente,
        reputacion: 8,
      );
      prepare?.call(env);
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ResumenPuntosBloc>(
              create: (_) =>
                  env.resumenPuntosBloc()..add(ResumenPuntosStarted()),
            ),
            BlocProvider<PaginatedBloc<MovimientoPuntos>>(
              create: (_) => PaginatedBloc<MovimientoPuntos>(
                  fetchPage: env.getMovimientosPuntos.call, pageSize: pageSize)
                ..add(PaginatedStarted()),
            ),
          ],
          child: const MisPuntosPage(),
        ),
      ));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('muestra puntos, nivel, lo que falta y la reputación',
        (tester) async {
      await pump(tester);

      expect(find.text('Mis puntos'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('Nivel Frecuente'), findsOneWidget);
      expect(find.textContaining('Experto: te faltan 380 pts'), findsOneWidget);
      expect(find.text('8 / 100'), findsOneWidget);
    });

    testWidgets('el historial muestra cada movimiento con su signo',
        (tester) async {
      await pump(tester, prepare: (env) {
        env.puntos.movimientosLista.addAll([
          movimiento(1, puntos: 20),
          movimiento(2, puntos: 10),
          movimiento(3, puntos: -50, tipo: TipoMovimientoPuntos.canje),
        ]);
      });

      expect(find.text('HISTORIAL DE PUNTOS'), findsOneWidget);
      expect(find.text('Reporte validado: Producto 1'), findsOneWidget);
      expect(find.text('+20 pts'), findsOneWidget);
      expect(find.text('+10 pts'), findsOneWidget);
      expect(find.text('-50 pts'), findsOneWidget);
    });

    testWidgets('el historial se carga por páginas al desplazarse',
        (tester) async {
      await pump(tester, pageSize: 6, prepare: (env) {
        for (var i = 1; i <= 14; i++) {
          env.puntos.movimientosLista.add(movimiento(i));
        }
      });
      expect(find.text('Reporte validado: Producto 14'), findsNothing);

      await tester.dragUntilVisible(
        find.text('Reporte validado: Producto 14'),
        find.byType(Scrollable).last,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reporte validado: Producto 14'), findsOneWidget);
    });

    testWidgets('sin movimientos explica cómo ganar puntos', (tester) async {
      await pump(tester);

      expect(find.textContaining('Aún no tienes puntos'), findsOneWidget);
    });

    testWidgets('un colaborador en el último nivel ya no tiene siguiente',
        (tester) async {
      await pump(tester, prepare: (env) {
        env.puntos.resumenActual = const ResumenPuntos(
          saldo: 900,
          acumulados: 900,
          nivel: NivelColaborador.experto,
          reputacion: 60,
        );
      });

      expect(find.text('Nivel Experto'), findsOneWidget);
      expect(find.text('Ya eres Experto'), findsOneWidget);
    });

    testWidgets('si falla la carga del resumen lo dice', (tester) async {
      await pump(
        tester,
        prepare: (env) =>
            env.puntos.resumenError = const AuthFailure('Sin conexión.'),
      );

      expect(find.text('Sin conexión.'), findsOneWidget);
    });

    testWidgets('actualizar vuelve a leer los puntos', (tester) async {
      final env = await pump(tester);
      final antes = env.puntos.llamadasResumen;

      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(env.puntos.llamadasResumen, antes + 1);
    });
  });

  group('perfil y Home del colaborador', () {
    const stats = CollaboratorStats(points: 120, level: 2, reputation: 8);

    testWidgets('el Home muestra los puntos y el nivel reales, no los de '
        'ejemplo', (tester) async {
      setScreenSize(tester, 420, 1200);
      await tester.pumpWidget(const MaterialApp(
        home: ColaboradorHomeScreen(nombre: 'Ana', stats: stats),
      ));

      expect(find.text('120'), findsOneWidget);
      expect(find.text('Nivel Frecuente'), findsOneWidget);
      expect(find.textContaining('Experto'), findsOneWidget);
      expect(find.text('2.450'), findsNothing);
      expect(find.text('Nivel Plata'), findsNothing);
    });

    testWidgets('un colaborador sin puntos parte como Nuevo', (tester) async {
      setScreenSize(tester, 420, 1200);
      await tester.pumpWidget(const MaterialApp(
        home: ColaboradorHomeScreen(nombre: 'Ana'),
      ));

      expect(find.text('Nivel Nuevo'), findsOneWidget);
      expect(find.textContaining('0% para Frecuente'), findsOneWidget);
    });

    testWidgets('tocar la tarjeta del Home abre los puntos', (tester) async {
      setScreenSize(tester, 420, 1200);
      var abrio = false;
      await tester.pumpWidget(MaterialApp(
        home: ColaboradorHomeScreen(
          nombre: 'Ana',
          stats: stats,
          onVerPuntos: () => abrio = true,
        ),
      ));

      await tester.tap(find.text('MIS SMARTPOINTS'));
      expect(abrio, isTrue);
    });

    testWidgets('el perfil muestra el nivel con su nombre y los accesos',
        (tester) async {
      setScreenSize(tester, 420, 1400);
      var puntos = 0, historial = 0, porConfirmar = 0;
      await tester.pumpWidget(MaterialApp(
        home: ColaboradorPerfilScreen(
          profile: profileWith({UserRole.colaborador}, collaborator: stats),
          onVerPuntos: () => puntos++,
          onVerHistorial: () => historial++,
          onPorConfirmar: () => porConfirmar++,
        ),
      ));

      expect(find.text('Frecuente'), findsOneWidget);
      expect(find.text('NIVEL'), findsOneWidget);

      await tester.tap(find.text('Mis puntos'));
      await tester.tap(find.text('Historial de reportes'));
      await tester.tap(find.text('Reportes por confirmar'));

      expect([puntos, historial, porConfirmar], [1, 1, 1]);
    });
  });

  group('desde el RolShell', () {
    Future<TestEnv> pumpShell(
      WidgetTester tester, {
      required UserRole role,
      required void Function(TestEnv env) prepare,
      CollaboratorStats? stats,
    }) async {
      setScreenSize(tester, 420, 1400);
      final env = TestEnv();
      env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
      prepare(env);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>(create: (_) => env.sessionBloc()),
              if (role == UserRole.comercio)
                BlocProvider<ComercioBloc>(
                  create: (_) => env.comercioBloc()..add(ComercioStarted()),
                ),
            ],
            child: RolShell(
              rol: role,
              profile: profileWith({role}, collaborator: stats),
              crearMisReportes: role == UserRole.colaborador
                  ? () => env.misReportesBloc()
                  : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('el colaborador abre sus puntos desde la tarjeta del Home',
        (tester) async {
      await pumpShell(
        tester,
        role: UserRole.colaborador,
        stats: const CollaboratorStats(points: 40, level: 1, reputation: 2),
        prepare: (env) => env.iniciarSesionComoColaborador(),
      );

      await tester.tap(find.text('MIS SMARTPOINTS'));
      await tester.pumpAndSettle();

      expect(find.text('MIS PUNTOS'), findsOneWidget);
    });

    testWidgets('el colaborador llega a sus puntos y a los reportes por '
        'confirmar desde el Perfil', (tester) async {
      await pumpShell(
        tester,
        role: UserRole.colaborador,
        stats: const CollaboratorStats(points: 40, level: 1, reputation: 2),
        prepare: (env) => env.iniciarSesionComoColaborador(),
      );
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mis puntos'));
      await tester.pumpAndSettle();
      expect(find.text('MIS PUNTOS'), findsOneWidget);
    });

    testWidgets('el comercio aprobado llega a los reportes de la comunidad '
        'desde su Perfil', (tester) async {
      await pumpShell(
        tester,
        role: UserRole.comercio,
        prepare: (env) => env.iniciarSesionComoComercio(ApprovalStatus.aprobado),
      );
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportes de la comunidad'));
      await tester.pumpAndSettle();

      expect(find.text('REPORTES COMUNIDAD'), findsOneWidget);
    });
  });
}
