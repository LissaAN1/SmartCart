import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con las funciones de aprobación de Supabase
/// (`solicitudes_pendientes` y `decidir_solicitud`, ver
/// docs/sql/sprint2_hu24.sql). Ambas verifican en la base de datos que quien
/// llama sea administrador.
class SupabaseAprobacionDataSource {
  final SupabaseClient _client;

  SupabaseAprobacionDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<SolicitudAprobacion>> getPendientes(
    PageRequest request,
  ) async {
    try {
      final rows = await _client.rpc('solicitudes_pendientes', params: {
        // Una fila de más para saber si existe otra página.
        'p_limit': request.pageSize + 1,
        'p_offset': request.from,
      }) as List<dynamic>;
      final solicitudes = [
        for (final row in rows) _toSolicitud(row as Map<String, dynamic>),
      ];
      return PagedResult.fromRows(solicitudes, request);
    } on PostgrestException catch (e) {
      throw _map(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> decidir(
    SolicitudAprobacion solicitud, {
    required bool aprobar,
    String? motivo,
  }) async {
    try {
      await _client.rpc('decidir_solicitud', params: {
        'p_tipo': solicitud.tipo.dbName,
        'p_id': solicitud.id,
        'p_aprobar': aprobar,
        'p_motivo': motivo,
      });
    } on PostgrestException catch (e) {
      throw _map(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  SolicitudAprobacion _toSolicitud(Map<String, dynamic> row) {
    return SolicitudAprobacion(
      // Un tipo desconocido no debería llegar; se trata como comercio solo
      // para poder mostrarlo, y decidir_solicitud lo rechazaría.
      tipo: TipoSolicitud.fromDbName(row['tipo'] as String?) ??
          TipoSolicitud.comercio,
      id: row['id'].toString(),
      userId: row['id_usuario'].toString(),
      nombre: row['nombre'] as String? ?? '',
      detalle: row['detalle'] as String? ?? '',
      contacto: row['contacto'] as String?,
    );
  }

  /// Códigos que lanzan las funciones: 42501 (sin permiso, ya lo traduce
  /// `mapPostgrestException`), P0002 (otro administrador ya la resolvió) y
  /// 22023 (dato inválido, p. ej. rechazo sin motivo).
  AuthFailure _map(PostgrestException e) {
    switch (e.code) {
      case 'P0002':
        return const AuthFailure(
          'Esta solicitud ya fue resuelta. Actualiza la lista.',
        );
      case '22023':
        return AuthFailure(e.message);
      default:
        return mapPostgrestException(e);
    }
  }
}
