import 'dart:async';

import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';
import 'package:smartcart/features/seguimiento/domain/repository/seguimiento_repository.dart';
import 'package:smartcart/features/seguimiento/domain/usecases/seguimiento_usecases.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/detalle_orden_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/ordenes_cliente_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/push_bloc.dart';

import 'fakes.dart';

// ───────────────────────── Datos de ejemplo ─────────────────────────

/// "Hoy" en las pruebas de la HU-23.
final ahoraSeguimiento = DateTime(2026, 11, 28, 11, 0);

Orden ordenSeguimiento({
  String id = 'o105',
  int numero = 105,
  String comercio = 'Minimercado La Esquina',
  EstadoOrden estado = EstadoOrden.listaParaRecoger,
  TipoEntrega tipo = TipoEntrega.recogida,
  int total = 17100,
  DateTime? creadoEn,
  DateTime? cerradaEn,
  int productos = 4,
  bool tieneRepartidor = false,
}) =>
    Orden(
      id: id,
      numero: numero,
      comercio: comercio,
      estado: estado,
      tipoEntrega: tipo,
      total: total,
      creadoEn: creadoEn ?? DateTime(2026, 11, 28, 9, 15),
      cerradaEn: cerradaEn,
      productos: productos,
      tieneRepartidor: tieneRepartidor,
    );

/// El detalle de [orden], con productos y el historial hasta su estado.
DetalleOrden detalleSeguimiento(Orden orden) {
  const camino = [
    EstadoOrden.generada,
    EstadoOrden.aceptada,
    EstadoOrden.enPreparacion,
    EstadoOrden.listaParaRecoger,
    EstadoOrden.enCamino,
    EstadoOrden.entregada,
  ];
  final hasta = camino.indexOf(orden.estado);
  final pasos = hasta < 0
      ? [EstadoOrden.generada, orden.estado]
      : camino.sublist(0, hasta + 1)
          .where((e) =>
              orden.tipoEntrega == TipoEntrega.entrega ||
              e != EstadoOrden.enCamino)
          .toList();
  return DetalleOrden(
    orden: orden,
    comercioDireccion: 'Carrera 15 # 124-30',
    comercioCiudad: 'Bogotá',
    direccionEntrega:
        orden.tipoEntrega == TipoEntrega.entrega ? 'Calle 80 # 10-20' : null,
    items: const [
      ItemOrden(nombre: 'Arroz Blanco Premium 1kg', cantidad: 2, precioUnitario: 4900),
      ItemOrden(nombre: 'Papas Chips Clásicas 150g', cantidad: 1, precioUnitario: 5200),
      ItemOrden(nombre: 'Leche Entera 1L', cantidad: 1, precioUnitario: 2100),
    ],
    historial: [
      for (final (i, e) in pasos.indexed)
        CambioEstado(
          estado: e,
          fecha: DateTime(2026, 11, 28, 9, 15).add(Duration(minutes: 15 * i)),
        ),
    ],
  );
}

// ───────────────────────── Dobles ─────────────────────────

/// Seguimiento en memoria (HU-23). Imita a la base: "En curso" es lo que no
/// está cerrado ni rechazado, y confirmar cierra la orden (una recogida pasa
/// a "Recogida").
class FakeSeguimientoRepository implements SeguimientoRepository {
  final ordenesGuardadas = <Orden>[];
  final detalles = <String, DetalleOrden>{};
  final confirmadas = <String>[];
  final pedidos = <({bool enCurso, PageRequest request})>[];
  Object? listaError;
  Object? detalleError;
  Object? confirmarError;

  void guardar(Orden orden) {
    ordenesGuardadas.removeWhere((o) => o.id == orden.id);
    ordenesGuardadas.add(orden);
    detalles[orden.id] = detalleSeguimiento(orden);
  }

  bool _enCurso(Orden o) =>
      o.cerradaEn == null && o.estado != EstadoOrden.rechazada;

  @override
  Future<PagedResult<Orden>> ordenes({
    required bool enCurso,
    required PageRequest request,
  }) async {
    pedidos.add((enCurso: enCurso, request: request));
    if (listaError != null) throw listaError!;
    final filas = ordenesGuardadas
        .where((o) => _enCurso(o) == enCurso)
        .skip(request.from)
        .take(request.pageSize + 1)
        .toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<int> cuantasEnCurso() async =>
      ordenesGuardadas.where(_enCurso).length;

  @override
  Future<DetalleOrden?> detalle(String idOrden) async {
    if (detalleError != null) throw detalleError!;
    return detalles[idOrden];
  }

  @override
  Future<void> confirmarRecepcion(String idOrden) async {
    if (confirmarError != null) throw confirmarError!;
    confirmadas.add(idOrden);
    final actual = detalles[idOrden]!.orden;
    final cerrada = Orden(
      id: actual.id,
      numero: actual.numero,
      comercio: actual.comercio,
      estado: actual.tipoEntrega == TipoEntrega.recogida
          ? EstadoOrden.recogida
          : actual.estado,
      tipoEntrega: actual.tipoEntrega,
      total: actual.total,
      creadoEn: actual.creadoEn,
      cerradaEn: ahoraSeguimiento,
      productos: actual.productos,
      tieneRepartidor: actual.tieneRepartidor,
    );
    final anterior = detalles[idOrden]!;
    ordenesGuardadas
      ..removeWhere((o) => o.id == idOrden)
      ..add(cerrada);
    detalles[idOrden] = DetalleOrden(
      orden: cerrada,
      comercioDireccion: anterior.comercioDireccion,
      comercioCiudad: anterior.comercioCiudad,
      direccionEntrega: anterior.direccionEntrega,
      items: anterior.items,
      historial: [
        ...anterior.historial,
        if (cerrada.estado != actual.estado)
          CambioEstado(estado: cerrada.estado, fecha: ahoraSeguimiento),
      ],
    );
  }
}

class FakeDispositivosRepository implements DispositivosRepository {
  final registrados = <({String token, String plataforma})>[];
  final quitados = <String>[];
  Object? registrarError;

  @override
  Future<void> registrar(String token, String plataforma) async {
    if (registrarError != null) throw registrarError!;
    registrados.add((token: token, plataforma: plataforma));
  }

  @override
  Future<void> quitar(String token) async => quitados.add(token);
}

/// Push en memoria: [token] es lo que "entrega Firebase" (`null` = sin
/// permiso o sin configurar). Los controladores simulan los avisos.
class FakeNotificacionesPush implements NotificacionesPush {
  String? token = 'token-fcm-de-prueba';
  int activaciones = 0;
  final primerPlano = StreamController<AvisoPush>.broadcast();
  final abiertos = StreamController<void>.broadcast();
  final renovados = StreamController<String>.broadcast();

  @override
  Future<String?> activar() async {
    activaciones++;
    return token;
  }

  @override
  String get plataforma => 'android';

  @override
  Stream<String> get tokenRenovado => renovados.stream;

  @override
  Stream<AvisoPush> get enPrimerPlano => primerPlano.stream;

  @override
  Stream<void> get avisoAbierto => abiertos.stream;
}

class SeguimientoFakes {
  final seguimiento = FakeSeguimientoRepository();
  final dispositivos = FakeDispositivosRepository();
  final push = FakeNotificacionesPush();
}

final _fakesDeSeguimiento = Expando<SeguimientoFakes>();

/// Casos de uso y Blocs de la HU-23 construidos con los dobles del entorno.
/// Viven aparte de `TestEnv` para no tocar su archivo.
extension EntornoSeguimiento on TestEnv {
  SeguimientoFakes get seg => _fakesDeSeguimiento[this] ??= SeguimientoFakes();

  /// Deja la sesión iniciada como cliente, sin órdenes.
  void iniciarSesionComoClienteConOrdenes([List<Orden> ordenes = const []]) {
    iniciarSesionCon({UserRole.cliente});
    ordenes.forEach(seg.seguimiento.guardar);
  }

  GetClienteActivoUseCase get _cliente =>
      GetClienteActivoUseCase(auth: auth, profiles: profiles);

  GetOrdenesClienteUseCase get getOrdenesCliente =>
      GetOrdenesClienteUseCase(cliente: _cliente, seguimiento: seg.seguimiento);
  ContarOrdenesEnCursoUseCase get contarOrdenesEnCurso =>
      ContarOrdenesEnCursoUseCase(
          cliente: _cliente, seguimiento: seg.seguimiento);
  GetDetalleOrdenUseCase get getDetalleOrden =>
      GetDetalleOrdenUseCase(cliente: _cliente, seguimiento: seg.seguimiento);
  ConfirmarRecepcionUseCase get confirmarRecepcion =>
      ConfirmarRecepcionUseCase(
          cliente: _cliente, seguimiento: seg.seguimiento);
  ActivarNotificacionesPushUseCase get activarPush =>
      ActivarNotificacionesPushUseCase(
          auth: auth, push: seg.push, dispositivos: seg.dispositivos);

  OrdenesClienteBloc ordenesClienteBloc({int pageSize = 20}) =>
      OrdenesClienteBloc(ordenes: getOrdenesCliente, pageSize: pageSize);
  ConteoOrdenesBloc conteoOrdenesBloc() =>
      ConteoOrdenesBloc(contar: contarOrdenesEnCurso);
  DetalleOrdenBloc detalleOrdenBloc(String idOrden) => DetalleOrdenBloc(
        idOrden: idOrden,
        detalle: getDetalleOrden,
        confirmar: confirmarRecepcion,
      );
  PushBloc pushBloc() => PushBloc(activar: activarPush, push: seg.push);
}
