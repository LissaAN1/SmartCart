import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';

import '../support/fakes.dart';

/// Comprueba que los archivos de docs/ejemplos hacen lo que ahí decimos, para
/// que quien los use para probar la app sepa qué resultado esperar.
void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
    // Las seis categorías que siembra docs/sql/sprint2_hu10.sql.
    env.catalogo.categoriasDisponibles = [
      for (final nombre in [
        'Super',
        'Frutas',
        'Lácteos',
        'Aseo',
        'Café',
        'Panadería',
      ])
        Categoria(id: 'cat-$nombre', nombre: nombre),
    ];
  });

  String leer(String archivo) =>
      File('docs/ejemplos/$archivo').readAsStringSync();

  test('productos_validos.csv carga 45 productos sin errores', () async {
    final resultado = await env.cargarProductosCsv(leer('productos_validos.csv'));

    expect(resultado.cargados, 45);
    expect(resultado.errores, isEmpty);
    expect(env.catalogo.deComercio('c1').length, 45);
  });

  test('productos_con_errores.csv solo: carga 4 y reporta 7 filas', () async {
    final resultado =
        await env.cargarProductosCsv(leer('productos_con_errores.csv'));

    expect(resultado.cargados, 4);
    expect(resultado.errores.map((e) => e.fila), [3, 4, 5, 6, 8, 9, 11]);
  });

  test('productos_con_errores.csv después de los válidos: carga 3 y reporta 8',
      () async {
    await env.cargarProductosCsv(leer('productos_validos.csv'));

    final resultado =
        await env.cargarProductosCsv(leer('productos_con_errores.csv'));

    expect(resultado.cargados, 3);
    expect(resultado.errores.map((e) => e.fila), [2, 3, 4, 5, 6, 8, 9, 11]);
    expect(resultado.errores.first.motivo, contains('Ya tienes'));
  });
}
