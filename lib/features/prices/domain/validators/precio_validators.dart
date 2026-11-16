import 'package:smartcart/core/utils/format_helpers.dart';

/// Reglas de precios y promociones (HU-11). Como los demás validadores,
/// devuelven el mensaje de error o `null`. Los límites también están como
/// `check` en docs/sql/sprint2_hu11.sql.
abstract final class PrecioValidators {
  /// Tope razonable para un producto de barrio; evita errores de digitación
  /// (un cero de más).
  static const precioMax = 100000000;

  static final _soloDigitos = RegExp(r'^\d+$');

  /// Lee lo que se escribe en el campo de precio: acepta "2500", "2.500" y
  /// "$ 2.500". Devuelve `null` si no es un número entero de pesos.
  static int? leerPesos(String? texto) {
    final limpio = (texto ?? '').replaceAll(RegExp(r'[\s$.]'), '');
    if (!_soloDigitos.hasMatch(limpio)) return null;
    return int.tryParse(limpio);
  }

  /// Valida un valor ya convertido a pesos.
  static String? valor(int pesos) {
    if (pesos <= 0) return 'El precio debe ser mayor a cero';
    if (pesos > precioMax) {
      return 'El precio no puede superar ${formatoCop(precioMax)}';
    }
    return null;
  }

  /// Valida el texto del campo de precio.
  static String? precio(String? texto) {
    final text = (texto ?? '').trim();
    if (text.isEmpty) return 'Escribe el precio';
    if (text.contains(',')) return 'Escribe el precio sin centavos';
    final pesos = leerPesos(text);
    if (pesos == null) return 'Escribe solo números, sin letras';
    return valor(pesos);
  }

  /// El precio promocional, además, debe ser menor que el precio normal.
  static String? valorPromocional(int pesos, int precioNormal) {
    final error = valor(pesos);
    if (error != null) return error;
    if (pesos >= precioNormal) {
      return 'La promoción debe costar menos que el precio normal '
          '(${formatoCop(precioNormal)})';
    }
    return null;
  }

  static String? precioPromocional(String? texto, int? precioNormal) {
    final error = precio(texto);
    if (error != null) return error;
    if (precioNormal == null) return 'Primero registra el precio normal';
    return valorPromocional(leerPesos(texto)!, precioNormal);
  }

  /// La promoción va de [inicio] a [fin], ambos incluidos, y no puede haber
  /// terminado ya.
  static String? fechas(DateTime? inicio, DateTime? fin, DateTime ahora) {
    if (inicio == null || fin == null) {
      return 'Elige la fecha de inicio y la de fin';
    }
    if (soloFecha(fin).isBefore(soloFecha(inicio))) {
      return 'La fecha de fin debe ser igual o posterior a la de inicio';
    }
    if (soloFecha(fin).isBefore(soloFecha(ahora))) {
      return 'Esa promoción ya habría terminado: elige un fin desde hoy';
    }
    return null;
  }
}
