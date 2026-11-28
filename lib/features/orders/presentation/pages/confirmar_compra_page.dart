import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/orders/domain/compras_reglas.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';
import 'package:smartcart/features/orders/presentation/pages/compra_confirmada_page.dart';

/// HU-20: antes de confirmar, el cliente elige por cada comercio si recoge su
/// compra o se la llevan (y adónde). Al confirmar se genera una orden por
/// comercio registrado; los establecimientos sin registro quedan como lista
/// de compra.
///
/// Necesita un `ConfirmarCompraBloc` y el `CarritoBloc` del cliente arriba en
/// el árbol (los da `AppRouter`): el segundo se relee al terminar, porque la
/// compra vacía el carrito.
class ConfirmarCompraPage extends StatelessWidget {
  const ConfirmarCompraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfirmarCompraBloc, ConfirmarCompraState>(
      listenWhen: (previous, current) =>
          (current.aviso != null && current.aviso!.id != previous.aviso?.id) ||
          (current.status == ConfirmarCompraStatus.exito &&
              previous.status != ConfirmarCompraStatus.exito),
      listener: (context, state) {
        if (state.status == ConfirmarCompraStatus.exito) {
          context.read<CarritoBloc>().add(CarritoStarted());
        } else if (esPantallaActual(context)) {
          mostrarAviso(context, state.aviso!);
        }
      },
      builder: (context, state) {
        final comprobante = state.comprobante;
        if (state.status == ConfirmarCompraStatus.exito && comprobante != null) {
          return CompraConfirmadaPage(comprobante: comprobante);
        }
        return PantallaRol(
          tema: TemaRol.cliente,
          barraSuperior: const BarraTituloRol(
            titulo: 'Confirmar compra',
            mostrarAtras: true,
          ),
          cuerpo: switch (state.status) {
            ConfirmarCompraStatus.cargando => const Center(
                child: CircularProgressIndicator(),
              ),
            ConfirmarCompraStatus.falloCarga => _FalloCarga(
                mensaje: state.errorMessage,
                onReintentar: () => context
                    .read<ConfirmarCompraBloc>()
                    .add(ConfirmarCompraStarted()),
              ),
            _ => _Contenido(state: state),
          },
        );
      },
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
            ErrorMessage(
              message: mensaje ?? 'No pudimos preparar tu compra.',
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final ConfirmarCompraState state;

  const _Contenido({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final plan = state.plan!;
    final confirmando = state.status == ConfirmarCompraStatus.confirmando;
    final bloqueo = state.motivoBloqueo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final grupo in plan.registrados)
          _TarjetaComercio(
            grupo: grupo,
            eleccion: state.elecciones[grupo.idComercio] ??
                EleccionEntrega.recogida,
            habilitada: !confirmando,
          ),
        for (final grupo in plan.sinRegistro) _TarjetaSinRegistro(grupo: grupo),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.texto,
              ),
            ),
            const Spacer(),
            Text(
              formatoCop(plan.total),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BotonPrimario(
          texto: 'Confirmar compra',
          cargando: confirmando,
          onTap: state.puedeConfirmar
              ? () =>
                  context.read<ConfirmarCompraBloc>().add(CompraConfirmada())
              : null,
        ),
        if (bloqueo != null && !confirmando)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              bloqueo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textoGris),
            ),
          ),
      ],
    );
  }
}

/// Un comercio registrado: sus productos, recogida o entrega y la dirección.
class _TarjetaComercio extends StatelessWidget {
  final GrupoCompra grupo;
  final EleccionEntrega eleccion;
  final bool habilitada;

  const _TarjetaComercio({
    required this.grupo,
    required this.eleccion,
    required this.habilitada,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final id = grupo.idComercio!;
    final bloc = context.read<ConfirmarCompraBloc>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grupo.establecimiento,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 8),
            for (final linea in grupo.lineas) _FilaLinea(linea: linea),
            const Divider(height: 24),
            Text(
              '¿Cómo recibes esta compra?',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.textoGris,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: Text(TipoEntrega.recogida.label),
                  selected: eleccion.tipo == TipoEntrega.recogida,
                  onSelected: habilitada
                      ? (_) =>
                          bloc.add(EntregaElegida(id, TipoEntrega.recogida))
                      : null,
                ),
                // La entrega solo aparece disponible en comercios que la
                // ofrecen.
                if (grupo.ofreceEntrega)
                  ChoiceChip(
                    label: Text(TipoEntrega.entrega.label),
                    selected: eleccion.tipo == TipoEntrega.entrega,
                    onSelected: habilitada
                        ? (_) =>
                            bloc.add(EntregaElegida(id, TipoEntrega.entrega))
                        : null,
                  ),
              ],
            ),
            if (!grupo.ofreceEntrega)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Este comercio solo ofrece recogida en tienda.',
                  style: TextStyle(fontSize: 12.5, color: t.textoGris),
                ),
              ),
            if (eleccion.tipo == TipoEntrega.entrega)
              _CampoDireccion(
                // Una clave por comercio: al reconstruirse conserva el texto.
                key: ValueKey('direccion-$id'),
                inicial: eleccion.direccion ?? '',
                habilitado: habilitada,
                onChanged: (texto) => bloc.add(DireccionCambiada(id, texto)),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal ${formatoCop(grupo.subtotal)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.texto,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoDireccion extends StatefulWidget {
  final String inicial;
  final bool habilitado;
  final ValueChanged<String> onChanged;

  const _CampoDireccion({
    super.key,
    required this.inicial,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  State<_CampoDireccion> createState() => _CampoDireccionState();
}

class _CampoDireccionState extends State<_CampoDireccion> {
  late final _controller = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: _controller,
        enabled: widget.habilitado,
        onChanged: widget.onChanged,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 200,
        decoration: InputDecoration(
          labelText: 'Dirección de entrega',
          hintText: 'Calle, número, barrio',
          helperText:
              'Mínimo ${ComprasReglas.direccionMinima} caracteres.',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _FilaLinea extends StatelessWidget {
  final LineaCompra linea;

  const _FilaLinea({required this.linea});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${linea.cantidad} × ${linea.nombre}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: t.texto),
            ),
          ),
          const SizedBox(width: 8),
          if (linea.disponible)
            Text(
              formatoCop(linea.subtotal),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.texto,
              ),
            )
          else
            const Text(
              'No disponible',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColoresEstado.rojo,
              ),
            ),
        ],
      ),
    );
  }
}

/// Un establecimiento sin registro en SmartCart: no genera orden, el cliente
/// recibe su lista de compra.
class _TarjetaSinRegistro extends StatelessWidget {
  final GrupoCompra grupo;

  const _TarjetaSinRegistro({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grupo.establecimiento,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Este establecimiento no está registrado en SmartCart: no se '
              'genera orden, recibirás la lista para comprar allá.',
              style: TextStyle(fontSize: 13, color: t.textoGris),
            ),
            const SizedBox(height: 8),
            for (final linea in grupo.lineas) _FilaLinea(linea: linea),
          ],
        ),
      ),
    );
  }
}
