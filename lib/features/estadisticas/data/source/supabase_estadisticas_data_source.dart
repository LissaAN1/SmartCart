import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que llama a `estadisticas_panel` (HU-28,
/// docs/sql/sprint3_hu28.sql), que devuelve un objeto JSON con los conteos.
class SupabaseEstadisticasDataSource {
  final SupabaseClient _client;

  SupabaseEstadisticasDataSource({required SupabaseClient client})
      : _client = client;

  Future<EstadisticasPlataforma> obtener() {
    return traducirErroresSupabase(() async {
      final json = await _client.rpc(SupabaseFunctions.estadisticasPanel);
      return desdeJson(Map<String, dynamic>.from(json as Map));
    });
  }

  /// Convierte la respuesta de la función. Un rol o estado sin filas puede no
  /// venir: cuenta como cero.
  static EstadisticasPlataforma desdeJson(Map<String, dynamic> json) {
    int numero(String clave) => parseInt(json[clave]) ?? 0;
    final usuarios = _mapa(json[SupabaseColumns.estadisticaUsuariosPorRol]);
    final comercios =
        _mapa(json[SupabaseColumns.estadisticaComerciosPorEstado]);
    final ordenes = json[SupabaseColumns.estadisticaOrdenes];

    return EstadisticasPlataforma(
      usuariosPorRol: {
        for (final rol in UserRole.values)
          rol: parseInt(usuarios[rol.dbName]) ?? 0,
      },
      comerciosPorEstado: {
        for (final estado in ApprovalStatus.values)
          estado: parseInt(comercios[estado.dbName]) ?? 0,
      },
      repartidoresAprobados:
          numero(SupabaseColumns.estadisticaRepartidoresAprobados),
      repartidoresEnLinea:
          numero(SupabaseColumns.estadisticaRepartidoresEnLinea),
      solicitudesComercio:
          numero(SupabaseColumns.estadisticaSolicitudesComercio),
      solicitudesRepartidor:
          numero(SupabaseColumns.estadisticaSolicitudesRepartidor),
      reportesPrecioPendientes:
          numero(SupabaseColumns.estadisticaReportesPendientes),
      ordenes: ordenes == null ? null : _ordenes(_mapa(ordenes)),
    );
  }

  static EstadisticasOrdenes _ordenes(Map<String, dynamic> json) {
    final porEstado = _mapa(json[SupabaseColumns.estadisticaOrdenesPorEstado]);
    return EstadisticasOrdenes(
      hoy: parseInt(json[SupabaseColumns.estadisticaOrdenesHoy]) ?? 0,
      porEstado: {
        for (final estado in EstadoOrden.values)
          estado: parseInt(porEstado[estado.dbName]) ?? 0,
      },
    );
  }

  static Map<String, dynamic> _mapa(dynamic valor) =>
      valor is Map ? Map<String, dynamic>.from(valor) : const {};
}
