import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';

/// Pide a la persona que elija el CSV y lo entrega como texto. Devuelve
/// `null` si cancela.
class ElegirArchivoCsvUseCase {
  final SelectorArchivoCsv _selector;

  ElegirArchivoCsvUseCase({required SelectorArchivoCsv selector})
      : _selector = selector;

  Future<ArchivoCsv?> call() => _selector.elegir();
}
