import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/profile_selection/presentation/pages/profile_selection_page.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pumpSelection(
  WidgetTester tester, {
  Set<UserRole>? sessionRoles,
}) async {
  setScreenSize(tester, 420, 1100);
  final env = TestEnv();
  if (sessionRoles != null) {
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    env.profiles.stored = profileWith(sessionRoles);
  }
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<SessionBloc>(
        create: (_) => env.sessionBloc()..add(SessionStarted()),
        child: const ProfileSelectionPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

void main() {
  testWidgets('muestra los cinco perfiles', (tester) async {
    await _pumpSelection(tester);

    expect(find.text('Selecciona tu perfil para continuar'), findsOneWidget);
    for (final name in const [
      'Cliente',
      'Colaborador',
      'Comercio',
      'Repartidor',
      'Administrador',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });

  // Un test por perfil: así cada uno arranca con su propio árbol y su propia
  // pila de navegación.
  for (final role in UserRole.values) {
    testWidgets('${role.label} abre su inicio de sesión', (tester) async {
      await _pumpSelection(tester);
      await tester.tap(find.text(role.label));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN UserRole.${role.name}'), findsOneWidget);
    });
  }

  testWidgets('con una sesión de un solo perfil entra directo a su Home',
      (tester) async {
    await _pumpSelection(tester, sessionRoles: {UserRole.repartidor});
    expect(find.text('HOME repartidor'), findsOneWidget);
  });

  testWidgets('con varios perfiles entra directo solo al que la cuenta tiene',
      (tester) async {
    await _pumpSelection(
      tester,
      sessionRoles: {UserRole.cliente, UserRole.colaborador},
    );
    expect(find.text('Selecciona tu perfil para continuar'), findsOneWidget);

    await tester.tap(find.text('Colaborador'));
    await tester.pumpAndSettle();
    expect(find.text('HOME colaborador'), findsOneWidget);
  });

  testWidgets('un perfil que la sesión no tiene pide iniciar sesión',
      (tester) async {
    await _pumpSelection(
      tester,
      sessionRoles: {UserRole.cliente, UserRole.colaborador},
    );

    await tester.tap(find.text('Administrador'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN UserRole.administrador'), findsOneWidget);
  });
}
