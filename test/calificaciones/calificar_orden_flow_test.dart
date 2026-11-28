import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_args.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_page.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/comercio/presentation/pages/comercio_perfil_screen.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/presentation/pages/mis_ordenes_page.dart';

import '../support/fakes.dart';
import '../support/fakes_ordenes.dart';
import '../support/pump_helpers.dart';

Future<CalificarOrdenState> _hasta(
  CalificarOrdenBloc bloc,
  CalificarOrdenStatus status,
) =>
    bloc.stream.firstWhere((s) => s.status == status);

/// Monta [CalificarOrdenPage] como una ruta que devuelve `bool`, para ver lo
/// que devuelve al cerrarse.
Future<(TestEnv, CalificarOrdenBloc, ValueNotifier<bool?>)> _pumpCalificar(
  WidgetTester tester, {
  TipoCalificacion tipo = TipoCalificacion.comercio,
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 900);
  final env = TestEnv()..iniciarSesionComoClienteConCompras();
  prepare?.call(env);
  final bloc = env.calificarOrdenBloc('o1', tipo);
  addTearDown(bloc.close);
  final resultado = ValueNotifier<bool?>(null);
  final args = CalificarOrdenArgs(
    idOrden: 'o1',
    numeroOrden: 1001,
    comercio: 'Minimercado La Esquina',
    tipo: tipo,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                resultado.value = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: CalificarOrdenPage(args: args),
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return (env, bloc, resultado);
}

Finder _estrella(int n) =>
    find.byTooltip(n == 1 ? '1 estrella' : '$n estrellas');

bool _enviarHabilitado(WidgetTester tester) => tester
        .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enviar calificación'))
        .onPressed !=
    null;

void main() {
  group('CalificarOrdenBloc', () {
    test('sin elegir estrellas no se puede enviar', () {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final bloc = env.calificarOrdenBloc('o1', TipoCalificacion.comercio);

      expect(bloc.state.puedeEnviar, isFalse);
      bloc.close();
    });

    test('elegir estrellas habilita el envío y el comentario es opcional',
        () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final bloc = env.calificarOrdenBloc('o1', TipoCalificacion.comercio);

      bloc.add(EstrellasElegidas(4));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.estrellas, 4);
      expect(bloc.state.puedeEnviar, isTrue);
      await bloc.close();
    });

    test('un comentario de más de 500 caracteres bloquea el envío', () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final bloc = env.calificarOrdenBloc('o1', TipoCalificacion.comercio);

      bloc
        ..add(EstrellasElegidas(5))
        ..add(ComentarioCambiado('a' * 501));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.puedeEnviar, isFalse);
      await bloc.close();
    });

    test('enviar califica una sola vez aunque se toque dos veces', () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final bloc = env.calificarOrdenBloc('o1', TipoCalificacion.repartidor);

      bloc
        ..add(EstrellasElegidas(5))
        ..add(ComentarioCambiado('Muy rápido'))
        ..add(CalificacionEnviada())
        ..add(CalificacionEnviada());
      final state = await _hasta(bloc, CalificarOrdenStatus.enviada);

      expect(state.resumen!.promedio, 5.0);
      expect(env.ordenes.calificaciones.calls, 1);
      expect(env.ordenes.calificaciones.enviadas.single.tipo,
          TipoCalificacion.repartidor);
      await bloc.close();
    });

    test('si la orden ya estaba calificada vuelve a editar con el motivo',
        () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.ordenes.calificaciones.error =
          const AuthFailure('Ya calificaste esta orden.');
      final bloc = env.calificarOrdenBloc('o1', TipoCalificacion.comercio);

      bloc
        ..add(EstrellasElegidas(3))
        ..add(CalificacionEnviada());
      final state = await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(state.status, CalificarOrdenStatus.editando);
      expect(state.errorMessage, 'Ya calificaste esta orden.');
      expect(state.estrellas, 3);
      await bloc.close();
    });
  });

  group('CalificarOrdenPage', () {
    testWidgets('muestra 5 estrellas y el comentario opcional; enviar espera',
        (tester) async {
      await _pumpCalificar(tester);

      expect(find.text('Calificar al comercio'), findsOneWidget);
      expect(find.text('Orden #1001 · Minimercado La Esquina'), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        expect(_estrella(i), findsOneWidget);
      }
      expect(find.text('Comentario (opcional)'), findsOneWidget);
      expect(_enviarHabilitado(tester), isFalse);
    });

    testWidgets('al repartidor se le califica con su propio título',
        (tester) async {
      await _pumpCalificar(tester, tipo: TipoCalificacion.repartidor);

      expect(find.text('Calificar al repartidor'), findsOneWidget);
      expect(find.text('¿Cómo fue la entrega?'), findsOneWidget);
    });

    testWidgets('tocar una estrella marca hasta ella y habilita enviar',
        (tester) async {
      await _pumpCalificar(tester);

      await tester.tap(_estrella(4));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(_enviarHabilitado(tester), isTrue);
    });

    testWidgets('enviar guarda estrellas y comentario y se cierra con true',
        (tester) async {
      final (env, _, resultado) = await _pumpCalificar(tester);

      await tester.tap(_estrella(5));
      await tester.enterText(find.byType(TextField), '  Excelente  ');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      final enviada = env.ordenes.calificaciones.enviadas.single;
      expect(enviada.estrellas, 5);
      expect(enviada.comentario, 'Excelente');
      expect(resultado.value, isTrue);
      expect(find.text('¡Gracias por tu calificación!'), findsOneWidget);
    });

    testWidgets('sin comentario también se puede enviar', (tester) async {
      final (env, _, resultado) = await _pumpCalificar(tester);

      await tester.tap(_estrella(2));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(env.ordenes.calificaciones.enviadas.single.comentario, isNull);
      expect(resultado.value, isTrue);
    });

    testWidgets('si la base rechaza muestra el motivo y no se cierra',
        (tester) async {
      final (_, _, resultado) = await _pumpCalificar(
        tester,
        prepare: (env) => env.ordenes.calificaciones.error = const AuthFailure(
            'Solo puedes calificar una orden completada.'),
      );

      await tester.tap(_estrella(3));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(find.text('Solo puedes calificar una orden completada.'),
          findsOneWidget);
      expect(find.text('Calificar al comercio'), findsOneWidget);
      expect(resultado.value, isNull);
    });
  });

  group('MisOrdenesPage', () {
    Future<(TestEnv, PaginatedBloc<Orden>)> pumpOrdenes(
      WidgetTester tester,
      List<Orden> ordenes,
    ) async {
      setScreenSize(tester, 420, 1400);
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.ordenes.compras.ordenes.addAll(ordenes);
      final bloc = env.misOrdenesBloc()..add(PaginatedStarted());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.calificarOrden) {
              final args = settings.arguments as CalificarOrdenArgs;
              return MaterialPageRoute<bool>(
                settings: settings,
                builder: (_) => Scaffold(
                  body: Column(
                    children: [
                      Text('CALIFICAR ${args.tipo.dbName} ${args.idOrden}'),
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('listo'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return stubRoutes(settings);
          },
          home: BlocProvider.value(value: bloc, child: const MisOrdenesPage()),
        ),
      );
      await tester.pumpAndSettle();
      return (env, bloc);
    }

    testWidgets('sin órdenes lo dice', (tester) async {
      await pumpOrdenes(tester, const []);

      expect(find.textContaining('Aún no tienes órdenes'), findsOneWidget);
    });

    testWidgets('una orden completada ofrece calificar al comercio',
        (tester) async {
      await pumpOrdenes(tester, [ordenDePrueba()]);

      expect(find.text('Orden #1001'), findsOneWidget);
      expect(find.text('Entregada'), findsOneWidget);
      expect(find.text('Calificar al comercio'), findsOneWidget);
      // Sin repartidor no hay a quién calificar de más.
      expect(find.text('Calificar al repartidor'), findsNothing);
    });

    testWidgets('con repartidor se pueden calificar los dos', (tester) async {
      await pumpOrdenes(tester, [ordenDePrueba(tieneRepartidor: true)]);

      expect(find.text('Calificar al comercio'), findsOneWidget);
      expect(find.text('Calificar al repartidor'), findsOneWidget);
    });

    testWidgets('una orden sin completar no se puede calificar',
        (tester) async {
      await pumpOrdenes(tester, [
        ordenDePrueba(
            id: 'o2', numero: 1002, estado: EstadoOrden.generada, tieneRepartidor: true),
        ordenDePrueba(
            id: 'o3', numero: 1003, estado: EstadoOrden.enCamino, tieneRepartidor: true),
      ]);

      expect(find.text('Orden generada'), findsOneWidget);
      expect(find.text('En camino'), findsOneWidget);
      expect(find.textContaining('Calificar al'), findsNothing);
      expect(find.textContaining('Ya calificaste'), findsNothing);
    });

    testWidgets('una orden ya calificada no ofrece calificar otra vez',
        (tester) async {
      await pumpOrdenes(tester, [ordenDePrueba(calificadaComercio: true)]);

      expect(find.text('Calificar al comercio'), findsNothing);
      expect(find.text('Ya calificaste al comercio'), findsOneWidget);
    });

    testWidgets('calificar abre la pantalla y al volver relee la lista',
        (tester) async {
      final (env, _) = await pumpOrdenes(tester, [ordenDePrueba()]);

      await tester.tap(find.text('Calificar al comercio'));
      await tester.pumpAndSettle();
      expect(find.text('CALIFICAR comercio o1'), findsOneWidget);

      // Mientras tanto la orden quedó calificada en la base.
      env.ordenes.compras.ordenes
        ..clear()
        ..add(ordenDePrueba(calificadaComercio: true));
      await tester.tap(find.text('listo'));
      await tester.pumpAndSettle();

      expect(find.text('Calificar al comercio'), findsNothing);
      expect(find.text('Ya calificaste al comercio'), findsOneWidget);
    });
  });

  group('Perfil del comercio · calificación', () {
    Future<void> pumpPerfil(WidgetTester tester, {double? rating, int total = 0}) {
      setScreenSize(tester, 420, 1400);
      return tester.pumpWidget(
        MaterialApp(
          home: ComercioPerfilScreen(
            profile: profileWith({UserRole.comercio},
                rating: rating, ratingCount: total),
            comercio: comercioConEstado(ApprovalStatus.aprobado),
          ),
        ),
      );
    }

    testWidgets('sin calificaciones dice "Sin calificaciones"', (tester) async {
      await pumpPerfil(tester);

      expect(find.text('Sin calificaciones'), findsOneWidget);
    });

    testWidgets('con calificaciones muestra el promedio y el total',
        (tester) async {
      await pumpPerfil(tester, rating: 4.5, total: 12);

      expect(find.text('Sin calificaciones'), findsNothing);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(12)'), findsOneWidget);
    });
  });
}
