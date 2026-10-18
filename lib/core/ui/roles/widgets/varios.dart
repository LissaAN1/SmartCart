// lib/src/core/ui/roles/widgets/varios.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Ícono en círculo + etiqueta + valor. Ej: "Correo electrónico".
class FilaContacto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const FilaContacto({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
            child: Icon(icono, size: 22, color: t.primarioOscuro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: TextStyle(fontSize: 13.5, color: t.primario)),
                const SizedBox(height: 2),
                Text(valor,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: t.texto)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen de red con placeholder (ícono sobre fondo suave) mientras no
/// haya URL o si falla la carga.
class ImagenPlaceholder extends StatelessWidget {
  final String? url;
  final double? ancho;
  final double? alto;
  final double radio;
  final IconData icono;

  const ImagenPlaceholder({
    super.key,
    this.url,
    this.ancho,
    this.alto,
    this.radio = 12,
    this.icono = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final placeholder = Container(
      width: ancho,
      height: alto,
      color: t.suave,
      alignment: Alignment.center,
      child: Icon(icono, color: t.primario.withValues(alpha: 0.6), size: 28),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(
              url!,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Gráfico de barras simple sin dependencias (Lun..Dom).
class GraficoBarrasSemana extends StatelessWidget {
  final List<double> valores;
  final List<String> etiquetas;
  final double alto;
  final int divisiones; // líneas guía horizontales
  final Color? color;

  const GraficoBarrasSemana({
    super.key,
    required this.valores,
    this.etiquetas = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
    this.alto = 180,
    this.divisiones = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final double maxDato = valores.isEmpty
        ? 1.0
        : valores.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity).toDouble();
    // Redondea el tope del eje a un múltiplo de 20 por encima del máximo.
    final tope = ((maxDato / 20).ceil() * 20).toDouble();
    final estiloEje = TextStyle(fontSize: 11, color: t.textoGris);

    return SizedBox(
      height: alto + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eje Y
          SizedBox(
            width: 28,
            height: alto,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = divisiones; i >= 0; i--)
                  Text((tope / divisiones * i).round().toString(),
                      style: estiloEje),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: alto,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Líneas guía
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i <= divisiones; i++)
                            Divider(height: 1, color: t.borde),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final v in valores)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Container(
                                  height: alto * (v / tope),
                                  decoration: BoxDecoration(
                                    color: color ?? t.primarioOscuro,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final e in etiquetas.take(valores.length))
                      Expanded(
                        child: Text(e,
                            textAlign: TextAlign.center, style: estiloEje),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie de perfil: "SMARTCART COLOMBIA / Versión 2.4.1 (Build 402)".
class PieVersion extends StatelessWidget {
  final String marca;
  final String version;

  const PieVersion({
    super.key,
    this.marca = 'SMARTCART COLOMBIA',
    this.version = 'Versión 2.4.1 (Build 402)',
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      children: [
        Text(marca,
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: t.textoGris.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Text(version,
            style: TextStyle(
                fontSize: 11.5, color: t.textoGris.withValues(alpha: 0.7))),
      ],
    );
  }
}
