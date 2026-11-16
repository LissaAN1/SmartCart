import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/presentation/widgets/comercio_cliente_card.dart';
import 'package:smartcart/features/cliente/presentation/widgets/producto_cliente_card.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

/// Crean los Blocs de las dos listas paginadas. Los entrega el `AppRouter`
/// (con GetIt); la página no conoce de dónde vienen los datos.
typedef CrearFavoritosProductos = PaginatedBloc<ProductoConComercio> Function();
typedef CrearFavoritosComercios = PaginatedBloc<ComercioResumen> Function();

/// HU-17: los favoritos del cliente, en dos pestañas: productos y comercios.
/// Cada lista se carga por páginas. Quitar un corazón saca el elemento de la
/// lista.
///
/// Necesita un `FavoritosBloc` y un `CarritoBloc` arriba en el árbol (los da
/// `AppRouter`).
class FavoritosPage extends StatelessWidget {
  final CrearFavoritosProductos crearProductos;
  final CrearFavoritosComercios crearComercios;

  const FavoritosPage({
    super.key,
    required this.crearProductos,
    required this.crearComercios,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return MultiBlocListener(
      listeners: [
        BlocListener<FavoritosBloc, FavoritosState>(
          listenWhen: (p, c) =>
              c.aviso != null && c.aviso!.id != p.aviso?.id,
          listener: (context, state) {
            if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
          },
        ),
        BlocListener<CarritoBloc, CarritoState>(
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
          barraSuperior: const BarraTituloRol(
            titulo: 'Mis favoritos',
            mostrarAtras: true,
          ),
          cuerpo: Column(
            children: [
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
                      create: (_) => crearProductos()..add(PaginatedStarted()),
                      child: _RecargarAlCambiar<ProductoConComercio>(
                        cambio: (p, c) =>
                            !setEquals(p.ids.productos, c.ids.productos),
                        child: PaginatedListView<ProductoConComercio>(
                          emptyMessage: 'Aún no tienes productos favoritos. '
                              'Toca el corazón de un producto para guardarlo.',
                          itemBuilder: (context, p) =>
                              ProductoClienteCard(producto: p),
                        ),
                      ),
                    ),
                    BlocProvider<PaginatedBloc<ComercioResumen>>(
                      create: (_) => crearComercios()..add(PaginatedStarted()),
                      child: _RecargarAlCambiar<ComercioResumen>(
                        cambio: (p, c) =>
                            !setEquals(p.ids.comercios, c.ids.comercios),
                        child: PaginatedListView<ComercioResumen>(
                          emptyMessage: 'Aún no tienes comercios favoritos. '
                              'Toca el corazón de un comercio para guardarlo.',
                          itemBuilder: (context, c) =>
                              ComercioClienteCard(comercio: c),
                        ),
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

/// Vuelve a cargar la lista de la pestaña cuando cambian sus favoritos (por
/// ejemplo, al quitar un corazón), para que el elemento desaparezca.
class _RecargarAlCambiar<T> extends StatelessWidget {
  final bool Function(FavoritosState anterior, FavoritosState actual) cambio;
  final Widget child;

  const _RecargarAlCambiar({required this.cambio, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoritosBloc, FavoritosState>(
      listenWhen: cambio,
      listener: (context, _) =>
          context.read<PaginatedBloc<T>>().add(PaginatedStarted()),
      child: child,
    );
  }
}
