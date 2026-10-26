// lib/src/features/cliente/ui/screens/cliente_home_screen.dart
// Home del CLIENTE. Solo UI: los datos de ejemplo están en las listas
// privadas de abajo; reemplázalos por lo que venga de tu Bloc.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/cliente_widgets.dart';

class ClienteHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTab;
  const ClienteHomeScreen({super.key, this.onTab});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _categoria = 0;

  static const _categorias = [
    (Icons.shopping_cart_outlined, 'Super'),
    (Icons.auto_awesome_outlined, 'Frutas'),
    (Icons.sell_outlined, 'Lácteos'),
    (Icons.trending_up, 'Aseo'),
    (Icons.local_cafe_outlined, 'Café'),
    (Icons.bakery_dining_outlined, 'Panadería'),
  ];

  static const _ofertas = [
    (tienda: 'Éxito', nombre: 'Piña', precio: r'$ 12.900', antes: r'$ 18.500', tag: '-30%'),
    (tienda: 'Carulla', nombre: 'Mix Frutas', precio: r'$ 8.400', antes: r'$ 10.200', tag: 'Top'),
    (tienda: 'Olímpica', nombre: 'Leche entera 1L', precio: r'$ 4.250', antes: r'$ 5.000', tag: '-15%'),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.cliente,
      navItems: navCliente(itemsCarrito: 3),
      tabActiva: 0,
      onTab: widget.onTab,
      barraSuperior: EncabezadoSaludo(
        nombre: 'Camila',
        ubicacion: 'Bogotá, Colombia',
        acciones: [
          BotonCircular(icono: Icons.search, onTap: () {}),
          BotonCircular(
              icono: Icons.notifications_none, conPunto: true, onTap: () {}),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ══ BÚSQUEDA ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BuscadorComparar(onComparar: () {}),
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
              descripcion: 'Encuentra el mejor precio entre Carulla, Éxito y más.',
              textoBoton: 'Comenzar ahora',
              iconoGrande: Icons.shopping_cart_outlined,
              onBoton: () {},
            ),
          ),

          // ══ OFERTAS ══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TituloSeccion(
              titulo: 'OFERTAS CERCA DE TI',
              accion: 'Ver todas  ›',
              onAccion: () {},
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
                    onTap: () {},
                    onAgregar: () {},
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
