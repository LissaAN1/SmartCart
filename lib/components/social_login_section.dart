import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Separador "o" y botón "Continuar con Google" que aparecen en el login y
/// en el registro.
///
/// Google todavía no está habilitado: requiere configurar el proveedor en
/// Supabase y los enlaces de retorno de la app, y eso no está en los
/// requisitos actuales. Por eso el botón solo avisa y no finge iniciar sesión.
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: t.borde, thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: TextStyle(color: t.textoGris)),
            ),
            Expanded(child: Divider(color: t.borde, thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Continuar con Google aún no está disponible. '
                      'Usa tu correo y contraseña.',
                    ),
                  ),
                );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: t.texto,
              backgroundColor: const Color(0xFFF6F7F9),
              side: BorderSide(color: t.borde, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4285F4),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Continuar con Google',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
