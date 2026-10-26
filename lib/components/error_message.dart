import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Aviso de error bajo un formulario. Se anuncia como región en vivo para que
/// los lectores de pantalla lo lean cuando aparece.
class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColoresEstado.rojoSuave,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 20, color: ColoresEstado.rojo),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: ColoresEstado.rojo, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
