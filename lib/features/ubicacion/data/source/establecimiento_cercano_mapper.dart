import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Convierte una fila de `comercios_cercanos` (HU-14) o de
/// `comercios_en_radio` (HU-19): las dos devuelven las mismas columnas.
EstablecimientoCercano establecimientoCercanoFromRow(Map<String, dynamic> row) {
  return EstablecimientoCercano(
    id: row[SupabaseColumns.comercioId].toString(),
    nombre: row[SupabaseColumns.comercioNombre] as String? ?? '',
    direccion: row[SupabaseColumns.comercioDireccion] as String? ?? '',
    ciudad: row[SupabaseColumns.comercioCiudad] as String? ?? '',
    ubicacion: Ubicacion(
      latitud: (row[SupabaseColumns.comercioLatitud] as num).toDouble(),
      longitud: (row[SupabaseColumns.comercioLongitud] as num).toDouble(),
    ),
    distanciaM: (row[SupabaseColumns.cercanoDistancia] as num).toDouble(),
  );
}
