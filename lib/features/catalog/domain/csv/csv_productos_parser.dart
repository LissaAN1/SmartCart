import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

/// Una fila del CSV tal como viene escrita, sin validar todavía.
class FilaCsv {
  final int numero;
  final String nombre;
  final String marca;
  final String codigoBarras;
  final String categoria;

  const FilaCsv({
    required this.numero,
    required this.nombre,
    required this.marca,
    required this.codigoBarras,
    required this.categoria,
  });
}

/// Lee el texto de un CSV de productos. Solo se ocupa del formato del
/// archivo; que cada fila cumpla las reglas del negocio lo decide
/// `CargarProductosCsvUseCase`.
///
/// Formato: la primera fila es el encabezado, con las columnas `nombre` y
/// `categoria` (obligatorias) y `marca` y `codigo_barras` (opcionales), en
/// cualquier orden. Acepta coma o punto y coma, porque Excel en español
/// guarda con punto y coma, y campos entre comillas.
abstract final class CsvProductosParser {
  /// Tope por archivo para no mandar miles de filas en una sola carga.
  static const maxFilas = 500;

  static List<FilaCsv> leer(String contenido) {
    final texto =
        contenido.startsWith('﻿') ? contenido.substring(1) : contenido;
    if (texto.trim().isEmpty) {
      throw const AuthFailure('El archivo está vacío.');
    }

    final registros = _registros(texto, _separador(texto));
    final encabezado = registros.first
        .map((c) => c.trim().toLowerCase().replaceAll(' ', '_'))
        .toList();
    final iNombre = encabezado.indexOf('nombre');
    final iCategoria = encabezado.indexOf('categoria');
    if (iNombre < 0 || iCategoria < 0) {
      throw const AuthFailure(
        'La primera fila debe tener las columnas "nombre" y "categoria".',
      );
    }
    final iMarca = encabezado.indexOf('marca');
    final iCodigo = encabezado.indexOf('codigo_barras');

    String celda(List<String> fila, int i) =>
        i < 0 || i >= fila.length ? '' : fila[i].trim();

    final filas = <FilaCsv>[];
    for (var i = 1; i < registros.length; i++) {
      final registro = registros[i];
      // Las líneas en blanco se ignoran, pero siguen contando para el número
      // de fila que se le muestra a la persona.
      if (registro.every((c) => c.trim().isEmpty)) continue;
      filas.add(FilaCsv(
        numero: i + 1,
        nombre: celda(registro, iNombre),
        marca: celda(registro, iMarca),
        codigoBarras: celda(registro, iCodigo),
        categoria: celda(registro, iCategoria),
      ));
    }

    if (filas.isEmpty) {
      throw const AuthFailure('El archivo no tiene productos para cargar.');
    }
    if (filas.length > maxFilas) {
      throw const AuthFailure(
        'El archivo tiene más de $maxFilas productos. Divídelo en varios.',
      );
    }
    return filas;
  }

  /// Punto y coma si abunda más que la coma en el encabezado.
  static String _separador(String texto) {
    final fin = texto.indexOf('\n');
    final primera = fin < 0 ? texto : texto.substring(0, fin);
    final puntoYComa = ';'.allMatches(primera).length;
    final coma = ','.allMatches(primera).length;
    return puntoYComa > coma ? ';' : ',';
  }

  /// Parte el texto en registros y campos respetando las comillas: dentro de
  /// unas comillas el separador y los saltos de línea son parte del texto, y
  /// `""` es una comilla.
  static List<List<String>> _registros(String texto, String separador) {
    final registros = <List<String>>[];
    var campos = <String>[];
    final campo = StringBuffer();
    var entreComillas = false;

    void cerrarCampo() {
      campos.add(campo.toString());
      campo.clear();
    }

    void cerrarRegistro() {
      cerrarCampo();
      registros.add(campos);
      campos = <String>[];
    }

    for (var i = 0; i < texto.length; i++) {
      final c = texto[i];
      if (entreComillas) {
        if (c == '"') {
          if (i + 1 < texto.length && texto[i + 1] == '"') {
            campo.write('"');
            i++;
          } else {
            entreComillas = false;
          }
        } else {
          campo.write(c);
        }
      } else if (c == '"') {
        entreComillas = true;
      } else if (c == separador) {
        cerrarCampo();
      } else if (c == '\n') {
        cerrarRegistro();
      } else if (c != '\r') {
        campo.write(c);
      }
    }
    // El último registro no siempre termina con salto de línea.
    if (campo.isNotEmpty || campos.isNotEmpty) cerrarRegistro();
    return registros;
  }
}
