import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/reporte_reglas.dart';

/// Resultado de revisar un reporte: en qué estado queda y por qué.
class RevisionReporte {
  final EstadoReporte estado;

  /// Por qué se rechazó, o qué falta para confirmarlo; `null` si se validó.
  final String? motivo;

  /// El reporte espera que otro colaborador o el comercio lo confirme.
  final bool requiereConfirmacion;

  /// Se rechazó por incumplir una regla (ubicación o evidencia): le baja la
  /// reputación al colaborador. Un rechazo porque el comercio corrigió el
  /// precio no cuenta como falso.
  final bool esFalso;

  const RevisionReporte({
    required this.estado,
    this.motivo,
    this.requiereConfirmacion = false,
    this.esFalso = false,
  });

  @override
  bool operator ==(Object other) =>
      other is RevisionReporte &&
      other.estado == estado &&
      other.motivo == motivo &&
      other.requiereConfirmacion == requiereConfirmacion &&
      other.esFalso == esFalso;

  @override
  int get hashCode => Object.hash(estado, motivo, requiereConfirmacion, esFalso);
}

/// Reglas con las que el sistema revisa un reporte de precio (HU-15): su
/// ubicación, su evidencia y su coherencia con el historial del producto.
///
/// La base las aplica al recibir cada reporte (`revisar_reporte()` en
/// docs/sql/sprint3_hu15_hu16.sql); aquí están como función pura para
/// documentarlas, probarlas y calcular lo que muestran las pantallas. Si
/// cambias un valor o un texto, cámbialo en los dos lados.
abstract final class ValidacionReglas {
  /// Cuánto puede alejarse el precio reportado del precio actual (como
  /// fracción del actual) sin pedir confirmación. El backlog dice "muy
  /// distinto" sin dar cifra; 30 % deja pasar los cambios normales de precio
  /// y detiene los errores de digitación.
  static const diferenciaMaxima = 0.30;

  static const motivoUbicacion =
      'La ubicación no coincide con el establecimiento.';
  static const motivoEvidencia = 'No se encontró la foto de la etiqueta.';

  static String motivoConfirmacion(int precioActual) =>
      'El precio es muy distinto al registrado (\$ $precioActual). '
      'Espera la confirmación de otro colaborador o del comercio.';

  /// Qué tanto se aparta [precio] de [referencia], como fracción de
  /// [referencia] (0,5 = 50 %).
  static double diferenciaRelativa(int precio, int referencia) =>
      (precio - referencia).abs() / referencia;

  /// `true` si [precio] difiere de [precioReferencia] más que
  /// [diferenciaMaxima]. Sin precio de referencia (producto sin datos) no hay
  /// con qué comparar: nunca es "muy distinto".
  static bool esMuyDistinto(int precio, int? precioReferencia) {
    if (precioReferencia == null || precioReferencia <= 0) return false;
    return diferenciaRelativa(precio, precioReferencia) > diferenciaMaxima;
  }

  /// Revisa un reporte. [precioReferencia] es el precio que tenía el producto
  /// antes del reporte, o `null` si no tenía.
  ///
  /// Las reglas van en orden y la primera que falla decide: ubicación,
  /// evidencia y, por último, coherencia con el historial.
  static RevisionReporte revisar({
    required double distanciaM,
    required bool tieneFoto,
    required int precio,
    int? precioReferencia,
  }) {
    if (!ReporteReglas.estaDentro(distanciaM)) {
      return const RevisionReporte(
        estado: EstadoReporte.rechazado,
        motivo: motivoUbicacion,
        esFalso: true,
      );
    }
    if (!tieneFoto) {
      return const RevisionReporte(
        estado: EstadoReporte.rechazado,
        motivo: motivoEvidencia,
        esFalso: true,
      );
    }
    if (esMuyDistinto(precio, precioReferencia)) {
      return RevisionReporte(
        estado: EstadoReporte.pendiente,
        motivo: motivoConfirmacion(precioReferencia!),
        requiereConfirmacion: true,
      );
    }
    return const RevisionReporte(estado: EstadoReporte.validado);
  }
}
