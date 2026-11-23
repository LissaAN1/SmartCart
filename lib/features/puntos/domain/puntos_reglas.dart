import 'package:smartcart/features/confianza/domain/confianza_reglas.dart';

/// Reglas de puntos y reputación de los reportes (HU-16).
///
/// La base las aplica al validar o rechazar un reporte (`puntos_para_reporte()`
/// y `reporte_precio_aplicar_resultado()` en docs/sql/sprint3_hu15_hu16.sql);
/// aquí están como funciones puras para documentarlas y probarlas. Si cambias
/// un valor, cámbialo en los dos lados.
///
/// El backlog dice "más puntos por productos o zonas sin datos o
/// desactualizados" pero no da cifras ni define "zona"; tomamos estas.
abstract final class PuntosReglas {
  /// Puntos de cualquier reporte validado.
  static const puntosBase = 10;

  /// Extra si el producto no tenía precio (sin datos).
  static const bonusSinDatos = 10;

  /// Extra si el precio tenía más de [ConfianzaReglas.diasLimite] días.
  static const bonusDesactualizado = 5;

  /// Reputación: mínimo, máximo, y cuánto sube o baja.
  static const reputacionMinima = 0;
  static const reputacionMaxima = 100;
  static const reputacionPorValidado = 1;
  static const penalizacionPorFalso = 5;

  /// Puntos que gana un reporte validado. [precioActualizadoEn] es la fecha
  /// del precio que tenía el producto antes del reporte, o `null` si no tenía
  /// ninguno. [ahora] solo existe para poder probarlo.
  static int puntosPorReporte({
    required DateTime? precioActualizadoEn,
    DateTime? ahora,
  }) {
    if (precioActualizadoEn == null) return puntosBase + bonusSinDatos;
    final referencia = ahora ?? DateTime.now();
    final dias = ConfianzaReglas.diasDeAntiguedad(precioActualizadoEn, referencia);
    return dias > ConfianzaReglas.diasLimite
        ? puntosBase + bonusDesactualizado
        : puntosBase;
  }

  /// La reputación después de un reporte validado: sube, hasta el máximo.
  static num reputacionTrasValidado(num actual) =>
      (actual + reputacionPorValidado).clamp(reputacionMinima, reputacionMaxima);

  /// La reputación después de un reporte falso: baja, hasta el mínimo.
  static num reputacionTrasFalso(num actual) =>
      (actual - penalizacionPorFalso).clamp(reputacionMinima, reputacionMaxima);
}
