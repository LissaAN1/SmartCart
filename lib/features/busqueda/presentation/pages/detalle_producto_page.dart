import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/widgets/resultado_card.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';

/// HU-12 · escenario 2: un producto con el precio de cada establecimiento,
/// del más barato al más caro. Se abre desde un resultado o escaneando el
/// código de barras.
///
/// Necesita un `DetalleProductoBloc` arriba en el árbol (lo provee
/// `AppRouter`).
class DetalleProductoPage extends StatelessWidget {
  const DetalleProductoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Precios del producto',
        mostrarAtras: true,
      ),
      cuerpo: BlocBuilder<DetalleProductoBloc, DetalleProductoState>(
        builder: (context, state) {
          final detalle = state.detalle;
          if (state.status == DetalleProductoStatus.failed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: t.textoGris),
                    const SizedBox(height: 12),
                    ErrorMessage(
                      message: state.errorMessage ??
                          'No pudimos cargar los precios.',
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context
                          .read<DetalleProductoBloc>()
                          .add(DetalleProductoStarted()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (detalle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Cabecera(detalle: detalle),
              const SizedBox(height: 22),
              const TituloSeccion(titulo: 'PRECIOS POR ESTABLECIMIENTO'),
              const SizedBox(height: 4),
              for (final (i, oferta) in detalle.ofertas.indexed)
                _OfertaTile(
                  oferta: oferta,
                  // El primero es el más barato de los disponibles.
                  mejorPrecio: i == 0 &&
                      oferta.disponible &&
                      detalle.disponibles.length > 1,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final DetalleProducto detalle;

  const _Cabecera({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final min = detalle.precioMin;
    final max = detalle.precioMax;
    final marca = detalle.marca;
    final codigo = detalle.codigoBarras;
    return TarjetaSuave(
      radio: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: ImagenPlaceholder(
              url: detalle.fotoUrl,
              radio: 16,
              icono: iconoDeCategoria(detalle.categoria),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.nombre,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: t.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  marca == null || marca.isEmpty
                      ? detalle.categoria
                      : '$marca · ${detalle.categoria}',
                  style: TextStyle(fontSize: 13, color: t.textoGris),
                ),
                if (codigo != null)
                  Text(
                    'Código $codigo',
                    style: TextStyle(fontSize: 12, color: t.textoGris),
                  ),
                const SizedBox(height: 10),
                if (min == null || max == null)
                  const EtiquetaEstado.error(
                      'Agotado en todos los establecimientos')
                else ...[
                  Text(
                    textoRango(min, max),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.primario,
                    ),
                  ),
                  Text(
                    textoEstablecimientos(detalle.disponibles.length),
                    style: TextStyle(fontSize: 12.5, color: t.textoGris),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfertaTile extends StatelessWidget {
  final OfertaProducto oferta;
  final bool mejorPrecio;

  const _OfertaTile({required this.oferta, required this.mejorPrecio});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final ubicacion = [
      if ((oferta.direccion ?? '').isNotEmpty) oferta.direccion!,
      if ((oferta.ciudad ?? '').isNotEmpty) oferta.ciudad!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Opacity(
        // Los agotados se ven, pero atenuados (HU-11, escenario 2).
        opacity: oferta.disponible ? 1 : 0.6,
        child: TarjetaSuave(
          radio: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_outlined, color: t.primario),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oferta.comercio,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.texto,
                          ),
                        ),
                        if (ubicacion.isNotEmpty)
                          Text(
                            ubicacion,
                            style:
                                TextStyle(fontSize: 12.5, color: t.textoGris),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatoCop(oferta.precio),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: t.primario,
                        ),
                      ),
                      if (oferta.enPromocion)
                        Text(
                          formatoCop(oferta.precioNormal),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: t.textoGris,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (mejorPrecio) const EtiquetaEstado.exito('Mejor precio'),
                  if (oferta.enPromocion) const EtiquetaEstado.info('Promoción'),
                  if (!oferta.disponible) const EtiquetaEstado.error('Agotado'),
                  Text(
                    'Actualizado ${fechaHora(oferta.actualizadoEn)} · '
                    'Fuente: ${oferta.fuente.etiqueta}',
                    style: TextStyle(fontSize: 11.5, color: t.textoGris),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
