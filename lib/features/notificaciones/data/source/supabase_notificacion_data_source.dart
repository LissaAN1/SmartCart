import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe la tabla `notificacion`. La política RLS
/// solo deja ver y marcar como leídas las propias (sprint2_hu24.sql).
class SupabaseNotificacionDataSource {
  final SupabaseClient _client;

  SupabaseNotificacionDataSource({required SupabaseClient client})
      : _client = client;

  Future<List<Notificacion>> noLeidas(String userId) async {
    try {
      final rows = await _client
          .from(SupabaseTables.notificacion)
          .select()
          .eq(SupabaseColumns.notificacionUsuario, userId)
          .eq(SupabaseColumns.notificacionLeida, false)
          .order(SupabaseColumns.notificacionCreadoEn, ascending: true);
      return [for (final row in rows) _toNotificacion(row)];
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> marcarLeidas(List<String> ids) async {
    try {
      await _client
          .from(SupabaseTables.notificacion)
          .update({SupabaseColumns.notificacionLeida: true}).inFilter(
              SupabaseColumns.notificacionId, ids);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Notificacion _toNotificacion(Map<String, dynamic> row) {
    final creado = row[SupabaseColumns.notificacionCreadoEn];
    return Notificacion(
      id: row[SupabaseColumns.notificacionId].toString(),
      titulo: row[SupabaseColumns.notificacionTitulo] as String? ?? '',
      mensaje: row[SupabaseColumns.notificacionMensaje] as String? ?? '',
      creadoEn: creado == null
          ? null
          : DateTime.tryParse(creado.toString())?.toLocal(),
    );
  }
}
