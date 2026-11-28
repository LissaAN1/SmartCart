import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/pages/mapa_comercios_page.dart';
import 'package:smartcart/features/ubicacion/presentation/widgets/mapa_establecimientos.dart';

import '../support/fakes.dart';
import '../support/fakes_ubicacion.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pump(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  double ancho = 420,
}) async {
  setScreenSize(tester, ancho, 1400);
  final env = TestEnv()..iniciarSesionComoClienteConComercios();
  prepare?.call(env);
  final bloc = env.mapaBloc()..add(MapaIniciado());
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider.value(value: bloc, child: const MapaComerciosPage()),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

void main() {
  // En las pruebas no hay red para descargar el mapa.
  setUpAll(() => MapaEstablecimientos.cargarTeselas = false);
  tearDownAll(() => MapaEstablecimientos.cargarTeselas = true);

  testWidgets('escenario 1: con el GPS muestra el mapa y los comercios del '
      'radio con su distancia', (tester) async {
    await _pump(tester);

    expect(find.byType(MapaEstablecimientos), findsOneWidget);
    expect(find.text('Tu ubicación actual (GPS)'), findsOneWidget);
    expect(find.text('2 COMERCIOS A MENOS DE 5 KM'), findsOneWidget);
    expect(find.text('Minimercado La Esquina'), findsOneWidget);
    expect(find.text('556 m'), findsOneWidget);
    expect(find.text('Tienda Doña Rosa'), findsOneWidget);
    expect(find.text('3,3 km'), findsOneWidget);
    expect(find.text('Fruver El Lejano'), findsNothing);
  });

  testWidgets('escenario 2: sin permiso pide escribir la dirección y luego '
      'muestra los comercios', (tester) async {
    final env = await _pump(tester, prepare: (env) {
      env.servicioUbicacion.error = const AuthFailure(
          'Necesitamos el permiso de ubicación para comprobar dónde estás.');
    });

    expect(find.text('Escribe tu dirección'), findsOneWidget);
    expect(find.textContaining('permiso de ubicación'), findsOneWidget);
    expect(find.byType(MapaEstablecimientos), findsNothing);

    await tester.enterText(find.byType(TextField), direccionEjemplo);
    await tester.tap(find.text('Buscar dirección'));
    await tester.pumpAndSettle();

    expect(find.byType(MapaEstablecimientos), findsOneWidget);
    expect(find.text(direccionEjemplo), findsOneWidget);
    expect(find.text('Guardamos tu dirección.'), findsOneWidget);
    expect(env.ubicacion.repositorio.guardada?.direccion, direccionEjemplo);
  });

  testWidgets('escenario 3: al ampliar el radio aparecen más comercios',
      (tester) async {
    final env = await _pump(tester);

    await tester.tap(find.text('10 km'));
    await tester.pumpAndSettle();

    expect(find.text('3 COMERCIOS A MENOS DE 10 KM'), findsOneWidget);
    expect(find.text('Fruver El Lejano'), findsOneWidget);
    expect(env.ubicacion.repositorio.guardada?.radioM, 10000);
  });

  testWidgets('sin comercios en el radio invita a ampliarlo', (tester) async {
    await _pump(tester, prepare: (env) {
      env.ubicacion.repositorio.guardada = const PreferenciaUbicacion(
          ubicacion: ubicacionCliente, radioM: 1000);
      env.ubicacion.repositorio.comercios
        ..clear()
        ..add(comercioLejos);
    });

    expect(find.textContaining('No hay comercios aprobados a menos de 1 km'),
        findsOneWidget);
  });

  testWidgets('"Escribir dirección" abre el formulario y guarda la nueva',
      (tester) async {
    final env = await _pump(tester);

    await tester.tap(find.text('Escribir dirección'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), direccionEjemplo);
    await tester.tap(find.text('Buscar dirección'));
    await tester.pumpAndSettle();

    expect(find.text(direccionEjemplo), findsOneWidget);
    expect(env.ubicacion.repositorio.guardada?.ubicacion, ubicacionDireccion);
  });

  testWidgets('si la carga falla muestra el error y reintenta',
      (tester) async {
    final env = await _pump(tester, prepare: (env) {
      env.ubicacion.repositorio.errorAlLeer =
          const AuthFailure('No hay conexión a internet.');
    });

    expect(find.text('No hay conexión a internet.'), findsOneWidget);

    env.ubicacion.repositorio.errorAlLeer = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(MapaEstablecimientos), findsOneWidget);
  });

  testWidgets('en 320 px no hay desbordes', (tester) async {
    await _pump(tester, ancho: 320);

    expect(tester.takeException(), isNull);
    expect(find.text('Minimercado La Esquina'), findsOneWidget);
  });
}
