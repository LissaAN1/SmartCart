import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/catalog/presentation/widgets/encabezado_inventario.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';

/// HU-10 + HU-11: catálogo del comercio. Buscador, chips de categorías,
/// resumen del inventario y la lista paginada de productos con su precio,
/// stock y si está ACTIVO o INACTIVO. Tocar un producto abre Editar Producto,
/// donde se cambia todo (también la disponibilidad); el botón + crea uno y el
/// de la barra abre la carga por archivo.
///
/// Necesita arriba en el árbol un `PaginatedBloc<Producto>` (un
/// `CatalogoListaBloc`) y un `InventarioBloc` (los provee `AppRouter`). Si el
/// comercio no está aprobado, la lista muestra el aviso de espera que viene
/// del caso de uso.
class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  /// Espera tras la última tecla antes de buscar, para no consultar la base
  /// con cada letra.
  static const _pausaBusqueda = Duration(milliseconds: 350);

  final _buscador = TextEditingController();
  Timer? _espera;
  String? _idCategoria;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  FiltroCatalogo get _filtro =>
      FiltroCatalogo(texto: _buscador.text, idCategoria: _idCategoria);

  void _aplicarFiltro() {
    if (!mounted) return;
    // Redibuja para que el mensaje de lista vacía corresponda al filtro.
    setState(() {});
    context.read<PaginatedBloc<Producto>>().add(FiltroCatalogoCambiado(_filtro));
  }

  void _alBuscar(String _) {
    _espera?.cancel();
    _espera = Timer(_pausaBusqueda, _aplicarFiltro);
  }

  void _alElegirCategoria(String? idCategoria) {
    if (idCategoria == _idCategoria) return;
    _idCategoria = idCategoria;
    _aplicarFiltro();
  }

  /// Recarga la lista (con el filtro vigente) y el resumen.
  void _recargar() {
    context.read<PaginatedBloc<Producto>>().add(PaginatedStarted());
    context.read<InventarioBloc>().add(InventarioStarted());
  }

  Future<void> _abrirFormulario([Producto? producto]) =>
      _abrir(AppRoutes.catalogoProducto, producto);

  Future<void> _abrirCsv() => _abrir(AppRoutes.catalogoCsv, null);

  Future<void> _abrir(String ruta, Object? argumentos) async {
    // Las rutas devuelven tipos distintos (el formulario un `bool`, el CSV
    // nada), por eso el resultado se pide como `Object?`.
    final cambio = await Navigator.of(context)
        .pushNamed<Object?>(ruta, arguments: argumentos);
    // Del CSV se puede volver con el gesto "atrás" sin devolver nada, así
    // que ahí siempre recargamos.
    if (!mounted) return;
    if (cambio == true || ruta == AppRoutes.catalogoCsv) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Catálogo',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Cargar por archivo',
            icon: Icon(Icons.upload_file, color: t.texto),
            onPressed: _abrirCsv,
          ),
        ],
      ),
      fab: FloatingActionButton(
        tooltip: 'Agregar producto',
        backgroundColor: t.primario,
        shape: const CircleBorder(),
        onPressed: _abrirFormulario,
        child: Icon(Icons.add, color: t.superficie, size: 30),
      ),
      cuerpo: BlocBuilder<InventarioBloc, InventarioState>(
        builder: (context, inventario) {
          return PaginatedListView<Producto>(
            emptyMessage: _filtro.vacio
                ? 'Aún no tienes productos. Toca + para agregar el primero.'
                : 'No encontramos productos con ese filtro.',
            // Espacio abajo para que el botón + no tape la última fila.
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            encabezado: EncabezadoInventario(
              buscador: _buscador,
              onBuscar: _alBuscar,
              categorias: inventario.encabezado?.categorias ?? const [],
              idCategoria: _idCategoria,
              onCategoria: _alElegirCategoria,
              resumen: inventario.encabezado?.resumen,
            ),
            itemBuilder: (context, producto) => ProductoCard(
              producto: producto,
              onTap: () => _abrirFormulario(producto),
            ),
          );
        },
      ),
    );
  }
}
