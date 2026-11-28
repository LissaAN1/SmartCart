import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/reportes/presentation/bloc/reporte_form_bloc.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_args.dart';

/// HU-14, paso 3: precio, promoción, disponibilidad y foto de la etiqueta.
/// Al enviar, el reporte queda pendiente de revisión.
///
/// Necesita un `ReporteFormBloc` arriba en el árbol (lo provee `AppRouter`).
class ReporteFormPage extends StatefulWidget {
  final ReporteFormArgs args;

  const ReporteFormPage({super.key, required this.args});

  @override
  State<ReporteFormPage> createState() => _ReporteFormPageState();
}

class _ReporteFormPageState extends State<ReporteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _precio = TextEditingController();
  final _promocion = TextEditingController();
  bool _agotado = false;

  @override
  void dispose() {
    _precio.dispose();
    _promocion.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ReporteFormBloc>().add(
          ReporteEnviado(
            ReporteDatos(
              establecimiento: widget.args.establecimiento,
              producto: widget.args.producto,
              precio: ReporteValidators.parsePrecio(_precio.text)!,
              precioPromocional: ReporteValidators.parsePrecio(_promocion.text),
              agotado: _agotado,
            ),
          ),
        );
  }

  Future<void> _avisarEnviado() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reporte enviado'),
        content: const Text(
          'Quedó pendiente de revisión. Gracias por ayudar a mantener los '
          'precios al día.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // Cierra todo el flujo del reporte y vuelve al inicio.
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    final e = widget.args.establecimiento;
    final p = widget.args.producto;
    return BlocConsumer<ReporteFormBloc, ReporteFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ReporteFormStatus.enviado,
      listener: (context, state) => _avisarEnviado(),
      builder: (context, state) {
        final ocupado = state.status == ReporteFormStatus.enviando ||
            state.status == ReporteFormStatus.tomandoFoto;
        final error = state.status == ReporteFormStatus.envioFallido ||
                state.status == ReporteFormStatus.fotoFallida
            ? state.errorMessage
            : null;
        return PantallaRol(
          tema: t,
          barraSuperior: const BarraTituloRol(
            titulo: 'Reportar precio',
            mostrarAtras: true,
          ),
          cuerpo: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                TarjetaSuave(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.texto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.nombre,
                        style: TextStyle(fontSize: 13, color: t.textoGris),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _precio,
                  label: 'Precio (COP)',
                  hint: 'Ej. 4900',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: ReporteValidators.precio,
                  enabled: !ocupado,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _promocion,
                  label: 'Precio en promoción (opcional)',
                  hint: 'Solo si tiene promoción',
                  icon: Icons.local_offer_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      ReporteValidators.precioPromocional(value, _precio.text),
                  enabled: !ocupado,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('El producto está agotado'),
                  value: _agotado,
                  onChanged: ocupado
                      ? null
                      : (v) => setState(() => _agotado = v),
                ),
                const SizedBox(height: 8),
                _BloqueFoto(
                  foto: state.foto,
                  ocupado: ocupado,
                  hayCamara: context.read<ReporteFormBloc>().hayCamara,
                  onElegir: (origen) => context
                      .read<ReporteFormBloc>()
                      .add(ReporteFotoSolicitada(origen: origen)),
                  onQuitar: () =>
                      context.read<ReporteFormBloc>().add(ReporteFotoQuitada()),
                ),
                const SizedBox(height: 20),
                if (error != null) ...[
                  ErrorMessage(message: error),
                  const SizedBox(height: 16),
                ],
                BotonPrimario(
                  texto: 'Enviar reporte',
                  cargando: state.status == ReporteFormStatus.enviando,
                  onTap: ocupado ? null : _enviar,
                ),
                const SizedBox(height: 10),
                Text(
                  'Comprobaremos que estás en el establecimiento al enviar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: t.textoGris),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La foto de la etiqueta: dos opciones, tomarla con la cámara o subir una de
/// la galería, y vista previa cuando ya hay una. Es obligatoria; si falta, el
/// envío la reclama. Donde no hay cámara (apps de escritorio) solo se ofrece
/// subir una imagen.
class _BloqueFoto extends StatelessWidget {
  final FotoReporte? foto;
  final bool ocupado;
  final bool hayCamara;
  final ValueChanged<OrigenFoto> onElegir;
  final VoidCallback onQuitar;

  const _BloqueFoto({
    required this.foto,
    required this.ocupado,
    required this.hayCamara,
    required this.onElegir,
    required this.onQuitar,
  });

  /// "Cambiar foto": con cámara pregunta de dónde; sin cámara abre la galería.
  Future<void> _cambiar(BuildContext context) async {
    if (!hayCamara) {
      onElegir(OrigenFoto.galeria);
      return;
    }
    final origen = await showModalBottomSheet<OrigenFoto>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(OrigenFoto.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Subir foto de la galería'),
              onTap: () => Navigator.of(ctx).pop(OrigenFoto.galeria),
            ),
          ],
        ),
      ),
    );
    if (origen != null) onElegir(origen);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final f = foto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto de la etiqueta',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: t.texto,
          ),
        ),
        const SizedBox(height: 8),
        if (f != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              f.bytes,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                alignment: Alignment.center,
                color: t.suave,
                child: const Text('Foto lista'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: ocupado ? null : () => _cambiar(context),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Cambiar foto'),
              ),
              TextButton(
                onPressed: ocupado ? null : onQuitar,
                child: const Text('Quitar'),
              ),
            ],
          ),
        ] else
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (hayCamara)
                OutlinedButton.icon(
                  onPressed:
                      ocupado ? null : () => onElegir(OrigenFoto.camara),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto de la etiqueta'),
                ),
              OutlinedButton.icon(
                onPressed:
                    ocupado ? null : () => onElegir(OrigenFoto.galeria),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hayCamara ? 'Subir foto' : 'Subir foto de la etiqueta'),
              ),
            ],
          ),
      ],
    );
  }
}
