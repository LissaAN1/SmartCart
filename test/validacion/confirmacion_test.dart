import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
import 'package:smartcart/features/reportes/presentation/pages/mis_reportes_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reportes_por_confirmar_page.dart';
import 'package:smartcart/features/reportes/presentation/widgets/reporte_historial_item.dart';

import '../support/fakes_validacion.dart';
import '../support/pump_helpers.dart';

/// HU-15: confirmar o corregir un reporte dudoso. Escenario 3 del backlog:
/// "el precio reportado es muy distinto al historial: queda pendiente hasta
/// que otro colaborador o el comercio lo confirme o lo corrija".
void main() {
  group('casos de uso del colaborador', () {
    late ValidacionEnv env;

    setUp(() {
      env = ValidacionEnv()..iniciarSesionComoColaborador();
      env.validacion.porConfirmarLista
          .addAll([reportePorConfirmar(1), reportePorConfirmar(2)]);
    });

    test('lista los reportes por confirmar, por páginas', () async {
      env.validacion.porConfirmarLista.add(reportePorConfirmar(3));

      final primera = await env.getPorConfirmar(const PageRequest(pageSize: 2));
      final segunda = await env
          .getPorConfirmar(const PageRequest(pageSize: 2).next);

      expect(primera.items, hasLength(2));
      expect(primera.hasMore, isTrue);
      expect(segunda.items, hasLength(1));
      expect(segunda.hasMore, isFalse);
    });

    test('confirmar usa el GPS y deja el reporte confirmado', () async {
      await env.confirmarColaborador('rp1');

      expect(env.validacion.confirmadosColaborador, hasLength(1));
      expect(env.validacion.confirmadosColaborador.single.$1, 'rp1');
      expect(env.validacion.confirmadosColaborador.single.$2,
          env.servicioUbicacion.ubicacion);
      expect(env.servicioUbicacion.llamadas, 1);
    });

    test('un reporte confirmado ya no necesita confirmación', () async {
      await env.confirmarColaborador('rp1');

      final pagina = await env.getPorConfirmar(const PageRequest());

      expect(pagina.items.map((r) => r.id), ['rp2']);
    });

    test('sin poder leer el GPS no confirma nada', () async {
      env.servicioUbicacion.error =
          const AuthFailure('Activa la ubicación del dispositivo.');

      await expectLater(
        env.confirmarColaborador('rp1'),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.validacion.confirmadosColaborador, isEmpty);
    });

    test('quien no es colaborador no ve ni confirma reportes', () async {
      env.iniciarSesionCon({});

      await expectLater(
          env.getPorConfirmar(const PageRequest()), throwsA(isA<AuthFailure>()));
      await expectLater(
          env.confirmarColaborador('rp1'), throwsA(isA<AuthFailure>()));
      expect(env.validacion.confirmadosColaborador, isEmpty);
    });

    test('el error de la base (por ejemplo, estar lejos) llega tal cual',
        () async {
      env.validacion.accionError = const AuthFailure(
          'Debes estar en el establecimiento para confirmar el precio.');

      await expectLater(
        env.confirmarColaborador('rp1'),
        throwsA(isA<AuthFailure>().having(
            (e) => e.message, 'message', contains('en el establecimiento'))),
      );
    });
  });

  group('casos de uso del comercio', () {
    late ValidacionEnv env;

    setUp(() {
      env = ValidacionEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
      env.validacion.deMiComercioLista
          .addAll([reportePorConfirmar(1), reportePorConfirmar(2)]);
    });

    test('el comercio aprobado ve los reportes de sus productos', () async {
      final pagina = await env.getDeMiComercio(const PageRequest());

      expect(pagina.items, hasLength(2));
    });

    test('confirmar deja el reporte confirmado', () async {
      await env.confirmarComercio('rp1');

      expect(env.validacion.confirmadosComercio, ['rp1']);
    });

    test('corregir guarda el precio que indica el comercio', () async {
      await env.corregirComercio('rp1', 5000);

      expect(env.validacion.corregidos, [('rp1', 5000)]);
    });

    test('corregir con un precio inválido no llega a la base', () async {
      for (final precio in [0, -5, 100000001]) {
        await expectLater(
          env.corregirComercio('rp1', precio),
          throwsA(isA<AuthFailure>()),
        );
      }
      expect(env.validacion.corregidos, isEmpty);
    });

    test('un comercio pendiente no puede confirmar ni corregir', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(
          env.getDeMiComercio(const PageRequest()), throwsA(isA<AuthFailure>()));
      await expectLater(
          env.confirmarComercio('rp1'), throwsA(isA<AuthFailure>()));
      await expectLater(
          env.corregirComercio('rp1', 5000), throwsA(isA<AuthFailure>()));
      expect(env.validacion.confirmadosComercio, isEmpty);
      expect(env.validacion.corregidos, isEmpty);
    });
  });

  group('AccionReporteBloc', () {
    late ValidacionEnv env;

    setUp(() => env = ValidacionEnv()..iniciarSesionComoColaborador());

    test('confirmar emite loading y success y cuenta el éxito', () async {
      final bloc = env.accionReporteBloc();
      addTearDown(bloc.close);

      final esperado = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AccionReporteState>()
              .having((s) => s.status, 'status', AccionReporteStatus.loading)
              .having((s) => s.idEnProceso, 'id', 'rp1'),
          isA<AccionReporteState>()
              .having((s) => s.status, 'status', AccionReporteStatus.success)
              .having((s) => s.exitos, 'exitos', 1),
        ]),
      );
      bloc.add(ReporteConfirmadoPorColaborador('rp1'));
      await esperado;
    });

    test('si falla emite failure con el mensaje y no cuenta el éxito',
        () async {
      env.validacion.accionError = const AuthFailure('Ya confirmaste este reporte.');
      final bloc = env.accionReporteBloc();
      addTearDown(bloc.close);

      final esperado = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AccionReporteState>()
              .having((s) => s.status, 'status', AccionReporteStatus.loading),
          isA<AccionReporteState>()
              .having((s) => s.status, 'status', AccionReporteStatus.failure)
              .having((s) => s.mensaje, 'mensaje', 'Ya confirmaste este reporte.')
              .having((s) => s.exitos, 'exitos', 0),
        ]),
      );
      bloc.add(ReporteConfirmadoPorColaborador('rp1'));
      await esperado;
    });

    test('un segundo toque mientras se procesa no repite la acción', () async {
      final bloc = env.accionReporteBloc();
      addTearDown(bloc.close);

      bloc
        ..add(ReporteConfirmadoPorColaborador('rp1'))
        ..add(ReporteConfirmadoPorColaborador('rp1'));
      await bloc.stream
          .firstWhere((s) => s.status == AccionReporteStatus.success);
      await Future<void>.delayed(Duration.zero);

      expect(env.validacion.confirmadosColaborador, hasLength(1));
    });
  });

  group('ReportesPorConfirmarPage (colaborador)', () {
    Future<ValidacionEnv> pump(
      WidgetTester tester, {
      void Function(ValidacionEnv env)? prepare,
    }) async {
      setScreenSize(tester, 420, 1000);
      final env = ValidacionEnv()..iniciarSesionComoColaborador();
      env.validacion.porConfirmarLista
          .addAll([reportePorConfirmar(1), reportePorConfirmar(2)]);
      prepare?.call(env);
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PaginatedBloc<ReportePorConfirmar>>(
              create: (_) => PaginatedBloc<ReportePorConfirmar>(
                  fetchPage: env.getPorConfirmar.call)
                ..add(PaginatedStarted()),
            ),
            BlocProvider<AccionReporteBloc>(
                create: (_) => env.accionReporteBloc()),
          ],
          child: const ReportesPorConfirmarPage(),
        ),
      ));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('muestra el precio reportado, el registrado y la diferencia',
        (tester) async {
      await pump(tester);

      expect(find.text('Reportes por confirmar'), findsOneWidget);
      expect(find.text('Producto 1'), findsOneWidget);
      expect(find.text(r'$ 8.000'), findsWidgets);
      expect(find.text(r'$ 4.900'), findsWidgets);
      expect(find.text('+63 %'), findsWidgets);
      expect(find.text('Confirmar precio'), findsWidgets);
      // El colaborador solo confirma: corregir es del comercio.
      expect(find.text('Corregir'), findsNothing);
    });

    testWidgets('confirmar un reporte lo saca de la lista y avisa',
        (tester) async {
      final env = await pump(tester);

      await tester.tap(find.text('Confirmar precio').first);
      await tester.pumpAndSettle();

      expect(env.validacion.confirmadosColaborador.single.$1, 'rp1');
      expect(find.text('Producto 1'), findsNothing);
      expect(find.text('Producto 2'), findsOneWidget);
      expect(find.textContaining('Confirmaste el reporte'), findsOneWidget);
    });

    testWidgets('si la base rechaza la confirmación muestra el motivo',
        (tester) async {
      await pump(
        tester,
        prepare: (env) => env.validacion.accionError =
            const AuthFailure('No puedes confirmar tu propio reporte.'),
      );

      await tester.tap(find.text('Confirmar precio').first);
      await tester.pumpAndSettle();

      expect(find.text('No puedes confirmar tu propio reporte.'),
          findsOneWidget);
      expect(find.text('Producto 1'), findsOneWidget);
    });

    testWidgets('sin reportes por confirmar lo dice', (tester) async {
      await pump(tester, prepare: (env) => env.validacion.porConfirmarLista.clear());

      expect(find.textContaining('No hay reportes por confirmar'),
          findsOneWidget);
    });
  });

  group('ReportesPorConfirmarPage (comercio)', () {
    Future<ValidacionEnv> pump(WidgetTester tester) async {
      setScreenSize(tester, 420, 1000);
      final env = ValidacionEnv()
        ..iniciarSesionComoComercio(ApprovalStatus.aprobado);
      env.validacion.deMiComercioLista
          .addAll([reportePorConfirmar(1), reportePorConfirmar(2)]);
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PaginatedBloc<ReportePorConfirmar>>(
              create: (_) => PaginatedBloc<ReportePorConfirmar>(
                  fetchPage: env.getDeMiComercio.call)
                ..add(PaginatedStarted()),
            ),
            BlocProvider<AccionReporteBloc>(
                create: (_) => env.accionReporteBloc()),
          ],
          child: const ReportesPorConfirmarPage(esComercio: true),
        ),
      ));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('el comercio puede confirmar o corregir', (tester) async {
      await pump(tester);

      expect(find.text('Reportes de la comunidad'), findsOneWidget);
      expect(find.text('Confirmar precio'), findsWidgets);
      expect(find.text('Corregir'), findsWidgets);
    });

    testWidgets('confirmar deja el reporte confirmado por el comercio',
        (tester) async {
      final env = await pump(tester);

      await tester.tap(find.text('Confirmar precio').first);
      await tester.pumpAndSettle();

      expect(env.validacion.confirmadosComercio, ['rp1']);
      expect(find.text('Producto 1'), findsNothing);
    });

    testWidgets('corregir pide el precio y lo guarda', (tester) async {
      final env = await pump(tester);

      await tester.tap(find.text('Corregir').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '5.200');
      await tester.tap(find.widgetWithText(FilledButton, 'Corregir'));
      await tester.pumpAndSettle();

      expect(env.validacion.corregidos, [('rp1', 5200)]);
      expect(find.text('Producto 1'), findsNothing);
    });

    testWidgets('corregir sin escribir un precio válido no guarda nada',
        (tester) async {
      final env = await pump(tester);

      await tester.tap(find.text('Corregir').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Corregir'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe el precio'), findsOneWidget);
      expect(env.validacion.corregidos, isEmpty);
    });

    testWidgets('cancelar el cuadro no corrige nada', (tester) async {
      final env = await pump(tester);

      await tester.tap(find.text('Corregir').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(env.validacion.corregidos, isEmpty);
      expect(find.text('Producto 1'), findsOneWidget);
    });
  });

  group('estado y motivo en mis reportes', () {
    MiReporte reporte(
      String id,
      EstadoReporte estado, {
      String? motivo,
      bool confirmar = false,
    }) =>
        MiReporte(
          id: id,
          producto: 'Producto $id',
          establecimiento: 'Minimercado La Esquina',
          precio: 4900,
          estado: estado,
          creadoEn: DateTime.now(),
          motivo: motivo,
          requiereConfirmacion: confirmar,
        );

    testWidgets('un reporte rechazado muestra su motivo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReporteHistorialItem(
            reporte: reporte('1', EstadoReporte.rechazado,
                motivo: 'La ubicación no coincide con el establecimiento.'),
          ),
        ),
      ));

      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('La ubicación no coincide con el establecimiento.'),
          findsOneWidget);
    });

    testWidgets('un reporte dudoso dice que espera confirmación',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReporteHistorialItem(
            reporte: reporte('1', EstadoReporte.pendiente,
                confirmar: true,
                motivo: 'El precio es muy distinto al registrado (\$ 4900). '
                    'Espera la confirmación de otro colaborador o del comercio.'),
          ),
        ),
      ));

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.textContaining('Espera la confirmación'), findsOneWidget);
    });

    testWidgets('un reporte validado no muestra motivo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReporteHistorialItem(
              reporte: reporte('1', EstadoReporte.validado)),
        ),
      ));

      expect(find.text('Verificado'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(4)); // producto, tienda, precio, chip
    });

    testWidgets('la pantalla de mis reportes los lista con su motivo',
        (tester) async {
      setScreenSize(tester, 420, 900);
      final env = ValidacionEnv()..iniciarSesionComoColaborador();
      env.reportes.reportesPrevios.addAll([
        reporte('1', EstadoReporte.rechazado,
            motivo: 'No se encontró la foto de la etiqueta.'),
        reporte('2', EstadoReporte.validado),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider(
          create: (_) => env.misReportesBloc()..add(PaginatedStarted()),
          child: const MisReportesPage(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No se encontró la foto de la etiqueta.'),
          findsOneWidget);
      expect(find.text('Verificado'), findsOneWidget);
    });
  });

  test('stubRoutes conoce las rutas nuevas de la HU-15 y la HU-16', () {
    for (final nombre in [
      '/colaborador/reportes/por-confirmar',
      '/colaborador/puntos',
      '/comercio/reportes-comunidad',
    ]) {
      expect(stubRoutes(RouteSettings(name: nombre)), isNotNull, reason: nombre);
    }
  });
}
