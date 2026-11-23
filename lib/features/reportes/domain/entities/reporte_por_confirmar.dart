import 'package:smartcart/features/reportes/domain/validacion_reglas.dart';

/// Un reporte de precio que esperó confirmación porque el precio reportado
/// es muy distinto al registrado (HU-15). Otro colaborador o el comercio lo
/// confirma; el comercio también puede corregirlo.
class ReportePorConfirmar {
  final String id;
  final String producto;
  final String establecimiento;

  /// Precio reportado, en pesos colombianos (COP).
  final int precio;

  /// Precio que tenía el producto antes del reporte, o `null` si no tenía.
  final int? precioActual;
  final DateTime creadoEn;

  /// Por qué espera confirmación.
  final String? motivo;

  const ReportePorConfirmar({
    required this.id,
    required this.producto,
    required this.establecimiento,
    required this.precio,
    required this.creadoEn,
    this.precioActual,
    this.motivo,
  });

  /// Cuánto se aparta el precio reportado del actual (0,5 = 50 %), o `null`
  /// si el producto no tenía precio.
  double? get diferencia => precioActual == null || precioActual! <= 0
      ? null
      : ValidacionReglas.diferenciaRelativa(precio, precioActual!);
}
