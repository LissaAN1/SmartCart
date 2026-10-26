// lib/src/core/ui/roles/widgets/menu.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Fila de menú: ícono en cuadro suave + título + subtítulo + chevron.
class ItemMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onTap;
  final Widget? trailing; // reemplaza el chevron (ej: Switch)
  final bool peligro; // "Cerrar sesión" en rojo

  const ItemMenu({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.onTap,
    this.trailing,
    this.peligro = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final colorIcono = peligro ? ColoresEstado.rojo : t.primario;
    final fondoIcono = peligro ? ColoresEstado.rojoSuave : t.suave;
    final colorTitulo = peligro ? ColoresEstado.rojo : t.texto;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fondoIcono,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 22, color: colorIcono),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: colorTitulo)),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: t.textoGris)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(Icons.chevron_right,
                    color: peligro
                        ? ColoresEstado.rojo.withValues(alpha: 0.5)
                        : t.textoGris),
          ],
        ),
      ),
    );
  }
}

/// Agrupa varios [ItemMenu] con divisores. Con [conTarjeta] los mete en
/// una tarjeta blanca (colaborador, admin); sin ella quedan sueltos
/// (perfil del cliente).
class GrupoMenu extends StatelessWidget {
  final List<Widget> items;
  final bool conTarjeta;

  const GrupoMenu({super.key, required this.items, this.conTarjeta = true});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final columna = Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: t.borde),
          items[i],
        ],
      ],
    );

    if (!conTarjeta) return columna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borde),
      ),
      child: columna,
    );
  }
}

/// Tarjeta con interruptor. Ej: "MODO COLABORADOR - Ayuda a otros...".
class TarjetaInterruptor extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final bool valor;
  final ValueChanged<bool>? onCambio;

  const TarjetaInterruptor({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    required this.valor,
    this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: t.superficie.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.borde, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: t.borde.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: Icon(icono, color: t.textoGris, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: t.texto)),
                if (subtitulo != null)
                  Text(subtitulo!,
                      style: TextStyle(fontSize: 13, color: t.textoGris)),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onCambio,
            activeTrackColor: t.primario,
          ),
        ],
      ),
    );
  }
}
