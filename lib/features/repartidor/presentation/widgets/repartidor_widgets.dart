// lib/src/features/repartidor/ui/widgets/repartidor_widgets.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';

/// Pestañas del repartidor: 0 Inicio, 1 Ruta, 2 Perfil.
const navRepartidor = [
  ItemNav(Icons.home_outlined, 'Inicio', iconoActivo: Icons.home),
  ItemNav(Icons.map_outlined, 'Ruta', iconoActivo: Icons.map),
  ItemNav(Icons.person_outline, 'Perfil', iconoActivo: Icons.person),
];

/// Interruptor de disponibilidad (en línea / desconectado).
class TarjetaDisponibilidad extends StatelessWidget {
  final bool enLinea;
  final String zona;
  final ValueChanged<bool>? onCambio;

  const TarjetaDisponibilidad({
    super.key,
    required this.enLinea,
    required this.zona,
    this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      sombra: true,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: enLinea ? ColoresEstado.verdeSuave : t.suave,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.two_wheeler,
                color: enLinea ? ColoresEstado.verde : t.textoGris),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enLinea ? 'Estás en línea' : 'Estás desconectado',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                Text(
                    enLinea
                        ? 'Recibiendo pedidos en $zona'
                        : 'Actívate para recibir pedidos',
                    style: TextStyle(fontSize: 13, color: t.textoGris)),
              ],
            ),
          ),
          Switch(
            value: enLinea,
            onChanged: onCambio,
            activeTrackColor: ColoresEstado.verde,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de pedido disponible para aceptar.
class PedidoDisponibleCard extends StatelessWidget {
  final String comercio;
  final String codigoOrden;
  final String tarifa;
  final String origen;
  final String destino;
  final String distancia;
  final String tiempo;
  final String? imagenUrl;
  final VoidCallback? onAceptar;

  const PedidoDisponibleCard({
    super.key,
    required this.comercio,
    required this.codigoOrden,
    required this.tarifa,
    required this.origen,
    required this.destino,
    required this.distancia,
    required this.tiempo,
    this.imagenUrl,
    this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.borde),
        boxShadow: [
          BoxShadow(
              color: t.primarioOscuro.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Comercio + tarifa
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ImagenPlaceholder(
                    url: imagenUrl,
                    ancho: 56,
                    alto: 56,
                    icono: Icons.storefront_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comercio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: t.texto)),
                      const SizedBox(height: 4),
                      Text('ORDEN $codigoOrden',
                          style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.6,
                              color: t.textoGris)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tarifa,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: t.primario)),
                    const SizedBox(height: 4),
                    Text('TARIFA ESTIMADA',
                        style: TextStyle(fontSize: 10.5, color: t.textoGris)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.borde),

          // Ruta
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _parada(t, Icons.circle, 10, t.primario, origen,
                              negrita: true),
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  width: 1.5, height: 14, color: t.borde),
                            ),
                          ),
                          _parada(t, Icons.place_outlined, 15,
                              ColoresEstado.rojo, destino),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _pastilla(t, distancia),
                        const SizedBox(height: 8),
                        _pastilla(t, tiempo),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BotonPrimario(
                  texto: 'Aceptar Pedido',
                  iconoFinal: Icons.arrow_forward,
                  onTap: onAceptar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _parada(TemaRol t, IconData icono, double tam, Color color,
      String texto,
      {bool negrita = false}) {
    return Row(
      children: [
        SizedBox(width: 14, child: Icon(icono, size: tam, color: color)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: negrita ? FontWeight.w500 : FontWeight.w400,
                  color: negrita ? t.texto : t.textoGris)),
        ),
      ],
    );
  }

  Widget _pastilla(TemaRol t, String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: t.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.borde),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: t.texto)),
      );
}

enum EstadoDocumento { verificado, enRevision, vencido }

/// Documento del repartidor con su estado.
class DocumentoItem extends StatelessWidget {
  final String nombre;
  final EstadoDocumento estado;
  final VoidCallback? onTap;

  const DocumentoItem({
    super.key,
    required this.nombre,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final chip = switch (estado) {
      EstadoDocumento.verificado => const EtiquetaEstado.exito('Verificado'),
      EstadoDocumento.enRevision =>
        const EtiquetaEstado.pendiente('En revisión'),
      EstadoDocumento.vencido => const EtiquetaEstado.error('Vencido'),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(Icons.description_outlined,
                  size: 20, color: t.textoGris),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(nombre,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.texto)),
            ),
            chip,
          ],
        ),
      ),
    );
  }
}

/// Entrega del historial.
class EntregaItem extends StatelessWidget {
  final String comercio;
  final String destino;
  final String fecha;
  final String valor;
  final VoidCallback? onTap;

  const EntregaItem({
    super.key,
    required this.comercio,
    required this.destino,
    required this.fecha,
    required this.valor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: ColoresEstado.verdeSuave, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 20, color: ColoresEstado.verde),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comercio,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.texto)),
                  Text('$destino • $fecha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.textoGris)),
                ],
              ),
            ),
            Text(valor,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.primario)),
          ],
        ),
      ),
    );
  }
}
