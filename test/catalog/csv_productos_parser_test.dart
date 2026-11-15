import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/csv/csv_productos_parser.dart';

void main() {
  group('CsvProductosParser', () {
    test('lee un archivo con coma como separador', () {
      final filas = CsvProductosParser.leer(
        'nombre,marca,codigo_barras,categoria\n'
        'Arroz blanco,Diana,7701234567890,Super\n'
        'Leche entera,Alpina,,Lácteos\n',
      );

      expect(filas.length, 2);
      expect(filas[0].nombre, 'Arroz blanco');
      expect(filas[0].marca, 'Diana');
      expect(filas[0].codigoBarras, '7701234567890');
      expect(filas[0].categoria, 'Super');
      expect(filas[1].codigoBarras, '');
      expect(filas[1].categoria, 'Lácteos');
    });

    test('numera las filas empezando en 2, porque la 1 es el encabezado', () {
      final filas = CsvProductosParser.leer(
        'nombre,categoria\nA producto,Super\nB producto,Aseo\n',
      );

      expect(filas.map((f) => f.numero), [2, 3]);
    });

    test('acepta punto y coma, el separador que guarda Excel en español', () {
      final filas = CsvProductosParser.leer(
        'nombre;marca;codigo_barras;categoria\n'
        'Café molido;Juan Valdez;7709990001112;Café\n',
      );

      expect(filas.single.nombre, 'Café molido');
      expect(filas.single.marca, 'Juan Valdez');
      expect(filas.single.categoria, 'Café');
    });

    test('las columnas pueden venir en otro orden y las opcionales faltar', () {
      final filas = CsvProductosParser.leer(
        'categoria,nombre\nFrutas,Mango tommy\n',
      );

      expect(filas.single.nombre, 'Mango tommy');
      expect(filas.single.categoria, 'Frutas');
      expect(filas.single.marca, '');
      expect(filas.single.codigoBarras, '');
    });

    test('el encabezado no distingue mayúsculas ni espacios de más', () {
      final filas = CsvProductosParser.leer(
        ' Nombre , Codigo Barras , CATEGORIA \nSal marina,,Super\n',
      );

      expect(filas.single.nombre, 'Sal marina');
      expect(filas.single.codigoBarras, '');
      expect(filas.single.categoria, 'Super');
    });

    test('respeta los campos entre comillas con comas y comillas dobles', () {
      final filas = CsvProductosParser.leer(
        'nombre,marca,categoria\n'
        '"Galletas, sabor ""vainilla""",Noel,Panadería\n',
      );

      expect(filas.single.nombre, 'Galletas, sabor "vainilla"');
      expect(filas.single.marca, 'Noel');
    });

    test('maneja saltos de línea de Windows y el BOM del inicio', () {
      final filas = CsvProductosParser.leer(
        '﻿nombre,categoria\r\nArroz largo,Super\r\nLeche entera,Lácteos\r\n',
      );

      expect(filas.length, 2);
      expect(filas.first.nombre, 'Arroz largo');
    });

    test('ignora las líneas en blanco pero conserva la numeración', () {
      final filas = CsvProductosParser.leer(
        'nombre,categoria\nArroz largo,Super\n\n,\nLeche entera,Lácteos',
      );

      expect(filas.map((f) => f.numero), [2, 5]);
    });

    test('un archivo vacío falla con un mensaje claro', () {
      expect(
        () => CsvProductosParser.leer('  \n '),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('sin las columnas obligatorias falla', () {
      expect(
        () => CsvProductosParser.leer('nombre,marca\nArroz largo,Diana\n'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('"nombre" y "categoria"'),
        )),
      );
    });

    test('solo con encabezado no hay productos para cargar', () {
      expect(
        () => CsvProductosParser.leer('nombre,categoria\n'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('rechaza archivos con más filas que el máximo', () {
      final cuerpo = List.generate(
        CsvProductosParser.maxFilas + 1,
        (i) => 'Producto $i,Super',
      ).join('\n');

      expect(
        () => CsvProductosParser.leer('nombre,categoria\n$cuerpo'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        CsvProductosParser.leer(
          'nombre,categoria\n'
          '${List.generate(CsvProductosParser.maxFilas, (i) => 'Producto $i,Super').join('\n')}',
        ).length,
        CsvProductosParser.maxFilas,
      );
    });
  });
}
