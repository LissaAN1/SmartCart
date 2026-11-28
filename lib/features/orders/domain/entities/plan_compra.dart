import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Un producto y cuántas unidades se piden; es lo que viaja a la base para
/// armar o confirmar la compra. Los precios no viajan: los pone la base.
class LineaSolicitud {
  final String idProducto;
  final int cantidad;

  const LineaSolicitud({required this.idProducto, required this.cantidad});
}

/// Una línea de la compra con el precio de hoy.
class LineaCompra {
  /// `null` en un establecimiento sin registro en SmartCart.
  final String? idProducto;
  final String nombre;
  final String? marca;
  final int cantidad;

  /// Precio unitario en pesos (COP), con la promoción si hoy está vigente;
  /// `null` si el producto no tiene precio.
  final int? precioUnitario;

  /// Se puede comprar: tiene precio y no está agotado.
  final bool disponible;

  const LineaCompra({
    required this.nombre,
    required this.cantidad,
    this.idProducto,
    this.marca,
    this.precioUnitario,
    this.disponible = true,
  });

  /// Lo que cuestan las unidades pedidas; 0 si no se puede comprar.
  int get subtotal =>
      disponible && precioUnitario != null ? precioUnitario! * cantidad : 0;
}

/// Las líneas de la compra que salen de un mismo establecimiento. Si está
/// registrado en SmartCart ([idComercio] no es nulo) se le genera una orden;
/// si no, el cliente recibe su lista de compra.
class GrupoCompra {
  final String? idComercio;
  final String establecimiento;

  /// Lo que ofrece el comercio (recogida, entrega o ambos). Sin registro no
  /// se sabe, y no se genera orden.
  final ServicioComercio? servicio;
  final List<LineaCompra> lineas;

  const GrupoCompra({
    required this.establecimiento,
    required this.lineas,
    this.idComercio,
    this.servicio,
  });

  bool get registrado => idComercio != null;

  /// La entrega solo está disponible en comercios que la ofrecen.
  bool get ofreceEntrega =>
      servicio == ServicioComercio.entrega || servicio == ServicioComercio.ambos;

  int get subtotal => lineas.fold(0, (suma, l) => suma + l.subtotal);

  bool get hayNoDisponibles => lineas.any((l) => !l.disponible);
}

/// Una línea tal como la devuelve la base: el producto con el comercio que lo
/// vende. [PlanCompra.agrupar] las reparte por comercio.
class LineaPrevia {
  /// `null` en un establecimiento sin registro en SmartCart.
  final String? idComercio;
  final String establecimiento;
  final ServicioComercio? servicio;
  final LineaCompra linea;

  const LineaPrevia({
    required this.establecimiento,
    required this.linea,
    this.idComercio,
    this.servicio,
  });
}

/// Lo que el cliente va a comprar, repartido por establecimiento. Es la
/// "alternativa de carrito" elegida: hoy sale del carrito tal cual (cada
/// producto es de un comercio), y la HU-18 podrá proponer otros repartos con
/// la misma forma.
class PlanCompra {
  final List<GrupoCompra> grupos;

  const PlanCompra(this.grupos);

  /// Reparte las [lineas] por comercio: un grupo por cada comercio
  /// registrado (los productos del mismo comercio van juntos, en el orden en
  /// que llegan) y un grupo por cada establecimiento sin registro.
  factory PlanCompra.agrupar(List<LineaPrevia> lineas) {
    final grupos = <String, List<LineaPrevia>>{};
    for (final l in lineas) {
      final clave = l.idComercio ?? 'sin-registro:${l.establecimiento}';
      grupos.putIfAbsent(clave, () => []).add(l);
    }
    return PlanCompra([
      for (final g in grupos.values)
        GrupoCompra(
          idComercio: g.first.idComercio,
          establecimiento: g.first.establecimiento,
          servicio: g.first.servicio,
          lineas: [for (final l in g) l.linea],
        ),
    ]);
  }

  /// Los comercios registrados: a cada uno le sale una orden.
  List<GrupoCompra> get registrados =>
      grupos.where((g) => g.registrado).toList();

  /// Los establecimientos sin registro: reciben una lista de compra.
  List<GrupoCompra> get sinRegistro =>
      grupos.where((g) => !g.registrado).toList();

  bool get estaVacio => grupos.every((g) => g.lineas.isEmpty);

  bool get hayNoDisponibles => grupos.any((g) => g.hayNoDisponibles);

  int get total => grupos.fold(0, (suma, g) => suma + g.subtotal);

  int get unidades => grupos.fold(
      0, (suma, g) => suma + g.lineas.fold(0, (s, l) => s + l.cantidad));

  /// Las líneas que se mandan a la base: solo las de comercios registrados.
  List<LineaSolicitud> get lineasSolicitud => [
        for (final g in registrados)
          for (final l in g.lineas)
            LineaSolicitud(idProducto: l.idProducto!, cantidad: l.cantidad),
      ];
}
