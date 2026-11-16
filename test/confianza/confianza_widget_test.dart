import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/confianza/presentation/widgets/confianza_del_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';

import '../support/pump_helpers.dart';

/// "Hoy" de las pruebas: 15 de noviembre de 2026, a mediodía.
final _ahora = DateTime(2026, 11, 15, 12);

Future<void> _pump(
  WidgetTester tester, {
  FuentePrecio fuente = FuentePrecio.comercio,
  DateTime? actualizadoEn,
  VoidCallback? onReportar,
  bool reportado = false,
  bool enviando = false,
  double ancho = 420,
}) async {
  setScreenSize(tester, ancho, 900);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ConfianzaDelPrecio(
            fuente: fuente,
            actualizadoEn: actualizadoEn ?? DateTime(2026, 11, 15, 9, 30),
            ahora: _ahora,
            onReportar: onReportar,
            reportado: reportado,
            enviando: enviando,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Escenario 1: precio reciente de un comercio', () {
    testWidgets('muestra la fuente, la fecha de hoy y confianza alta',
        (tester) async {
      await _pump(tester);

      expect(find.text('Fuente: Comercio'), findsOneWidget);
      expect(find.text('Actualizado 15 nov 2026 · 09:30 (hoy)'), findsOneWidget);
      expect(find.text('Confianza alta'), findsOneWidget);
      expect(find.text('Desactualizado'), findsNothing);
    });
  });

  group('Escenario 2: precio desactualizado', () {
    testWidgets('lo marca desactualizado y baja la confianza', (tester) async {
      await _pump(tester, actualizadoEn: DateTime(2026, 11, 3, 8));

      expect(find.text('Desactualizado'), findsOneWidget);
      expect(find.text('Confianza baja'), findsOneWidget);
      expect(find.text('Confianza alta'), findsNothing);
      expect(find.text('Actualizado 3 nov 2026 · 08:00 (hace 12 días)'),
          findsOneWidget);
    });

    testWidgets('con 5 días todavía no está desactualizado: confianza media',
        (tester) async {
      await _pump(tester, actualizadoEn: DateTime(2026, 11, 10, 8));

      expect(find.text('Confianza media'), findsOneWidget);
      expect(find.text('Desactualizado'), findsNothing);
    });
  });

  group('La fuente se muestra como Comercio o Comunidad', () {
    testWidgets('un precio de colaborador sale como Comunidad', (tester) async {
      await _pump(tester, fuente: FuentePrecio.colaborador);

      expect(find.text('Fuente: Comunidad'), findsOneWidget);
      expect(find.text('Fuente: Colaborador'), findsNothing);
      // La comunidad nunca llega a confianza alta.
      expect(find.text('Confianza media'), findsOneWidget);
    });
  });

  group('Escenario 3: botón "Reportar precio incorrecto"', () {
    testWidgets('si se pasa onReportar, el botón está y avisa al tocarlo',
        (tester) async {
      var toques = 0;
      await _pump(tester, onReportar: () => toques++);

      await tester.tap(find.text('Reportar precio incorrecto'));

      expect(toques, 1);
    });

    testWidgets('sin onReportar no hay botón', (tester) async {
      await _pump(tester);

      expect(find.text('Reportar precio incorrecto'), findsNothing);
    });

    testWidgets('ya reportado: dice "Reporte enviado" y no se puede repetir',
        (tester) async {
      var toques = 0;
      await _pump(tester, onReportar: () => toques++, reportado: true);

      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(find.text('Reportar precio incorrecto'), findsNothing);
      expect(toques, 0);
    });

    testWidgets('mientras se envía, el botón no acepta otro toque',
        (tester) async {
      var toques = 0;
      await _pump(tester, onReportar: () => toques++, enviando: true);

      await tester.tap(find.text('Reportar precio incorrecto'));

      expect(toques, 0);
    });
  });

  group('En pantallas angostas', () {
    testWidgets('en 320 px no hay desbordes, ni siquiera con todo a la vez',
        (tester) async {
      await _pump(
        tester,
        ancho: 320,
        fuente: FuentePrecio.colaborador,
        actualizadoEn: DateTime(2026, 10, 1),
        onReportar: () {},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Desactualizado'), findsOneWidget);
    });
  });
}
