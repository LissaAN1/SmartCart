// lib/src/features/colaborador/ui/widgets/colaborador_widgets.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';

/// Pestañas del colaborador:
/// 0 Inicio, 1 Misiones, 2 Reportar Precio, 3 Perfil, 4 Quejas.
List<ItemNav> navColaborador({int misionesNuevas = 0}) => [
      const ItemNav(Icons.home_outlined, 'Inicio', iconoActivo: Icons.home),
      ItemNav(Icons.event_available_outlined, 'Misiones',
          iconoActivo: Icons.event_available, badge: misionesNuevas),
      const ItemNav(Icons.notification_add_outlined, 'Reportar Precio'),
      const ItemNav(Icons.person_outline, 'Perfil', iconoActivo: Icons.person),
      const ItemNav(Icons.sentiment_dissatisfied_outlined, 'Quejas'),
    ];

/// Tarjeta de SmartPoints con nivel y progreso al siguiente nivel.
class TarjetaPuntos extends StatelessWidget {
  final int puntos;
  final String nivel;
  final String siguienteNivel;
  final double progreso; // 0..1
  final VoidCallback? onCanjear;

  const TarjetaPuntos({
    super.key,
    required this.puntos,
    required this.nivel,
    required this.siguienteNivel,
    required this.progreso,
    this.onCanjear,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.primario, const Color(0xFFE2582A)],
        ),
        boxShadow: [
          BoxShadow(
            color: t.primario.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('MIS SMARTPOINTS',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(nivel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_formatoMiles(puntos),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                    '${(progreso * 100).round()}% para $siguienteNivel',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
              ),
              GestureDetector(
                onTap: onCanjear,
                child: const Row(
                  children: [
                    Text('Canjear',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
                    Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatoMiles(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

/// Botón cuadrado de acción rápida: "Reportar precio", "Escanear".
class AccionRapida extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onTap;

  const AccionRapida({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: t.suave, borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: t.primario),
          ),
          const SizedBox(height: 12),
          Text(titulo,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: t.texto)),
          if (subtitulo != null)
            Text(subtitulo!,
                style: TextStyle(fontSize: 12.5, color: t.textoGris)),
        ],
      ),
    );
  }
}

/// Misión disponible para el colaborador.
class MisionCard extends StatelessWidget {
  final String titulo;
  final String tienda;
  final String distancia;
  final int recompensa; // puntos
  final int completados;
  final int total;
  final VoidCallback? onTap;

  const MisionCard({
    super.key,
    required this.titulo,
    required this.tienda,
    required this.distancia,
    required this.recompensa,
    this.completados = 0,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final progreso = total == 0 ? 0.0 : completados / total;

    return TarjetaSuave(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: t.suave, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.flag_outlined, color: t.primario),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.texto)),
                    const SizedBox(height: 3),
                    Text('$tienda • $distancia',
                        style: TextStyle(fontSize: 12.5, color: t.textoGris)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EtiquetaEstado.marca('+$recompensa pts'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 6,
                    backgroundColor: t.suave,
                    valueColor: AlwaysStoppedAnimation(t.primario),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$completados/$total',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.textoGris)),
            ],
          ),
        ],
      ),
    );
  }
}

enum EstadoReportePrecio { verificado, enRevision, rechazado }

/// Fila de un reporte de precio enviado.
class ReporteItem extends StatelessWidget {
  final String producto;
  final String tienda;
  final String precio;
  final String fecha;
  final EstadoReportePrecio estado;
  final VoidCallback? onTap;

  const ReporteItem({
    super.key,
    required this.producto,
    required this.tienda,
    required this.precio,
    required this.fecha,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final chip = switch (estado) {
      EstadoReportePrecio.verificado => const EtiquetaEstado.exito('Verificado'),
      EstadoReportePrecio.enRevision => const EtiquetaEstado.pendiente('En revisión'),
      EstadoReportePrecio.rechazado => const EtiquetaEstado.error('Rechazado'),
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: t.suave, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long_outlined, color: t.primario),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.texto)),
                  Text('$tienda • $fecha',
                      style: TextStyle(fontSize: 12.5, color: t.textoGris)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(precio,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                const SizedBox(height: 4),
                chip,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
