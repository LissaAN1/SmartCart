import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Home del colaborador dentro del `RolShell`, con rutas de apoyo que marcan
/// en pantalla a dónde se navegó.
Future<void> _pumpHomeColaborador(WidgetTester tester) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<SessionBloc>(
        create: (_) => env.sessionBloc(),
        child: RolShell(
          rol: UserRole.colaborador,
          profile: profileWith({UserRole.cliente, UserRole.colaborador}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HU-14: accesos al reporte de precio desde el Home del colaborador', () {
    testWidgets('la pestaña "Reportar Precio" abre el reporte', (tester) async {
      await _pumpHomeColaborador(tester);

      await tester.tap(find.text('Reportar Precio'));
      await tester.pumpAndSettle();

      expect(find.text('REPORTE'), findsOneWidget);
      expect(find.text('Pantalla aún no disponible'), findsNothing);
    });

    testWidgets('la acción rápida "Reportar precio" abre el reporte',
        (tester) async {
      await _pumpHomeColaborador(tester);

      await tester.tap(find.text('Reportar precio'));
      await tester.pumpAndSettle();

      expect(find.text('REPORTE'), findsOneWidget);
    });

    testWidgets('la acción rápida "Escanear" también empieza el reporte',
        (tester) async {
      await _pumpHomeColaborador(tester);

      await tester.tap(find.text('Escanear'));
      await tester.pumpAndSettle();

      expect(find.text('REPORTE'), findsOneWidget);
    });
  });
}
