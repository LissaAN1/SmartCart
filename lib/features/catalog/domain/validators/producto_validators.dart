import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Reglas del formulario de producto y de cada fila del CSV. Igual que los
/// demás validadores: devuelven el mensaje de error o `null`. Los límites
/// también están como `check` en docs/sql/sprint2_hu10.sql.
abstract final class ProductoValidators {
  static const nombreMin = 3;
  static const nombreMax = 100;
  static const marcaMax = 60;

  /// HU-11: unidades en stock, como el `check` de la base.
  static const stockMax = 100000;

  static final _codigoPattern = RegExp(r'^\d{8,14}$');

  static String? nombre(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe el nombre del producto';
    if (text.length < nombreMin) return 'Usa mínimo $nombreMin caracteres';
    if (text.length > nombreMax) return 'Usa máximo $nombreMax caracteres';
    return null;
  }

  static String? marca(String? value) {
    final text = (value ?? '').trim();
    if (text.length > marcaMax) return 'Usa máximo $marcaMax caracteres';
    return null;
  }

  /// Opcional: vacío es válido. Si se escribe, son solo dígitos (8 a 14,
  /// que cubre EAN-8, UPC y EAN-13).
  static String? codigoBarras(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!_codigoPattern.hasMatch(text)) {
      return 'El código debe tener entre 8 y 14 dígitos';
    }
    return null;
  }

  static String? categoria(String? idCategoria) {
    return (idCategoria ?? '').isEmpty ? 'Elige una categoría' : null;
  }

  /// HU-11: el texto del campo de stock. Vacío cuenta como 0.
  static String? stock(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final unidades = int.tryParse(text);
    if (unidades == null) return 'Escribe solo números enteros';
    return stockValor(unidades);
  }

  static String? stockValor(int unidades) {
    if (unidades < 0) return 'El stock no puede ser negativo';
    if (unidades > stockMax) return 'Usa máximo $stockMax unidades';
    return null;
  }

  /// Primer error de los datos completos, o `null` si todos son válidos.
  static String? datos(ProductoDatos datos) =>
      nombre(datos.nombre) ??
      marca(datos.marca) ??
      codigoBarras(datos.codigoBarras) ??
      categoria(datos.idCategoria) ??
      stockValor(datos.stock);
}
