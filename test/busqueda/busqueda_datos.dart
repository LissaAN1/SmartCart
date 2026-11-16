import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';

import '../support/fakes.dart';

/// Datos de prueba de la HU-12: el mismo arroz en tres tiendas (una con
/// promoción y una agotada), una lenteja agotada en todas y una leche.
const arrozResultado = ResultadoBusqueda(
  clave: 'cb:7701234567890',
  nombre: 'Arroz Diana 500 g',
  marca: 'Diana',
  codigoBarras: '7701234567890',
  categoria: 'Super',
  precioMin: 4200,
  precioMax: 5000,
  establecimientos: 2,
);

const lentejaResultado = ResultadoBusqueda(
  clave: 'nm:lenteja|',
  nombre: 'Lenteja',
  categoria: 'Super',
);

const lecheResultado = ResultadoBusqueda(
  clave: 'cb:7700000000002',
  nombre: 'Leche entera 1L',
  marca: 'Alquería',
  categoria: 'Lácteos',
  precioMin: 3800,
  precioMax: 3800,
  establecimientos: 1,
);

final arrozDetalle = DetalleProducto(
  clave: 'cb:7701234567890',
  nombre: 'Arroz Diana 500 g',
  marca: 'Diana',
  codigoBarras: '7701234567890',
  categoria: 'Super',
  ofertas: [
    OfertaProducto(
      idProducto: 'p1',
      comercio: 'Minimercado La Esquina',
      direccion: 'Calle 10 # 5-20',
      ciudad: 'Cali',
      precio: 4200,
      precioNormal: 5000,
      enPromocion: true,
      actualizadoEn: DateTime(2026, 11, 15, 9, 30),
    ),
    OfertaProducto(
      idProducto: 'p2',
      comercio: 'Tienda Don Pepe',
      ciudad: 'Cali',
      precio: 5000,
      precioNormal: 5000,
      actualizadoEn: DateTime(2026, 11, 14, 18),
    ),
    OfertaProducto(
      idProducto: 'p3',
      comercio: 'Fruver El Centro',
      precio: 4800,
      precioNormal: 4800,
      disponible: false,
      actualizadoEn: DateTime(2026, 11, 10, 8),
    ),
  ],
);

/// Cliente con sesión y el catálogo de prueba cargado.
TestEnv entornoBusqueda() {
  final env = TestEnv()..iniciarSesionCon({UserRole.cliente});
  env.busqueda.resultados.addAll(
      const [arrozResultado, lentejaResultado, lecheResultado]);
  env.busqueda.detalles[arrozDetalle.clave] = arrozDetalle;
  return env;
}
