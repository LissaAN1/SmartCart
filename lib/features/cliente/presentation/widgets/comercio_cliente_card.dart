import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/presentation/widgets/favorito_boton.dart';

/// Una fila de comercio para el cliente: nombre, dirección y ciudad, con el
/// corazón de favoritos. La usan la exploración y los favoritos.
///
/// Necesita un `FavoritosBloc` arriba en el árbol.
class ComercioClienteCard extends StatelessWidget {
  final ComercioResumen comercio;

  const ComercioClienteCard({super.key, required this.comercio});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined, color: t.primarioOscuro),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comercio.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${comercio.direccion} · ${comercio.ciudad}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textoGris),
                  ),
                ],
              ),
            ),
            FavoritoBoton(tipo: TipoFavorito.comercio, id: comercio.id),
          ],
        ),
      ),
    );
  }
}
