import 'package:smartcart/features/reportes/domain/entities/reporte.dart';

/// Reglas del formulario del reporte y de la sugerencia de establecimiento.
/// Devuelven el mensaje de error o `null`, como los demás validadores. Los
/// límites también están como `check` en docs/sql/sprint2_hu14.sql.
abstract final class ReporteValidators {
  /// Tope del precio, en pesos. Evita errores de digitación (un cero de más).
  static const precioMax = 100000000;

  static final _separadores = RegExp(r'[\s$.,]');
  static final _soloDigitos = RegExp(r'^\d+$');

  /// Convierte lo escrito ("4.900", "$ 4900") en pesos, o `null` si no son
  /// solo números.
  static int? parsePrecio(String? value) {
    final texto = (value ?? '').replaceAll(_separadores, '');
    if (!_soloDigitos.hasMatch(texto)) return null;
    return int.tryParse(texto);
  }

  static String? precio(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Escribe el precio';
    final pesos = parsePrecio(value);
    if (pesos == null) return 'Escribe solo números';
    return precioEnPesos(pesos);
  }

  /// Valida un precio ya convertido (lo usa también el caso de uso).
  static String? precioEnPesos(int pesos) {
    if (pesos <= 0) return 'El precio debe ser mayor que cero';
    if (pesos > precioMax) return 'El precio es demasiado alto';
    return null;
  }

  /// Opcional: vacío es válido. Si se escribe, debe ser menor que el precio
  /// normal.
  static String? precioPromocional(String? promocion, String? precioNormal) {
    if ((promocion ?? '').trim().isEmpty) return null;
    final promo = parsePrecio(promocion);
    if (promo == null) return 'Escribe solo números';
    return promocionEnPesos(promo, parsePrecio(precioNormal));
  }

  static String? promocionEnPesos(int promo, int? precioNormal) {
    if (promo <= 0) return 'El precio debe ser mayor que cero';
    if (precioNormal != null && promo >= precioNormal) {
      return 'La promoción debe ser menor que el precio normal';
    }
    return null;
  }

  static String? foto(FotoReporte? foto) {
    return foto == null || foto.bytes.isEmpty
        ? 'La foto de la etiqueta es obligatoria'
        : null;
  }

  static String? nombreSugerido(String? value) =>
      _largo(value, 3, 100, 'Escribe el nombre del establecimiento');

  static String? direccionSugerida(String? value) =>
      _largo(value, 3, 150, 'Escribe la dirección');

  static String? ciudadSugerida(String? value) =>
      _largo(value, 3, 60, 'Escribe la ciudad o el barrio');

  static String? _largo(String? value, int min, int max, String vacio) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return vacio;
    if (texto.length < min) return 'Usa mínimo $min caracteres';
    if (texto.length > max) return 'Usa máximo $max caracteres';
    return null;
  }

  /// Primer error de la sugerencia, o `null` si es válida.
  static String? sugerencia(SugerenciaDatos datos) =>
      nombreSugerido(datos.nombre) ??
      direccionSugerida(datos.direccion) ??
      ciudadSugerida(datos.ciudad);
}
