import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_estadisticas.dart';
import '../support/pump_helpers.dart';

/// El panel del administrador dentro del `RolShell`, como lo arma la app.
Future<TestEnv> _pump(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  double ancho = 420,
  bool esperar = true,
}) async {
  setScreenSize(tester, ancho, 2600);
  final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<SessionBloc>(
        create: (_) => env.sessionBloc(),
        child: RolShell(
          rol: UserRole.administrador,
          profile: profileWith({UserRole.administrador}),
          crearEstadisticas: env.estadisticasBloc,
        ),
      ),
    ),
  );
  if (esperar) await tester.pumpAndSettle();
  return env;
}

/// La cifra que acompaña a [nombre] en una tarjeta de métrica.
String _metrica(WidgetTester tester, String nombre) => tester
    .widget<TarjetaMetrica>(find.ancestor(
        of: find.text(nombre.toUpperCase()),
        matching: find.byType(TarjetaMetrica)))
    .valor;

/// La cifra de la fila [nombre] en una lista.
Finder _fila(String nombre, String cifra) => find.descendant(
      of: find.ancestor(of: find.text(nombre), matching: find.byType(Row)).first,
      matching: find.text(cifra),
    );

void main() {
  testWidgets('escenario 1: muestra las cifras de la base', (tester) async {
    await _pump(tester);

    expect(_metrica(tester, 'Rechazados'), '0');
    expect(_metrica(tester, 'Pendientes'), '1');
    expect(_metrica(tester, 'En línea'), '4');
    expect(find.text('USUARIOS REGISTRADOS'), findsOneWidget);
    expect(_fila('Cliente', '1.250'), findsOneWidget);
    expect(_fila('Reportes de precio', '7'), findsOneWidget);
    expect(_fila('Solicitudes de repartidores', '2'), findsOneWidget);
  });

  testWidgets('no quedan cifras de ejemplo, variaciones ni "Estado del '
      'sistema"', (tester) async {
    await _pump(tester);

    for (final texto in ['12.480', '1.326', '342', '87']) {
      expect(find.text(texto), findsNothing, reason: texto);
    }
    expect(find.textContaining('vs ayer'), findsNothing);
    expect(find.textContaining('esta semana'), findsNothing);
    expect(find.text('Estado del sistema'), findsNothing);
    expect(find.text('Usuarios activos'), findsNothing);
    expect(find.textContaining('Pasarela de pagos'), findsNothing);
  });

  testWidgets('escenario 3: sin órdenes dice "No hay información disponible"',
      (tester) async {
    await _pump(tester);

    expect(find.text('No hay información disponible'), findsOneWidget);
    expect(find.text('PEDIDOS HOY'), findsNothing);
  });

  testWidgets('con órdenes muestra los pedidos de hoy y las órdenes por estado',
      (tester) async {
    await _pump(tester, prepare: (env) {
      env.estadisticas.datos = cifras(ordenes: ordenesDeEjemplo);
    });

    expect(_metrica(tester, 'Pedidos hoy'), '9');
    expect(_fila('Orden generada', '11'), findsOneWidget);
    expect(_fila('Entregada', '13'), findsOneWidget);
    expect(find.text('Rechazada'), findsNothing);
    expect(find.text('No hay información disponible'), findsNothing);
  });

  testWidgets('escenario 2: al volver de aprobar una solicitud las cifras se '
      'actualizan', (tester) async {
    final env = await _pump(tester);
    expect(env.estadisticas.llamadas, 1);

    await tester.tap(find.text('Aprobaciones'));
    await tester.pumpAndSettle();
    expect(find.text('SOLICITUDES'), findsOneWidget);

    // Mientras estaba en las solicitudes aprobó el comercio pendiente.
    env.estadisticas.datos = cifras(aprobados: 4, pendientes: 0);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(env.estadisticas.llamadas, 2);
    expect(_metrica(tester, 'Pendientes'), '0');
    expect(
        tester
            .widgetList<TarjetaMetrica>(find.byType(TarjetaMetrica))
            .firstWhere((t) => t.etiqueta == 'Aprobados')
            .valor,
        '4');
  });

  testWidgets('al volver al panel desde el perfil se consultan otra vez',
      (tester) async {
    final env = await _pump(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(env.estadisticas.llamadas, 1);

    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle();

    expect(env.estadisticas.llamadas, 2);
  });

  testWidgets('la pestaña y el acceso de Aprobaciones muestran las solicitudes '
      'pendientes', (tester) async {
    await _pump(tester);

    final barra = tester.widget<BarraNavRol>(find.byType(BarraNavRol));
    expect(barra.items.firstWhere((i) => i.etiqueta == 'Aprobar').badge, 3);
    expect(find.text('Acción Requerida'), findsOneWidget);
  });

  testWidgets('sin solicitudes pendientes no pide ninguna acción',
      (tester) async {
    await _pump(tester, prepare: (env) {
      env.estadisticas.datos = cifras(pendientes: 0, solicitudesRepartidor: 0);
    });

    expect(find.text('Acción Requerida'), findsNothing);
  });

  testWidgets('mientras carga muestra un indicador', (tester) async {
    final espera = Completer<void>();
    await _pump(tester, esperar: false, prepare: (env) {
      env.estadisticas.gate = espera;
    });
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TarjetaMetrica), findsNothing);

    espera.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TarjetaMetrica), findsWidgets);
  });

  testWidgets('si falla muestra el error y reintenta', (tester) async {
    final env = await _pump(tester, prepare: (env) {
      env.estadisticas.error =
          const AuthFailure('No hay conexión a internet.');
    });

    expect(find.text('No hay conexión a internet.'), findsOneWidget);
    expect(find.byType(TarjetaMetrica), findsNothing);

    env.estadisticas.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(TarjetaMetrica), findsWidgets);
  });

  testWidgets('en 320 px no hay desbordes', (tester) async {
    await _pump(tester, ancho: 320, prepare: (env) {
      env.estadisticas.datos = cifras(ordenes: ordenesDeEjemplo);
    });

    expect(tester.takeException(), isNull);
  });
}
