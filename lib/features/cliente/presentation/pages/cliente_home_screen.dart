// lib/src/features/cliente/ui/screens/cliente_home_screen.dart
// Home del CLIENTE. Solo UI: los datos de ejemplo están en las listas
// privadas de abajo; reemplázalos por lo que venga de tu Bloc.
import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/cliente_widgets.dart';

class ClienteHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTab;
  final String nombre;

  /// HU-17: cuántos productos hay en el carrito (el número de la pestaña).
  final int itemsCarrito;

  /// HU-17: abre la exploración de productos y comercios. Sin él avisa
  /// "próximamente".
  final VoidCallback? onAbrirExplorar;

  /// HU-13: abre la búsqueda (HU-12) con el texto escrito. Lo da el
  /// `RolShell` para que la búsqueda lleve el carrito y los favoritos del
  /// cliente; sin él, la abre sin ellos.
  final ValueChanged<String>? onBuscar;

  /// HU-19: abre el mapa con la ubicación, el radio y los comercios
  /// cercanos. Sin él avisa "próximamente".
  final VoidCallback? onAbrirMapa;

  const ClienteHomeScreen({
    super.key,
    this.onTab,
    required this.nombre,
    this.itemsCarrito = 0,
    this.onAbrirExplorar,
    this.onBuscar,
    this.onAbrirMapa,
  });

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _categoria = 0;

  /// HU-12: abre la búsqueda, con el texto escrito si lo hay.
  void _buscar([String texto = '']) {
    final onBuscar = widget.onBuscar;
    if (onBuscar != null) {
      onBuscar(texto.trim());
      return;
    }
    Navigator.of(context)
        .pushNamed(AppRoutes.busqueda, arguments: texto.trim());
  }

  static const _categorias = [
    (Icons.shopping_cart_outlined, 'Super'),
    (Icons.auto_awesome_outlined, 'Frutas'),
    (Icons.sell_outlined, 'Lácteos'),
    (Icons.trending_up, 'Aseo'),
    (Icons.local_cafe_outlined, 'Café'),
    (Icons.bakery_dining_outlined, 'Panadería'),
  ];

  static const _ofertas = [
    (
      tienda: 'Éxito',
      nombre: 'Piña',
      precio: r'$ 12.900',
      antes: r'$ 18.500',
      tag: '-30%'
    ),
    (
      tienda: 'Carulla',
      nombre: 'Mix Frutas',
      precio: r'$ 8.400',
      antes: r'$ 10.200',
      tag: 'Top'
    ),
    (
      tienda: 'Olímpica',
      nombre: 'Leche entera 1L',
      precio: r'$ 4.250',
      antes: r'$ 5.000',
      tag: '-15%'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.cliente,
      navItems: navCliente(itemsCarrito: widget.itemsCarrito),
      tabActiva: 0,
      onTab: widget.onTab,
      barraSuperior: EncabezadoSaludo(
        nombre: widget.nombre,
        acciones: [
          BotonCircular(icono: Icons.search, onTap: _buscar),
          BotonCircular(
              icono: Icons.place_outlined,
              onTap: widget.onAbrirMapa ?? () => mostrarProximamente(context)),
          BotonCircular(
              icono: Icons.notifications_none,
              conPunto: true,
              onTap: () => mostrarProximamente(context)),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ══ BÚSQUEDA ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BuscadorComparar(
              onBuscar: _buscar,
              onComparar: () => _buscar(),
            ),
          ),

          // ══ CATEGORÍAS ══
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TituloSeccion(titulo: 'CATEGORÍAS'),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => CategoriaItem(
                icono: _categorias[i].$1,
                nombre: _categorias[i].$2,
                seleccionada: i == _categoria,
                onTap: () => setState(() => _categoria = i),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ══ BANNER ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BannerPromo(
              etiqueta: 'NUEVO',
              sobretitulo: 'Ahorro inteligente',
              titulo: 'Arma tu carrito y compáralo ahora',
              descripcion:
                  'Encuentra el mejor precio entre Carulla, Éxito y más.',
              textoBoton: 'Comenzar ahora',
              iconoGrande: Icons.shopping_cart_outlined,
              onBoton:
                  widget.onAbrirExplorar ?? () => mostrarProximamente(context),
            ),
          ),

          // ══ OFERTAS ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TituloSeccion(
              titulo: 'OFERTAS CERCA DE TI',
              accion: 'Ver todas  ›',
              onAccion: () => mostrarProximamente(context),
            ),
          ),
          SizedBox(
            height: 352,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ofertas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final o = _ofertas[i];
                return Align(
                  alignment: Alignment.topCenter,
                  child: OfertaCard(
                    tienda: o.tienda,
                    nombre: o.nombre,
                    precio: o.precio,
                    precioAnterior: o.antes,
                    etiqueta: o.tag,
                    onTap: () => mostrarProximamente(context),
                    onAgregar: () => mostrarProximamente(context),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
