import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_args.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';

/// Las órdenes del cliente, de la más reciente a la más antigua, por páginas.
/// Desde aquí se califica al comercio (y al repartidor, si hubo) de una orden
/// completada (HU-25).
///
/// Necesita un `PaginatedBloc<Orden>` arriba en el árbol (lo da `AppRouter`).
class MisOrdenesPage extends StatelessWidget {
  const MisOrdenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Mis órdenes',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh, color: t.texto),
            onPressed: () =>
                context.read<PaginatedBloc<Orden>>().add(PaginatedStarted()),
          ),
        ],
      ),
      cuerpo: PaginatedListView<Orden>(
        emptyMessage: 'Aún no tienes órdenes. Confirma tu carrito para '
            'generar la primera.',
        itemBuilder: (context, orden) => _TarjetaOrden(orden: orden),
      ),
    );
  }
}

class _TarjetaOrden extends StatelessWidget {
  final Orden orden;

  const _TarjetaOrden({required this.orden});

  Future<void> _calificar(BuildContext context, TipoCalificacion tipo) async {
    final bloc = context.read<PaginatedBloc<Orden>>();
    final enviada = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.calificarOrden,
      arguments: CalificarOrdenArgs(
        idOrden: orden.id,
        numeroOrden: orden.numero,
        comercio: orden.comercio,
        tipo: tipo,
      ),
    );
    // Calificada: la lista se relee para que ya no ofrezca calificar otra vez.
    if (enviada == true) bloc.add(PaginatedStarted());
  }

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
                orden.estado.completada
                    ? EtiquetaEstado.exito(orden.estado.label)
                    : EtiquetaEstado.info(orden.estado.label),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              orden.comercio,
              style: TextStyle(fontSize: 14.5, color: t.texto),
            ),
            Text(
              '${orden.tipoEntrega.label} · ${fechaHora(orden.creadoEn)}',
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
            if (orden.estado.completada) ...[
              const SizedBox(height: 10),
              if (orden.puedeCalificarComercio)
                BotonSuave(
                  texto: 'Calificar al comercio',
                  icono: Icons.star_outline_rounded,
                  onTap: () => _calificar(context, TipoCalificacion.comercio),
                )
              else
                _YaCalificada(texto: 'Ya calificaste al comercio'),
              if (orden.tieneRepartidor) ...[
                const SizedBox(height: 8),
                if (orden.puedeCalificarRepartidor)
                  BotonSuave(
                    texto: 'Calificar al repartidor',
                    icono: Icons.star_outline_rounded,
                    onTap: () =>
                        _calificar(context, TipoCalificacion.repartidor),
                  )
                else
                  _YaCalificada(texto: 'Ya calificaste al repartidor'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _YaCalificada extends StatelessWidget {
  final String texto;

  const _YaCalificada({required this.texto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            size: 18, color: ColoresEstado.verde),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: TextStyle(fontSize: 13, color: t.textoGris)),
        ),
      ],
    );
  }
}
