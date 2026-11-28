import 'package:smartcart/features/comparacion/data/source/supabase_comparacion_data_source.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/comparacion/domain/repository/comparacion_repository.dart';

/// Cumple ComparacionRepository delegando en el data source de Supabase.
class ComparacionRepositoryImpl implements ComparacionRepository {
  final SupabaseComparacionDataSource _dataSource;

  ComparacionRepositoryImpl({required SupabaseComparacionDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<LineaComparable>> ofertasDelCarrito() =>
      _dataSource.ofertasDelCarrito();
}
