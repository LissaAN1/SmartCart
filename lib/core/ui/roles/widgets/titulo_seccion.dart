// lib/src/core/ui/roles/widgets/titulo_seccion.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

enum EstiloTitulo {
  /// "CATEGORÍAS", "ACTIVIDAD Y GESTIÓN": pequeño, mayúsculas, espaciado.
  etiqueta,

  /// "Órdenes Recientes", "Accesos Rápidos": grande y en negrita.
  grande,
}

class TituloSeccion extends StatelessWidget {
  final String titulo;
  final IconData? icono;
  final String? accion; // "Ver todas", "ACTUALIZAR"...
  final VoidCallback? onAccion;
  final EstiloTitulo estilo;
  final EdgeInsetsGeometry padding;

  const TituloSeccion({
    super.key,
    required this.titulo,
    this.icono,
    this.accion,
    this.onAccion,
    this.estilo = EstiloTitulo.etiqueta,
    this.padding = const EdgeInsets.only(top: 26, bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final esEtiqueta = estilo == EstiloTitulo.etiqueta;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: esEtiqueta ? 16 : 20, color: t.primario),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titulo,
              style: esEtiqueta
                  ? TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: t.texto.withValues(alpha: 0.75))
                  : TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: t.texto),
            ),
          ),
          if (accion != null)
            InkWell(
              onTap: onAccion,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(accion!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.primario)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
