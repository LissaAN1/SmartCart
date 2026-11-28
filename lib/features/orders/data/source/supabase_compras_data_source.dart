import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase para las compras (HU-20): las
/// funciones `previsualizar_compra`, `confirmar_compra` y `mis_ordenes`.
///
/// Los precios, quién puede comprar y las reglas de la entrega las decide la
/// base, en docs/sql/sprint3_hu20_hu25.sql; sus mensajes salen en español y se
/// muestran tal cual.
class SupabaseComprasDataSource {
  final SupabaseClient _client;

  SupabaseComprasDataSource({required SupabaseClient client})
      : _client = client;

  Future<List<LineaPrevia>> previsualizar(List<LineaSolicitud> lineas) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.previsualizarCompra,
        params: {'p_lineas': _lineasJson(lineas)},
      ) as List<dynamic>;
      return [for (final r in rows) _toPrevia(r as Map<String, dynamic>)];
    });
  }

  Future<List<OrdenGenerada>> confirmar(
    List<LineaSolicitud> lineas,
    Map<String, EleccionEntrega> elecciones, {
    List<String>? quitarDelCarrito,
  }) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.confirmarCompra,
        params: {
          'p_lineas': _lineasJson(lineas),
          'p_entregas': [
            for (final e in elecciones.entries)
              {'id_comercio': e.key, 'tipo': e.value.tipo.dbName},
          ],
          'p_quitar_del_carrito': quitarDelCarrito,
        },
      ) as List<dynamic>;
      return [
        for (final r in rows) _toOrdenGenerada(r as Map<String, dynamic>),
      ];
    });
  }

  Future<PagedResult<Orden>> misOrdenes(PageRequest request) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.misOrdenes,
        params: {
          // Una fila de más: indica si hay otra página (ver PageRequest).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [for (final r in rows) _toOrden(r as Map<String, dynamic>)],
        request,
      );
    });
  }

  List<Map<String, dynamic>> _lineasJson(List<LineaSolicitud> lineas) => [
        for (final l in lineas)
          {'id_producto': l.idProducto, 'cantidad': l.cantidad},
      ];

  LineaPrevia _toPrevia(Map<String, dynamic> row) => LineaPrevia(
        idComercio: row[SupabaseColumns.lineaComercioId]?.toString(),
        establecimiento: row[SupabaseColumns.lineaComercio] as String? ?? '',
        servicio: ServicioComercio.fromDbName(
          row[SupabaseColumns.lineaServicio] as String?,
        ),
        linea: _toLinea(row),
      );

  LineaCompra _toLinea(Map<String, dynamic> row) {
    final precio = (row[SupabaseColumns.lineaPrecio] as num?)?.toInt();
    return LineaCompra(
      idProducto: row[SupabaseColumns.lineaProducto].toString(),
      nombre: row[SupabaseColumns.lineaNombre] as String? ?? '',
      marca: row[SupabaseColumns.lineaMarca] as String?,
      cantidad: (row[SupabaseColumns.lineaCantidad] as num).toInt(),
      precioUnitario: precio,
      // Sin precio o agotado: no se puede comprar.
      disponible:
          precio != null && (row[SupabaseColumns.lineaDisponible] as bool? ?? false),
    );
  }

  OrdenGenerada _toOrdenGenerada(Map<String, dynamic> row) {
    return OrdenGenerada(
      id: row[SupabaseColumns.compraOrdenId].toString(),
      numero: (row[SupabaseColumns.compraOrdenNumero] as num).toInt(),
      idComercio: row[SupabaseColumns.compraComercioId].toString(),
      comercio: row[SupabaseColumns.compraComercio] as String? ?? '',
      tipoEntrega: TipoEntrega.fromDbName(
        row[SupabaseColumns.compraTipoEntrega] as String?,
      ),
      total: (row[SupabaseColumns.compraTotal] as num).toInt(),
    );
  }

  Orden _toOrden(Map<String, dynamic> row) {
    return Orden(
      id: row[SupabaseColumns.ordenId].toString(),
      numero: (row[SupabaseColumns.ordenNumero] as num).toInt(),
      comercio: row[SupabaseColumns.ordenComercio] as String? ?? '',
      estado: EstadoOrden.fromDbName(row[SupabaseColumns.ordenEstado] as String?),
      tipoEntrega: TipoEntrega.fromDbName(
        row[SupabaseColumns.ordenTipoEntrega] as String?,
      ),
      total: (row[SupabaseColumns.ordenTotal] as num).toInt(),
      // La base guarda la hora en UTC; se muestra en la del dispositivo.
      creadoEn: DateTime.parse(
        row[SupabaseColumns.ordenCreadoEn].toString(),
      ).toLocal(),
      tieneRepartidor:
          row[SupabaseColumns.ordenTieneRepartidor] as bool? ?? false,
      calificadaComercio:
          row[SupabaseColumns.ordenCalificadaComercio] as bool? ?? false,
      calificadaRepartidor:
          row[SupabaseColumns.ordenCalificadaRepartidor] as bool? ?? false,
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
