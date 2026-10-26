import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pumpShell(WidgetTester tester, UserRole role) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv();
  env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<SessionBloc>(
        create: (_) => env.sessionBloc(),
        child: RolShell(rol: role, profile: profileWith({role})),
      ),
    ),
  );
  return env;
}

void main() {
  testWidgets('el Home del cliente saluda con el nombre real', (tester) async {
    await _pumpShell(tester, UserRole.cliente);

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(find.textContaining('Camila'), findsNothing);
  });

  testWidgets('el perfil del cliente muestra su nombre y correo', (tester) async {
    await _pumpShell(tester, UserRole.cliente);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Ana María Gómez'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
  });

  testWidgets('cerrar sesión cierra la sesión y vuelve a la selección',
      (tester) async {
    final env = await _pumpShell(tester, UserRole.cliente);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    final logout = find.text('Cerrar sesión');
    await tester.scrollUntilVisible(logout, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(env.auth.signOutCalls, 1);
    expect(find.text('SELECTION'), findsOneWidget);
  });

  for (final role in const [
    UserRole.colaborador,
    UserRole.comercio,
    UserRole.repartidor,
    UserRole.administrador,
  ]) {
    testWidgets('el Home de ${role.label} se construye sin errores',
        (tester) async {
      await _pumpShell(tester, role);
      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });
  }
}
