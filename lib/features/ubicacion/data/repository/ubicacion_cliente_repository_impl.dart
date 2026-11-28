import 'package:smartcart/features/ubicacion/data/source/supabase_ubicacion_cliente_data_source.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart';

/// Cumple UbicacionClienteRepository delegando en el data source de Supabase.
class UbicacionClienteRepositoryImpl implements UbicacionClienteRepository {
  final SupabaseUbicacionClienteDataSource _dataSource;

  UbicacionClienteRepositoryImpl({
    required SupabaseUbicacionClienteDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<PreferenciaUbicacion?> obtener() => _dataSource.obtener();

  @override
  Future<void> guardar(PreferenciaUbicacion preferencia) =>
      _dataSource.guardar(preferencia);

  @override
  Future<List<EstablecimientoCercano>> comerciosEnRadio(
    Ubicacion centro,
    int radioM,
  ) =>
      _dataSource.comerciosEnRadio(centro, radioM);
}
