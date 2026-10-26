import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/register/ui/screens/register_screen.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

final _submitButton = find.widgetWithText(FilledButton, 'Crear cuenta');

Future<TestEnv> _pumpRegister(
  WidgetTester tester, {
  UserRole? initialRole,
  double width = 420,
  double height = 900,
}) async {
  setScreenSize(tester, width, height);
  final env = TestEnv();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<RegisterBloc>(
        create: (_) => env.registerBloc(),
        child: RegisterScreen(initialRole: initialRole),
      ),
    ),
  );
  return env;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _fillValid(WidgetTester tester, {String confirm = 'clave1234'}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Ana Gómez');
  await tester.enterText(fields.at(1), 'ana@correo.com');
  await tester.enterText(fields.at(2), '+57 300 000 0000');
  await tester.enterText(fields.at(3), 'clave1234');
  await tester.enterText(fields.at(4), confirm);
  await _tapVisible(tester, find.byType(Checkbox));
}

void main() {
  testWidgets('con el formulario vacío muestra todos los errores',
      (tester) async {
    final env = await _pumpRegister(tester);

    await _tapVisible(tester, _submitButton);

    expect(find.text('Escribe tu nombre completo'), findsOneWidget);
    expect(find.text('Escribe tu correo electrónico'), findsOneWidget);
    expect(find.text('Escribe una contraseña'), findsOneWidget);
    expect(find.text('Repite tu contraseña'), findsOneWidget);
    expect(find.text('Debes aceptar los términos y la política de privacidad'),
        findsOneWidget);
    expect(env.auth.signUpCalls, 0);
  });

  testWidgets('avisa cuando las contraseñas no coinciden', (tester) async {
    final env = await _pumpRegister(tester);

    await _fillValid(tester, confirm: 'otraclave99');
    await _tapVisible(tester, _submitButton);

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(env.auth.signUpCalls, 0);
  });

  testWidgets('registra con el perfil elegido y entra a su Home',
      (tester) async {
    final env = await _pumpRegister(tester);

    await _tapVisible(tester, find.text('Comercio'));
    await _fillValid(tester);
    await _tapVisible(tester, _submitButton);
    await tester.pumpAndSettle();

    expect(env.profiles.created.single.roles, {UserRole.comercio});
    expect(env.profiles.created.single.phone, '+57 300 000 0000');
    expect(find.text('HOME comercio'), findsOneWidget);
  });

  testWidgets('preselecciona el perfil del login del que se llegó',
      (tester) async {
    final env = await _pumpRegister(tester, initialRole: UserRole.repartidor);

    await _fillValid(tester);
    await _tapVisible(tester, _submitButton);
    await tester.pumpAndSettle();

    expect(env.profiles.created.single.roles, {UserRole.repartidor});
  });
  
  testWidgets('el administrador no aparece entre los perfiles de registro',
      (tester) async {
    final env = await _pumpRegister(tester);

    expect(find.text('Administrador'), findsNothing);
    expect(find.text('Lo asigna SmartCart'), findsNothing);

    await _fillValid(tester);
    await _tapVisible(tester, _submitButton);
    await tester.pumpAndSettle();

    expect(env.profiles.created.single.roles, {UserRole.cliente});
  });

  testWidgets('muestra el error del registro y deja corregir', (tester) async {
    final env = await _pumpRegister(tester);
    env.auth.signUpError =
        const AuthFailure('Ya existe una cuenta con este correo.');

    await _fillValid(tester);
    await _tapVisible(tester, _submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Ya existe una cuenta con este correo.'), findsOneWidget);
    expect(find.textContaining('HOME'), findsNothing);
  });

  testWidgets('mientras carga no permite enviar de nuevo', (tester) async {
    final env = await _pumpRegister(tester);
    env.auth.gate = Completer<void>();

    await _fillValid(tester);
    await _tapVisible(tester, _submitButton);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
    await tester.pump();
    expect(env.auth.signUpCalls, 1);

    env.auth.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('permite desplazarse en pantalla baja con el teclado abierto',
      (tester) async {
    await _pumpRegister(tester, width: 320, height: 480);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Continuar con Google'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en escritorio el formulario no se estira de lado a lado',
      (tester) async {
    await _pumpRegister(tester, width: 1400, height: 900);

    final width = tester.getSize(find.byType(AutofillGroup)).width;
    expect(width, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });
}
