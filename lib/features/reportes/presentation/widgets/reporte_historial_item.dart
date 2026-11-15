import 'package:flutter/material.dart';
import 'package:smartcart/features/colaborador/presentation/widgets/colaborador_widgets.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/presentation/reporte_formato.dart';

/// Una fila del historial de reportes del colaborador: producto, dónde y
/// cuándo, el precio reportado y su estado. Un reporte recién enviado sale
/// como "Pendiente".
class ReporteHistorialItem extends StatelessWidget {
  final MiReporte reporte;
  final VoidCallback? onTap;

  const ReporteHistorialItem({super.key, required this.reporte, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ReporteItem(
      producto: reporte.producto,
      tienda: reporte.establecimiento,
      // Con promoción se muestra el precio de la promoción, que es el que
      // paga quien compra hoy.
      precio: formatoPesos(reporte.precioPromocional ?? reporte.precio),
      fecha: formatoFechaHora(reporte.creadoEn),
      estado: switch (reporte.estado) {
        EstadoReporte.pendiente => EstadoReportePrecio.enRevision,
        EstadoReporte.validado => EstadoReportePrecio.verificado,
        EstadoReporte.rechazado => EstadoReportePrecio.rechazado,
      },
      onTap: onTap,
    );
  }
}
