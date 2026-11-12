import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/data/source/supabase_comercio_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lee las solicitudes pendientes de `comercio` y `perfil_repartidor`, y
/// decide sobre ellas con la función `decidir_solicitud` (HU-24).
///
/// Solo el administrador ve filas ajenas y puede cambiar el estado: lo
/// garantizan las políticas RLS de docs/sql/sprint2_hu24.sql.
class SupabaseSolicitudesDataSource {
  final SupabaseClient _client;

  SupabaseSolicitudesDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<Solicitud>> pendientes(
    TipoSolicitud tipo,
    PageRequest request,
  ) async {
    try {
      final solicitudes = switch (tipo) {
        TipoSolicitud.comercio => await _comerciosPendientes(request),
        TipoSolicitud.repartidor => await _repartidoresPendientes(request),
      };
      return PagedResult.fromRows(solicitudes, request);
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> decidir(
    Solicitud solicitud, {
    required bool aprobar,
    String? motivo,
  }) async {
    try {
      await _client.rpc(SupabaseFunctions.decidirSolicitud, params: {
        'p_tipo': solicitud.tipo.dbName,
        'p_id': solicitud.id,
        'p_aprobar': aprobar,
        'p_motivo': motivo,
      });
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<List<Solicitud>> _comerciosPendientes(PageRequest request) async {
    final rows = await _client
        .from(SupabaseTables.comercio)
        .select()
        .eq(SupabaseColumns.comercioEstado, ApprovalStatus.pendiente.dbName)
        .order(SupabaseColumns.comercioCreadoEn, ascending: true)
        .order(SupabaseColumns.comercioId, ascending: true)
        .range(request.from, request.to);
    final usuarios = await _usuarios(
      rows.map((r) => r[SupabaseColumns.comercioUsuario] as String),
    );
    return [
      for (final row in rows)
        _comercioToSolicitud(
          row,
          usuarios[row[SupabaseColumns.comercioUsuario] as String],
        ),
    ];
  }

  Future<List<Solicitud>> _repartidoresPendientes(PageRequest request) async {
    final rows = await _client
        .from(SupabaseTables.perfilRepartidor)
        .select()
        .eq(SupabaseColumns.repartidorEstado, ApprovalStatus.pendiente.dbName)
        .order(SupabaseColumns.repartidorCreadoEn, ascending: true)
        .order(SupabaseColumns.repartidorUsuario, ascending: true)
        .range(request.from, request.to);
    final usuarios = await _usuarios(
      rows.map((r) => r[SupabaseColumns.repartidorUsuario] as String),
    );
    return [
      for (final row in rows)
        _repartidorToSolicitud(
          row,
          usuarios[row[SupabaseColumns.repartidorUsuario] as String],
        ),
    ];
  }

  /// Nombre, correo y teléfono de las cuentas [ids], en una sola consulta.
  /// Se pide aparte (y no con una relación embebida) para no depender de
  /// que exista la llave foránea en el proyecto.
  Future<Map<String, Map<String, dynamic>>> _usuarios(
    Iterable<String> ids,
  ) async {
    final unicos = ids.toSet().toList();
    if (unicos.isEmpty) return const {};
    final rows = await _client
        .from(SupabaseTables.usuario)
        .select()
        .inFilter(SupabaseColumns.usuarioId, unicos);
    return {
      for (final row in rows) row[SupabaseColumns.usuarioId] as String: row,
    };
  }

  Solicitud _comercioToSolicitud(
    Map<String, dynamic> row,
    Map<String, dynamic>? usuario,
  ) {
    final comercio = comercioFromRow(row);
    return Solicitud(
      tipo: TipoSolicitud.comercio,
      id: comercio.id,
      idUsuario: row[SupabaseColumns.comercioUsuario] as String,
      nombre: comercio.nombre,
      responsable: usuario?[SupabaseColumns.usuarioNombre] as String?,
      correo: usuario?[SupabaseColumns.usuarioCorreo] as String?,
      telefono: comercio.telefono ??
          usuario?[SupabaseColumns.usuarioTelefono] as String?,
      creadoEn: _fecha(row[SupabaseColumns.comercioCreadoEn]),
      comercio: comercio,
    );
  }

  Solicitud _repartidorToSolicitud(
    Map<String, dynamic> row,
    Map<String, dynamic>? usuario,
  ) {
    final nombre = usuario?[SupabaseColumns.usuarioNombre] as String?;
    return Solicitud(
      tipo: TipoSolicitud.repartidor,
      id: row[SupabaseColumns.repartidorUsuario] as String,
      idUsuario: row[SupabaseColumns.repartidorUsuario] as String,
      nombre: nombre ?? 'Repartidor sin nombre',
      responsable: nombre,
      correo: usuario?[SupabaseColumns.usuarioCorreo] as String?,
      telefono: usuario?[SupabaseColumns.usuarioTelefono] as String?,
      creadoEn: _fecha(row[SupabaseColumns.repartidorCreadoEn]),
    );
  }

  DateTime? _fecha(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
}
