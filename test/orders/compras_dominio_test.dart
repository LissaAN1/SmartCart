import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/orders/domain/compras_reglas.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/fakes_ordenes.dart';

const _arroz = LineaCompra(
  idProducto: 'p1',
  nombre: 'Arroz',
  cantidad: 2,
  precioUnitario: 3000,
);
const _leche = LineaCompra(
  idProducto: 'p2',
  nombre: 'Leche',
  cantidad: 1,
  precioUnitario: 4500,
);
const _cafe = LineaCompra(
  idProducto: 'p3',
  nombre: 'Café',
  cantidad: 1,
  precioUnitario: 12000,
);

GrupoCompra _esquina({
  ServicioComercio servicio = ServicioComercio.ambos,
  List<LineaCompra> lineas = const [_arroz, _leche],
}) =>
    GrupoCompra(
      idComercio: 'c1',
      establecimiento: 'La Esquina',
      servicio: servicio,
      lineas: lineas,
    );

GrupoCompra _rosa() => const GrupoCompra(
      idComercio: 'c2',
      establecimiento: 'Doña Rosa',
      servicio: ServicioComercio.recogida,
      lineas: [_cafe],
    );

Future<void> _falla(Future<Object?> Function() accion, String mensaje) async {
  try {
    await accion();
  } on AuthFailure catch (e) {
    expect(e.message, contains(mensaje));
    return;
  }
  fail('Debió fallar con "$mensaje"');
}

void main() {
  group('EstadoOrden', () {
    test('lee los valores de la base y desconocido es "generada"', () {
      expect(EstadoOrden.fromDbName('entregada'), EstadoOrden.entregada);
      expect(EstadoOrden.fromDbName('en_camino'), EstadoOrden.enCamino);
      expect(EstadoOrden.fromDbName('otra_cosa'), EstadoOrden.generada);
      expect(EstadoOrden.fromDbName(null), EstadoOrden.generada);
    });

    test('solo recogida y entregada son completadas', () {
      final completadas =
          EstadoOrden.values.where((e) => e.completada).toList();
      expect(completadas, [EstadoOrden.recogida, EstadoOrden.entregada]);
    });

    test('la orden nueva nace en "Orden generada"', () {
      const orden = OrdenGenerada(
        id: 'o1',
        numero: 1,
        idComercio: 'c1',
        comercio: 'La Esquina',
        tipoEntrega: TipoEntrega.recogida,
        total: 100,
      );
      expect(orden.estado, EstadoOrden.generada);
      expect(orden.estado.label, 'Orden generada');
    });
  });

  group('PlanCompra.agrupar · división del carrito por comercio', () {
    test('los productos del mismo comercio van juntos, un grupo por comercio',
        () {
      final plan = PlanCompra.agrupar([
        LineaPrevia(
            idComercio: 'c1',
            establecimiento: 'La Esquina',
            servicio: ServicioComercio.ambos,
            linea: _arroz),
        LineaPrevia(
            idComercio: 'c2',
            establecimiento: 'Doña Rosa',
            servicio: ServicioComercio.recogida,
            linea: _cafe),
        LineaPrevia(
            idComercio: 'c1',
            establecimiento: 'La Esquina',
            servicio: ServicioComercio.ambos,
            linea: _leche),
      ]);

      expect(plan.grupos.length, 2);
      expect(plan.grupos[0].idComercio, 'c1');
      expect(plan.grupos[0].lineas.map((l) => l.idProducto), ['p1', 'p2']);
      expect(plan.grupos[1].idComercio, 'c2');
      expect(plan.grupos[1].lineas.map((l) => l.idProducto), ['p3']);
    });

    test('un establecimiento sin registro queda aparte y no genera orden', () {
      final plan = PlanCompra.agrupar([
        LineaPrevia(
            idComercio: 'c1',
            establecimiento: 'La Esquina',
            servicio: ServicioComercio.ambos,
            linea: _arroz),
        const LineaPrevia(establecimiento: 'Plaza de mercado', linea: _cafe),
      ]);

      expect(plan.registrados.length, 1);
      expect(plan.sinRegistro.length, 1);
      expect(plan.sinRegistro.single.establecimiento, 'Plaza de mercado');
      // A la base solo viajan las líneas del comercio registrado.
      expect(plan.lineasSolicitud.map((l) => l.idProducto), ['p1']);
    });

    test('dos establecimientos sin registro distintos no se mezclan', () {
      final plan = PlanCompra.agrupar([
        const LineaPrevia(establecimiento: 'Plaza A', linea: _arroz),
        const LineaPrevia(establecimiento: 'Plaza B', linea: _cafe),
        const LineaPrevia(establecimiento: 'Plaza A', linea: _leche),
      ]);

      expect(plan.sinRegistro.length, 2);
      expect(plan.sinRegistro.first.lineas.length, 2);
    });

    test('totales: subtotal por comercio y total del plan', () {
      final plan = PlanCompra([_esquina(), _rosa()]);

      expect(plan.grupos[0].subtotal, 2 * 3000 + 4500);
      expect(plan.grupos[1].subtotal, 12000);
      expect(plan.total, 22500);
      expect(plan.unidades, 4);
    });

    test('un producto agotado o sin precio no suma y bloquea', () {
      const agotado = LineaCompra(
        idProducto: 'p4',
        nombre: 'Agotado',
        cantidad: 3,
        precioUnitario: 1000,
        disponible: false,
      );
      final plan = PlanCompra([_esquina(lineas: [_arroz, agotado])]);

      expect(plan.hayNoDisponibles, isTrue);
      expect(plan.total, 6000);
    });

    test('sin líneas el plan está vacío', () {
      expect(PlanCompra.agrupar(const []).estaVacio, isTrue);
    });
  });

  group('ComprasReglas.validar', () {
    final plan = PlanCompra([_esquina(), _rosa()]);
    const recogida = EleccionEntrega.recogida;

    test('recogida en todos los comercios se puede confirmar', () {
      expect(
        ComprasReglas.validar(plan, {'c1': recogida, 'c2': recogida}),
        isNull,
      );
    });

    test('un carrito vacío no se puede confirmar', () {
      expect(ComprasReglas.validar(const PlanCompra([]), const {}),
          ComprasReglas.mensajeCarritoVacio);
    });

    test('falta elegir en un comercio', () {
      expect(
        ComprasReglas.validar(plan, {'c1': recogida}),
        'Elige recogida o entrega para Doña Rosa.',
      );
    });

    test('la entrega solo vale donde el comercio la ofrece', () {
      const entrega = EleccionEntrega.entrega;
      expect(
        ComprasReglas.validar(plan, {'c1': recogida, 'c2': entrega},
            tieneUbicacion: true),
        'Doña Rosa no ofrece entrega. Elige recogida.',
      );
      expect(
        ComprasReglas.validar(plan, {'c1': entrega, 'c2': recogida},
            tieneUbicacion: true),
        isNull,
      );
    });

    test('escenario 3: la entrega pide la ubicación guardada', () {
      expect(
        ComprasReglas.validar(
            plan, {'c1': EleccionEntrega.entrega, 'c2': recogida}),
        ComprasReglas.mensajeSinUbicacion,
      );
      // La recogida no la necesita.
      expect(
        ComprasReglas.validar(plan, {'c1': recogida, 'c2': recogida}),
        isNull,
      );
    });

    test('productos agotados bloquean la confirmación', () {
      const agotado = LineaCompra(
        idProducto: 'p4',
        nombre: 'Agotado',
        cantidad: 1,
        disponible: false,
      );
      final conAgotado = PlanCompra([_esquina(lineas: [agotado])]);
      expect(ComprasReglas.validar(conAgotado, {'c1': recogida}),
          ComprasReglas.mensajeNoDisponibles);
    });

    test('un establecimiento sin registro no pide elección', () {
      final mixto = PlanCompra([
        _esquina(),
        const GrupoCompra(establecimiento: 'Plaza', lineas: [_cafe]),
      ]);
      expect(ComprasReglas.validar(mixto, {'c1': recogida}), isNull);
    });
  });

  group('GetPlanCompraUseCase', () {
    late TestEnv env;

    setUp(() {
      env = TestEnv()..iniciarSesionComoClienteConCompras();
    });

    test('divide el carrito por comercio con el precio de hoy', () async {
      env.llenarCarrito({'p1': 2, 'p3': 1, 'p2': 1});

      final plan = await env.getPlanCompra();

      expect(plan.registrados.length, 2);
      final esquina = plan.registrados.firstWhere((g) => g.idComercio == 'c1');
      expect(esquina.lineas.map((l) => l.idProducto), unorderedEquals(['p1', 'p2']));
      expect(esquina.subtotal, 2 * 3000 + 4500);
      expect(plan.total, 22500);
    });

    test('con el carrito vacío falla sin llamar a la base', () async {
      await _falla(() => env.getPlanCompra(), 'carrito está vacío');
      expect(env.ordenes.compras.previsualizarCalls, 0);
    });

    test('si la base falla el error llega tal cual', () async {
      env.llenarCarrito({'p1': 1});
      env.ordenes.compras.previsualizarError =
          const AuthFailure('Sin conexión.');
      await _falla(() => env.getPlanCompra(), 'Sin conexión.');
    });
  });

  group('ConfirmarCompraUseCase · generación de órdenes', () {
    late TestEnv env;

    setUp(() {
      env = TestEnv()..iniciarSesionComoClienteConCompras();
    });

    Future<PlanCompra> planDe(Map<String, int> carrito) async {
      env.llenarCarrito(carrito);
      return env.getPlanCompra();
    }

    test('genera una orden por comercio, todas "Orden generada"', () async {
      final plan = await planDe({'p1': 2, 'p2': 1, 'p3': 1});

      final comprobante = await env.confirmarCompra(plan, {
        'c1': EleccionEntrega.recogida,
        'c2': EleccionEntrega.recogida,
      });

      expect(comprobante.ordenes.length, 2);
      expect(comprobante.ordenes.map((o) => o.idComercio),
          unorderedEquals(['c1', 'c2']));
      expect(comprobante.ordenes.every((o) => o.estado == EstadoOrden.generada),
          isTrue);
      expect(comprobante.total, 22500);
      expect(comprobante.listasDeCompra, isEmpty);
      expect(env.ordenes.compras.ordenes.length, 2);
    });

    test('cada orden lleva lo que se eligió para su comercio', () async {
      env.guardarUbicacionDelCliente();
      final plan = await planDe({'p1': 1, 'p3': 1});

      final comprobante = await env.confirmarCompra(plan, {
        'c1': EleccionEntrega.entrega,
        'c2': EleccionEntrega.recogida,
      });

      final porComercio = {for (final o in comprobante.ordenes) o.idComercio: o};
      expect(porComercio['c1']!.tipoEntrega, TipoEntrega.entrega);
      expect(porComercio['c2']!.tipoEntrega, TipoEntrega.recogida);
      expect(env.ordenes.compras.ultimasElecciones!['c1']!.tipo,
          TipoEntrega.entrega);
    });

    test('cada orden entrega la lista de compra de su comercio', () async {
      final plan = await planDe({'p1': 2, 'p2': 1, 'p3': 1});

      final comprobante = await env.confirmarCompra(plan, {
        'c1': EleccionEntrega.recogida,
        'c2': EleccionEntrega.recogida,
      });

      final porComercio = {for (final o in comprobante.ordenes) o.idComercio: o};
      expect(porComercio['c1']!.lineas.map((l) => l.idProducto),
          unorderedEquals(['p1', 'p2']));
      expect(porComercio['c2']!.lineas.single.cantidad, 1);
    });

    test('al confirmar una alternativa sale del carrito lo que cubre', () async {
      env.llenarCarrito({'p2': 1});
      // La alternativa compra p1 en lugar del p2 del carrito.
      const seleccion = SeleccionCompra(
        lineas: [LineaSolicitud(idProducto: 'p1', cantidad: 1)],
        productosDelCarrito: ['p2'],
      );
      final plan = await env.getPlanCompra(seleccion);

      await env.confirmarCompra(plan, {'c1': EleccionEntrega.recogida},
          quitarDelCarrito: seleccion.productosDelCarrito);

      expect(env.ordenes.compras.ultimasLineas!.map((l) => l.idProducto), ['p1']);
      expect(env.ordenes.compras.ultimoQuitarDelCarrito, ['p2']);
      expect(env.cliente.carrito.lineas, isEmpty);
    });

    test('un establecimiento sin registro recibe lista de compra, no orden',
        () async {
      env.ordenes.compras.catalogo['p3'] = const LineaPrevia(
        establecimiento: 'Plaza de mercado',
        linea: LineaCompra(
            idProducto: 'p3',
            nombre: 'Café molido 500 g',
            cantidad: 1,
            precioUnitario: 12000),
      );
      final plan = await planDe({'p1': 1, 'p3': 2});

      final comprobante =
          await env.confirmarCompra(plan, {'c1': EleccionEntrega.recogida});

      expect(comprobante.ordenes.length, 1);
      expect(comprobante.ordenes.single.idComercio, 'c1');
      expect(comprobante.listasDeCompra.length, 1);
      expect(comprobante.listasDeCompra.single.establecimiento,
          'Plaza de mercado');
      // La base no recibió el producto del establecimiento sin registro.
      expect(env.ordenes.compras.ultimasLineas!.map((l) => l.idProducto), ['p1']);
    });

    test('solo establecimientos sin registro: lista, sin llamar a la base',
        () async {
      env.ordenes.compras.catalogo['p1'] = const LineaPrevia(
        establecimiento: 'Plaza de mercado',
        linea: LineaCompra(
            idProducto: 'p1', nombre: 'Arroz', cantidad: 1, precioUnitario: 3000),
      );
      final plan = await planDe({'p1': 1});

      final comprobante = await env.confirmarCompra(plan, const {});

      expect(comprobante.ordenes, isEmpty);
      expect(comprobante.listasDeCompra.length, 1);
      expect(env.ordenes.compras.confirmarCalls, 0);
    });

    test('no confirma un carrito vacío', () async {
      await _falla(
        () => env.confirmarCompra(const PlanCompra([]), const {}),
        'carrito está vacío',
      );
      expect(env.ordenes.compras.confirmarCalls, 0);
    });

    test('no pide entrega en un comercio que no la ofrece', () async {
      final plan = await planDe({'p3': 1});

      await _falla(
        () => env.confirmarCompra(plan, {'c2': EleccionEntrega.entrega}),
        'no ofrece entrega',
      );
      expect(env.ordenes.compras.confirmarCalls, 0);
    });

    test('escenario 3: sin ubicación no se confirma una entrega', () async {
      final plan = await planDe({'p1': 1});

      await _falla(
        () => env.confirmarCompra(plan, {'c1': EleccionEntrega.entrega}),
        'Configura tu ubicación',
      );
      expect(env.ordenes.compras.confirmarCalls, 0);
    });

    test('solo un cliente confirma compras', () async {
      final plan = await planDe({'p1': 1});
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(
        env.confirmarCompra(plan, {'c1': EleccionEntrega.recogida}),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.ordenes.compras.confirmarCalls, 0);
    });

    test('si la base rechaza, no hay órdenes y el error se conserva', () async {
      final plan = await planDe({'p1': 1});
      env.ordenes.compras.confirmarError =
          const AuthFailure('Uno de los productos ya no está disponible.');

      await _falla(
        () => env.confirmarCompra(plan, {'c1': EleccionEntrega.recogida}),
        'ya no está disponible',
      );
      expect(env.ordenes.compras.ordenes, isEmpty);
    });
  });

  group('GetMisOrdenesUseCase', () {
    test('devuelve las órdenes por páginas, la más reciente primero',
        () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.ordenes.compras.ordenes.addAll([
        for (var i = 0; i < 5; i++)
          ordenDePrueba(id: 'o$i', numero: 2000 - i),
      ]);

      final primera =
          await env.getMisOrdenes(const PageRequest(page: 0, pageSize: 3));
      final segunda =
          await env.getMisOrdenes(const PageRequest(page: 1, pageSize: 3));

      expect(primera.items.length, 3);
      expect(primera.hasMore, isTrue);
      expect(segunda.items.length, 2);
      expect(segunda.hasMore, isFalse);
    });

    test('solo un cliente ve sus órdenes', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.repartidor});
      await expectLater(
        env.getMisOrdenes(const PageRequest(page: 0, pageSize: 3)),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('Orden · quién se califica', () {
    test('solo una orden completada se califica, y una sola vez', () {
      expect(ordenDePrueba(estado: EstadoOrden.generada).puedeCalificarComercio,
          isFalse);
      expect(ordenDePrueba(estado: EstadoOrden.enCamino).puedeCalificarComercio,
          isFalse);
      expect(ordenDePrueba(estado: EstadoOrden.entregada).puedeCalificarComercio,
          isTrue);
      expect(ordenDePrueba(estado: EstadoOrden.recogida).puedeCalificarComercio,
          isTrue);
      expect(
        ordenDePrueba(calificadaComercio: true).puedeCalificarComercio,
        isFalse,
      );
    });

    test('al repartidor se le califica si la orden tuvo uno', () {
      expect(ordenDePrueba().puedeCalificarRepartidor, isFalse);
      expect(ordenDePrueba(tieneRepartidor: true).puedeCalificarRepartidor,
          isTrue);
      expect(
        ordenDePrueba(tieneRepartidor: true, calificadaRepartidor: true)
            .puedeCalificarRepartidor,
        isFalse,
      );
      expect(
        ordenDePrueba(tieneRepartidor: true, estado: EstadoOrden.generada)
            .puedeCalificarRepartidor,
        isFalse,
      );
    });
  });
}
