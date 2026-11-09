import 'package:smartcart/features/comercio/data/source/supabase_comercio_data_source.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';

/// Cumple ComercioRepository delegando en el data source de Supabase.
class ComercioRepositoryImpl implements ComercioRepository {
  final SupabaseComercioDataSource _dataSource;

  ComercioRepositoryImpl({required SupabaseComercioDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Comercio?> getMine(String userId) => _dataSource.getMine(userId);

  @override
  Future<Comercio> register(String userId, ComercioDatos datos) {
    return _dataSource.register(userId, datos);
  }
}
