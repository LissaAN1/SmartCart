import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/cliente/presentation/widgets/comercio_cliente_card.dart';
import 'package:smartcart/features/cliente/presentation/widgets/producto_cliente_card.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

/// Crean los Blocs de las listas paginadas para un texto de búsqueda. Los
/// entrega el `AppRouter` (con GetIt).
typedef CrearExplorarProductos = PaginatedBloc<ProductoConComercio> Function(
  String texto,
);
typedef CrearExplorarComercios = PaginatedBloc<ComercioResumen> Function(
  String texto,
);

/// HU-17: la lista mínima con la que el cliente encuentra productos y
/// comercios para agregarlos al carrito o a favoritos. Dos pestañas, con un
/// buscador por nombre; las listas se cargan por páginas.
///
/// Es provisional: cuando existan la búsqueda (HU-12) y el detalle (HU-13)
/// pondrán los mismos botones (`AgregarCarritoBoton` y `FavoritoBoton`) en sus
/// pantallas.
///
/// Necesita un `CarritoBloc` y un `FavoritosBloc` arriba en el árbol (los da
/// `AppRouter`).
class ExplorarPage extends StatefulWidget {
  final CrearExplorarProductos crearProductos;
  final CrearExplorarComercios crearComercios;

  const ExplorarPage({
    super.key,
    required this.crearProductos,
    required this.crearComercios,
  });

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  /// Tiempo que esperamos después de la última tecla para buscar, así no
  /// pedimos una página por cada letra.
  static const _pausa = Duration(milliseconds: 400);

  final _texto = TextEditingController();
  Timer? _temporizador;
  String _busqueda = '';

  @override
  void dispose() {
    _temporizador?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _alEscribir(String valor) {
    _temporizador?.cancel();
    _temporizador = Timer(_pausa, () {
      if (mounted) setState(() => _busqueda = valor.trim());
    });
  }

  void _limpiar() {
    _temporizador?.cancel();
    _texto.clear();
    setState(() => _busqueda = '');
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return MultiBlocListener(
      listeners: [
        BlocListener<CarritoBloc, CarritoState>(
          listenWhen: (p, c) =>
              c.aviso != null && c.aviso!.id != p.aviso?.id,
          listener: (context, state) {
            if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
          },
        ),
        BlocListener<FavoritosBloc, FavoritosState>(
          listenWhen: (p, c) =>
              c.aviso != null && c.aviso!.id != p.aviso?.id,
          listener: (context, state) {
            if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
          },
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: PantallaRol(
          tema: t,
          barraSuperior: BarraTituloRol(
            titulo: 'Explorar',
            mostrarAtras: true,
            acciones: [
              IconButton(
                tooltip: 'Mis favoritos',
                icon: Icon(Icons.favorite_border, color: t.texto),
                onPressed: () => context.abrirFavoritos(),
              ),
              BlocBuilder<CarritoBloc, CarritoState>(
                buildWhen: (p, c) => p.productos != c.productos,
                builder: (context, state) => IconButton(
                  tooltip: 'Ver carrito',
                  icon: Badge(
                    isLabelVisible: state.productos > 0,
                    label: Text('${state.productos}'),
                    child: Icon(Icons.shopping_cart_outlined, color: t.texto),
                  ),
                  onPressed: () => context.abrirCarrito(),
                ),
              ),
            ],
          ),
          cuerpo: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _texto,
                  onChanged: _alEscribir,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Busca por nombre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _texto.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Quitar búsqueda',
                            icon: const Icon(Icons.close),
                            onPressed: _limpiar,
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: t.borde),
                    ),
                  ),
                ),
              ),
              TabBar(
                labelColor: t.primarioOscuro,
                unselectedLabelColor: t.textoGris,
                indicatorColor: t.primario,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
                  Tab(icon: Icon(Icons.storefront_outlined), text: 'Comercios'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    BlocProvider<PaginatedBloc<ProductoConComercio>>(
                      // Otra búsqueda, otra lista.
                      key: ValueKey('productos:$_busqueda'),
                      create: (_) => widget.crearProductos(_busqueda)
                        ..add(PaginatedStarted()),
                      child: PaginatedListView<ProductoConComercio>(
                        emptyMessage: _busqueda.isEmpty
                            ? 'Todavía no hay productos para mostrar.'
                            : 'No encontramos productos con "$_busqueda".',
                        itemBuilder: (context, p) =>
                            ProductoClienteCard(producto: p),
                      ),
                    ),
                    BlocProvider<PaginatedBloc<ComercioResumen>>(
                      key: ValueKey('comercios:$_busqueda'),
                      create: (_) => widget.crearComercios(_busqueda)
                        ..add(PaginatedStarted()),
                      child: PaginatedListView<ComercioResumen>(
                        emptyMessage: _busqueda.isEmpty
                            ? 'Todavía no hay comercios para mostrar.'
                            : 'No encontramos comercios con "$_busqueda".',
                        itemBuilder: (context, c) =>
                            ComercioClienteCard(comercio: c),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
