import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Campo del formulario de login y registro: etiqueta arriba, ícono a la
/// izquierda y, si es de contraseña, botón para mostrarla u ocultarla.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Widget opcional a la derecha de la etiqueta (por ejemplo, "¿Olvidaste tu
  /// contraseña?").
  final Widget? labelTrailing;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
    this.labelTrailing,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _hidden = true;

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.texto,
                ),
              ),
            ),
            if (widget.labelTrailing != null) widget.labelTrailing!,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.isPassword && _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          autocorrect: false,
          enableSuggestions: !widget.isPassword,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: t.textoGris.withValues(alpha: 0.8)),
            filled: true,
            fillColor: const Color(0xFFF6F7F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(widget.icon, color: t.texto, size: 22),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip:
                        _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: t.textoGris,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            border: _border(t.borde),
            enabledBorder: _border(t.borde),
            disabledBorder: _border(t.borde),
            focusedBorder: _border(t.primario, 2),
            errorBorder: _border(ColoresEstado.rojo),
            focusedErrorBorder: _border(ColoresEstado.rojo, 2),
          ),
        ),
      ],
    );
  }
}
