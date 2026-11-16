import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/domain/carrito_reglas.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';

/// HU-17: el carrito del cliente. Muestra cuántos productos hay, deja cambiar
/// la cantidad de cada uno y quitarlos. El carrito está guardado en la base:
/// al volver a abrir la app sigue ahí.
///
/// Necesita un `CarritoBloc` y un `FavoritosBloc` arriba en el árbol (los da
/// `AppRouter`; el segundo, para poder abrir la exploración desde aquí).
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
            current.aviso != null && current.aviso!.id != previous.aviso?.id,
        listener: (context, state) {
          if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
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
        for (final item in state.items) _LineaCarrito(item: item),
        const SizedBox(height: 4),
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

  const _LineaCarrito({required this.item});

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
