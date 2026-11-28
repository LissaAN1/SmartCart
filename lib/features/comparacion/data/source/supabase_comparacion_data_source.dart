import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que llama a `ofertas_del_carrito` (HU-18,
/// docs/sql/sprint3_hu18.sql). La función devuelve una fila por línea del
/// carrito y oferta; aquí se agrupan por línea.
class SupabaseComparacionDataSource {
  final SupabaseClient _client;

  SupabaseComparacionDataSource({required SupabaseClient client})
      : _client = client;

  Future<List<LineaComparable>> ofertasDelCarrito() {
    return traducirErroresSupabase(() async {
      final rows =
          await _client.rpc(SupabaseFunctions.ofertasDelCarrito) as List<dynamic>;
      final lineas = <String, _Linea>{};
      for (final dynamic fila in rows) {
        final row = Map<String, dynamic>.from(fila as Map);
        final id = row[SupabaseColumns.ofertaCarritoLinea].toString();
        final linea = lineas.putIfAbsent(
          id,
          () => _Linea(
            id: id,
            nombre: row[SupabaseColumns.busquedaNombre] as String? ?? '',
            marca: row[SupabaseColumns.busquedaMarca] as String?,
            cantidad: parseInt(row[SupabaseColumns.filaCantidad]) ?? 1,
          ),
        );
        // Un producto sin ofertas llega una vez con la oferta vacía.
        if (row[SupabaseColumns.ofertaProducto] != null) {
          linea.ofertas.add(_toOferta(row));
        }
      }
      return [for (final l in lineas.values) l.aEntidad()];
    });
  }

  static OfertaComparable _toOferta(Map<String, dynamic> row) {
    final latitud = parseDouble(row[SupabaseColumns.comercioLatitud]);
    final longitud = parseDouble(row[SupabaseColumns.comercioLongitud]);
    return OfertaComparable(
      idProducto: row[SupabaseColumns.ofertaProducto].toString(),
      idComercio: row[SupabaseColumns.ofertaCarritoComercio].toString(),
      comercio: row[SupabaseColumns.ofertaComercio] as String? ?? '',
      direccion: row[SupabaseColumns.ofertaDireccion] as String? ?? '',
      ciudad: row[SupabaseColumns.ofertaCiudad] as String? ?? '',
      ubicacionComercio: latitud == null || longitud == null
          ? null
          : Ubicacion(latitud: latitud, longitud: longitud),
      precio: parseInt(row[SupabaseColumns.ofertaPrecio]) ?? 0,
      precioNormal: parseInt(row[SupabaseColumns.ofertaPrecioNormal]) ?? 0,
      enPromocion: parseBool(row[SupabaseColumns.ofertaEnPromocion]),
      disponible: parseBool(row[SupabaseColumns.ofertaDisponible]),
      fuente: FuentePrecio.desdeCodigo(
          row[SupabaseColumns.ofertaFuente] as String?),
      actualizadoEn: parseDate(row[SupabaseColumns.ofertaActualizadoEn]) ??
          DateTime.now(),
      calificacion: parseDouble(row[SupabaseColumns.ofertaCalificacion]),
      totalCalificaciones:
          parseInt(row[SupabaseColumns.ofertaTotalCalificaciones]) ?? 0,
    );
  }
}

class _Linea {
  final String id;
  final String nombre;
  final String? marca;
  final int cantidad;
  final ofertas = <OfertaComparable>[];

  _Linea({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.cantidad,
  });

  LineaComparable aEntidad() => LineaComparable(
        idProducto: id,
        nombre: nombre,
        marca: marca,
        cantidad: cantidad,
        ofertas: ofertas,
      );
}
