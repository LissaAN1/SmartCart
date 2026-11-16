/// De dónde viene un precio. En la HU-11 solo escribe el comercio; la HU-13
/// mostrará la fuente junto a cada precio.
enum FuentePrecio {
  comercio('comercio', 'Comercio'),
  colaborador('colaborador', 'Colaborador');

  /// Valor guardado en la columna `fuente`.
  final String codigo;

  /// Texto que se muestra en pantalla.
  final String etiqueta;

  const FuentePrecio(this.codigo, this.etiqueta);

  /// Un valor desconocido se lee como [comercio], que es el valor por
  /// defecto de la columna.
  static FuentePrecio desdeCodigo(String? codigo) => FuentePrecio.values
      .firstWhere((f) => f.codigo == codigo, orElse: () => comercio);
}

/// Lo que el comercio guarda: el precio en pesos y si hay existencias.
class PrecioDatos {
  final int precio;
  final bool disponible;

  const PrecioDatos({required this.precio, this.disponible = true});
}

/// Precio actual de un producto, ya guardado.
class PrecioProducto {
  final String idProducto;
  final int precio;
  final bool disponible;
  final FuentePrecio fuente;
  final DateTime actualizadoEn;

  const PrecioProducto({
    required this.idProducto,
    required this.precio,
    required this.disponible,
    required this.fuente,
    required this.actualizadoEn,
  });
}

/// Una fila del historial: cómo quedó el precio después de un cambio.
class RegistroPrecio {
  final int precio;
  final bool disponible;
  final FuentePrecio fuente;
  final DateTime registradoEn;

  const RegistroPrecio({
    required this.precio,
    required this.disponible,
    required this.fuente,
    required this.registradoEn,
  });
}
