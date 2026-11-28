import 'package:flutter/material.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';

/// HU-20: lo que recibe el cliente al confirmar: una orden por comercio, todas
/// en "Orden generada", y la lista de compra de los establecimientos sin
/// registro.
class CompraConfirmadaPage extends StatelessWidget {
  final ComprobanteCompra comprobante;

  const CompraConfirmadaPage({super.key, required this.comprobante});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    final ordenes = comprobante.ordenes;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Compra confirmada',
        mostrarAtras: true,
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: ColoresEstado.verde, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ordenes.isEmpty
                      ? 'Tu lista de compra está lista'
                      : ordenes.length == 1
                          ? 'Se generó 1 orden'
                          : 'Se generaron ${ordenes.length} órdenes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final orden in ordenes) _TarjetaOrden(orden: orden),
          for (final lista in comprobante.listasDeCompra)
            _TarjetaListaDeCompra(grupo: lista),
          const SizedBox(height: 8),
          if (ordenes.isNotEmpty)
            BotonPrimario(
              texto: 'Ver mis órdenes',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.misOrdenes),
            ),
          const SizedBox(height: 10),
          BotonSuave(
            texto: 'Volver al inicio',
            icono: Icons.home_outlined,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}

class _TarjetaOrden extends StatelessWidget {
  final OrdenGenerada orden;

  const _TarjetaOrden({required this.orden});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orden #${orden.numero}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: t.texto,
                    ),
                  ),
                ),
                EtiquetaEstado.info(orden.estado.label),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              orden.comercio,
              style: TextStyle(fontSize: 14.5, color: t.texto),
            ),
            Text(
              orden.tipoEntrega.label,
              style: TextStyle(fontSize: 13, color: t.textoGris),
            ),
            const SizedBox(height: 6),
            Text(
              formatoCop(orden.total),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaListaDeCompra extends StatelessWidget {
  final GrupoCompra grupo;

  const _TarjetaListaDeCompra({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lista de compra · ${grupo.establecimiento}',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Establecimiento sin registro: cómpralo allá con esta lista.',
              style: TextStyle(fontSize: 13, color: t.textoGris),
            ),
            const SizedBox(height: 8),
            for (final linea in grupo.lineas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${linea.cantidad} × ${linea.nombre}',
                  style: TextStyle(fontSize: 14, color: t.texto),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
