import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';

/// Contrato para que la persona elija un archivo CSV del dispositivo. El
/// dominio no sabe cómo se abre el selector: lo resuelve la capa de datos.
abstract class SelectorArchivoCsv {
  /// El archivo elegido, o `null` si la persona canceló.
  Future<ArchivoCsv?> elegir();
}
