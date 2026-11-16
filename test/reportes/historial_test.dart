import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_home_screen.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/pages/mis_reportes_page.dart';
import 'package:smartcart/features/reportes/presentation/reporte_formato.dart';
import 'package:smartcart/features/reportes/presentation/widgets/reporte_historial_item.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

MiReporte _reporte(
  String id,
  String producto, {
  EstadoReporte estado = EstadoReporte.pendiente,
  int precio = 4900,
  int? promocion,
  DateTime? creadoEn,
}) =>
    MiReporte(
      id: id,
      producto: producto,
      establecimiento: 'Minimercado La Esquina',
      precio: precio,
      precioPromocional: promocion,
      estado: estado,
      creadoEn: creadoEn ?? DateTime.now(),
    );

/// Envía un reporte de verdad por el caso de uso: queda pendiente.
Future<void> _enviarReporte(TestEnv env, {int precio = 4900}) => env.enviarReporte(
      ReporteDatos(
        establecimiento: establecimientoDePrueba(),
        producto: productoDePrueba,
        precio: precio,
      ),
      FakeSelectorFoto().foto,
    );

void main() {
  group('EstadoReporte', () {
    test('lee el valor de la base y trata lo desconocido como pendiente', () {
      expect(EstadoReporte.fromDbName('pendiente'), EstadoReporte.pendiente);
      expect(EstadoReporte.fromDbName('validado'), EstadoReporte.validado);
      expect(EstadoReporte.fromDbName('rechazado'), EstadoReporte.rechazado);
      expect(EstadoReporte.fromDbName('otro'), EstadoReporte.pendiente);
      expect(EstadoReporte.fromDbName(null), EstadoReporte.pendiente);
    });
  });

  group('formatoPesos', () {
    test('separa los miles con punto', () {
      expect(formatoPesos(0), r'$ 0');
      expect(formatoPesos(999), r'$ 999');
      expect(formatoPesos(4900), r'$ 4.900');
      expect(formatoPesos(1234567), r'$ 1.234.567');
      expect(formatoPesos(100000000), r'$ 100.000.000');
    });
  });

  group('formatoFechaHora', () {
    final ahora = DateTime(2026, 11, 15, 18, 0);

    test('hoy y ayer llevan la hora', () {
      expect(formatoFechaHora(DateTime(2026, 11, 15, 15, 5), ahora: ahora),
          'Hoy, 15:05');
      expect(formatoFechaHora(DateTime(2026, 11, 14, 9, 30), ahora: ahora),
          'Ayer, 09:30');
    });

    test('antes de ayer lleva el día y el mes', () {
      expect(formatoFechaHora(DateTime(2026, 11, 12, 15, 5), ahora: ahora),
          '12 nov, 15:05');
    });

    test('de otro año lleva el año', () {
      expect(formatoFechaHora(DateTime(2025, 12, 31, 23, 59), ahora: ahora),
          '31 dic 2025, 23:59');
    });
  });

  group('GetMisReportesUseCase', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('un reporte recién enviado aparece como pendiente, aunque nadie lo revise',
        () async {
      await _enviarReporte(env);

      final pagina = await env.getMisReportes(const PageRequest());

      expect(pagina.items.single.estado, EstadoReporte.pendiente);
      expect(pagina.items.single.producto, 'Arroz blanco 500 g');
      expect(pagina.items.single.establecimiento, 'Minimercado La Esquina');
      expect(pagina.items.single.precio, 4900);
    });

    test('muestra los reportes de todos los estados, los más recientes primero',
        () async {
      env.reportes.reportesPrevios.addAll([
        _reporte('v1', 'Leche entera 1 L', estado: EstadoReporte.validado),
        _reporte('x1', 'Sal marina 1 kg', estado: EstadoReporte.rechazado),
      ]);
      await _enviarReporte(env);

      final pagina = await env.getMisReportes(const PageRequest());

      expect(pagina.items.map((r) => r.estado), [
        EstadoReporte.pendiente,
        EstadoReporte.validado,
        EstadoReporte.rechazado,
      ]);
    });

    test('se carga por páginas e indica si hay más', () async {
      for (var i = 1; i <= 5; i++) {
        env.reportes.reportesPrevios.add(_reporte('r$i', 'Producto $i'));
      }

      final primera = await env.getMisReportes(const PageRequest(pageSize: 2));
      expect(primera.items.length, 2);
      expect(primera.hasMore, isTrue);

      final ultima =
          await env.getMisReportes(const PageRequest(page: 2, pageSize: 2));
      expect(ultima.items.length, 1);
      expect(ultima.hasMore, isFalse);
    });

    test('exige el modo Colaborador', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(
        env.getMisReportes(const PageRequest()),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('modo Colaborador'))),
      );
    });
  });

  group('ReporteHistorialItem', () {
    Future<void> pump(WidgetTester tester, MiReporte reporte) async {
      await tester.pumpWidget(MaterialApp(
        home: PantallaRol(
          tema: TemaRol.colaborador,
          cuerpo: ReporteHistorialItem(reporte: reporte),
        ),
      ));
    }

    testWidgets('un reporte pendiente se ve como Pendiente', (tester) async {
      await pump(tester, _reporte('1', 'Arroz blanco 500 g'));

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text(r'$ 4.900'), findsOneWidget);
      expect(find.textContaining('Minimercado La Esquina'), findsOneWidget);
      expect(find.textContaining('Hoy'), findsOneWidget);
    });

    testWidgets('validado y rechazado se distinguen', (tester) async {
      await pump(tester, _reporte('1', 'Arroz', estado: EstadoReporte.validado));
      expect(find.text('Verificado'), findsOneWidget);

      await pump(tester, _reporte('2', 'Arroz', estado: EstadoReporte.rechazado));
      expect(find.text('Rechazado'), findsOneWidget);
    });

    testWidgets('con promoción muestra el precio de la promoción', (tester) async {
      await pump(tester, _reporte('1', 'Arroz', precio: 4900, promocion: 4500));

      expect(find.text(r'$ 4.500'), findsOneWidget);
      expect(find.text(r'$ 4.900'), findsNothing);
    });
  });

  group('MisReportesPage', () {
    Future<TestEnv> pump(
      WidgetTester tester, {
      void Function(TestEnv env)? prepare,
    }) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoColaborador();
      prepare?.call(env);
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider(
          create: (_) => env.misReportesBloc()..add(PaginatedStarted()),
          child: const MisReportesPage(),
        ),
      ));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('muestra los reportes reales, también los pendientes',
        (tester) async {
      await pump(tester, prepare: (env) {
        env.reportes.reportesPrevios.addAll([
          _reporte('v1', 'Leche entera 1 L', estado: EstadoReporte.validado),
          _reporte('x1', 'Sal marina 1 kg', estado: EstadoReporte.rechazado),
        ]);
      });

      expect(find.text('Mis reportes'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Sal marina 1 kg'), findsOneWidget);
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Rechazado'), findsOneWidget);
    });

    testWidgets('un reporte recién enviado aparece como pendiente',
        (tester) async {
      final env = TestEnv()..iniciarSesionComoColaborador();
      await _enviarReporte(env);
      setScreenSize(tester, 420, 900);

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider(
          create: (_) => env.misReportesBloc()..add(PaginatedStarted()),
          child: const MisReportesPage(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('sin reportes invita a enviar el primero', (tester) async {
      await pump(tester);

      expect(find.textContaining('Aún no has enviado reportes'), findsOneWidget);
    });

    testWidgets('si la carga falla deja reintentar', (tester) async {
      final env = await pump(
        tester,
        prepare: (env) => env.reportes.historialError =
            const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.reportes.historialError = null;
      env.reportes.reportesPrevios.add(_reporte('1', 'Arroz blanco 500 g'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
    });

    testWidgets('el botón Actualizar trae los reportes nuevos', (tester) async {
      final env = await pump(tester);
      expect(find.text('Arroz blanco 500 g'), findsNothing);

      env.reportes.reportesPrevios.add(_reporte('1', 'Arroz blanco 500 g'));
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
    });

    testWidgets('carga más reportes al llegar al final de la lista',
        (tester) async {
      await pump(tester, prepare: (env) {
        for (var i = 1; i <= 25; i++) {
          env.reportes.reportesPrevios.add(_reporte('r$i', 'Producto $i'));
        }
      });
      expect(find.text('Producto 25'), findsNothing);

      await tester.dragUntilVisible(
        find.text('Producto 25'),
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Producto 25'), findsOneWidget);
    });
  });

  group('ColaboradorHomeScreen · mis últimos reportes', () {
    Future<void> pump(
      WidgetTester tester, {
      List<MiReporte> reportes = const [],
      bool cargando = false,
      String? error,
      VoidCallback? onReintentar,
      VoidCallback? onVerHistorial,
    }) async {
      setScreenSize(tester, 420, 2400);
      await tester.pumpWidget(MaterialApp(
        home: ColaboradorHomeScreen(
          nombre: 'Ana',
          reportes: reportes,
          cargandoReportes: cargando,
          errorReportes: error,
          onReintentarReportes: onReintentar,
          onVerHistorial: onVerHistorial,
        ),
      ));
      await tester.pump();
    }

    testWidgets('muestra los reportes reales y ya no los de ejemplo',
        (tester) async {
      await pump(tester, reportes: [_reporte('1', 'Arroz blanco 500 g')]);

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Arroz Diana 1kg'), findsNothing);
      expect(find.text('Huevos AA x30'), findsNothing);
    });

    testWidgets('en el Home solo caben los 3 más recientes', (tester) async {
      await pump(tester, reportes: [
        for (var i = 1; i <= 5; i++) _reporte('r$i', 'Producto $i'),
      ]);

      expect(find.text('Producto 1'), findsOneWidget);
      expect(find.text('Producto 3'), findsOneWidget);
      expect(find.text('Producto 4'), findsNothing);
    });

    testWidgets('sin reportes lo dice', (tester) async {
      await pump(tester);

      expect(find.textContaining('Aún no has enviado reportes'), findsOneWidget);
    });

    testWidgets('mientras carga muestra el indicador', (tester) async {
      await pump(tester, cargando: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Aún no has enviado reportes'), findsNothing);
    });

    testWidgets('si falla muestra el error y deja reintentar', (tester) async {
      var reintentos = 0;
      await pump(
        tester,
        error: 'No pudimos conectarnos.',
        onReintentar: () => reintentos++,
      );

      expect(find.text('No pudimos conectarnos.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('"Historial" y tocar un reporte abren el historial',
        (tester) async {
      var aperturas = 0;
      await pump(
        tester,
        reportes: [_reporte('1', 'Arroz blanco 500 g')],
        onVerHistorial: () => aperturas++,
      );

      await tester.tap(find.text('Historial'));
      await tester.tap(find.text('Arroz blanco 500 g'));

      expect(aperturas, 2);
    });
  });

  group('Home del colaborador dentro del RolShell', () {
    Future<TestEnv> pumpShell(
      WidgetTester tester, {
      void Function(TestEnv env)? prepare,
    }) async {
      setScreenSize(tester, 420, 2400);
      final env = TestEnv()..iniciarSesionComoColaborador();
      prepare?.call(env);
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          // El flujo del reporte de mentira: un botón que "envía" un reporte
          // de verdad por el caso de uso y vuelve.
          if (settings.name == AppRoutes.reporteEstablecimiento) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _enviarReporte(env, precio: 7000);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Enviar de mentira'),
                  ),
                ),
              ),
            );
          }
          return stubRoutes(settings);
        },
        home: BlocProvider<SessionBloc>(
          create: (_) => env.sessionBloc(),
          child: RolShell(
            rol: UserRole.colaborador,
            profile: profileWith({UserRole.cliente, UserRole.colaborador}),
            crearMisReportes: () => env.misReportesBloc(pageSize: 3),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('muestra los reportes reales, incluido el pendiente',
        (tester) async {
      await pumpShell(tester, prepare: (env) {
        env.reportes.reportesPrevios.addAll([
          _reporte('v1', 'Leche entera 1 L', estado: EstadoReporte.validado),
        ]);
      });

      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Arroz Diana 1kg'), findsNothing);
    });

    testWidgets('sin reportes lo dice', (tester) async {
      await pumpShell(tester);

      expect(find.textContaining('Aún no has enviado reportes'), findsOneWidget);
    });

    testWidgets('en el Home aparecen solo los 3 más recientes', (tester) async {
      await pumpShell(tester, prepare: (env) {
        for (var i = 1; i <= 5; i++) {
          env.reportes.reportesPrevios.add(_reporte('r$i', 'Producto $i'));
        }
      });

      expect(find.text('Producto 3'), findsOneWidget);
      expect(find.text('Producto 4'), findsNothing);
    });

    testWidgets('al volver de reportar, el reporte nuevo ya aparece como pendiente',
        (tester) async {
      await pumpShell(tester);
      expect(find.text('Arroz blanco 500 g'), findsNothing);

      await tester.tap(find.text('Reportar precio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar de mentira'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text(r'$ 7.000'), findsOneWidget);
    });

    testWidgets('"Historial" abre el historial completo', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('MIS REPORTES'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra el error y reintenta', (tester) async {
      final env = await pumpShell(
        tester,
        prepare: (env) => env.reportes.historialError =
            const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.reportes.historialError = null;
      env.reportes.reportesPrevios.add(_reporte('1', 'Leche entera 1 L'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Leche entera 1 L'), findsOneWidget);
    });
  });
}
