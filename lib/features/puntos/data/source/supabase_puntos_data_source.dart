import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/nivel_colaborador.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase para los puntos (HU-16): las
/// funciones `resumen_puntos` y `mis_movimientos_puntos`. Los puntos los
/// asigna la base al validar un reporte; la app solo los lee.
class SupabasePuntosDataSource {
  final SupabaseClient _client;

  SupabasePuntosDataSource({required SupabaseClient client}) : _client = client;

  Future<ResumenPuntos> resumen() {
    return _proteger(() async {
      final rows =
          await _client.rpc(SupabaseFunctions.resumenPuntos) as List<dynamic>;
      // Sin fila: el colaborador aún no tiene perfil de puntos.
      if (rows.isEmpty) return ResumenPuntos.inicial;
      return _toResumen(rows.first as Map<String, dynamic>);
    });
  }

  Future<PagedResult<MovimientoPuntos>> movimientos(PageRequest request) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.misMovimientosPuntos,
        params: {
          // Una fila de más: indica si hay otra página (ver PageRequest).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [for (final row in rows) _toMovimiento(row as Map<String, dynamic>)],
        request,
      );
    });
  }

  ResumenPuntos _toResumen(Map<String, dynamic> row) {
    return ResumenPuntos(
      saldo: (row[SupabaseColumns.resumenSaldo] as num?)?.toInt() ?? 0,
      acumulados:
          (row[SupabaseColumns.resumenAcumulados] as num?)?.toInt() ?? 0,
      nivel: NivelColaborador.desdeNumero(
        (row[SupabaseColumns.resumenNivel] as num?)?.toInt() ?? 1,
      ),
      reputacion: (row[SupabaseColumns.resumenReputacion] as num?) ?? 0,
    );
  }

  MovimientoPuntos _toMovimiento(Map<String, dynamic> row) {
    return MovimientoPuntos(
      id: row[SupabaseColumns.movimientoId].toString(),
      puntos: (row[SupabaseColumns.movimientoPuntos] as num).toInt(),
      tipo: TipoMovimientoPuntos.fromDbName(
        row[SupabaseColumns.movimientoTipo] as String?,
      ),
      motivo: row[SupabaseColumns.movimientoMotivo] as String? ?? '',
      // La base guarda la hora en UTC; se muestra en la del dispositivo.
      creadoEn: DateTime.parse(
        row[SupabaseColumns.movimientoCreadoEn].toString(),
      ).toLocal(),
    );
  }

  /// Traduce los errores del SDK a [AuthFailure] para que ni los casos de uso
  /// ni la interfaz conozcan Supabase.
  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }
}
