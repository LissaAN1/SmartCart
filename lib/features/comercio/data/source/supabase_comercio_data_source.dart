import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe la tabla `comercio`. Solo el dueño ve y
/// edita su fila (política RLS, ver docs/sql/sprint2_hu06_07_08.sql); aquí
/// además se filtra siempre por el id del dueño.
class SupabaseComercioDataSource {
  final SupabaseClient _client;

  SupabaseComercioDataSource({required SupabaseClient client})
      : _client = client;

  Future<Comercio?> getMine(String userId) async {
    try {
      final row = await _client
          .from(SupabaseTables.comercio)
          .select()
          .eq(SupabaseColumns.comercioUsuario, userId)
          .limit(1)
          .maybeSingle();
      return row == null ? null : _toComercio(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<Comercio> register(String userId, ComercioDatos datos) async {
    try {
      final row = await _client
          .from(SupabaseTables.comercio)
          .insert({
            SupabaseColumns.comercioUsuario: userId,
            SupabaseColumns.comercioNombre: datos.nombre,
            SupabaseColumns.comercioTelefono: datos.telefono,
            SupabaseColumns.comercioDireccion: datos.direccion,
            SupabaseColumns.comercioCiudad: datos.ciudad,
            SupabaseColumns.comercioHoraApertura: datos.horaApertura,
            SupabaseColumns.comercioHoraCierre: datos.horaCierre,
            SupabaseColumns.comercioServicio: datos.servicio.dbName,
            // La política de insert exige que nazca pendiente.
            SupabaseColumns.comercioEstado: ApprovalStatus.pendiente.dbName,
          })
          .select()
          .single();
      return _toComercio(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Comercio _toComercio(Map<String, dynamic> row) => comercioFromRow(row);
}

/// Convierte una fila de la tabla `comercio` en la entidad. La comparten el
/// dueño (HU-07) y la aprobación del administrador (HU-24).
Comercio comercioFromRow(Map<String, dynamic> row) {
  return Comercio(
    id: row[SupabaseColumns.comercioId].toString(),
    nombre: row[SupabaseColumns.comercioNombre] as String? ?? '',
    telefono: row[SupabaseColumns.comercioTelefono] as String?,
    direccion: row[SupabaseColumns.comercioDireccion] as String? ?? '',
    ciudad: row[SupabaseColumns.comercioCiudad] as String? ?? '',
    horaApertura: _hhmm(row[SupabaseColumns.comercioHoraApertura]),
    horaCierre: _hhmm(row[SupabaseColumns.comercioHoraCierre]),
    servicio: ServicioComercio.fromDbName(
            row[SupabaseColumns.comercioServicio] as String?) ??
        ServicioComercio.recogida,
    // Un estado desconocido se trata como pendiente: nunca se da por
    // aprobado un comercio por error.
    estado: ApprovalStatus.fromDbName(
            row[SupabaseColumns.comercioEstado] as String?) ??
        ApprovalStatus.pendiente,
    motivoRechazo: row[SupabaseColumns.comercioMotivoRechazo] as String?,
  );
}

/// Si la columna es de tipo `time` llega como "HH:mm:ss"; se muestra "HH:mm".
String _hhmm(dynamic value) {
  final text = value?.toString() ?? '';
  return text.length >= 5 ? text.substring(0, 5) : text;
}
