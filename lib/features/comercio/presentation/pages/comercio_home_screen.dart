// lib/src/features/comercio/ui/screens/comercio_home_screen.dart
// Home del COMERCIO ("Panel del comercio"). Solo UI con datos de ejemplo.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/comercio_widgets.dart';

class ComercioHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  const ComercioHomeScreen({super.key, this.onTab});

  static const _ordenes = [
    (codigo: '#108-A', estado: EstadoOrdenComercio.pendiente, hace: 'Hace 5 min', cliente: 'Carlos Rodriguez', productos: 4, total: r'$ 45.200'),
    (codigo: '#109-C', estado: EstadoOrdenComercio.enProceso, hace: 'Hace 15 min', cliente: 'Maria Elena Gomez', productos: 2, total: r'$ 12.900'),
    (codigo: '#110-B', estado: EstadoOrdenComercio.entregado, hace: 'Hace 1 hora', cliente: 'Supermercado Central', productos: 12, total: r'$ 156.000'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      navItems: navComercio,
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: BarraTituloRol(
        titulo: 'Panel del comercio',
        acciones: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: t.texto),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: AvatarPerfil(radio: 20, nombre: 'Mercado Local'),
          ),
        ],
      ),
      fab: FloatingActionButton(
        backgroundColor: t.primario,
        shape: const CircleBorder(),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ══ MÉTRICAS ══
          const Row(
            children: [
              Expanded(
                child: TarjetaMetrica(
                  valor: r'$ 840.000',
                  etiqueta: 'Ventas hoy',
                  nota: '+12% vs ayer',
                  centrada: false,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  valor: '14',
                  etiqueta: 'Pedidos activos',
                  nota: '3 por despachar',
                  centrada: false,
                ),
              ),
            ],
          ),

          // ══ ÓRDENES ══
          TituloSeccion(
            titulo: 'Órdenes Recientes',
            estilo: EstiloTitulo.grande,
            accion: 'Ver todas',
            onAccion: () {},
          ),
          for (final o in _ordenes) ...[
            OrdenComercioCard(
              codigo: o.codigo,
              estado: o.estado,
              hace: o.hace,
              cliente: o.cliente,
              productos: o.productos,
              total: o.total,
              onVerDetalle: () {},
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),

          // ══ TIP ══
          TarjetaTip(
            titulo: 'Tip de Crecimiento',
            textoAntes: 'Los comercios que actualizan su catálogo '
                'semanalmente venden un ',
            resaltado: '20% más',
            textoDespues: '.',
            textoBoton: 'Ir al Catálogo',
            onBoton: () {},
          ),
        ],
      ),
    );
  }
}
