import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';

/// Las órdenes de la plataforma (HU-28).
class EstadisticasOrdenes {
  /// Órdenes creadas hoy (fecha de Colombia), en cualquier estado.
  final int hoy;
  final Map<EstadoOrden, int> porEstado;

  const EstadisticasOrdenes({required this.hoy, required this.porEstado});

  int de(EstadoOrden estado) => porEstado[estado] ?? 0;
}

/// Las cifras del panel del administrador (HU-28). Todas salen de la base.
class EstadisticasPlataforma {
  final Map<UserRole, int> usuariosPorRol;
  final Map<ApprovalStatus, int> comerciosPorEstado;
  final int repartidoresAprobados;

  /// Los aprobados que tienen la disponibilidad activa.
  final int repartidoresEnLinea;
  final int solicitudesComercio;
  final int solicitudesRepartidor;
  final int reportesPrecioPendientes;

  /// `null` si todavía no hay ninguna orden: no se muestran cifras.
  final EstadisticasOrdenes? ordenes;

  const EstadisticasPlataforma({
    this.usuariosPorRol = const {},
    this.comerciosPorEstado = const {},
    this.repartidoresAprobados = 0,
    this.repartidoresEnLinea = 0,
    this.solicitudesComercio = 0,
    this.solicitudesRepartidor = 0,
    this.reportesPrecioPendientes = 0,
    this.ordenes,
  });

  int usuariosDe(UserRole rol) => usuariosPorRol[rol] ?? 0;

  int comerciosEn(ApprovalStatus estado) => comerciosPorEstado[estado] ?? 0;

  /// Comercios y repartidores que esperan la decisión del administrador.
  int get solicitudesPendientes => solicitudesComercio + solicitudesRepartidor;
}
