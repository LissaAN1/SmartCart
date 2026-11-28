import 'package:smartcart/features/calificaciones/data/source/supabase_calificaciones_data_source.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/repository/calificaciones_repository.dart';

/// Cumple CalificacionesRepository delegando en el data source de Supabase.
class CalificacionesRepositoryImpl implements CalificacionesRepository {
  final SupabaseCalificacionesDataSource _dataSource;

  CalificacionesRepositoryImpl({
    required SupabaseCalificacionesDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<ResumenCalificaciones> calificar({
    required String idOrden,
    required TipoCalificacion tipo,
    required int estrellas,
    String? comentario,
  }) =>
      _dataSource.calificar(
        idOrden: idOrden,
        tipo: tipo,
        estrellas: estrellas,
        comentario: comentario,
      );
}
