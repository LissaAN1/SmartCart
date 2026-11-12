import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_state.dart';
import 'package:smartcart/features/aprobaciones/presentation/widgets/motivo_rechazo_dialog.dart';
import 'package:smartcart/features/aprobaciones/presentation/widgets/solicitud_card.dart';

/// HU-24: datos de una solicitud con las acciones Aprobar y Rechazar. Al
/// decidir vuelve a la lista devolviendo la decisión
/// (`Navigator.pop(context, decision)`).
///
/// Necesita un `DecisionSolicitudBloc` arriba en el árbol (lo provee
/// `AppRouter`).
class SolicitudDetallePage extends StatelessWidget {
  const SolicitudDetallePage({super.key});

  Future<void> _aprobar(BuildContext context, Solicitud solicitud) async {
    final bloc = context.read<DecisionSolicitudBloc>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Aprobar ${solicitud.nombre}?'),
        content: Text(solicitud.tipo == TipoSolicitud.comercio
            ? 'El comercio podrá publicar su catálogo y sus precios.'
            : 'El repartidor podrá activar su disponibilidad.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirmado == true) bloc.add(AprobacionSolicitada());
  }

  Future<void> _rechazar(BuildContext context, Solicitud solicitud) async {
    final bloc = context.read<DecisionSolicitudBloc>();
    final motivo = await pedirMotivoRechazo(context, solicitud.nombre);
    if (motivo != null) bloc.add(RechazoSolicitado(motivo));
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    final solicitud = context.read<DecisionSolicitudBloc>().solicitud;
    return BlocConsumer<DecisionSolicitudBloc, DecisionSolicitudState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DecisionSolicitudStatus.success) {
          Navigator.of(context).pop(state.decision);
        }
      },
      builder: (context, state) {
        return PantallaRol(
          tema: t,
          barraSuperior: BarraTituloRol(
            titulo: 'Solicitud de ${solicitud.tipo.label.toLowerCase()}',
            mostrarAtras: true,
          ),
          cuerpo: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
            children: [
              _Encabezado(solicitud: solicitud),
              const SizedBox(height: 20),
              _Datos(solicitud: solicitud),
              const SizedBox(height: 24),
              if (state.status == DecisionSolicitudStatus.failure &&
                  state.errorMessage != null) ...[
                ErrorMessage(message: state.errorMessage!),
                const SizedBox(height: 16),
              ],
              BotonPrimario(
                texto: 'Aprobar',
                iconoFinal: Icons.check_circle_outline,
                cargando: state.enviando,
                onTap: () => _aprobar(context, solicitud),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.enviando
                      ? null
                      : () => _rechazar(context, solicitud),
                  icon: const Icon(Icons.highlight_off),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColoresEstado.rojo,
                    side: const BorderSide(color: ColoresEstado.rojo),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  final Solicitud solicitud;

  const _Encabezado({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final fecha = solicitud.creadoEn;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
          child: Icon(iconoSolicitud(solicitud.tipo),
              size: 40, color: t.primarioOscuro),
        ),
        const SizedBox(height: 14),
        Text(
          solicitud.nombre,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: t.texto),
        ),
        const SizedBox(height: 6),
        Text(
          fecha == null
              ? solicitud.tipo.label
              : '${solicitud.tipo.label} · enviada el ${fechaCorta(fecha)}',
          style: TextStyle(fontSize: 13.5, color: t.textoGris),
        ),
        const SizedBox(height: 12),
        const EtiquetaEstado.pendiente('Pendiente de aprobación'),
      ],
    );
  }
}

class _Datos extends StatelessWidget {
  final Solicitud solicitud;

  const _Datos({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final comercio = solicitud.comercio;
    return TarjetaSuave(
      radio: 18,
      child: Column(
        children: [
          if (comercio != null) ...[
            _Dato(Icons.place_outlined, 'Ubicación',
                '${comercio.direccion}, ${comercio.ciudad}'),
            _Dato(Icons.schedule, 'Horario', comercio.horario),
            _Dato(Icons.local_shipping_outlined, 'Servicio',
                comercio.servicio.label),
            if (solicitud.responsable != null)
              _Dato(Icons.person_outline, 'Dueño', solicitud.responsable!),
          ],
          _Dato(Icons.mail_outline, 'Correo',
              solicitud.correo ?? 'No registrado'),
          _Dato(Icons.phone_iphone, 'Teléfono',
              solicitud.telefono ?? 'No registrado'),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Dato(this.icono, this.etiqueta, this.valor);

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
