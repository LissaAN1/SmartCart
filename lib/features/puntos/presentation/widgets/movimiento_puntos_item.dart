import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/reportes/presentation/reporte_formato.dart';

/// Una fila del historial de puntos: el motivo, cuándo, y los puntos con su
/// signo (verde si suma, rojo si resta).
class MovimientoPuntosItem extends StatelessWidget {
  final MovimientoPuntos movimiento;

  const MovimientoPuntosItem({super.key, required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final color = movimiento.suma ? ColoresEstado.verde : ColoresEstado.rojo;
    final signo = movimiento.suma ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.suave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icono(movimiento.tipo), color: t.primario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movimiento.motivo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.texto)),
                const SizedBox(height: 2),
                Text(formatoFechaHora(movimiento.creadoEn),
                    style: TextStyle(fontSize: 12.5, color: t.textoGris)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$signo${movimiento.puntos} pts',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  IconData _icono(TipoMovimientoPuntos tipo) => switch (tipo) {
        TipoMovimientoPuntos.reporteValidado => Icons.verified_outlined,
        TipoMovimientoPuntos.canje => Icons.card_giftcard,
        TipoMovimientoPuntos.ajuste => Icons.tune,
      };
}
