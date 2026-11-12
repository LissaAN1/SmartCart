import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/validators/comercio_validators.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';

/// HU-07: formulario de registro del comercio (datos, ubicación, horario y
/// tipo de servicio). Se muestra en lugar del Home mientras la cuenta de
/// Comercio no tenga un establecimiento registrado. Al guardar, el
/// `ComercioBloc` queda con el comercio pendiente y `ComercioGate` pasa a la
/// pantalla de "registro en revisión".
class ComercioRegistroPage extends StatefulWidget {
  final VoidCallback? onCerrarSesion;

  const ComercioRegistroPage({super.key, this.onCerrarSesion});

  @override
  State<ComercioRegistroPage> createState() => _ComercioRegistroPageState();
}

class _ComercioRegistroPageState extends State<ComercioRegistroPage> {
  /// Ancho máximo del formulario en tablet y escritorio.
  static const double _maxContentWidth = 480;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _aperturaController = TextEditingController();
  final _cierreController = TextEditingController();
  ServicioComercio? _servicio;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _aperturaController.dispose();
    _cierreController.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(
    TextEditingController controller,
    TimeOfDay porDefecto,
  ) async {
    final actual = _parseHora(controller.text) ?? porDefecto;
    final elegida = await showTimePicker(context: context, initialTime: actual);
    if (elegida == null) return;
    final hh = elegida.hour.toString().padLeft(2, '0');
    final mm = elegida.minute.toString().padLeft(2, '0');
    controller.text = '$hh:$mm';
  }

  TimeOfDay? _parseHora(String text) {
    if (ComercioValidators.hora(text) != null) return null;
    final partes = text.trim().split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ComercioBloc>().add(
          ComercioSubmitted(
            ComercioDatos(
              nombre: _nombreController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              ciudad: _ciudadController.text.trim(),
              horaApertura: _aperturaController.text.trim(),
              horaCierre: _cierreController.text.trim(),
              servicio: _servicio!,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return TemaRolScope(
      tema: t,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Registra tu comercio',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.texto,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: Icon(Icons.logout, color: t.texto),
              onPressed: () =>
                  confirmarCierreSesion(context, widget.onCerrarSesion),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: BlocBuilder<ComercioBloc, ComercioState>(
                builder: (context, state) {
                  final guardando = state.status == ComercioStatus.saving;
                  final error = state.status == ComercioStatus.saveFailed
                      ? state.errorMessage
                      : null;
                  return _buildForm(t, guardando, error);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TemaRol t, bool guardando, String? error) {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'Cuéntanos sobre tu establecimiento',
            style: TextStyle(
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: t.texto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Un administrador revisará tu registro antes de que puedas '
            'publicar tus productos.',
            style: TextStyle(fontSize: 14, color: t.textoGris),
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: _nombreController,
            label: 'Nombre del establecimiento',
            hint: 'Ej. Minimercado La Esquina',
            icon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: ComercioValidators.nombre,
            enabled: !guardando,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _telefonoController,
            label: 'Teléfono del comercio',
            hint: '+57 300 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: ComercioValidators.telefono,
            enabled: !guardando,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _direccionController,
            label: 'Dirección',
            hint: 'Calle 10 # 5-20',
            icon: Icons.place_outlined,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: ComercioValidators.direccion,
            enabled: !guardando,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _ciudadController,
            label: 'Ciudad y barrio',
            hint: 'Cali, San Fernando',
            icon: Icons.location_city_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: ComercioValidators.ciudad,
            enabled: !guardando,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CampoHora(
                  controller: _aperturaController,
                  label: 'Apertura',
                  enabled: !guardando,
                  validator: ComercioValidators.hora,
                  onTap: () => _elegirHora(
                    _aperturaController,
                    const TimeOfDay(hour: 8, minute: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CampoHora(
                  controller: _cierreController,
                  label: 'Cierre',
                  enabled: !guardando,
                  validator: (value) => ComercioValidators.cierre(
                    value,
                    _aperturaController.text,
                  ),
                  onTap: () => _elegirHora(
                    _cierreController,
                    const TimeOfDay(hour: 18, minute: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SelectorServicio(
            seleccionado: _servicio,
            enabled: !guardando,
            onChanged: (value) => setState(() => _servicio = value),
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            ErrorMessage(message: error),
            const SizedBox(height: 16),
          ],
          BotonPrimario(
            texto: 'Registrar',
            cargando: guardando,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

/// Campo de hora: no se escribe, se toca para abrir el selector de hora.
class _CampoHora extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final VoidCallback onTap;

  const _CampoHora({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.validator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        child: AuthTextField(
          controller: controller,
          label: label,
          hint: 'HH:mm',
          icon: Icons.schedule,
          validator: validator,
          enabled: enabled,
        ),
      ),
    );
  }
}

/// Tipo de servicio: recogida, entrega o ambos. Es un FormField para que el
/// formulario lo valide junto con los demás campos.
class _SelectorServicio extends FormField<ServicioComercio> {
  _SelectorServicio({
    required ServicioComercio? seleccionado,
    required ValueChanged<ServicioComercio> onChanged,
    super.enabled,
  }) : super(
          initialValue: seleccionado,
          validator: ComercioValidators.servicio,
          builder: (state) {
            final t = TemaRol.of(state.context);
            final enabled = state.widget.enabled;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de servicio',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.texto,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final servicio in ServicioComercio.values)
                      ChoiceChip(
                        label: Text(servicio.label),
                        selected: state.value == servicio,
                        selectedColor: t.suave,
                        onSelected: enabled
                            ? (_) {
                                state.didChange(servicio);
                                onChanged(servicio);
                              }
                            : null,
                      ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColoresEstado.rojo,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
