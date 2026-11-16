import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';

/// "$ 4.200" o "$ 4.200 – $ 5.000".
String textoRango(int min, int max) =>
    min == max ? formatoCop(min) : '${formatoCop(min)} – ${formatoCop(max)}';

/// "En 1 establecimiento", "En 3 establecimientos".
String textoEstablecimientos(int n) =>
    n == 1 ? 'En 1 establecimiento' : 'En $n establecimientos';

/// HU-12: un resultado de la búsqueda con el rango de precios y en cuántos
/// establecimientos está.
class ResultadoCard extends StatelessWidget {
  final ResultadoBusqueda resultado;
  final VoidCallback? onTap;

  const ResultadoCard({super.key, required this.resultado, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final marca = resultado.marca;
    final min = resultado.precioMin;
    final max = resultado.precioMax;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ImagenPlaceholder(
                url: resultado.fotoUrl,
                radio: 14,
                icono: iconoDeCategoria(resultado.categoria),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    marca == null || marca.isEmpty
                        ? resultado.categoria
                        : '$marca · ${resultado.categoria}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: t.textoGris),
                  ),
                  const SizedBox(height: 8),
                  if (min == null || max == null)
                    const EtiquetaEstado.error('Agotado')
                  else ...[
                    Text(
                      textoRango(min, max),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.primario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 15, color: t.textoGris),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            textoEstablecimientos(resultado.establecimientos),
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12.5, color: t.textoGris),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textoGris),
          ],
        ),
      ),
    );
  }
}
