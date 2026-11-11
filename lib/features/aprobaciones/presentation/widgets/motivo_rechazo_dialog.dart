import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/aprobaciones/domain/validators/aprobacion_validators.dart';

/// Pide el motivo del rechazo (HU-24, escenario 2). Devuelve el motivo
/// escrito, o `null` si el administrador cancela. No deja confirmar con el
/// campo vacío: muestra el error en el mismo diálogo.
Future<String?> pedirMotivoRechazo(BuildContext context, String nombre) {
  return showDialog<String>(
    context: context,
    builder: (_) => _MotivoRechazoDialog(nombre: nombre),
  );
}

class _MotivoRechazoDialog extends StatefulWidget {
  final String nombre;

  const _MotivoRechazoDialog({required this.nombre});

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
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rechazar ${widget.nombre}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('motivo-rechazo'),
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: AprobacionValidators.motivoMaximo,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'El solicitante lo verá en su notificación',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          validator: AprobacionValidators.motivoRechazo,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _confirmar,
          child: const Text(
            'Rechazar',
            style: TextStyle(color: ColoresEstado.rojo),
          ),
        ),
      ],
    );
  }
}
