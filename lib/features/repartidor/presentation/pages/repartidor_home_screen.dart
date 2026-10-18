// lib/src/features/repartidor/ui/screens/repartidor_home_screen.dart
// Home del REPARTIDOR ("Panel del Mensajero"). Solo UI con datos de ejemplo.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/repartidor_widgets.dart';

class RepartidorHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTab;
  const RepartidorHomeScreen({super.key, this.onTab});

  @override
  State<RepartidorHomeScreen> createState() => _RepartidorHomeScreenState();
}

class _RepartidorHomeScreenState extends State<RepartidorHomeScreen> {
  bool _enLinea = true;

  static const _pedidos = [
    (comercio: 'Mercado Local Centro', orden: '#SC-4029', tarifa: r'$ 4.500', origen: 'Carrera 7 # 12-45, Centro', destino: 'Calle 19 # 4-82, Las Aguas', km: '1.2 km', min: '12 min'),
    (comercio: 'Panadería La Estancia', orden: '#SC-4031', tarifa: r'$ 6.200', origen: 'Calle 45 # 24-10, Palermo', destino: 'Carrera 13 # 60-15, Chapinero', km: '3.4 km', min: '22 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.repartidor,
      navItems: navRepartidor,
      tabActiva: 0,
      onTab: widget.onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Panel del Mensajero'),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          // ══ DISPONIBILIDAD ══
          TarjetaDisponibilidad(
            enLinea: _enLinea,
            zona: 'Chapinero',
            onCambio: (v) => setState(() => _enLinea = v),
          ),
          const SizedBox(height: 14),

          // ══ RESUMEN DEL DÍA ══
          const Row(
            children: [
              Expanded(
                child: TarjetaMetrica(
                  valor: r'$ 38.400',
                  etiqueta: 'Ganancias hoy',
                  icono: Icons.account_balance_wallet_outlined,
                  centrada: false,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  valor: '7',
                  etiqueta: 'Entregas hoy',
                  icono: Icons.inventory_2_outlined,
                  centrada: false,
                ),
              ),
            ],
          ),

          // ══ PEDIDOS ══
          TituloSeccion(
            titulo: 'Pedidos Disponibles',
            icono: Icons.bolt,
            estilo: EstiloTitulo.grande,
            accion: '${_pedidos.length} cerca',
          ),
          for (final p in _pedidos) ...[
            PedidoDisponibleCard(
              comercio: p.comercio,
              codigoOrden: p.orden,
              tarifa: p.tarifa,
              origen: p.origen,
              destino: p.destino,
              distancia: p.km,
              tiempo: p.min,
              onAceptar: () {},
            ),
            const SizedBox(height: 16),
          ],

          // ══ TIP ══
          const BannerPromo(
            titulo: 'Tip de Ganancias',
            descripcion: 'Hoy hay alta demanda en el sector de Chapinero. '
                '¡Dirígete allí para ganar bonos!',
          ),
          const SizedBox(height: 12),
          AvisoDestacado(
            icono: Icons.notifications_none,
            titulo: 'Nueva tarifa dinámica activa (+15%)',
            descripcion: 'Válido para las próximas 2 horas',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
