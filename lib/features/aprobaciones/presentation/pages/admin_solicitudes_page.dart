import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/presentation/widgets/solicitud_card.dart';

/// Crea el Bloc de la lista paginada de cada pestaña. Lo entrega el
/// `AppRouter` (con GetIt); la página no conoce de dónde vienen los datos.
typedef CrearListaSolicitudes = PaginatedBloc<Solicitud> Function(
  TipoSolicitud tipo,
);

/// HU-24: solicitudes pendientes del administrador, una pestaña por tipo
/// (comercios y repartidores). Cada lista se carga por páginas. Al tocar una
/// se abre su detalle; si allí se decide, la lista se recarga.
class AdminSolicitudesPage extends StatelessWidget {
  final CrearListaSolicitudes crearLista;

  const AdminSolicitudesPage({super.key, required this.crearLista});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return DefaultTabController(
      length: TipoSolicitud.values.length,
      child: PantallaRol(
        tema: t,
        barraSuperior: const BarraTituloRol(
          titulo: 'Solicitudes pendientes',
          mostrarAtras: true,
        ),
        cuerpo: Column(
          children: [
            TabBar(
              labelColor: t.primarioOscuro,
              unselectedLabelColor: t.textoGris,
              indicatorColor: t.primario,
              tabs: [
                for (final tipo in TipoSolicitud.values)
                  Tab(icon: Icon(iconoSolicitud(tipo)), text: tipo.plural),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final tipo in TipoSolicitud.values)
                    BlocProvider<PaginatedBloc<Solicitud>>(
                      create: (_) => crearLista(tipo)..add(PaginatedStarted()),
                      child: _ListaPendientes(tipo: tipo),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaPendientes extends StatelessWidget {
  final TipoSolicitud tipo;

  const _ListaPendientes({required this.tipo});

  Future<void> _abrir(BuildContext context, Solicitud solicitud) async {
    final bloc = context.read<PaginatedBloc<Solicitud>>();
    final messenger = ScaffoldMessenger.of(context);
    final decision = await Navigator.of(context).pushNamed<ApprovalStatus>(
      AppRoutes.adminSolicitudDetalle,
      arguments: solicitud,
    );
    if (decision == null) return;
    // La solicitud ya no está pendiente: se recarga la lista sin ella.
    bloc.add(PaginatedStarted());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(decision == ApprovalStatus.aprobado
            ? '${solicitud.nombre} fue aprobado. Se le notificó la decisión.'
            : '${solicitud.nombre} fue rechazado. Se le notificó el motivo.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<PaginatedBloc<Solicitud>>().add(PaginatedStarted()),
      child: PaginatedListView<Solicitud>(
        emptyMessage:
            'No hay ${tipo.plural.toLowerCase()} pendientes de aprobación',
        itemBuilder: (context, solicitud) => SolicitudCard(
          solicitud: solicitud,
          onTap: () => _abrir(context, solicitud),
        ),
      ),
    );
  }
}
