// lib/src/features/cliente/ui/widgets/cliente_widgets.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';

/// Pestañas de la barra inferior del cliente (mismo orden en todas sus
/// pantallas: 0 Inicio, 1 Carrito, 2 Ofertas, 3 Perfil, 4 Historial).
List<ItemNav> navCliente({int itemsCarrito = 0}) => [
      const ItemNav(Icons.home_outlined, 'Inicio', iconoActivo: Icons.home),
      ItemNav(Icons.shopping_cart_outlined, 'Carrito',
          iconoActivo: Icons.shopping_cart, badge: itemsCarrito),
      const ItemNav(Icons.sell_outlined, 'Ofertas', iconoActivo: Icons.sell),
      const ItemNav(Icons.person_outline, 'Perfil', iconoActivo: Icons.person),
      const ItemNav(Icons.history, 'Historial'),
    ];

/// Campo de búsqueda con la acción "Comparar" a la derecha.
class BuscadorComparar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onBuscar;
  final VoidCallback? onComparar;

  const BuscadorComparar({
    super.key,
    this.controller,
    this.hint = '¿Qué buscas hoy? (ej. Leche, Arroz)',
    this.onBuscar,
    this.onComparar,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borde),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: t.textoGris),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onBuscar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: t.textoGris, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(width: 1, height: 26, color: t.borde),
          TextButton(
            onPressed: onComparar,
            style: TextButton.styleFrom(foregroundColor: t.primario),
            child: const Text('Comparar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Ícono de categoría en cuadro redondeado + nombre debajo.
class CategoriaItem extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final bool seleccionada;
  final VoidCallback? onTap;

  const CategoriaItem({
    super.key,
    required this.icono,
    required this.nombre,
    this.seleccionada = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: seleccionada ? t.primario : t.superficie,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: seleccionada ? t.primario : t.borde, width: 1.5),
              ),
              child: Icon(icono,
                  size: 26, color: seleccionada ? Colors.white : t.texto),
            ),
            const SizedBox(height: 8),
            Text(nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        seleccionada ? FontWeight.w600 : FontWeight.w400,
                    color: seleccionada ? t.primario : t.texto)),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de producto en oferta (carrusel horizontal).
class OfertaCard extends StatelessWidget {
  final String tienda;
  final String nombre;
  final String precio;
  final String? precioAnterior;
  final String? etiqueta; // "-30%", "Top"
  final String? imagenUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAgregar;
  final double ancho;

  const OfertaCard({
    super.key,
    required this.tienda,
    required this.nombre,
    required this.precio,
    this.precioAnterior,
    this.etiqueta,
    this.imagenUrl,
    this.onTap,
    this.onAgregar,
    this.ancho = 172,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return SizedBox(
      width: ancho,
      child: TarjetaSuave(
        padding: const EdgeInsets.all(8),
        radio: 22,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImagenPlaceholder(
                  url: imagenUrl,
                  ancho: double.infinity,
                  alto: 140,
                  radio: 14,
                  icono: Icons.shopping_basket_outlined,
                ),
                if (etiqueta != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: EtiquetaEstado(
                      texto: etiqueta!,
                      color: const Color(0xFF8A3B12),
                      fondo: const Color(0xFFFDEBDD),
                      tamanoTexto: 11,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tienda.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                          color: t.textoGris)),
                  const SizedBox(height: 4),
                  Text(nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.texto)),
                  const SizedBox(height: 4),
                  Text(precio,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: t.primario)),
                  if (precioAnterior != null)
                    Text(precioAnterior!,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: t.textoGris,
                            decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(
                  backgroundColor: t.suave,
                  foregroundColor: t.primarioOscuro,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera horizontal del perfil del cliente: foto a la izquierda,
/// nombre, correo y etiquetas a la derecha.
class CabeceraPerfilCliente extends StatelessWidget {
  final String nombre;
  final String correo;
  final String? fotoUrl;
  final List<Widget> etiquetas;

  const CabeceraPerfilCliente({
    super.key,
    required this.nombre,
    required this.correo,
    this.fotoUrl,
    this.etiquetas = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      children: [
        AvatarPerfil(radio: 50, nombre: nombre, fotoUrl: fotoUrl, enLinea: true),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: t.texto)),
              const SizedBox(height: 2),
              Text(correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: t.textoGris)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: etiquetas),
            ],
          ),
        ),
      ],
    );
  }
}
