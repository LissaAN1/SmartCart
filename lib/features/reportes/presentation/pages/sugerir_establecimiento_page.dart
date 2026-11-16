import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/reportes/presentation/bloc/sugerencia_bloc.dart';

/// HU-14: el colaborador sugiere un establecimiento que todavía no está en
/// la plataforma. Se guarda con su ubicación actual para que quien lo revise
/// pueda encontrarlo.
///
/// Necesita un `SugerenciaBloc` arriba en el árbol (lo provee `AppRouter`).
class SugerirEstablecimientoPage extends StatefulWidget {
  const SugerirEstablecimientoPage({super.key});

  @override
  State<SugerirEstablecimientoPage> createState() =>
      _SugerirEstablecimientoPageState();
}

class _SugerirEstablecimientoPageState
    extends State<SugerirEstablecimientoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _ciudad = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _ciudad.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<SugerenciaBloc>().add(
          SugerenciaEnviada(
            SugerenciaDatos(
              nombre: _nombre.text,
              direccion: _direccion.text,
              ciudad: _ciudad.text,
            ),
          ),
        );
  }

  Future<void> _avisarEnviada() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sugerencia enviada'),
        content: const Text(
          'La revisaremos para agregar el establecimiento a la plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return BlocConsumer<SugerenciaBloc, SugerenciaState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SugerenciaStatus.enviada,
      listener: (context, state) => _avisarEnviada(),
      builder: (context, state) {
        final enviando = state.status == SugerenciaStatus.enviando;
        final error =
            state.status == SugerenciaStatus.fallida ? state.errorMessage : null;
        return PantallaRol(
          tema: t,
          barraSuperior: const BarraTituloRol(
            titulo: 'Sugerir establecimiento',
            mostrarAtras: true,
          ),
          cuerpo: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text(
                  'Dinos dónde estás y lo agregaremos a SmartCart. Usaremos tu '
                  'ubicación actual para encontrarlo.',
                  style: TextStyle(fontSize: 14, height: 1.35, color: t.textoGris),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _nombre,
                  label: 'Nombre del establecimiento',
                  hint: 'Ej. Tienda Doña Rosa',
                  icon: Icons.storefront_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: ReporteValidators.nombreSugerido,
                  enabled: !enviando,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _direccion,
                  label: 'Dirección',
                  hint: 'Calle 10 # 5-20',
                  icon: Icons.place_outlined,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: ReporteValidators.direccionSugerida,
                  enabled: !enviando,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _ciudad,
                  label: 'Ciudad o barrio',
                  hint: 'Cali, San Fernando',
                  icon: Icons.location_city_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  validator: ReporteValidators.ciudadSugerida,
                  enabled: !enviando,
                ),
                const SizedBox(height: 20),
                if (error != null) ...[
                  ErrorMessage(message: error),
                  const SizedBox(height: 16),
                ],
                BotonPrimario(
                  texto: 'Enviar sugerencia',
                  cargando: enviando,
                  onTap: _enviar,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
