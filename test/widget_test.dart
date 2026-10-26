import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/profile_selection/presentation/pages/profile_selection_page.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import 'support/fakes.dart';
import 'support/pump_helpers.dart';

void main() {
  testWidgets('La selección de perfil lleva al inicio de sesión del perfil',
      (WidgetTester tester) async {
    setScreenSize(tester, 420, 1100);
    final env = TestEnv();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: stubRoutes,
        home: BlocProvider<SessionBloc>(
          create: (_) => env.sessionBloc(),
          child: const ProfileSelectionPage(),
        ),
      ),
    );
    expect(find.text('Selecciona tu perfil para continuar'), findsOneWidget);

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona tu perfil para continuar'), findsNothing);
    expect(find.text('LOGIN UserRole.cliente'), findsOneWidget);
  });
}
