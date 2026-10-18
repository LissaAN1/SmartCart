// lib/src/core/ui/roles/widgets/encabezado_perfil.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';
import 'avatar_perfil.dart';

/// Cabecera centrada de perfil: avatar, nombre, fila de etiquetas
/// y ubicación. La usan repartidor, comercio, colaborador y admin.
class EncabezadoPerfil extends StatelessWidget {
  final String nombre;
  final String? fotoUrl;
  final IconData? insignia;
  final bool enLinea;
  final List<Widget> etiquetas; // EtiquetaEstado, calificación, etc.
  final String? ubicacion;
  final String? correo;

  const EncabezadoPerfil({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.insignia,
    this.enLinea = false,
    this.etiquetas = const [],
    this.ubicacion,
    this.correo,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      children: [
        AvatarPerfil(
          radio: 56,
          nombre: nombre,
          fotoUrl: fotoUrl,
          insignia: insignia,
          enLinea: enLinea,
        ),
        const SizedBox(height: 16),
        Text(nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: t.texto)),
        if (correo != null) ...[
          const SizedBox(height: 4),
          Text(correo!, style: TextStyle(fontSize: 14, color: t.textoGris)),
        ],
        if (etiquetas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: etiquetas,
          ),
        ],
        if (ubicacion != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.place_outlined, size: 16, color: t.textoGris),
              const SizedBox(width: 4),
              Flexible(
                child: Text(ubicacion!,
                    style: TextStyle(fontSize: 14, color: t.textoGris)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Calificación con estrella: "☆ 4.8 (120+ reseñas)".
class Calificacion extends StatelessWidget {
  final double valor;
  final String? detalle;
  const Calificacion({super.key, required this.valor, this.detalle});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_border_rounded, size: 18, color: t.primario),
        const SizedBox(width: 3),
        Text(valor.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: t.texto)),
        if (detalle != null) ...[
          const SizedBox(width: 4),
          Text(detalle!, style: TextStyle(fontSize: 14, color: t.textoGris)),
        ],
      ],
    );
  }
}
