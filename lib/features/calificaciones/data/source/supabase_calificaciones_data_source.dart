import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase para las calificaciones (HU-25): la
/// función `calificar_orden`, que comprueba que la orden esté completada, que
/// sea del cliente y que no se haya calificado, y recalcula el promedio.
class SupabaseCalificacionesDataSource {
  final SupabaseClient _client;

  SupabaseCalificacionesDataSource({required SupabaseClient client})
      : _client = client;

  Future<ResumenCalificaciones> calificar({
    required String idOrden,
    required TipoCalificacion tipo,
    required int estrellas,
    String? comentario,
  }) async {
    try {
      final rows = await _client.rpc(
        SupabaseFunctions.calificarOrden,
        params: {
          'p_id_orden': idOrden,
          'p_tipo': tipo.dbName,
          'p_estrellas': estrellas,
          'p_comentario': comentario,
        },
      ) as List<dynamic>;
      if (rows.isEmpty) return ResumenCalificaciones.sinCalificaciones;
      final row = rows.first as Map<String, dynamic>;
      return ResumenCalificaciones(
        promedio: (row[SupabaseColumns.calificacionPromedio] as num?)?.toDouble(),
        total: (row[SupabaseColumns.calificacionTotal] as num?)?.toInt() ?? 0,
      );
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }
}
