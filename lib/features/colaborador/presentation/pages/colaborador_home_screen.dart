// lib/src/features/colaborador/ui/screens/colaborador_home_screen.dart
// Home del COLABORADOR. Solo UI con datos de ejemplo.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/colaborador_widgets.dart';

class ColaboradorHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  const ColaboradorHomeScreen({super.key, this.onTab});

  static const _misiones = [
    (titulo: 'Verifica precios de lácteos', tienda: 'Éxito Calle 80', km: '1.2 km', pts: 150, hechos: 2, total: 5),
    (titulo: 'Fotografía la góndola de café', tienda: 'Carulla Calle 85', km: '2.4 km', pts: 90, hechos: 0, total: 3),
    (titulo: 'Confirma ofertas de aseo', tienda: 'D1 Chapinero', km: '0.8 km', pts: 60, hechos: 1, total: 4),
  ];

  static const _reportes = [
    (producto: 'Arroz Diana 1kg', tienda: 'Éxito', precio: r'$ 4.900', fecha: 'Hoy', estado: EstadoReportePrecio.verificado),
    (producto: 'Aceite Premier 900ml', tienda: 'Olímpica', precio: r'$ 12.300', fecha: 'Ayer', estado: EstadoReportePrecio.enRevision),
    (producto: 'Huevos AA x30', tienda: 'Carulla', precio: r'$ 18.700', fecha: '14 Oct', estado: EstadoReportePrecio.verificado),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.colaborador,
      navItems: navColaborador(misionesNuevas: 3),
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: EncabezadoSaludo(
        nombre: 'Camila',
        ubicacion: 'Bogotá, Colombia',
        acciones: [
          BotonCircular(icono: Icons.search, onTap: () {}),
          BotonCircular(
              icono: Icons.notifications_none, conPunto: true, onTap: () {}),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ══ PUNTOS ══
          TarjetaPuntos(
            puntos: 2450,
            nivel: 'Nivel Plata',
            siguienteNivel: 'Nivel Oro',
            progreso: 0.68,
            onCanjear: () {},
          ),
          const SizedBox(height: 16),

          // ══ ACCIONES RÁPIDAS ══
          Row(
            children: [
              Expanded(
                child: AccionRapida(
                  icono: Icons.photo_camera_outlined,
                  titulo: 'Reportar precio',
                  subtitulo: 'Foto + precio',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccionRapida(
                  icono: Icons.qr_code_scanner,
                  titulo: 'Escanear',
                  subtitulo: 'Código de barras',
                  onTap: () {},
                ),
              ),
            ],
          ),

          // ══ MISIONES ══
          TituloSeccion(
            titulo: 'MISIONES CERCA DE TI',
            accion: 'Ver todas',
            onAccion: () {},
          ),
          for (final m in _misiones) ...[
            MisionCard(
              titulo: m.titulo,
              tienda: m.tienda,
              distancia: m.km,
              recompensa: m.pts,
              completados: m.hechos,
              total: m.total,
              onTap: () {},
            ),
            const SizedBox(height: 12),
          ],

          // ══ ÚLTIMOS REPORTES ══
          TituloSeccion(
            titulo: 'MIS ÚLTIMOS REPORTES',
            accion: 'Historial',
            onAccion: () {},
            padding: const EdgeInsets.only(top: 14, bottom: 8),
          ),
          GrupoMenu(
            items: [
              for (final r in _reportes)
                ReporteItem(
                  producto: r.producto,
                  tienda: r.tienda,
                  precio: r.precio,
                  fecha: r.fecha,
                  estado: r.estado,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 20),

          const AvisoDestacado(
            icono: Icons.info_outline,
            estilo: EstiloAviso.suave,
            descripcion: 'Ser colaborador requiere un compromiso con la '
                'veracidad de los datos. Reportes falsos pueden llevar a la '
                'suspensión de la cuenta.',
          ),
        ],
      ),
    );
  }
}
