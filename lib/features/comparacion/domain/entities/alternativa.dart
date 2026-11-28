import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Qué prioriza el cliente al comparar su carrito (HU-18).
enum CriterioCompra {
  ahorro(
    'Mayor ahorro',
    'Cada producto en el comercio donde está más barato.',
  ),
  calidadPrecio(
    'Calidad/precio',
    'Combina el precio con la calificación de cada comercio.',
  ),
  comodidad(
    'Comodidad',
    'Todo en el menor número de comercios posible.',
  );

  final String etiqueta;
  final String descripcion;

  const CriterioCompra(this.etiqueta, this.descripcion);
}

/// Un producto de la alternativa: qué oferta se eligió para esa línea.
class ItemAlternativa {
  final LineaComparable linea;
  final OfertaComparable oferta;

  const ItemAlternativa({required this.linea, required this.oferta});

  int get subtotal => oferta.precio * linea.cantidad;
}

/// Lo que se compra en un comercio dentro de una alternativa.
class CompraEnComercio {
  final String idComercio;
  final String nombre;
  final String direccion;
  final String ciudad;
  final Ubicacion? ubicacion;
  final double? calificacion;
  final int totalCalificaciones;

  /// Distancia en línea recta desde la ubicación del cliente; `null` si no
  /// se conoce una de las dos.
  final double? distanciaM;
  final List<ItemAlternativa> items;

  const CompraEnComercio({
    required this.idComercio,
    required this.nombre,
    required this.items,
    this.direccion = '',
    this.ciudad = '',
    this.ubicacion,
    this.calificacion,
    this.totalCalificaciones = 0,
    this.distanciaM,
  });

  int get subtotal => items.fold(0, (suma, i) => suma + i.subtotal);

  bool get tieneCalificaciones =>
      calificacion != null && totalCalificaciones > 0;
}

/// Una forma de comprar el carrito según un criterio.
class Alternativa {
  final CriterioCompra criterio;
  final List<CompraEnComercio> comercios;

  /// Lo que costaría hoy el carrito tal como está, contando solo los
  /// productos que tienen precio en su comercio y que la alternativa cubre.
  final int totalActual;

  /// Suma de las distancias del cliente a cada comercio; `null` si falta la
  /// ubicación del cliente o la de algún comercio.
  final double? distanciaTotalM;

  const Alternativa({
    required this.criterio,
    required this.comercios,
    required this.totalActual,
    this.distanciaTotalM,
  });

  int get total => comercios.fold(0, (suma, c) => suma + c.subtotal);

  int get establecimientos => comercios.length;

  Iterable<ItemAlternativa> get items => comercios.expand((c) => c.items);

  /// Lo que se confirma al elegir esta alternativa (HU-20): cada producto en
  /// el comercio elegido (si dos líneas del carrito terminan en el mismo, se
  /// suman sus unidades) y los productos del carrito que quedan cubiertos.
  SeleccionCompra get seleccion {
    final cantidades = <String, int>{};
    for (final i in items) {
      cantidades[i.oferta.idProducto] =
          (cantidades[i.oferta.idProducto] ?? 0) + i.linea.cantidad;
    }
    return SeleccionCompra(
      lineas: [
        for (final e in cantidades.entries)
          LineaSolicitud(idProducto: e.key, cantidad: e.value),
      ],
      productosDelCarrito: [for (final i in items) i.linea.idProducto],
    );
  }

  /// Diferencia entre el carrito actual y la alternativa, sobre los mismos
  /// productos. Si la alternativa cuesta más, el ahorro es 0.
  int get ahorro {
    final mismos = items
        .where((i) => i.linea.precioActual != null)
        .fold(0, (suma, i) => suma + i.subtotal);
    final diferencia = totalActual - mismos;
    return diferencia > 0 ? diferencia : 0;
  }
}

/// Lo que devuelve la comparación: una alternativa por criterio y los
/// productos que no se encontraron en ningún comercio.
class ResultadoComparacion {
  final Map<CriterioCompra, Alternativa> alternativas;
  final List<LineaComparable> faltantes;

  const ResultadoComparacion({
    required this.alternativas,
    this.faltantes = const [],
  });

  bool get sinAlternativas => alternativas.isEmpty;
}
