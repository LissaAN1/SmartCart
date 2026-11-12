import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pumpShell(WidgetTester tester, UserRole role) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv();
  env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  // Un comercio aprobado deja pasar al Home de siempre (HU-07).
  env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionBloc>(create: (_) => env.sessionBloc()),
          BlocProvider<ComercioBloc>(
            create: (_) => env.comercioBloc()..add(ComercioStarted()),
          ),
          BlocProvider<DisponibilidadBloc>(
              create: (_) => env.disponibilidadBloc()),
        ],
        // El repartidor aprobado ve su Home completo (HU-08).
        child: RolShell(
          rol: role,
          profile: profileWith({role}, courierStatus: ApprovalStatus.aprobado),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('cerrar sesión cierra la sesión y vuelve a la primera pantalla',
      (tester) async {
    final env = await _pumpShell(tester, UserRole.cliente);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    final logout = find.text('Cerrar sesión');
    await tester.scrollUntilVisible(logout, 200,
        scrollable: find.byType(Scrollable).first);
    // El ListView construye elementos fuera de pantalla: se asegura que el
    // botón quede dentro del área visible antes de tocarlo.
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(env.auth.signOutCalls, 1);
    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('SELECTION'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
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