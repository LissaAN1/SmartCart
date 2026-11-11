import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/presentation/widgets/admin_widgets.dart';

/// HU-24: lista paginada de comercios y repartidores pendientes de
/// aprobación (pestaña "Aprobar" del administrador). Al tocar una solicitud
/// se abre su detalle con las acciones Aprobar y Rechazar.
///
/// Necesita un `PaginatedBloc<SolicitudAprobacion>` arriba en el árbol.
class AdminAprobacionesScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;

  const AdminAprobacionesScreen({super.key, this.onTab});

  Future<void> _abrirDetalle(
    BuildContext context,
    SolicitudAprobacion solicitud,
  ) async {
    final bloc = context.read<PaginatedBloc<SolicitudAprobacion>>();
    final decidida = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.solicitudDetalle,
      arguments: solicitud,
    );
    // Ya no está pendiente: se recarga la lista para que desaparezca.
    if (decidida == true) bloc.add(PaginatedStarted());
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return PantallaRol(
      tema: t,
      navItems: navAdmin(),
      tabActiva: 1,
      onTab: onTab,
      barraSuperior: BarraTituloRol(
        titulo: 'Aprobaciones',
        acciones: [
          IconButton(
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh, color: t.texto),
            onPressed: () => context
                .read<PaginatedBloc<SolicitudAprobacion>>()
                .add(PaginatedStarted()),
          ),
        ],
      ),
      cuerpo: PaginatedListView<SolicitudAprobacion>(
        emptyMessage: 'No hay solicitudes pendientes',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemBuilder: (context, solicitud) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SolicitudCard(
            solicitud: solicitud,
            onTap: () => _abrirDetalle(context, solicitud),
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final SolicitudAprobacion solicitud;
  final VoidCallback onTap;

  const _SolicitudCard({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final esComercio = solicitud.tipo == TipoSolicitud.comercio;
    return TarjetaSuave(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
            child: Icon(
              esComercio
                  ? Icons.storefront_outlined
                  : Icons.delivery_dining_outlined,
              color: t.primario,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.nombre.isEmpty ? 'Sin nombre' : solicitud.nombre,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: t.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  solicitud.detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: t.textoGris),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EtiquetaEstado.pendiente(solicitud.tipo.label),
        ],
      ),
    );
  }
}
