import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Los perfiles muestran los datos reales de la cuenta, sin cifras de ejemplo.
Future<TestEnv> _pump(
  WidgetTester tester, {
  required UserRole role,
  required Profile profile,
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 1400);
  final env = TestEnv();
  env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SessionBloc>(create: (_) => env.sessionBloc()),
          if (role == UserRole.comercio)
            BlocProvider<ComercioBloc>(
              create: (_) => env.comercioBloc()..add(ComercioStarted()),
            ),
          if (role == UserRole.repartidor)
            BlocProvider<DisponibilidadBloc>(
              create: (_) =>
                  env.disponibilidadBloc(inicial: profile.courierAvailable),
            ),
        ],
        child: RolShell(rol: role, profile: profile),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _perfil(WidgetTester tester) async {
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

final _desde = DateTime(2026, 11, 3);

void main() {
  testWidgets('cliente: nombre, correo, calificación y fecha reales, sin '
      'tarjeta de ejemplo', (tester) async {
    await _pump(
      tester,
      role: UserRole.cliente,
      profile: profileWith({UserRole.cliente},
          rating: 4.5, ratingCount: 8, memberSince: _desde),
    );
    await _perfil(tester);

    expect(find.text('Ana María Gómez'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('Desde nov 2026'), findsOneWidget);
    expect(find.textContaining('4.5'), findsOneWidget);
    expect(find.textContaining('4242'), findsNothing);
  });

  testWidgets('colaborador: puntos, nivel y reputación reales y nada de '
      'ganancias inventadas', (tester) async {
    await _pump(
      tester,
      role: UserRole.colaborador,
      profile: profileWith(
        {UserRole.colaborador},
        collaborator:
            const CollaboratorStats(points: 40, level: 2, reputation: 3),
        memberSince: _desde,
      ),
    );
    await _perfil(tester);

    expect(find.text('40'), findsOneWidget);
    expect(find.text('PUNTOS'), findsOneWidget);
    expect(find.text('Desde nov 2026'), findsOneWidget);
    expect(find.textContaining('18.500'), findsNothing);
    expect(find.textContaining('2.450'), findsNothing);
  });

  group('repartidor aprobado', () {
    final aprobado = profileWith(
      {UserRole.repartidor},
      courierStatus: ApprovalStatus.aprobado,
      rating: 4.8,
      ratingCount: 12,
      memberSince: _desde,
    );

    testWidgets('el perfil muestra su calificación, reseñas y antigüedad '
        'reales', (tester) async {
      await _pump(tester, role: UserRole.repartidor, profile: aprobado);
      await _perfil(tester);

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('nov 2026'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsWidgets);
      expect(find.textContaining('1.240'), findsNothing);
      expect(find.textContaining('ABC-12D'), findsNothing);
      expect(find.textContaining('12.900'), findsNothing);
    });

    testWidgets('sin calificaciones muestra un guion, no un número inventado',
        (tester) async {
      await _pump(
        tester,
        role: UserRole.repartidor,
        profile: profileWith({UserRole.repartidor},
            courierStatus: ApprovalStatus.aprobado),
      );
      await _perfil(tester);

      expect(find.text('—'), findsWidgets);
      expect(find.text('4.9'), findsNothing);
    });

    testWidgets('el Home parte con la disponibilidad guardada (el resto del '
        'diseño se conserva)', (tester) async {
      await _pump(
        tester,
        role: UserRole.repartidor,
        profile: profileWith({UserRole.repartidor},
            courierStatus: ApprovalStatus.aprobado, courierAvailable: true),
      );

      expect(find.text('Estás en línea'), findsOneWidget);
      // Diseño original: resumen del día y pedidos de ejemplo.
      expect(find.text('Pedidos Disponibles'), findsOneWidget);
      expect(find.textContaining('38.400'), findsOneWidget);
    });

    testWidgets('el interruptor guarda la disponibilidad', (tester) async {
      final env = await _pump(tester, role: UserRole.repartidor, profile: aprobado);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(env.profiles.availabilityCalls, [true]);
      expect(find.text('Estás en línea'), findsOneWidget);
    });

    testWidgets('si falla el guardado avisa y conserva el valor',
        (tester) async {
      final env = await _pump(
        tester,
        role: UserRole.repartidor,
        profile: aprobado,
        prepare: (env) => env.profiles.availabilityError = const AuthFailure(
            'Solo un repartidor aprobado puede cambiar su disponibilidad.'),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(env.profiles.availabilityCalls, isEmpty);
      expect(find.text('Estás desconectado'), findsOneWidget);
      expect(find.textContaining('Solo un repartidor aprobado'),
          findsOneWidget);
    });
  });

  group('comercio aprobado', () {
    Future<void> pumpComercio(WidgetTester tester) => _pump(
          tester,
          role: UserRole.comercio,
          profile: profileWith({UserRole.comercio}),
          prepare: (env) => env.comercios.stored =
              comercioConEstado(ApprovalStatus.aprobado),
        );

    testWidgets('el Home usa el nombre real del comercio y conserva su '
        'diseño original', (tester) async {
      await pumpComercio(tester);

      expect(find.text('Panel del comercio'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.textContaining('840.000'), findsOneWidget);
      expect(find.text('Órdenes Recientes'), findsOneWidget);
    });

    testWidgets('el perfil muestra los datos registrados del comercio',
        (tester) async {
      await pumpComercio(tester);
      await _perfil(tester);

      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('07:00 - 20:00'), findsOneWidget);
      expect(find.text('Calle 10 # 5-20, Cali, San Fernando'), findsOneWidget);
      expect(find.text('Ana María Gómez'), findsOneWidget);
      expect(find.textContaining('Mercado Local Centro'), findsNothing);
      expect(find.textContaining('120+'), findsNothing);
    });
  });

  testWidgets('administrador: datos de contacto reales y sin gráfico de '
      'ejemplo', (tester) async {
    await _pump(
      tester,
      role: UserRole.administrador,
      profile: profileWith({UserRole.administrador}, memberSince: _desde),
    );
    await _perfil(tester);

    expect(find.text('Ana María Gómez'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('+57 300 000 0000'), findsOneWidget);
    expect(find.text('Actividad semanal'), findsNothing);
  });
}
