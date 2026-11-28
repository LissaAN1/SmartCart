/// Reglas de las calificaciones (HU-25).
///
/// La base las vuelve a aplicar en `calificar_orden()`
/// (docs/sql/sprint3_hu20_hu25.sql) con los mismos textos; aquí están como
/// funciones puras para avisar rápido en la pantalla y probarlas. Si cambias
/// una, cámbiala en los dos lados.
abstract final class CalificacionReglas {
  static const estrellasMin = 1;
  static const estrellasMax = 5;
  static const comentarioMax = 500;

  static const mensajeRango = 'La calificación va de 1 a 5 estrellas.';
  static const mensajeComentarioLargo =
      'El comentario puede tener hasta $comentarioMax caracteres.';

  static bool estrellasValidas(int estrellas) =>
      estrellas >= estrellasMin && estrellas <= estrellasMax;

  /// Si la calificación se puede enviar devuelve `null`; si no, el motivo.
  /// El comentario es opcional.
  static String? validar(int estrellas, String? comentario) {
    if (!estrellasValidas(estrellas)) return mensajeRango;
    if ((comentario ?? '').trim().length > comentarioMax) {
      return mensajeComentarioLargo;
    }
    return null;
  }

  /// El comentario sin espacios sobrantes; `null` si quedó vacío.
  static String? limpiarComentario(String? comentario) {
    final texto = (comentario ?? '').trim();
    return texto.isEmpty ? null : texto;
  }

  /// Promedio de las calificaciones, o `null` si no hay ninguna.
  static double? promedio(List<int> estrellas) {
    if (estrellas.isEmpty) return null;
    return estrellas.fold<int>(0, (suma, e) => suma + e) / estrellas.length;
  }
}
