import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_onboarding_page.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Monta el RolShell con los Bloc que le provee el router en la app real.
Future<TestEnv> _pumpShell(
  WidgetTester tester, {
  required UserRole role,
  required Profile profile,
  void Function(TestEnv env)? prepare,
  RouteFactory onGenerateRoute = stubRoutes,
}) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv();
  env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: onGenerateRoute,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionBloc>(create: (_) => env.sessionBloc()),
          if (role == UserRole.comercio)
            BlocProvider<ComercioBloc>(
              create: (_) => env.comercioBloc()..add(ComercioStarted()),
            ),
          if (role == UserRole.repartidor)
            BlocProvider<DisponibilidadBloc>(
              create: (_) => env.disponibilidadBloc(
                  inicial: profile.courierAvailable),
            ),
        ],
        child: RolShell(rol: role, profile: profile),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _abrirPerfil(WidgetTester tester) async {
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

void main() {
  group('HU-06 · modo Colaborador desde el perfil del cliente', () {
    testWidgets('el cliente ve la opción de activar el modo', (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.cliente,
        profile: profileWith({UserRole.cliente}),
      );
      await _abrirPerfil(tester);

      expect(find.text('Activar modo Colaborador'), findsOneWidget);
      expect(find.text('PUNTOS'), findsNothing);
    });

    testWidgets('tocar la opción abre el onboarding del colaborador',
        (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.cliente,
        profile: profileWith({UserRole.cliente}),
      );
      await _abrirPerfil(tester);

      await tester.tap(find.text('Activar modo Colaborador'));
      await tester.pumpAndSettle();

      expect(find.text('ONBOARDING COLABORADOR'), findsOneWidget);
    });

    testWidgets('si ya es colaborador no aparece la opción y ve sus datos',
        (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.cliente,
        profile: profileWith(
          {UserRole.cliente, UserRole.colaborador},
          collaborator: const CollaboratorStats(
              points: 120, level: 2, reputation: 4.5),
        ),
      );
      await _abrirPerfil(tester);

      expect(find.text('Activar modo Colaborador'), findsNothing);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('PUNTOS'), findsOneWidget);
      expect(find.text('NIVEL'), findsOneWidget);
      expect(find.text('REPUTACIÓN'), findsOneWidget);
    });

    testWidgets('el perfil del colaborador muestra sus puntos, nivel y '
        'reputación reales', (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.colaborador,
        profile: profileWith(
          {UserRole.colaborador},
          collaborator: const CollaboratorStats(
              points: 75, level: 3, reputation: 0),
        ),
      );
      await _abrirPerfil(tester);

      expect(find.text('75'), findsOneWidget);
      expect(find.text('NIVEL'), findsOneWidget);
      expect(find.text('2.450'), findsNothing);
    });
  });

  group('HU-06 · pantalla de onboarding', () {
    /// Abre la página como lo hace el shell y devuelve lo que ella entrega al
    /// cerrarse.
    Future<(TestEnv, ValueNotifier<Profile?>)> pumpOnboarding(
      WidgetTester tester,
    ) async {
      setScreenSize(tester, 420, 1000);
      final env = TestEnv();
      env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
      env.profiles.stored = profileWith({UserRole.cliente});
      final result = ValueNotifier<Profile?>(null);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result.value = await Navigator.of(context).push<Profile>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<ColaboradorOnboardingBloc>(
                        create: (_) => env.colaboradorBloc(),
                        child: const ColaboradorOnboardingPage(),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return (env, result);
    }

    testWidgets('primero muestra la guía corta y luego las condiciones',
        (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('Así funciona reportar un precio'), findsOneWidget);
      expect(find.text('Activar'), findsNothing);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Condiciones de uso'), findsOneWidget);
      expect(find.text('Activar'), findsOneWidget);
    });

    testWidgets('Activar sin aceptar no activa y pide aceptar las condiciones',
        (tester) async {
      final (env, result) = await pumpOnboarding(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Debes aceptar las condiciones'),
          findsOneWidget);
      expect(env.profiles.activateCalls, 0);
      expect(result.value, isNull);
    });

    testWidgets('aceptar y Activar crea el perfil, agrega el rol y devuelve '
        'el perfil actualizado', (tester) async {
      final (env, result) = await pumpOnboarding(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar'));
      await tester.pumpAndSettle();

      expect(env.profiles.activateCalls, 1);
      expect(result.value?.roles, {UserRole.cliente, UserRole.colaborador});
      expect(find.text('abrir'), findsOneWidget); // volvió a la pantalla previa
    });
  });

  group('HU-07 · registro del comercio', () {
    testWidgets('un comercio sin registrar ve el formulario', (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
      );

      expect(find.text('Registra tu comercio'), findsOneWidget);
      expect(find.text('Panel del comercio'), findsNothing);
    });

    testWidgets('dejar campos vacíos muestra los errores y no guarda',
        (tester) async {
      final env = await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
      );

      await tester.ensureVisible(find.text('Registrar'));
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre del establecimiento'),
          findsOneWidget);
      expect(find.text('Escribe la dirección'), findsOneWidget);
      expect(find.text('Elige el tipo de servicio'), findsOneWidget);
      expect(env.comercios.registerCalls, 0);
    });

    testWidgets('completar el formulario guarda el comercio pendiente y '
        'muestra que está en revisión', (tester) async {
      final env = await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
      );

      // Orden del formulario: nombre, teléfono, dirección, ciudad.
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Minimercado La Esquina');
      await tester.enterText(campos.at(1), '+57 300 000 0000');
      await tester.enterText(campos.at(2), 'Calle 10 # 5-20');
      await tester.enterText(campos.at(3), 'Cali, San Fernando');

      await tester.ensureVisible(find.text('Apertura'));
      await tester.tap(find.text('Apertura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cierre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cierre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Recogida y entrega'));
      await tester.tap(find.text('Recogida y entrega'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Registrar'));
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(env.comercios.registerCalls, 1);
      expect(env.comercios.stored?.estado, ApprovalStatus.pendiente);
      expect(env.comercios.stored?.horaApertura, '08:00');
      expect(env.comercios.stored?.horaCierre, '18:00');
      expect(find.text('Tu registro está en revisión'), findsOneWidget);
    });

    testWidgets('un comercio pendiente ve el mensaje de revisión',
        (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
        prepare: (env) => env.comercios.stored =
            comercioConEstado(ApprovalStatus.pendiente),
      );

      expect(find.text('Tu registro está en revisión'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Panel del comercio'), findsNothing);
    });

    testWidgets('un comercio rechazado ve el motivo', (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
        prepare: (env) => env.comercios.stored = comercioConEstado(
          ApprovalStatus.rechazado,
          motivoRechazo: 'Dirección no verificable',
        ),
      );

      expect(find.text('Tu registro fue rechazado'), findsOneWidget);
      expect(find.textContaining('Dirección no verificable'), findsOneWidget);
    });

    testWidgets('un comercio aprobado entra a su panel', (tester) async {
      await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
        prepare: (env) => env.comercios.stored =
            comercioConEstado(ApprovalStatus.aprobado),
      );

      expect(find.text('Panel del comercio'), findsOneWidget);
    });

    testWidgets('desde la pantalla de revisión se puede cerrar sesión',
        (tester) async {
      final env = await _pumpShell(
        tester,
        role: UserRole.comercio,
        profile: profileWith({UserRole.comercio}),
        prepare: (env) => env.comercios.stored =
            comercioConEstado(ApprovalStatus.pendiente),
      );

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(env.auth.signOutCalls, 1);
      expect(find.text('INICIO'), findsOneWidget);
    });
  });

  group('HU-08 · repartidor pendiente', () {
    const aviso = 'Tu registro será revisado por el administrador';

    Future<TestEnv> pumpRepartidor(
      WidgetTester tester, {
      ApprovalStatus? estado = ApprovalStatus.pendiente,
    }) {
      return _pumpShell(
        tester,
        role: UserRole.repartidor,
        profile:
            profileWith({UserRole.repartidor}, courierStatus: estado),
      );
    }

    testWidgets('al entrar solo ve la espera de validación y cerrar sesión',
        (tester) async {
      await pumpRepartidor(tester);

      expect(find.textContaining(aviso), findsOneWidget);
      expect(find.text('Pendiente de aprobación'), findsOneWidget);
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
      // Sin Home, sin Perfil, sin barra de navegación ni disponibilidad.
      expect(find.text('Perfil'), findsNothing);
      expect(find.text('Inicio'), findsNothing);
      expect(find.text('Estás en línea'), findsNothing);
      expect(find.text('Estás desconectado'), findsNothing);
    });

    testWidgets('sin dato de aprobación se trata como pendiente',
        (tester) async {
      await pumpRepartidor(tester, estado: null);

      expect(find.textContaining(aviso), findsOneWidget);
      expect(find.text('Perfil'), findsNothing);
    });

    testWidgets('un repartidor rechazado tampoco accede', (tester) async {
      await pumpRepartidor(tester, estado: ApprovalStatus.rechazado);

      expect(find.text('Tu registro no fue aprobado'), findsOneWidget);
      expect(find.text('Perfil'), findsNothing);
      expect(find.text('Actualizar estado'), findsNothing);
    });

    testWidgets('puede cerrar sesión desde la espera', (tester) async {
      final env = await pumpRepartidor(tester);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(env.auth.signOutCalls, 1);
      expect(find.text('INICIO'), findsOneWidget);
    });

    testWidgets('al ser aprobado y actualizar el estado accede a su Home y '
        'a su perfil', (tester) async {
      final env = await pumpRepartidor(tester);
      env.profiles.stored = profileWith({UserRole.repartidor},
          courierStatus: ApprovalStatus.aprobado);

      await tester.tap(find.text('Actualizar estado'));
      await tester.pumpAndSettle();

      expect(find.text('Estás desconectado'), findsOneWidget);
      expect(find.textContaining(aviso), findsNothing);

      await _abrirPerfil(tester);
      expect(find.text('Aprobado'), findsOneWidget);
    });

    testWidgets('si sigue pendiente al actualizar se queda en la espera',
        (tester) async {
      final env = await pumpRepartidor(tester);
      env.profiles.stored = profileWith({UserRole.repartidor},
          courierStatus: ApprovalStatus.pendiente);

      await tester.tap(find.text('Actualizar estado'));
      await tester.pumpAndSettle();

      expect(find.textContaining(aviso), findsOneWidget);
    });

    testWidgets('si falla la actualización avisa y no cierra la sesión',
        (tester) async {
      final env = await pumpRepartidor(tester);
      env.profiles.getError = const AuthFailure('Sin conexión.');

      await tester.tap(find.text('Actualizar estado'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No pudimos actualizar tu estado'),
          findsOneWidget);
      expect(find.textContaining(aviso), findsOneWidget);
      expect(env.auth.signOutCalls, 0);
    });

    testWidgets('un repartidor aprobado ve su Home y su perfil',
        (tester) async {
      await pumpRepartidor(tester, estado: ApprovalStatus.aprobado);

      expect(find.text('Estás desconectado'), findsOneWidget);
      expect(find.textContaining(aviso), findsNothing);
      await _abrirPerfil(tester);
      expect(find.text('Aprobado'), findsOneWidget);
    });
  });

  test('stubRoutes conoce la ruta del onboarding del colaborador', () {
    expect(
      stubRoutes(const RouteSettings(name: AppRoutes.colaboradorOnboarding)),
      isNotNull,
    );
  });
}
