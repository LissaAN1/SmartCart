import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Casilla "Acepto los términos y la política de privacidad". Es un
/// FormField para que el formulario la valide junto con los demás campos.
class TermsCheckbox extends FormField<bool> {
  TermsCheckbox({super.key, super.enabled})
      : super(
          initialValue: false,
          validator: (accepted) => accepted == true
              ? null
              : 'Debes aceptar los términos y la política de privacidad',
          builder: (state) {
            final t = TemaRol.of(state.context);
            final enabled = state.widget.enabled;
            final accepted = state.value ?? false;
            final bold = TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.primario,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: enabled ? () => state.didChange(!accepted) : null,
                  child: Row(
                    children: [
                      Checkbox(
                        value: accepted,
                        activeColor: t.primario,
                        onChanged:
                            enabled ? (v) => state.didChange(v ?? false) : null,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style:
                                TextStyle(fontSize: 13, color: t.textoGris),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              TextSpan(text: 'términos', style: bold),
                              const TextSpan(text: ' y la '),
                              TextSpan(
                                text: 'política de privacidad',
                                style: bold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2),
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
