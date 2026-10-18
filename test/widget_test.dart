import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartcart/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('Home permite entrar a un rol y volver al cerrar sesión',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    expect(find.text('Selecciona tu perfil para continuar'), findsOneWidget);

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona tu perfil para continuar'), findsNothing);
  });
}
