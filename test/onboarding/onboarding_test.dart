import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/app.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:smartcart/features/profile_selection/presentation/pages/profile_selection_page.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

const _flecha = Icons.arrow_back_ios_new;
const _tituloOnboarding2 = 'Compara tu carrito completo';
const _tituloSeleccion = 'Selecciona tu perfil para continuar';

/// Arranca la app en el onboarding. La selección de perfil se abre encima,
/// como hace `AppRouter` al terminar la bienvenida.
Future<void> _pumpOnboarding(WidgetTester tester) async {
  setScreenSize(tester, 420, 1100);
  final env = TestEnv();
  await tester.pumpWidget(
    MaterialApp(
      home: const OnboardingPage(),
      onGenerateRoute: (settings) {
        if (settings.name != AppRoutes.profileSelection) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider(
            create: (_) => env.sessionBloc()..add(SessionStarted()),
            child: const ProfileSelectionPage(),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la app arranca en el onboarding sin pantallas debajo',
      (tester) async {
    setScreenSize(tester, 420, 1100);
    await tester.pumpWidget(const SmartCartApp());
    await tester.pumpAndSettle();

    expect(find.text('COLOMBIA'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('la primera pantalla de onboarding no tiene flecha atrás',
      (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('COLOMBIA'), findsOneWidget);
    expect(find.byIcon(_flecha), findsNothing);
  });

  testWidgets('la segunda pantalla tiene flecha y regresa a la primera',
      (tester) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.byTooltip('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text(_tituloOnboarding2), findsOneWidget);
    expect(find.byIcon(_flecha), findsOneWidget);

    await tester.tap(find.byIcon(_flecha));
    await tester.pumpAndSettle();

    expect(find.text('COLOMBIA'), findsOneWidget);
    expect(find.byIcon(_flecha), findsNothing);
  });

  testWidgets('la selección de perfil regresa a la segunda pantalla',
      (tester) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.byTooltip('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text(_tituloSeleccion), findsOneWidget);
    expect(find.byIcon(_flecha), findsOneWidget);

    await tester.tap(find.byIcon(_flecha));
    await tester.pumpAndSettle();

    // Vuelve a la segunda pantalla (no a la primera) y sin pantallas repetidas.
    expect(find.text(_tituloOnboarding2), findsOneWidget);
    expect(find.text(_tituloSeleccion), findsNothing);
  });

  testWidgets('la selección de perfil sin pantalla anterior no muestra flecha',
      (tester) async {
    setScreenSize(tester, 420, 1100);
    final env = TestEnv();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => env.sessionBloc()..add(SessionStarted()),
          child: const ProfileSelectionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_tituloSeleccion), findsOneWidget);
    expect(find.byIcon(_flecha), findsNothing);
  });

  testWidgets('la imagen de la segunda pantalla se ajusta sin recortarse',
      (tester) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.byTooltip('Continuar'));
    await tester.pumpAndSettle();

    final imagen = tester.widget<Image>(find.byType(Image));
    expect(imagen.fit, BoxFit.contain);
  });
}