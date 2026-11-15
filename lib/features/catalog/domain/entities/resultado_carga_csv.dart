/// Una fila del archivo que no se pudo cargar y la razón.
class ErrorFilaCsv {
  /// Número de la fila en el archivo; la primera es el encabezado.
  final int fila;
  final String motivo;

  const ErrorFilaCsv({required this.fila, required this.motivo});
}

/// Lo que pasó al cargar un CSV: las filas válidas se cargan y las demás se
/// reportan para que el comercio las corrija.
class ResultadoCargaCsv {
  final int cargados;
  final List<ErrorFilaCsv> errores;

  const ResultadoCargaCsv({required this.cargados, required this.errores});
}

/// Archivo que eligió la persona, ya leído como texto.
class ArchivoCsv {
  final String nombre;
  final String contenido;

  const ArchivoCsv({required this.nombre, required this.contenido});
}
