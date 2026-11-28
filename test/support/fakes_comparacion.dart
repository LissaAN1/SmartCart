import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/comparacion/domain/repository/comparacion_repository.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

import 'fakes.dart';
import 'fakes_cliente.dart';
import 'fakes_ubicacion.dart';

// ───────────────────────── Datos de ejemplo ─────────────────────────
//
// Tres comercios a ~0,6 km (A), ~3,3 km (B) y ~7,8 km (C) del cliente
// (`ubicacionCliente`, el mismo punto de los comercios de la HU-19).

/// "Hoy" en las pruebas de la comparación.
final ahoraComparacion = DateTime(2026, 11, 28, 10);

const _ubicacionA = Ubicacion(latitud: 3.4566, longitud: -76.5320);
const _ubicacionB = Ubicacion(latitud: 3.4816, longitud: -76.5320);
const _ubicacionC = Ubicacion(latitud: 3.5216, longitud: -76.5320);

OfertaComparable oferta(
  String idProducto,
  String comercio,
  int precio, {
  bool disponible = true,
  bool sinUbicacion = false,
  double? calificacion,
  int totalCalificaciones = 0,
  bool enPromocion = false,
  int? precioNormal,
  FuentePrecio fuente = FuentePrecio.comercio,
}) {
  final (nombre, ubicacion, cal, total) = switch (comercio) {
    'A' => ('Super A', _ubicacionA, 2.0, 5),
    'B' => ('Tienda B', _ubicacionB, 5.0, 10),
    'C' => ('Fruver C', _ubicacionC, null, 0),
    _ => ('Comercio $comercio', _ubicacionA, null, 0),
  };
  return OfertaComparable(
    idProducto: idProducto,
    idComercio: comercio,
    comercio: nombre,
    direccion: 'Calle $comercio',
    ciudad: 'Cali',
    ubicacionComercio: sinUbicacion ? null : ubicacion,
    precio: precio,
    precioNormal: precioNormal ?? precio,
    enPromocion: enPromocion,
    disponible: disponible,
    fuente: fuente,
    actualizadoEn: ahoraComparacion.subtract(const Duration(hours: 2)),
    calificacion: calificacion ?? cal,
    totalCalificaciones: calificacion == null ? total : totalCalificaciones,
  );
}

LineaComparable linea(
  String idProducto,
  String nombre,
  int cantidad,
  List<OfertaComparable> ofertas,
) =>
    LineaComparable(
      idProducto: idProducto,
      nombre: nombre,
      cantidad: cantidad,
      ofertas: ofertas,
    );

/// Carrito de ejemplo. El producto del carrito es el primero de cada línea.
/// Con los precios y las calificaciones de los comercios (A 2 estrellas, B 5,
/// C sin calificaciones):
///   · Ahorro: arroz en C, leche y café en B, pan en A → 3 comercios,
///     $ 29.900 (ahorra $ 2.200 frente a $ 32.100).
///   · Calidad/precio: arroz, leche y café en B, pan en A → $ 30.300.
///   · Comodidad: todo en A → 1 comercio, $ 32.600 (ahorro $ 0).
List<LineaComparable> carritoEjemplo() => [
      linea('arroz-a', 'Arroz 500 g', 2, [
        oferta('arroz-a', 'A', 5000),
        oferta('arroz-b', 'B', 4200),
        oferta('arroz-c', 'C', 4000),
      ]),
      linea('leche-a', 'Leche 1 L', 1, [
        oferta('leche-a', 'A', 4100),
        oferta('leche-b', 'B', 3900),
      ]),
      linea('cafe-b', 'Café 500 g', 1, [
        oferta('cafe-b', 'B', 12000),
        oferta('cafe-a', 'A', 12500),
      ]),
      linea('pan-a', 'Pan tajado', 3, [
        oferta('pan-a', 'A', 2000),
      ]),
    ];

// ───────────────────────── Dobles ─────────────────────────

class FakeComparacionRepository implements ComparacionRepository {
  List<LineaComparable> lineas = [];
  Object? error;
  int llamadas = 0;

  @override
  Future<List<LineaComparable>> ofertasDelCarrito() async {
    llamadas++;
    if (error != null) throw error!;
    return lineas;
  }
}

final _fakesDeComparacion =
    Expando<FakeComparacionRepository>('fakesDeComparacion');

/// Casos de uso y Blocs de la comparación (HU-18) con los dobles del
/// entorno.
extension EntornoComparacion on TestEnv {
  FakeComparacionRepository get comparacion =>
      _fakesDeComparacion[this] ??= FakeComparacionRepository();

  GetOfertasCarritoUseCase get getOfertasCarrito => GetOfertasCarritoUseCase(
      cliente: clienteActivo, repositorio: comparacion);

  ComparacionBloc comparacionBloc() => ComparacionBloc(
        ofertas: getOfertasCarrito,
        miUbicacion: getMiUbicacion,
        comparar: CompararCarritoUseCase(),
      );

  PreciosCarritoBloc preciosCarritoBloc() =>
      PreciosCarritoBloc(ofertas: getOfertasCarrito);
}
