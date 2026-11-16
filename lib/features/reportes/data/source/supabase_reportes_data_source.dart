import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/data/source/supabase_catalogo_data_source.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase para los reportes de precio (HU-14):
/// las funciones `comercios_cercanos` y `enviar_reporte_precio`, la tabla
/// `establecimiento_sugerido`, la lectura de productos y el bucket `reportes`.
///
/// Las reglas de seguridad (quién lee, quién escribe y a qué distancia) están
/// en la base, en docs/sql/sprint2_hu14.sql.
class SupabaseReportesDataSource {
  final SupabaseClient _client;

  SupabaseReportesDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<EstablecimientoCercano>> establecimientosCercanos(
    Ubicacion ubicacion,
    PageRequest request,
  ) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.comerciosCercanos,
        params: {
          'p_latitud': ubicacion.latitud,
          'p_longitud': ubicacion.longitud,
          // Una fila de más: indica si hay otra página (ver PageRequest).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [for (final row in rows) _toEstablecimiento(row as Map<String, dynamic>)],
        request,
      );
    });
  }

  Future<PagedResult<Producto>> buscarProductos(
    String idComercio,
    ConsultaProductoReporte consulta,
    PageRequest request,
  ) {
    return _proteger(() async {
      var filtro = _client
          .from(SupabaseTables.producto)
          .select(SupabaseCatalogoDataSource.seleccion)
          .eq(SupabaseColumns.productoComercio, idComercio);

      final texto = consulta.texto.trim();
      if (consulta.esCodigo) {
        filtro = filtro.eq(SupabaseColumns.productoCodigoBarras, texto);
      } else if (texto.isNotEmpty) {
        final patron = _limpiarPatron(texto);
        filtro = filtro.or(
          '${SupabaseColumns.productoNombre}.ilike.%$patron%,'
          '${SupabaseColumns.productoMarca}.ilike.%$patron%',
        );
      }

      final rows = await filtro
          .order(SupabaseColumns.productoNombre, ascending: true)
          .order(SupabaseColumns.productoId, ascending: true)
          .range(request.from, request.to);
      return PagedResult.fromRows(
        [for (final row in rows) productoFromRow(row)],
        request,
      );
    });
  }

  Future<String> enviarReporte(
    String userId,
    ReporteDatos datos,
    FotoReporte foto,
    Ubicacion ubicacion,
  ) {
    return _proteger(() async {
      // La carpeta lleva el id de la cuenta: la política de Storage solo deja
      // subir a la propia, y `enviar_reporte_precio` lo vuelve a comprobar.
      final ruta = '$userId/${DateTime.now().microsecondsSinceEpoch}.${foto.extension}';
      final bucket = _client.storage.from(SupabaseBuckets.reportes);
      await bucket.uploadBinary(
        ruta,
        foto.bytes,
        fileOptions: FileOptions(contentType: foto.mimeType),
      );
      try {
        final id = await _client.rpc(
          SupabaseFunctions.enviarReportePrecio,
          params: {
            'p_id_comercio': datos.establecimiento.id,
            'p_id_producto': datos.producto.id,
            'p_precio': datos.precio,
            'p_precio_promocional': datos.precioPromocional,
            'p_agotado': datos.agotado,
            'p_foto_path': ruta,
            'p_latitud': ubicacion.latitud,
            'p_longitud': ubicacion.longitud,
          },
        );
        return id.toString();
      } catch (_) {
        // Si el reporte no se guardó, la foto subida queda huérfana: la
        // borramos. Si esto también falla no importa, no es lo importante.
        try {
          await bucket.remove([ruta]);
        } catch (_) {}
        rethrow;
      }
    });
  }

  /// La función `mis_reportes` devuelve solo los reportes de quien llama y
  /// trae el nombre del establecimiento, que el colaborador no puede leer de
  /// la tabla `comercio`.
  Future<PagedResult<MiReporte>> misReportes(PageRequest request) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.misReportes,
        params: {
          // Una fila de más: indica si hay otra página (ver PageRequest).
          'p_limite': request.pageSize + 1,
          'p_desplazamiento': request.from,
        },
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [for (final row in rows) _toMiReporte(row as Map<String, dynamic>)],
        request,
      );
    });
  }

  Future<void> sugerirEstablecimiento(
    String userId,
    SugerenciaDatos datos,
    Ubicacion ubicacion,
  ) {
    return _proteger(() async {
      await _client.from(SupabaseTables.establecimientoSugerido).insert({
        SupabaseColumns.sugeridoColaborador: userId,
        SupabaseColumns.sugeridoNombre: datos.nombre,
        SupabaseColumns.sugeridoDireccion: datos.direccion,
        SupabaseColumns.sugeridoCiudad: datos.ciudad,
        SupabaseColumns.sugeridoLatitud: ubicacion.latitud,
        SupabaseColumns.sugeridoLongitud: ubicacion.longitud,
      });
    });
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
    } on StorageException {
      throw const AuthFailure(
        'No pudimos subir la foto. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on Exception {
      throw connectionFailure();
    }
  }

  /// El texto va dentro de un filtro `or(...)`: quitamos lo que lo rompería
  /// (comas, paréntesis) o lo convertiría en otro patrón (% y *).
  String _limpiarPatron(String texto) =>
      texto.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

  MiReporte _toMiReporte(Map<String, dynamic> row) {
    final promocion = row[SupabaseColumns.misReportePromocion] as num?;
    return MiReporte(
      id: row[SupabaseColumns.misReporteId].toString(),
      producto: row[SupabaseColumns.misReporteProducto] as String? ?? '',
      establecimiento: row[SupabaseColumns.misReporteComercio] as String? ?? '',
      precio: (row[SupabaseColumns.misReportePrecio] as num).toInt(),
      precioPromocional: promocion?.toInt(),
      agotado: row[SupabaseColumns.misReporteAgotado] as bool? ?? false,
      estado: EstadoReporte.fromDbName(
        row[SupabaseColumns.misReporteEstado] as String?,
      ),
      // La base guarda la hora en UTC; se muestra en la del dispositivo.
      creadoEn: DateTime.parse(
        row[SupabaseColumns.misReporteCreadoEn].toString(),
      ).toLocal(),
    );
  }

  EstablecimientoCercano _toEstablecimiento(Map<String, dynamic> row) {
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
}
