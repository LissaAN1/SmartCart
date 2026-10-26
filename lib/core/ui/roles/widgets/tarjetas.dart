// lib/src/core/ui/roles/widgets/tarjetas.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Contenedor blanco redondeado con borde suave. Base de casi todo.
class TarjetaSuave extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radio;
  final bool sombra;
  final VoidCallback? onTap;

  const TarjetaSuave({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radio = 18,
    this.sombra = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final borde = BorderRadius.circular(radio);
    return Container(
      decoration: BoxDecoration(
        color: color ?? t.superficie,
        borderRadius: borde,
        border: Border.all(color: t.borde),
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: t.primarioOscuro.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borde,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Número grande + etiqueta. Ej: "156 / VENTAS MES", "142 / ÓRDENES".
class TarjetaMetrica extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData? icono;
  final String? nota; // línea extra: "+12% vs ayer"
  final Color? color; // color del valor (por defecto primario del rol)
  final bool centrada;

  const TarjetaMetrica({
    super.key,
    required this.valor,
    required this.etiqueta,
    this.icono,
    this.nota,
    this.color,
    this.centrada = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final c = color ?? t.primario;
    final alineacion =
        centrada ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return TarjetaSuave(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: alineacion,
        children: [
          if (icono != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(icono, size: 18, color: c),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: Text(valor,
                textAlign: centrada ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: c)),
          ),
          const SizedBox(height: 4),
          Text(etiqueta.toUpperCase(),
              textAlign: centrada ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                  fontSize: 11.5, letterSpacing: 0.8, color: t.textoGris)),
          if (nota != null) ...[
            const SizedBox(height: 6),
            Text(nota!,
                textAlign: centrada ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ColoresEstado.verde)),
          ],
        ],
      ),
    );
  }
}

class Estadistica {
  final IconData icono;
  final String valor;
  final String etiqueta;
  const Estadistica(this.icono, this.valor, this.etiqueta);
}

/// Fila de estadísticas separadas por divisores verticales, con un pie
/// opcional (ej: "Saldo disponible $12.900" del repartidor).
class TarjetaEstadisticas extends StatelessWidget {
  final List<Estadistica> items;
  final Widget? pie;

  const TarjetaEstadisticas({super.key, required this.items, this.pie});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borde),
        boxShadow: [
          BoxShadow(
            color: t.primarioOscuro.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) VerticalDivider(width: 1, color: t.borde),
                  Expanded(child: _celda(t, items[i])),
                ],
              ],
            ),
          ),
          if (pie != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: t.suave,
                border: Border(top: BorderSide(color: t.borde)),
              ),
              child: pie,
            ),
        ],
      ),
    );
  }

  Widget _celda(TemaRol t, Estadistica e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(e.icono, size: 18, color: t.primario),
            ),
            const SizedBox(height: 8),
            Text(e.valor,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: t.texto)),
            const SizedBox(height: 2),
            Text(e.etiqueta.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10.5, letterSpacing: 0.8, color: t.textoGris)),
          ],
        ),
      );
}
