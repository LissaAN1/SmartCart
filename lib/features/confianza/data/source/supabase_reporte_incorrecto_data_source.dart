import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que guarda los reportes de precio incorrecto en Supabase.
///
/// La tabla `reporte_precio_incorrecto` no se escribe directo: la función
/// `reportar_precio_incorrecto` (docs/sql/sprint2_hu13.sql) comprueba que
/// quien reporta sea cliente, que el precio esté publicado y que no haya otro
/// reporte pendiente, y guarda el precio tal como se veía.
class SupabaseReporteIncorrectoDataSource {
  final SupabaseClient _client;

  SupabaseReporteIncorrectoDataSource({required SupabaseClient client})
      : _client = client;

  Future<ResultadoReporte> reportar(String idProducto, {String? motivo}) {
    return traducirErroresSupabase(() async {
      final resultado = await _client.rpc(
        SupabaseFunctions.reportarPrecioIncorrecto,
        params: {'p_id_producto': idProducto, 'p_motivo': motivo},
      );
      return resultado == 'ya_reportado'
          ? ResultadoReporte.yaReportado
          : ResultadoReporte.registrado;
    });
  }
}
