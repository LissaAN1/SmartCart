// lib/src/core/ui/roles/widgets/banners.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Banner de color primario con CTA. Ej: "Arma tu carrito y compáralo",
/// "Tip de Ganancias".
class BannerPromo extends StatelessWidget {
  final String? etiqueta; // pastilla "NUEVO"
  final String? sobretitulo; // "Ahorro inteligente"
  final String titulo;
  final String? descripcion;
  final String? textoBoton;
  final VoidCallback? onBoton;
  final IconData? iconoGrande; // ícono decorativo a la derecha
  final Color? color;
  final Color? colorBoton;
  final Color? colorTextoBoton;

  const BannerPromo({
    super.key,
    this.etiqueta,
    this.sobretitulo,
    required this.titulo,
    this.descripcion,
    this.textoBoton,
    this.onBoton,
    this.iconoGrande,
    this.color,
    this.colorBoton,
    this.colorTextoBoton,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final fondo = color ?? t.primario;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: fondo.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (iconoGrande != null)
            Positioned(
              right: 18,
              top: 0,
              bottom: 0,
              child: Icon(iconoGrande,
                  size: 96, color: Colors.white.withValues(alpha: 0.85)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (etiqueta != null || sobretitulo != null) ...[
                  Row(
                    children: [
                      if (etiqueta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Text(etiqueta!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6)),
                        ),
                      if (etiqueta != null && sobretitulo != null)
                        const SizedBox(width: 8),
                      if (sobretitulo != null)
                        Text(sobretitulo!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                FractionallySizedBox(
                  widthFactor: iconoGrande != null ? 0.68 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.25,
                              fontWeight: FontWeight.w700)),
                      if (descripcion != null) ...[
                        const SizedBox(height: 8),
                        Text(descripcion!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13.5,
                                height: 1.4)),
                      ],
                    ],
                  ),
                ),
                if (textoBoton != null) ...[
                  const SizedBox(height: 18),
                  Material(
                    color: colorBoton ?? const Color(0xFFFDEBDD),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onBoton,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(textoBoton!,
                                style: TextStyle(
                                    color: colorTextoBoton ??
                                        const Color(0xFF8A3B12),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward,
                                size: 16,
                                color: colorTextoBoton ??
                                    const Color(0xFF8A3B12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum EstiloAviso { oscuro, suave }

/// Aviso con ícono. [EstiloAviso.oscuro]: "Acción Requerida" del admin o
/// "Nueva tarifa dinámica" del repartidor. [EstiloAviso.suave]: nota
/// informativa ("Ser colaborador requiere...").
class AvisoDestacado extends StatelessWidget {
  final IconData icono;
  final String? titulo;
  final String? descripcion;
  final EstiloAviso estilo;
  final VoidCallback? onTap;

  const AvisoDestacado({
    super.key,
    required this.icono,
    this.titulo,
    this.descripcion,
    this.estilo = EstiloAviso.oscuro,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final oscuro = estilo == EstiloAviso.oscuro;
    final fondo = oscuro ? t.primarioOscuro : t.suave;
    final colorTitulo = oscuro ? Colors.white : t.texto;
    final colorDesc = oscuro
        ? Colors.white.withValues(alpha: 0.75)
        : t.texto.withValues(alpha: 0.75);

    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: oscuro ? t.primario : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono,
                    size: 22, color: oscuro ? Colors.white : t.primario),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titulo != null)
                      Text(titulo!,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorTitulo)),
                    if (titulo != null && descripcion != null)
                      const SizedBox(height: 4),
                    if (descripcion != null)
                      Text(descripcion!,
                          style: TextStyle(
                              fontSize: 13.5, height: 1.45, color: colorDesc)),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: oscuro ? Colors.white54 : t.textoGris),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
