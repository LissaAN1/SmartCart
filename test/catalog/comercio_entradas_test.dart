import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Home del comercio aprobado dentro del `RolShell`, con rutas de apoyo que
/// marcan en pantalla a dónde se navegó.
Future<void> _pumpHomeComercio(WidgetTester tester) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv();
  env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
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
        ],
        child: RolShell(
          rol: UserRole.comercio,
          profile: profileWith({UserRole.comercio}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HU-10: accesos al catálogo desde el Home del comercio', () {
    testWidgets('la pestaña Catálogo abre el catálogo', (tester) async {
      await _pumpHomeComercio(tester);

      await tester.tap(find.text('Catálogo').first);
      await tester.pumpAndSettle();

      expect(find.text('CATALOGO'), findsOneWidget);
      expect(find.text('Pantalla aún no disponible'), findsNothing);
    });

    testWidgets('el botón + abre el formulario de un producto nuevo',
        (tester) async {
      await _pumpHomeComercio(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('PRODUCTO NUEVO'), findsOneWidget);
    });

    testWidgets('"Ir al Catálogo" abre el catálogo', (tester) async {
      await _pumpHomeComercio(tester);

      // Desde HU-14 el Home puede mostrar antes el aviso de ubicación, así
      // que el botón queda más abajo y hay que desplazarse hasta él.
      final boton = find.text('Ir al Catálogo');
      await tester.scrollUntilVisible(boton, 300);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('CATALOGO'), findsOneWidget);
    });
  });
}
