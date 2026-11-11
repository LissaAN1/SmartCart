import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_state.dart';

/// HU-24: detalle de una solicitud con las acciones Aprobar y Rechazar. Al
/// rechazar pide un motivo. Cuando la decisión se guarda se cierra devolviendo
/// `true` a la lista (`Navigator.pop(context, true)`).
class SolicitudDetallePage extends StatelessWidget {
  final SolicitudAprobacion solicitud;

  const SolicitudDetallePage({super.key, required this.solicitud});

  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _maxContentWidth = 480;

  Future<void> _rechazar(BuildContext context) async {
    final bloc = context.read<DecisionSolicitudBloc>();
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoRechazoDialog(),
    );
    // Cancelar el diálogo no rechaza nada.
    if (motivo != null) bloc.add(SolicitudRechazada(solicitud, motivo));
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return TemaRolScope(
      tema: t,
      child: BlocListener<DecisionSolicitudBloc, DecisionSolicitudState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status != DecisionStatus.success) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.aprobada == true
                  ? 'Solicitud aprobada. Se notificó al solicitante.'
                  : 'Solicitud rechazada. Se notificó al solicitante.'),
            ));
          Navigator.of(context).pop(true);
        },
        child: Scaffold(
          backgroundColor: t.fondo,
          appBar: BarraTituloRol(
            titulo: 'Detalle de la solicitud',
            mostrarAtras: true,
            onAtras: () => Navigator.of(context).maybePop(),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: BlocBuilder<DecisionSolicitudBloc, DecisionSolicitudState>(
                  builder: (context, state) =>
                      _buildBody(context, t, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TemaRol t,
    DecisionSolicitudState state,
  ) {
    final cargando = state.status == DecisionStatus.loading;
    final error =
        state.status == DecisionStatus.failure ? state.errorMessage : null;
    final esComercio = solicitud.tipo == TipoSolicitud.comercio;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                solicitud.nombre.isEmpty ? 'Sin nombre' : solicitud.nombre,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: t.texto,
                ),
              ),
            ),
            EtiquetaEstado.pendiente(solicitud.tipo.label),
          ],
        ),
        const SizedBox(height: 16),
        TarjetaSuave(
          child: Column(
            children: [
              _Dato(
                icono: esComercio
                    ? Icons.place_outlined
                    : Icons.mail_outline,
                etiqueta: esComercio ? 'Ubicación' : 'Correo',
                valor: solicitud.detalle,
              ),
              if ((solicitud.contacto ?? '').isNotEmpty)
                _Dato(
                  icono: Icons.phone_outlined,
                  etiqueta: 'Teléfono',
                  valor: solicitud.contacto!,
                ),
              _Dato(
                icono: Icons.hourglass_top_rounded,
                etiqueta: 'Estado',
                valor: 'Pendiente de aprobación',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (error != null) ...[
          ErrorMessage(message: error),
          const SizedBox(height: 16),
        ],
        BotonPrimario(
          texto: 'Aprobar',
          iconoFinal: Icons.check,
          cargando: cargando,
          onTap: () => context
              .read<DecisionSolicitudBloc>()
              .add(SolicitudAprobada(solicitud)),
        ),
        const SizedBox(height: 12),
        BotonSuave(
          texto: 'Rechazar',
          icono: Icons.close,
          onTap: cargando ? null : () => _rechazar(context),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Dato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: t.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: TextStyle(fontSize: 12, color: t.textoGris)),
                Text(valor,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.texto)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pide el motivo del rechazo. No deja confirmar con el campo vacío.
class _MotivoRechazoDialog extends StatefulWidget {
  const _MotivoRechazoDialog();

  @override
  State<_MotivoRechazoDialog> createState() => _MotivoRechazoDialogState();
}

class _MotivoRechazoDialogState extends State<_MotivoRechazoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar solicitud'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Explica por qué no se aprueba',
          ),
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Escribe el motivo del rechazo'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Rechazar')),
      ],
    );
  }
}
