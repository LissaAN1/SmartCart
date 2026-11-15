import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';

/// HU-10: catálogo del comercio. Lista paginada de sus productos, con acceso
/// al formulario (crear y editar) y a la carga por archivo.
///
/// Necesita un `PaginatedBloc<Producto>` arriba en el árbol (lo provee
/// `AppRouter`). Si el comercio no está aprobado, la lista muestra el aviso
/// de espera que viene del caso de uso.
class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  /// Abre el formulario; si se guardó o eliminó algo, recarga la lista.
  Future<void> _abrirFormulario(BuildContext context, [Producto? producto]) {
    return _abrir(context, AppRoutes.catalogoProducto, producto);
  }

  Future<void> _abrirCsv(BuildContext context) {
    return _abrir(context, AppRoutes.catalogoCsv, null);
  }

  Future<void> _abrir(
    BuildContext context,
    String ruta,
    Object? argumentos,
  ) async {
    final bloc = context.read<PaginatedBloc<Producto>>();
    // Las rutas devuelven tipos distintos (el formulario un `bool`, el CSV
    // nada), por eso el resultado se pide como `Object?`.
    final cambio = await Navigator.of(context)
        .pushNamed<Object?>(ruta, arguments: argumentos);
    // Del CSV se puede volver con el gesto "atrás" sin devolver nada, así
    // que ahí siempre recargamos.
    if (cambio == true || ruta == AppRoutes.catalogoCsv) {
      bloc.add(PaginatedStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Mi catálogo',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Cargar por archivo',
            icon: Icon(Icons.upload_file, color: t.texto),
            onPressed: () => _abrirCsv(context),
          ),
        ],
      ),
      fab: FloatingActionButton(
        tooltip: 'Agregar producto',
        backgroundColor: t.primario,
        shape: const CircleBorder(),
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      cuerpo: PaginatedListView<Producto>(
        emptyMessage:
            'Aún no tienes productos. Toca + para agregar el primero.',
        // Espacio abajo para que el botón + no tape la última fila.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemBuilder: (context, producto) => ProductoCard(
          producto: producto,
          onTap: () => _abrirFormulario(context, producto),
        ),
      ),
    );
  }
}
