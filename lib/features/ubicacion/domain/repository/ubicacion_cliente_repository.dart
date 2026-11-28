import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Contrato de la ubicación del cliente. Se guarda en su cuenta: por eso se
/// recupera al volver a abrir la app (HU-19).
abstract class UbicacionClienteRepository {
  /// La ubicación y el radio guardados, o `null` si aún no hay.
  Future<PreferenciaUbicacion?> obtener();

  /// Guarda (o reemplaza) la ubicación y el radio del cliente.
  Future<void> guardar(PreferenciaUbicacion preferencia);

  /// Los comercios aprobados con ubicación a [radioM] metros o menos de
  /// [centro], del más cercano al más lejano.
  Future<List<EstablecimientoCercano>> comerciosEnRadio(
    Ubicacion centro,
    int radioM,
  );
}
