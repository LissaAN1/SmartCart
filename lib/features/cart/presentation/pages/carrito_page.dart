import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/domain/carrito_reglas.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/comparacion/domain/valor_carrito.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';

/// HU-17: el carrito del cliente. Muestra cuántos productos hay, deja cambiar
/// la cantidad de cada uno y quitarlos. El carrito está guardado en la base:
/// al volver a abrir la app sigue ahí.
///
/// HU-18: muestra el precio vigente de cada producto, su subtotal y el total,
/// y abre la comparación del carrito.
///
/// Necesita un `CarritoBloc`, un `FavoritosBloc` y un `PreciosCarritoBloc`
/// arriba en el árbol (los da `AppRouter`; el segundo, para poder abrir la
/// exploración desde aquí).
class CarritoPage extends StatelessWidget {
  const CarritoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Mi carrito',
        mostrarAtras: true,
      ),
      cuerpo: BlocConsumer<CarritoBloc, CarritoState>(
        listenWhen: (previous, current) =>
            (current.aviso != null &&
                current.aviso!.id != previous.aviso?.id) ||
            _productosCambiaron(previous, current),
        listener: (context, state) {
          final aviso = state.aviso;
          if (aviso != null && esPantallaActual(context)) {
            mostrarAviso(context, aviso);
          }
          // Un producto nuevo no tiene precio cargado: lo pedimos. Cambiar la
          // cantidad no hace falta, el subtotal se calcula con la que se ve.
          final precios = context.read<PreciosCarritoBloc>();
          if (precios.state.status != PreciosCarritoStatus.cargando &&
              state.items.any(
                  (i) => !precios.state.precios.containsKey(i.idProducto))) {
            precios.add(PreciosCarritoSolicitados());
          }
        },
        builder: (context, state) {
          if (state.vacio) {
            return switch (state.status) {
              CarritoStatus.initial ||
              CarritoStatus.cargando =>
                const Center(child: CircularProgressIndicator()),
              CarritoStatus.falloCarga => _FalloCarga(
                  mensaje: state.errorMessage,
                  onReintentar: () =>
                      context.read<CarritoBloc>().add(CarritoStarted()),
                ),
              CarritoStatus.listo => const _CarritoVacio(),
            };
          }
          return _Lista(state: state);
        },
      ),
    );
  }
}

bool _productosCambiaron(CarritoState antes, CarritoState ahora) {
  final a = antes.items.map((i) => i.idProducto).toSet();
  final b = ahora.items.map((i) => i.idProducto).toSet();
  return a.length != b.length || !a.containsAll(b);
}

class _FalloCarga extends StatelessWidget {
  final String? mensaje;
  final VoidCallback onReintentar;

  const _FalloCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorMessage(message: mensaje ?? 'No pudimos cargar tu carrito.'),
            const SizedBox(height: 8),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: t.textoGris),
            const SizedBox(height: 14),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega productos para preparar tu compra.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textoGris),
            ),
            const SizedBox(height: 20),
            BotonPrimario(
              texto: 'Explorar productos',
              expandido: false,
              onTap: () => context.abrirExplorar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final CarritoState state;

  const _Lista({required this.state});

  String get _resumen {
    final p = state.productos;
    final u = state.unidades;
    final productos = p == 1 ? '1 producto' : '$p productos';
    final unidades = u == 1 ? '1 unidad' : '$u unidades';
    return '$productos · $unidades';
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final precios = context.watch<PreciosCarritoBloc>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            _resumen,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textoGris,
            ),
          ),
        ),
        for (final item in state.items)
          _LineaCarrito(
            item: item,
            precio: precios.precios[item.idProducto],
            cargando: precios.status == PreciosCarritoStatus.cargando ||
                precios.status == PreciosCarritoStatus.initial,
          ),
        _Total(state: state, precios: precios),
        const SizedBox(height: 12),
        BotonSuave(
          texto: 'Agregar más productos',
          icono: Icons.add,
          onTap: () => context.abrirExplorar(),
        ),
      ],
    );
  }
}

/// Una línea del carrito: el producto, su comercio y los controles de
/// cantidad. Con 1 unidad no se puede bajar más (se usa "Quitar") y a las 99
/// no se puede subir.
class _LineaCarrito extends StatelessWidget {
  final ItemCarrito item;

  /// HU-18: el precio vigente del producto; `null` mientras carga.
  final PrecioLinea? precio;
  final bool cargando;

  const _LineaCarrito({
    required this.item,
    this.precio,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final p = item.producto;
    final bloc = context.read<CarritoBloc>();
    final marca = p.producto.marca;
    final detalle = marca == null || marca.isEmpty
        ? p.producto.categoria
        : '$marca · ${p.producto.categoria}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: t.texto,
              ),
            ),
            if (detalle.isNotEmpty)
              Text(
                detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: t.textoGris),
              ),
            Text(
              'Vende ${p.comercio}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: t.textoGris),
            ),
            if (precio != null || !cargando)
              _PrecioDeLinea(precio: precio, cantidad: item.cantidad),
            Row(
              children: [
                IconButton(
                  tooltip: 'Disminuir cantidad',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: item.cantidad <= CarritoReglas.cantidadMin
                      ? null
                      : () => bloc.add(CarritoCantidadCambiada(
                          item.idProducto, item.cantidad - 1)),
                ),
                Semantics(
                  label: 'Cantidad',
                  child: Text(
                    '${item.cantidad}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Aumentar cantidad',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: item.cantidad >= CarritoReglas.cantidadMax
                      ? null
                      : () => bloc.add(CarritoCantidadCambiada(
                          item.idProducto, item.cantidad + 1)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Quitar del carrito',
                  icon: const Icon(Icons.delete_outline,
                      color: ColoresEstado.rojo),
                  onPressed: () =>
                      bloc.add(CarritoProductoQuitado(item.idProducto)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// HU-18: "$ 4.900 c/u" con el subtotal de la línea, o por qué no se suma.
class _PrecioDeLinea extends StatelessWidget {
  final PrecioLinea? precio;
  final int cantidad;

  const _PrecioDeLinea({required this.precio, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final p = precio;
    final subtotal = p?.subtotal(cantidad);
    if (p == null || subtotal == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          p?.agotado == true
              ? 'Agotado en este comercio'
              : 'Sin precio publicado',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColoresEstado.ambar),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${formatoCop(p.precio!)} c/u${p.enPromocion ? ' · Promoción' : ''}',
              style: TextStyle(fontSize: 13.5, color: t.textoGris),
            ),
          ),
          Text(
            formatoCop(subtotal),
            style: TextStyle(
                fontSize: 15.5, fontWeight: FontWeight.w800, color: t.texto),
          ),
        ],
      ),
    );
  }
}

/// HU-18: el total del carrito con las cantidades que se ven y el botón para
/// compararlo.
class _Total extends StatelessWidget {
  final CarritoState state;
  final PreciosCarritoState precios;

  const _Total({required this.state, required this.precios});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final valor = ValorCarrito.de(state.items, precios.precios);
    final cargando = precios.status == PreciosCarritoStatus.cargando ||
        precios.status == PreciosCarritoStatus.initial;
    return TarjetaSuave(
      radio: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total estimado',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.texto),
                ),
              ),
              if (cargando && precios.precios.isEmpty)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text(
                  formatoCop(valor.total),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.primarioOscuro),
                ),
            ],
          ),
          if (precios.status == PreciosCarritoStatus.fallidos)
            TextButton(
              onPressed: () => context
                  .read<PreciosCarritoBloc>()
                  .add(PreciosCarritoSolicitados()),
              child: Text(
                  '${precios.errorMessage ?? 'No pudimos cargar los precios.'} Reintentar'),
            )
          else if (!cargando && valor.sinPrecio > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                valor.sinPrecio == 1
                    ? '1 producto sin precio no se suma.'
                    : '${valor.sinPrecio} productos sin precio no se suman.',
                style: TextStyle(fontSize: 12.5, color: t.textoGris),
              ),
            ),
          const SizedBox(height: 12),
          BotonPrimario(
            texto: 'Comparar carrito',
            iconoFinal: Icons.compare_arrows,
            onTap: () => context.abrirComparacion(),
          ),
        ],
      ),
    );
  }
}
