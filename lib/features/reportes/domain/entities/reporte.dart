import 'dart:typed_data';

import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';

// La entidad pasó a `ubicacion/` porque también la usa el mapa del cliente
// (HU-19); la exportamos aquí para no cambiar los imports de la HU-14.
export 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';

/// Cómo se busca el producto dentro de un establecimiento: por nombre o
/// marca (texto libre) o por el código de barras escaneado.
class ConsultaProductoReporte {
  final String texto;
  final bool esCodigo;

  const ConsultaProductoReporte({this.texto = '', this.esCodigo = false});

  const ConsultaProductoReporte.codigo(String codigo)
      : texto = codigo,
        esCodigo = true;
}

/// Foto de la etiqueta del precio, ya leída en memoria.
class FotoReporte {
  final Uint8List bytes;

  /// `jpg`, `png` o `webp`.
  final String extension;

  const FotoReporte({required this.bytes, this.extension = 'jpg'});

  String get mimeType => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}

/// Lo que el colaborador llena en el formulario del reporte. Los precios van
/// en pesos colombianos (COP), sin decimales.
class ReporteDatos {
  final EstablecimientoCercano establecimiento;
  final Producto producto;
  final int precio;

  /// Precio de la promoción; opcional.
  final int? precioPromocional;
  final bool agotado;

  const ReporteDatos({
    required this.establecimiento,
    required this.producto,
    required this.precio,
    this.precioPromocional,
    this.agotado = false,
  });
}

/// Un establecimiento que el colaborador sugiere porque aún no está en la
/// plataforma.
class SugerenciaDatos {
  final String nombre;
  final String direccion;
  final String ciudad;

  const SugerenciaDatos({
    required this.nombre,
    required this.direccion,
    required this.ciudad,
  });
}
