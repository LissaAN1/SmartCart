import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
import 'package:smartcart/features/reportes/presentation/reporte_formato.dart';

/// HU-15: reportes de precio que esperan confirmación porque el precio
/// reportado es muy distinto al registrado. La lista se carga por páginas.
///
/// * Con [esComercio] falso es la del colaborador: puede **confirmar** un
///   reporte de otra persona (estando en el establecimiento).
/// * Con [esComercio] verdadero es la del dueño del comercio: puede
///   **confirmar** el precio o **corregirlo**.
///
/// Necesita un `PaginatedBloc<ReportePorConfirmar>` y un `AccionReporteBloc`
/// arriba en el árbol (los provee `AppRouter`).
class ReportesPorConfirmarPage extends StatelessWidget {
  final bool esComercio;

  const ReportesPorConfirmarPage({super.key, this.esComercio = false});

  Future<void> _corregir(BuildContext context, ReportePorConfirmar r) async {
    final bloc = context.read<AccionReporteBloc>();
    final precio = await showDialog<int>(
      context: context,
      builder: (_) => _CorregirPrecioDialog(reporte: r),
    );
    // Cancelar el cuadro no corrige nada.
    if (precio != null) bloc.add(ReporteCorregidoPorComercio(r.id, precio));
  }

  @override
  Widget build(BuildContext context) {
    final t = esComercio ? TemaRol.comercio : TemaRol.colaborador;
    return BlocListener<AccionReporteBloc, AccionReporteState>(
      listenWhen: (anterior, actual) =>
          anterior.status != actual.status &&
          (actual.status == AccionReporteStatus.success ||
              actual.status == AccionReporteStatus.failure),
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.mensaje ?? '')));
        // Ya no necesita confirmación: se recarga para que desaparezca.
        if (state.status == AccionReporteStatus.success) {
          context
              .read<PaginatedBloc<ReportePorConfirmar>>()
              .add(PaginatedStarted());
        }
      },
      child: PantallaRol(
        tema: t,
        barraSuperior: BarraTituloRol(
          titulo: esComercio ? 'Reportes de la comunidad' : 'Reportes por confirmar',
          mostrarAtras: true,
          acciones: [
            IconButton(
              tooltip: 'Actualizar',
              icon: Icon(Icons.refresh, color: t.texto),
              onPressed: () => context
                  .read<PaginatedBloc<ReportePorConfirmar>>()
                  .add(PaginatedStarted()),
            ),
          ],
        ),
        cuerpo: PaginatedListView<ReportePorConfirmar>(
          emptyMessage: esComercio
              ? 'No hay reportes de la comunidad por confirmar.'
              : 'No hay reportes por confirmar. Cuando el precio que alguien '
                  'reporta es muy distinto al registrado, aparece aquí.',
          itemBuilder: (context, reporte) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReporteCard(
              reporte: reporte,
              esComercio: esComercio,
              onConfirmar: () => context.read<AccionReporteBloc>().add(
                    esComercio
                        ? ReporteConfirmadoPorComercio(reporte.id)
                        : ReporteConfirmadoPorColaborador(reporte.id),
                  ),
              onCorregir: esComercio ? () => _corregir(context, reporte) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final ReportePorConfirmar reporte;
  final bool esComercio;
  final VoidCallback onConfirmar;
  final VoidCallback? onCorregir;

  const _ReporteCard({
    required this.reporte,
    required this.esComercio,
    required this.onConfirmar,
    required this.onCorregir,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final actual = reporte.precioActual;
    final diferencia = reporte.diferencia;
    return BlocBuilder<AccionReporteBloc, AccionReporteState>(
      builder: (context, estado) {
        final ocupado = estado.status == AccionReporteStatus.loading;
        final esteOcupado = ocupado && estado.idEnProceso == reporte.id;
        return TarjetaSuave(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reporte.producto,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.texto)),
              const SizedBox(height: 2),
              Text('${reporte.establecimiento} • '
                  '${formatoFechaHora(reporte.creadoEn)}',
                  style: TextStyle(fontSize: 12.5, color: t.textoGris)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Precio(
                        etiqueta: 'Reportado',
                        valor: formatoPesos(reporte.precio),
                        destacado: true),
                  ),
                  Expanded(
                    child: _Precio(
                        etiqueta: 'Registrado',
                        valor: actual == null ? 'Sin precio' : formatoPesos(actual)),
                  ),
                  if (diferencia != null)
                    EtiquetaEstado.pendiente(
                        '${reporte.precio >= actual! ? '+' : '-'}'
                        '${(diferencia * 100).round()} %'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: BotonPrimario(
                      texto: 'Confirmar precio',
                      cargando: esteOcupado,
                      onTap: ocupado ? null : onConfirmar,
                    ),
                  ),
                  if (onCorregir != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: BotonSuave(
                        texto: 'Corregir',
                        onTap: ocupado ? null : onCorregir,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Precio extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _Precio({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 12, color: t.textoGris)),
        Text(valor,
            style: TextStyle(
                fontSize: 16,
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
                color: t.texto)),
      ],
    );
  }
}

/// Pide el precio correcto. No deja confirmar un precio inválido.
class _CorregirPrecioDialog extends StatefulWidget {
  final ReportePorConfirmar reporte;

  const _CorregirPrecioDialog({required this.reporte});

  @override
  State<_CorregirPrecioDialog> createState() => _CorregirPrecioDialogState();
}

class _CorregirPrecioDialogState extends State<_CorregirPrecioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ReporteValidators.parsePrecio(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Corregir el precio'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Precio correcto (COP)',
            hintText: 'Ej. ${widget.reporte.precioActual ?? 4900}',
          ),
          validator: ReporteValidators.precio,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Corregir')),
      ],
    );
  }
}
