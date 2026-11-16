import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe `precio_producto`, `historial_precio` y
/// `promocion` (HU-11). Las políticas RLS de docs/sql/sprint2_hu11.sql solo
/// dejan al dueño de un comercio aprobado tocar los precios de sus productos.
/// La fecha de actualización y el historial los pone la base (triggers).
class SupabasePreciosDataSource {
  final SupabaseClient _client;

  SupabasePreciosDataSource({required SupabaseClient client})
      : _client = client;

  Future<PrecioProducto?> precio(String idProducto) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.precioProducto)
          .select()
          .eq(SupabaseColumns.precioProducto, idProducto)
          .maybeSingle();
      return row == null ? null : _toPrecio(row);
    });
  }

  Future<Promocion?> promocion(String idProducto) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.promocion)
          .select()
          .eq(SupabaseColumns.promocionProducto, idProducto)
          .maybeSingle();
      return row == null ? null : _toPromocion(row);
    });
  }

  Future<List<RegistroPrecio>> historial(String idProducto, int limite) {
    return _proteger(() async {
      final rows = await _client
          .from(SupabaseTables.historialPrecio)
          .select()
          .eq(SupabaseColumns.historialProducto, idProducto)
          .order(SupabaseColumns.historialRegistradoEn, ascending: false)
          .limit(limite);
      return [
        for (final row in rows)
          RegistroPrecio(
            precio: parseInt(row[SupabaseColumns.historialPrecio]) ?? 0,
            disponible: parseBool(row[SupabaseColumns.historialDisponible]),
            fuente: FuentePrecio.desdeCodigo(
                row[SupabaseColumns.historialFuente] as String?),
            registradoEn:
                parseDate(row[SupabaseColumns.historialRegistradoEn]) ??
                    DateTime.now(),
          ),
      ];
    });
  }

  /// `upsert`: crea el precio la primera vez y lo actualiza después.
  Future<PrecioProducto> guardarPrecio(String idProducto, PrecioDatos datos) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.precioProducto)
          .upsert(
            {
              SupabaseColumns.precioProducto: idProducto,
              SupabaseColumns.precioValor: datos.precio,
              SupabaseColumns.precioDisponible: datos.disponible,
              SupabaseColumns.precioFuente: FuentePrecio.comercio.codigo,
            },
            onConflict: SupabaseColumns.precioProducto,
          )
          .select()
          .single();
      return _toPrecio(row);
    });
  }

  /// Hay una promoción por producto: guardar otra reemplaza la anterior.
  Future<Promocion> guardarPromocion(String idProducto, PromocionDatos datos) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.promocion)
          .upsert(
            {
              SupabaseColumns.promocionProducto: idProducto,
              SupabaseColumns.promocionPrecio: datos.precioPromocional,
              SupabaseColumns.promocionInicio: toSqlDate(datos.inicio),
              SupabaseColumns.promocionFin: toSqlDate(datos.fin),
            },
            onConflict: SupabaseColumns.promocionProducto,
          )
          .select()
          .single();
      return _toPromocion(row);
    });
  }

  Future<void> quitarPromocion(String idProducto) {
    return _proteger(() async {
      await _client
          .from(SupabaseTables.promocion)
          .delete()
          .eq(SupabaseColumns.promocionProducto, idProducto);
    });
  }

  /// Traduce los errores del SDK a [AuthFailure], igual que el catálogo.
  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      // 23514: un `check` de la tabla (precio o fechas fuera de rango).
      if (e.code == '23514') {
        throw const AuthFailure(
          'Revisa el precio y las fechas: algún valor no es válido.',
        );
      }
      // 23503: el producto ya no existe (se eliminó en otra pantalla).
      if (e.code == '23503') {
        throw const AuthFailure('No encontramos ese producto.');
      }
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  PrecioProducto _toPrecio(Map<String, dynamic> row) => PrecioProducto(
        idProducto: row[SupabaseColumns.precioProducto].toString(),
        precio: parseInt(row[SupabaseColumns.precioValor]) ?? 0,
        disponible: parseBool(row[SupabaseColumns.precioDisponible]),
        fuente: FuentePrecio.desdeCodigo(
            row[SupabaseColumns.precioFuente] as String?),
        actualizadoEn: parseDate(row[SupabaseColumns.precioActualizadoEn]) ??
            DateTime.now(),
      );

  Promocion _toPromocion(Map<String, dynamic> row) => Promocion(
        idProducto: row[SupabaseColumns.promocionProducto].toString(),
        precioPromocional: parseInt(row[SupabaseColumns.promocionPrecio]) ?? 0,
        inicio: parseSqlDate(row[SupabaseColumns.promocionInicio])!,
        fin: parseSqlDate(row[SupabaseColumns.promocionFin])!,
      );
}
