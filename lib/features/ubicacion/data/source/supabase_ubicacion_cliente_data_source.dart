import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/ubicacion/data/source/establecimiento_cercano_mapper.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe la ubicación del cliente en Supabase
/// (docs/sql/sprint3_hu19.sql): la tabla `ubicacion_cliente` para leerla
/// (la política RLS solo deja ver la propia), `guardar_ubicacion_cliente`
/// para escribirla y `comercios_en_radio` para el mapa.
class SupabaseUbicacionClienteDataSource {
  final SupabaseClient _client;

  SupabaseUbicacionClienteDataSource({required SupabaseClient client})
      : _client = client;

  Future<PreferenciaUbicacion?> obtener() {
    return traducirErroresSupabase(() async {
      final row = await _client
          .from(SupabaseTables.ubicacionCliente)
          .select()
          .maybeSingle();
      if (row == null) return null;
      return PreferenciaUbicacion(
        ubicacion: Ubicacion(
          latitud:
              (row[SupabaseColumns.ubicacionClienteLatitud] as num).toDouble(),
          longitud:
              (row[SupabaseColumns.ubicacionClienteLongitud] as num).toDouble(),
        ),
        radioM: (row[SupabaseColumns.ubicacionClienteRadio] as num).toInt(),
        direccion: row[SupabaseColumns.ubicacionClienteDireccion] as String?,
      );
    });
  }

  Future<void> guardar(PreferenciaUbicacion preferencia) {
    return traducirErroresSupabase(() async {
      await _client.rpc(
        SupabaseFunctions.guardarUbicacionCliente,
        params: {
          'p_latitud': preferencia.ubicacion.latitud,
          'p_longitud': preferencia.ubicacion.longitud,
          'p_radio_m': preferencia.radioM,
          'p_direccion': preferencia.direccion,
        },
      );
    });
  }

  Future<List<EstablecimientoCercano>> comerciosEnRadio(
    Ubicacion centro,
    int radioM,
  ) {
    return traducirErroresSupabase(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.comerciosEnRadio,
        params: {
          'p_latitud': centro.latitud,
          'p_longitud': centro.longitud,
          'p_radio_m': radioM,
        },
      ) as List<dynamic>;
      return [
        for (final row in rows)
          establecimientoCercanoFromRow(row as Map<String, dynamic>),
      ];
    });
  }
}
