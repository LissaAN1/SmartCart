import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';

/// Pide al colaborador la foto de la etiqueta del precio. Devuelve `null` si
/// cancela.
class TomarFotoUseCase {
  final SelectorFoto _selector;

  TomarFotoUseCase({required SelectorFoto selector}) : _selector = selector;

  Future<FotoReporte?> call() => _selector.tomar();
}
