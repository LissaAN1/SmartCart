import 'dart:async';

import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/estadisticas/domain/repository/estadisticas_repository.dart';
import 'package:smartcart/features/estadisticas/domain/usecases/get_estadisticas_usecase.dart';
import 'package:smartcart/features/estadisticas/presentation/bloc/estadisticas_bloc.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';

import 'fakes.dart';

/// Cifras de ejemplo: 3 comercios aprobados y 1 pendiente (escenario 1) y
/// sin órdenes, salvo que se den.
EstadisticasPlataforma cifras({
  int aprobados = 3,
  int pendientes = 1,
  int solicitudesRepartidor = 2,
  EstadisticasOrdenes? ordenes,
}) =>
    EstadisticasPlataforma(
      usuariosPorRol: const {
        UserRole.cliente: 1250,
        UserRole.colaborador: 8,
        UserRole.comercio: 5,
        UserRole.repartidor: 4,
        UserRole.administrador: 1,
      },
      comerciosPorEstado: {
        ApprovalStatus.aprobado: aprobados,
        ApprovalStatus.pendiente: pendientes,
        ApprovalStatus.rechazado: 0,
      },
      repartidoresAprobados: 6,
      repartidoresEnLinea: 4,
      solicitudesComercio: pendientes,
      solicitudesRepartidor: solicitudesRepartidor,
      reportesPrecioPendientes: 7,
      ordenes: ordenes,
    );

const ordenesDeEjemplo = EstadisticasOrdenes(
  hoy: 9,
  porEstado: {EstadoOrden.generada: 11, EstadoOrden.entregada: 13},
);

class FakeEstadisticasRepository implements EstadisticasRepository {
  EstadisticasPlataforma datos = cifras();
  Object? error;
  int llamadas = 0;

  /// Si se asigna, la siguiente consulta espera a que se complete y responde
  /// con las cifras que había al pedirla.
  Completer<void>? gate;

  @override
  Future<EstadisticasPlataforma> obtener() async {
    llamadas++;
    final respuesta = datos;
    final espera = gate;
    gate = null;
    await espera?.future;
    if (error != null) throw error!;
    return respuesta;
  }
}

final _fakesDeEstadisticas =
    Expando<FakeEstadisticasRepository>('fakesDeEstadisticas');

/// Casos de uso y Bloc del panel (HU-28) con los dobles del entorno.
extension EntornoEstadisticas on TestEnv {
  FakeEstadisticasRepository get estadisticas =>
      _fakesDeEstadisticas[this] ??= FakeEstadisticasRepository();

  GetEstadisticasUseCase get getEstadisticas => GetEstadisticasUseCase(
      auth: auth, profiles: profiles, estadisticas: estadisticas);

  EstadisticasBloc estadisticasBloc() =>
      EstadisticasBloc(obtener: getEstadisticas);
}
