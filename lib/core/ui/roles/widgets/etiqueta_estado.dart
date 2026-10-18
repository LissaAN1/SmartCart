// lib/src/core/ui/roles/widgets/etiqueta_estado.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Pastilla de texto: "Verificado", "Pendiente", "Usuario Premium", "-30%"...
class EtiquetaEstado extends StatelessWidget {
  final String texto;
  final Color color; // color del texto (y del borde si [conBorde])
  final Color fondo;
  final bool conBorde;
  final IconData? icono;
  final double tamanoTexto;

  const EtiquetaEstado({
    super.key,
    required this.texto,
    required this.color,
    required this.fondo,
    this.conBorde = false,
    this.icono,
    this.tamanoTexto = 11.5,
  });

  const EtiquetaEstado.exito(this.texto, {super.key})
      : color = ColoresEstado.verde,
        fondo = ColoresEstado.verdeSuave,
        conBorde = true,
        icono = null,
        tamanoTexto = 11.5;

  const EtiquetaEstado.pendiente(this.texto, {super.key})
      : color = ColoresEstado.ambar,
        fondo = ColoresEstado.ambarSuave,
        conBorde = true,
        icono = null,
        tamanoTexto = 11.5;

  const EtiquetaEstado.info(this.texto, {super.key})
      : color = ColoresEstado.azul,
        fondo = ColoresEstado.azulSuave,
        conBorde = true,
        icono = null,
        tamanoTexto = 11.5;

  const EtiquetaEstado.error(this.texto, {super.key})
      : color = ColoresEstado.rojo,
        fondo = ColoresEstado.rojoSuave,
        conBorde = true,
        icono = null,
        tamanoTexto = 11.5;

  /// Con los colores del rol activo.
  static Widget marca(String texto, {IconData? icono, bool contorno = false}) =>
      Builder(builder: (context) {
        final t = TemaRol.of(context);
        return EtiquetaEstado(
          texto: texto,
          icono: icono,
          color: contorno ? t.texto : t.primario,
          fondo: contorno ? t.superficie : t.suave,
          conBorde: contorno,
        );
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: conBorde
            ? Border.all(color: color.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: tamanoTexto + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(texto,
              style: TextStyle(
                  fontSize: tamanoTexto,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
