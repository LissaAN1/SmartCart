import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/presentation/widgets/reporte_historial_item.dart';

/// Historial de reportes del colaborador, del más reciente al más antiguo y
/// de cualquier estado: los recién enviados salen como "Pendiente". La lista
/// se carga por páginas.
///
/// Necesita un `PaginatedBloc<MiReporte>` arriba en el árbol (lo provee
/// `AppRouter`).
class MisReportesPage extends StatelessWidget {
  const MisReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Mis reportes',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh, color: t.texto),
            onPressed: () =>
                context.read<PaginatedBloc<MiReporte>>().add(PaginatedStarted()),
          ),
        ],
      ),
      cuerpo: PaginatedListView<MiReporte>(
        emptyMessage: 'Aún no has enviado reportes. Toca "Reportar precio" '
            'para enviar el primero.',
        itemBuilder: (context, reporte) =>
            ReporteHistorialItem(reporte: reporte),
      ),
    );
  }
}
