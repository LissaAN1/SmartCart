import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/confianza/domain/usecases/reportar_precio_incorrecto_usecase.dart';

/// Lo que el cliente escribió al reportar. [motivo] es `null` si lo dejó en
/// blanco (el motivo es opcional).
typedef MotivoDeReporte = ({String? motivo});

/// Pregunta el motivo del reporte (opcional) en una hoja inferior. Devuelve
/// `null` si el cliente cancela y el [MotivoDeReporte] si toca "Enviar
/// reporte".
Future<MotivoDeReporte?> pedirMotivoDeReporte(
  BuildContext context, {
  required String comercio,
  required String precio,
}) {
  return showModalBottomSheet<MotivoDeReporte>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _MotivoSheet(comercio: comercio, precio: precio),
  );
}

class _MotivoSheet extends StatefulWidget {
  final String comercio;
  final String precio;

  const _MotivoSheet({required this.comercio, required this.precio});

  @override
  State<_MotivoSheet> createState() => _MotivoSheetState();
}

class _MotivoSheetState extends State<_MotivoSheet> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controlador.text.trim();
    Navigator.of(context).pop<MotivoDeReporte>(
      (motivo: texto.isEmpty ? null : texto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    // Sube la hoja por encima del teclado.
    final teclado = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + teclado),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportar precio incorrecto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: t.texto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.comercio} · ${widget.precio}',
            style: TextStyle(fontSize: 13.5, color: t.textoGris),
          ),
          const SizedBox(height: 12),
          Text(
            'Revisaremos el precio. Si quieres, cuéntanos cuál viste.',
            style: TextStyle(fontSize: 13.5, color: t.texto),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controlador,
            maxLines: 3,
            minLines: 2,
            maxLength: ReportarPrecioIncorrectoUseCase.motivoMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Motivo (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          BotonPrimario(texto: 'Enviar reporte', onTap: _enviar),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}
