import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Título pequeño en mayúsculas sobre un campo, como en el diseño de Editar
/// producto ("NOMBRE DEL PRODUCTO", "PRECIO ACTUAL (COP)").
class EtiquetaCampo extends StatelessWidget {
  final String texto;

  const EtiquetaCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: t.textoGris,
      ),
    );
  }
}

/// Campo de Editar producto: etiqueta en mayúsculas arriba y caja blanca
/// redondeada con ícono, como en el diseño.
class CampoFormulario extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final IconData icono;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  /// Estilo del texto escrito (el precio va grande y en el color del rol).
  final TextStyle? estilo;

  /// Contenido a la derecha dentro del campo (la variación del precio).
  final Widget? sufijo;

  const CampoFormulario({
    super.key,
    required this.etiqueta,
    required this.controller,
    required this.icono,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.enabled = true,
    this.estilo,
    this.sufijo,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: ancho),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(etiqueta),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          autocorrect: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: estilo ?? TextStyle(fontSize: 16, color: t.texto),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textoGris.withValues(alpha: 0.8)),
            filled: true,
            fillColor: t.superficie,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(icono, color: t.primario, size: 22),
            suffixIcon: sufijo == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Align(
                      widthFactor: 1,
                      alignment: Alignment.centerRight,
                      child: sufijo,
                    ),
                  ),
            border: borde(t.borde),
            enabledBorder: borde(t.borde),
            disabledBorder: borde(t.borde),
            focusedBorder: borde(t.primario, 2),
            errorBorder: borde(ColoresEstado.rojo),
            focusedErrorBorder: borde(ColoresEstado.rojo, 2),
          ),
        ),
      ],
    );
  }
}
