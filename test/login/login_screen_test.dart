import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/login/ui/screens/login_screen.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pumpLogin(WidgetTester tester, UserRole role) async {
  setScreenSize(tester, 420, 900);
  final env = TestEnv();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<LoginBloc>(
        create: (_) => env.loginBloc(),
        child: LoginScreen(role: role),
      ),
    ),
  );
  return env;
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'ana@correo.com');
  await tester.enterText(fields.at(1), 'clave1234');
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pump();
}

void main() {
  testWidgets('con los campos vacíos muestra los errores y no llama a Supabase',
      (tester) async {
    final env = await _pumpLogin(tester, UserRole.cliente);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pump();

    expect(find.text('Escribe tu correo electrónico'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(env.auth.signInCalls, 0);
  });

  testWidgets('rechaza un correo mal escrito', (tester) async {
    await _pumpLogin(tester, UserRole.cliente);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pump();

    expect(find.text('Escribe un correo válido'), findsOneWidget);
  });

  testWidgets('un inicio de sesión correcto va al Home del perfil elegido',
      (tester) async {
    final env = await _pumpLogin(tester, UserRole.colaborador);
    env.profiles.stored = profileWith({UserRole.colaborador});

    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(env.auth.signInCalls, 1);
    expect(find.text('HOME colaborador'), findsOneWidget);
  });

  testWidgets('muestra el error de credenciales sin salir de la pantalla',
      (tester) async {
    final env = await _pumpLogin(tester, UserRole.cliente);
    env.auth.signInError =
        const AuthFailure('El correo o la contraseña no son correctos.');

    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('El correo o la contraseña no son correctos.'),
        findsOneWidget);
    expect(find.text('Bienvenido a SmartCart'), findsOneWidget);
  });

  testWidgets('un perfil que la cuenta no tiene no entra al Home',
      (tester) async {
    final env = await _pumpLogin(tester, UserRole.administrador);
    env.profiles.stored = profileWith({UserRole.cliente});

    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('no tiene el perfil de Administrador'),
        findsOneWidget);
    expect(find.textContaining('HOME'), findsNothing);
    expect(env.auth.signOutCalls, 1);
  });

  testWidgets('mientras carga muestra el indicador y no reenvía',
      (tester) async {
    final env = await _pumpLogin(tester, UserRole.cliente);
    env.profiles.stored = profileWith({UserRole.cliente});
    env.auth.gate = Completer<void>();

    await _fillAndSubmit(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // El botón ya no acepta toques mientras carga.
    await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
    await tester.pump();
    expect(env.auth.signInCalls, 1);

    env.auth.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('HOME cliente'), findsOneWidget);
  });

  testWidgets('los perfiles con registro ofrecen "Regístrate aquí"',
      (tester) async {
    await _pumpLogin(tester, UserRole.repartidor);

    await tester.ensureVisible(find.text('Regístrate aquí'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regístrate aquí'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTER UserRole.repartidor'), findsOneWidget);
  });

  testWidgets('el administrador no ofrece registro', (tester) async {
    await _pumpLogin(tester, UserRole.administrador);

    expect(find.text('Regístrate aquí'), findsNothing);
    expect(find.textContaining('las asigna el equipo de SmartCart'),
        findsOneWidget);
  });

  testWidgets('el mismo formulario usa el color de cada perfil',
      (tester) async {
    await _pumpLogin(tester, UserRole.comercio);
    final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
    final background = button.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(background, const Color(0xFFD6337A));
  });

  testWidgets('en pantalla pequeña con teclado abierto todo sigue alcanzable',
      (tester) async {
    setScreenSize(tester, 320, 480);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    final env = TestEnv();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginBloc>(
          create: (_) => env.loginBloc(),
          child: const LoginScreen(role: UserRole.cliente),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.textContaining('Al continuar, aceptas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
