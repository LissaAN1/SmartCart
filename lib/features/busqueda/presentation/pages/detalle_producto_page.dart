import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/widgets/resultado_card.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cart/presentation/widgets/agregar_carrito_boton.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/confianza/domain/confianza_reglas.dart';
import 'package:smartcart/features/confianza/presentation/widgets/confianza_del_precio.dart';
import 'package:smartcart/features/confianza/presentation/widgets/motivo_reporte_sheet.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';
import 'package:smartcart/features/favoritos/presentation/widgets/favorito_boton.dart';

/// HU-12 · escenario 2: un producto con el precio de cada establecimiento,
/// del más barato al más caro. Se abre desde un resultado o escaneando el
/// código de barras.
///
/// HU-13: cada precio muestra su fuente, su fecha, su nivel de confianza y si
/// está desactualizado, y se puede reportar como incorrecto. Si la pantalla
/// recibió el carrito y los favoritos del cliente (HU-17), cada
/// establecimiento tiene también sus botones de agregar y guardar.
///
/// Necesita un `DetalleProductoBloc` arriba en el árbol (lo provee
/// `AppRouter`). [reloj] da la fecha de "hoy" con la que se calcula la
/// confianza; se cambia solo en las pruebas.
class DetalleProductoPage extends StatelessWidget {
  final DateTime Function()? reloj;

  const DetalleProductoPage({super.key, this.reloj});

  @override
  Widget build(BuildContext context) {
    final cliente = clienteBlocsOrNull(context);
    final pagina = BlocListener<DetalleProductoBloc, DetalleProductoState>(
      listenWhen: (p, c) => c.aviso != null && c.aviso!.id != p.aviso?.id,
      listener: (context, state) {
        if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
      },
      child: _Contenido(reloj: reloj ?? DateTime.now, conCliente: cliente != null),
    );
    if (cliente == null) return pagina;
    // Los avisos de "Agregado al carrito" y de favoritos los muestra esta
    // pantalla mientras es la de arriba.
    return MultiBlocListener(
      listeners: [
        BlocListener<CarritoBloc, CarritoState>(
          listenWhen: (p, c) => c.aviso != null && c.aviso!.id != p.aviso?.id,
          listener: (context, state) {
            if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
          },
        ),
        BlocListener<FavoritosBloc, FavoritosState>(
          listenWhen: (p, c) => c.aviso != null && c.aviso!.id != p.aviso?.id,
          listener: (context, state) {
            if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
          },
        ),
      ],
      child: pagina,
    );
  }
}

class _Contenido extends StatelessWidget {
  final DateTime Function() reloj;
  final bool conCliente;

  const _Contenido({required this.reloj, required this.conCliente});

  /// Pregunta el motivo y, si el cliente envía, manda el reporte al Bloc.
  Future<void> _reportar(BuildContext context, OfertaProducto oferta) async {
    final bloc = context.read<DetalleProductoBloc>();
    final motivo = await pedirMotivoDeReporte(
      context,
      comercio: oferta.comercio,
      precio: formatoCop(oferta.precio),
    );
    if (motivo == null) return;
    bloc.add(PrecioIncorrectoReportado(oferta.idProducto, motivo: motivo.motivo));
  }

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
          final ahora = reloj();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Cabecera(detalle: detalle),
              const SizedBox(height: 12),
              const _NotaConfianza(),
              const SizedBox(height: 18),
              const TituloSeccion(titulo: 'PRECIOS POR ESTABLECIMIENTO'),
              const SizedBox(height: 4),
              for (final (i, oferta) in detalle.ofertas.indexed)
                _OfertaTile(
                  oferta: oferta,
                  ahora: ahora,
                  conCliente: conCliente,
                  // El primero es el más barato de los disponibles.
                  mejorPrecio: i == 0 &&
                      oferta.disponible &&
                      detalle.disponibles.length > 1,
                  reportando: state.reportando.contains(oferta.idProducto),
                  reportado: state.reportados.contains(oferta.idProducto),
                  onReportar: () => _reportar(context, oferta),
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

/// Explica en una línea cómo se mide la confianza (HU-13), con el límite de
/// días que fijamos.
class _NotaConfianza extends StatelessWidget {
  const _NotaConfianza();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: t.textoGris),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'La confianza depende de quién publicó el precio y de qué tan '
            'reciente es. Si tiene más de ${ConfianzaReglas.diasLimite} días, '
            'lo marcamos como desactualizado.',
            style: TextStyle(fontSize: 12.5, color: t.textoGris),
          ),
        ),
      ],
    );
  }
}

class _OfertaTile extends StatelessWidget {
  final OfertaProducto oferta;
  final DateTime ahora;
  final bool mejorPrecio;
  final bool conCliente;
  final bool reportando;
  final bool reportado;
  final VoidCallback onReportar;

  const _OfertaTile({
    required this.oferta,
    required this.ahora,
    required this.mejorPrecio,
    required this.conCliente,
    required this.reportando,
    required this.reportado,
    required this.onReportar,
  });

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
                ],
              ),
              const SizedBox(height: 8),
              // HU-13: fuente, fecha, confianza y el reporte del precio.
              ConfianzaDelPrecio(
                fuente: oferta.fuente,
                actualizadoEn: oferta.actualizadoEn,
                ahora: ahora,
                onReportar: onReportar,
                reportado: reportado,
                enviando: reportando,
              ),
              // HU-17: agregar al carrito y guardar en favoritos desde el
              // detalle, si esta pantalla los recibió.
              if (conCliente)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FavoritoBoton(
                        tipo: TipoFavorito.producto,
                        id: oferta.idProducto,
                      ),
                      if (oferta.disponible)
                        AgregarCarritoBoton(idProducto: oferta.idProducto),
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
