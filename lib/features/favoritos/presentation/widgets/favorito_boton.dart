import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

/// El corazón de favoritos de un producto o de un comercio. Reutilizable: la
/// búsqueda (HU-12) y el detalle (HU-13) pueden ponerlo en sus pantallas con
/// solo indicar el [tipo] y el [id].
///
/// Necesita un `FavoritosBloc` arriba en el árbol.
class FavoritoBoton extends StatelessWidget {
  final TipoFavorito tipo;
  final String id;

  const FavoritoBoton({super.key, required this.tipo, required this.id});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return BlocSelector<FavoritosBloc, FavoritosState, bool>(
      selector: (state) => state.ids.contiene(tipo, id),
      builder: (context, esFavorito) => IconButton(
        tooltip: esFavorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
        icon: Icon(
          esFavorito ? Icons.favorite : Icons.favorite_border,
          color: esFavorito ? ColoresEstado.rojo : t.textoGris,
        ),
        onPressed: () =>
            context.read<FavoritosBloc>().add(FavoritoAlternado(tipo, id)),
      ),
    );
  }
}
