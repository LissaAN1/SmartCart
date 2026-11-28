import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';

/// Pide al colaborador la foto de la etiqueta del precio: tomada con la
/// cámara o subida desde la galería. Devuelve `null` si cancela.
class TomarFotoUseCase {
  final SelectorFoto _selector;

  TomarFotoUseCase({required SelectorFoto selector}) : _selector = selector;

  /// Si se ofrece la cámara; la pantalla solo muestra "Tomar foto" cuando
  /// es `true`.
  bool get hayCamara => _selector.hayCamara;

  Future<FotoReporte?> call([OrigenFoto origen = OrigenFoto.camara]) =>
      _selector.elegir(origen);
}
