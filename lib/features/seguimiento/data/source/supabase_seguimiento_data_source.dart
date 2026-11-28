import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe el seguimiento de órdenes del cliente
/// (HU-23, docs/sql/sprint3_hu23.sql). Las funciones de la base solo
/// devuelven las órdenes del cliente con sesión; el historial y los
/// productos se leen con las políticas de la HU-20 y la HU-23.
class SupabaseSeguimientoDataSource {
  final SupabaseClient _client;

  SupabaseSeguimientoDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<Orden>> ordenes({
    required bool enCurso,
    required PageRequest request,
  }) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.ordenesCliente,
        params: {
          'p_en_curso': enCurso,
          // Una fila de más indica que hay otra página (PagedResult).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      );
      return PagedResult.fromRows(
        [for (final row in _filas(rows)) _toOrden(row)],
        request,
      );
    });
  }

  Future<int> cuantasEnCurso() {
    return _proteger(() async {
      final valor = await _client.rpc(SupabaseFunctions.ordenesEnCurso);
      return parseInt(valor) ?? 0;
    });
  }

  Future<DetalleOrden?> detalle(String idOrden) {
    return _proteger(() async {
      final filas = _filas(await _client.rpc(
        SupabaseFunctions.detalleOrden,
        params: {'p_id_orden': idOrden},
      ));
      if (filas.isEmpty) return null;
      final row = filas.first;

      final items = await _client
          .from(SupabaseTables.ordenItem)
          .select()
          .eq(SupabaseColumns.itemOrden, idOrden)
          .order(SupabaseColumns.itemNombre, ascending: true);
      final historial = await _client
          .from(SupabaseTables.ordenEstado)
          .select()
          .eq(SupabaseColumns.ordenEstadoOrden, idOrden)
          .order(SupabaseColumns.ordenEstadoCreadoEn, ascending: true);

      return DetalleOrden(
        orden: _toOrden({...row, SupabaseColumns.ordenComercio: row['comercio']}),
        comercioDireccion: row[SupabaseColumns.ordenComercioDireccion] as String?,
        comercioCiudad: row[SupabaseColumns.ordenComercioCiudad] as String?,
        comercioLatitud: parseDouble(row[SupabaseColumns.ordenComercioLatitud]),
        comercioLongitud: parseDouble(row[SupabaseColumns.ordenComercioLongitud]),
        direccionEntrega: row[SupabaseColumns.ordenDireccionEntrega] as String?,
        items: [
          for (final i in items)
            ItemOrden(
              nombre: i[SupabaseColumns.itemNombre] as String? ?? '',
              marca: i[SupabaseColumns.itemMarca] as String?,
              cantidad: parseInt(i[SupabaseColumns.itemCantidad]) ?? 0,
              precioUnitario:
                  parseInt(i[SupabaseColumns.itemPrecioUnitario]) ?? 0,
            ),
        ],
        historial: [
          for (final h in historial)
            CambioEstado(
              estado: EstadoOrden.fromDbName(
                  h[SupabaseColumns.ordenEstadoEstado] as String?),
              fecha: _fecha(h[SupabaseColumns.ordenEstadoCreadoEn]) ??
                  DateTime.now(),
            ),
        ],
      );
    });
  }

  Future<void> confirmarRecepcion(String idOrden) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.confirmarRecepcion,
        params: {'p_id_orden': idOrden},
      );
    });
  }

  Future<void> registrarDispositivo(String token, String plataforma) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.registrarDispositivo,
        params: {'p_token': token, 'p_plataforma': plataforma},
      );
    });
  }

  Future<void> quitarDispositivo(String token) {
    return _proteger(() async {
      await _client.rpc(
        SupabaseFunctions.quitarDispositivo,
        params: {'p_token': token},
      );
    });
  }

  static List<Map<String, dynamic>> _filas(dynamic rows) => [
        if (rows is List)
          for (final row in rows)
            if (row is Map) Map<String, dynamic>.from(row),
      ];

  /// La base guarda la hora en UTC; se muestra en la del dispositivo.
  static DateTime? _fecha(dynamic valor) => parseDate(valor)?.toLocal();

  Orden _toOrden(Map<String, dynamic> row) => Orden(
        id: row[SupabaseColumns.ordenId].toString(),
        numero: parseInt(row[SupabaseColumns.ordenNumero]) ?? 0,
        comercio: row[SupabaseColumns.ordenComercio] as String? ?? '',
        estado: EstadoOrden.fromDbName(
            row[SupabaseColumns.ordenEstado] as String?),
        tipoEntrega: TipoEntrega.fromDbName(
            row[SupabaseColumns.ordenTipoEntrega] as String?),
        total: parseInt(row[SupabaseColumns.ordenTotal]) ?? 0,
        creadoEn: _fecha(row[SupabaseColumns.ordenCreadoEn]) ?? DateTime.now(),
        actualizadoEn: _fecha(row[SupabaseColumns.ordenActualizadoEn]),
        cerradaEn: _fecha(row[SupabaseColumns.ordenCerradaEn]),
        productos: parseInt(row[SupabaseColumns.ordenProductos]) ?? 0,
        tieneRepartidor:
            parseBool(row[SupabaseColumns.ordenTieneRepartidor]),
        calificadaComercio:
            parseBool(row[SupabaseColumns.ordenCalificadaComercio]),
        calificadaRepartidor:
            parseBool(row[SupabaseColumns.ordenCalificadaRepartidor]),
      );

  /// Traduce los errores del SDK a [AuthFailure]. Los mensajes de
  /// `confirmar_recepcion` (P0001) ya vienen en español y el traductor
  /// común los deja pasar tal cual.
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
