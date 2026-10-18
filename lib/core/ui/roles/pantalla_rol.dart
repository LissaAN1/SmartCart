// lib/src/core/ui/roles/pantalla_rol.dart
// Scaffold base de todas las pantallas por rol: aplica el tema, la barra
// superior y la barra de navegación inferior.
import 'package:flutter/material.dart';
import 'tema_rol.dart';
import 'widgets/avatar_perfil.dart';

class PantallaRol extends StatelessWidget {
  final TemaRol tema;
  final PreferredSizeWidget? barraSuperior;
  final Widget cuerpo;
  final List<ItemNav> navItems;
  final int tabActiva;
  final ValueChanged<int>? onTab;
  final Widget? fab;

  const PantallaRol({
    super.key,
    required this.tema,
    required this.cuerpo,
    this.barraSuperior,
    this.navItems = const [],
    this.tabActiva = 0,
    this.onTab,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return TemaRolScope(
      tema: tema,
      child: Scaffold(
        backgroundColor: tema.fondo,
        appBar: barraSuperior,
        body: SafeArea(top: barraSuperior == null, bottom: false, child: cuerpo),
        floatingActionButton: fab,
        bottomNavigationBar: navItems.isEmpty
            ? null
            : BarraNavRol(items: navItems, activa: tabActiva, onTab: onTab),
      ),
    );
  }
}

// ═════════════════════════ NAVEGACIÓN INFERIOR ═════════════════════════

class ItemNav {
  final IconData icono;
  final IconData? iconoActivo;
  final String etiqueta;
  final int badge; // 0 = sin badge
  const ItemNav(this.icono, this.etiqueta, {this.iconoActivo, this.badge = 0});
}

class BarraNavRol extends StatelessWidget {
  final List<ItemNav> items;
  final int activa;
  final ValueChanged<int>? onTab;

  const BarraNavRol({
    super.key,
    required this.items,
    required this.activa,
    this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.superficie,
        border: Border(top: BorderSide(color: t.borde)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _boton(t, i, items[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boton(TemaRol t, int i, ItemNav item) {
    final activo = i == activa;
    final color = activo ? t.primario : t.textoGris;
    return InkWell(
      onTap: onTab == null ? null : () => onTab!(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(activo ? (item.iconoActivo ?? item.icono) : item.icono,
                  color: color, size: 24),
              if (item.badge > 0)
                Positioned(
                  right: -7,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: ColoresEstado.rojo,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.superficie, width: 1.5),
                    ),
                    child: Text('${item.badge}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ BARRAS SUPERIORES ═════════════════════════

/// Título centrado con flecha atrás opcional y acciones a la derecha.
/// Ej: "Mi Perfil", "Panel del Mensajero", "Panel del comercio".
class BarraTituloRol extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final bool mostrarAtras;
  final VoidCallback? onAtras;
  final List<Widget> acciones;

  const BarraTituloRol({
    super.key,
    required this.titulo,
    this.mostrarAtras = false,
    this.onAtras,
    this.acciones = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return AppBar(
      backgroundColor: t.fondo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      leading: mostrarAtras
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: t.texto),
              onPressed: onAtras ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Text(titulo,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: t.texto)),
      actions: [...acciones, const SizedBox(width: 8)],
      shape: Border(bottom: BorderSide(color: t.borde, width: 1.5)),
    );
  }
}

/// Logo de la app + (sobretítulo, título) a la izquierda y un widget libre
/// a la derecha. Ej: "SMARTCART / Mi Perfil" o el header del admin.
class BarraMarca extends StatelessWidget implements PreferredSizeWidget {
  final IconData iconoLogo;
  final String? sobretitulo;
  final String? titulo;
  final Widget? trailing;

  const BarraMarca({
    super.key,
    this.iconoLogo = Icons.shopping_cart_outlined,
    this.sobretitulo,
    this.titulo,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return AppBar(
      backgroundColor: t.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      shape: Border(bottom: BorderSide(color: t.borde)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: t.primario,
            child: Icon(iconoLogo, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sobretitulo != null)
                Text(sobretitulo!,
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: t.textoGris)),
              if (titulo != null)
                Text(titulo!,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.texto)),
            ],
          ),
        ],
      ),
      actions: [if (trailing != null) trailing!, const SizedBox(width: 16)],
    );
  }
}

/// "¡Hola, Camila!" + ubicación + botones circulares (buscar, notificaciones).
class EncabezadoSaludo extends StatelessWidget implements PreferredSizeWidget {
  final String nombre;
  final String? ubicacion;
  final String? fotoUrl;
  final List<BotonCircular> acciones;

  const EncabezadoSaludo({
    super.key,
    required this.nombre,
    this.ubicacion,
    this.fotoUrl,
    this.acciones = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return AppBar(
      backgroundColor: t.fondo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      shape: Border(bottom: BorderSide(color: t.borde)),
      title: Row(
        children: [
          AvatarPerfil(radio: 24, fotoUrl: fotoUrl, nombre: nombre),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¡Hola, $nombre!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                if (ubicacion != null)
                  Row(children: [
                    Icon(Icons.place_outlined, size: 13, color: t.textoGris),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(ubicacion!,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12.5, color: t.textoGris)),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
      actions: [
        for (final a in acciones)
          Padding(padding: const EdgeInsets.only(left: 8), child: a),
        const SizedBox(width: 16),
      ],
    );
  }
}

/// Botón redondo con fondo suave y punto de notificación opcional.
class BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  final bool conPunto;
  final double tamano;

  const BotonCircular({
    super.key,
    required this.icono,
    this.onTap,
    this.conPunto = false,
    this.tamano = 42,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return InkResponse(
      onTap: onTap,
      radius: tamano / 2 + 4,
      child: Stack(
        children: [
          Container(
            width: tamano,
            height: tamano,
            decoration: BoxDecoration(
              color: t.primario.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 20, color: t.primarioOscuro),
          ),
          if (conPunto)
            Positioned(
              right: tamano * 0.24,
              top: tamano * 0.22,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: ColoresEstado.rojo, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
