import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase para confirmar reportes dudosos
/// (HU-15): las funciones `reportes_por_confirmar`, `reportes_de_mi_comercio`,
/// `confirmar_reporte_colaborador`, `confirmar_reporte_comercio` y
/// `corregir_reporte_comercio`.
///
/// Quién puede confirmar o corregir lo decide la base, en
/// docs/sql/sprint3_hu15_hu16.sql; sus mensajes salen en español y se
/// muestran tal cual.
class SupabaseValidacionDataSource {
  final SupabaseClient _client;

  SupabaseValidacionDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<ReportePorConfirmar>> porConfirmar(PageRequest request) {
    return _lista(SupabaseFunctions.reportesPorConfirmar, request);
  }

  Future<PagedResult<ReportePorConfirmar>> deMiComercio(PageRequest request) {
    return _lista(SupabaseFunctions.reportesDeMiComercio, request);
  }

  Future<void> confirmarComoColaborador(
    String idReporte,
    Ubicacion ubicacion,
  ) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.confirmarReporteColaborador,
        params: {
          'p_id_reporte': idReporte,
          'p_latitud': ubicacion.latitud,
          'p_longitud': ubicacion.longitud,
        },
      );
    });
  }

  Future<void> confirmarComoComercio(String idReporte) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.confirmarReporteComercio,
        params: {'p_id_reporte': idReporte},
      );
    });
  }

  Future<void> corregirComoComercio(String idReporte, int precio) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.corregirReporteComercio,
        params: {'p_id_reporte': idReporte, 'p_precio': precio},
      );
    });
  }

  Future<PagedResult<ReportePorConfirmar>> _lista(
    String funcion,
    PageRequest request,
  ) {
    return _proteger(() async {
      final rows = await _client.rpc(
        funcion,
        params: {
          // Una fila de más: indica si hay otra página (ver PageRequest).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [for (final row in rows) _toReporte(row as Map<String, dynamic>)],
        request,
      );
    });
  }

  ReportePorConfirmar _toReporte(Map<String, dynamic> row) {
    return ReportePorConfirmar(
      id: row[SupabaseColumns.misReporteId].toString(),
      producto: row[SupabaseColumns.misReporteProducto] as String? ?? '',
      establecimiento: row[SupabaseColumns.misReporteComercio] as String? ?? '',
      precio: (row[SupabaseColumns.misReportePrecio] as num).toInt(),
      precioActual:
          (row[SupabaseColumns.porConfirmarPrecioActual] as num?)?.toInt(),
      motivo: row[SupabaseColumns.misReporteMotivo] as String?,
      // La base guarda la hora en UTC; se muestra en la del dispositivo.
      creadoEn: DateTime.parse(
        row[SupabaseColumns.misReporteCreadoEn].toString(),
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
