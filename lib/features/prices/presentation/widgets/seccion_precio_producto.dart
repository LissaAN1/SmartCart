import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/catalog/presentation/widgets/campo_formulario.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';

/// HU-11: promoción de un producto ya guardado, dentro de Editar Producto.
/// Necesita un `PrecioProductoBloc` arriba en el árbol. La disponibilidad se
/// marca en el formulario y se guarda con "Guardar Cambios".
class SeccionPrecioProducto extends StatefulWidget {
  final DateTime Function() ahora;

  const SeccionPrecioProducto({super.key, required this.ahora});

  @override
  State<SeccionPrecioProducto> createState() => _SeccionPrecioProductoState();
}

class _SeccionPrecioProductoState extends State<SeccionPrecioProducto> {
  final _promoKey = GlobalKey<FormState>();
  final _promoController = TextEditingController();
  DateTime? _inicio;
  DateTime? _fin;
  String? _errorFechas;

  /// Los campos se llenan una sola vez, con lo que ya estaba guardado.
  bool _camposListos = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _llenarCampos(Promocion? promo) {
    if (_camposListos) return;
    _camposListos = true;
    // Una promoción vencida no se ofrece para editar: se crea otra.
    if (promo != null &&
        promo.estadoEn(widget.ahora()) != EstadoPromocion.vencida) {
      _promoController.text = formatoMiles(promo.precioPromocional);
      _inicio = promo.inicio;
      _fin = promo.fin;
    }
  }

  Future<void> _elegirFechas() async {
    final hoy = soloFecha(widget.ahora());
    final inicio = _inicio;
    final fin = _fin;
    final rango = await showDateRangePicker(
      context: context,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      initialDateRange:
          inicio != null && fin != null && !inicio.isBefore(hoy)
              ? DateTimeRange(start: inicio, end: fin)
              : null,
      helpText: 'Fechas de la promoción',
      saveText: 'Listo',
    );
    if (rango == null) return;
    setState(() {
      _inicio = rango.start;
      _fin = rango.end;
      _errorFechas = null;
    });
  }

  void _guardarPromocion() {
    final errorFechas = PrecioValidators.fechas(_inicio, _fin, widget.ahora());
    final camposOk = _promoKey.currentState!.validate();
    setState(() => _errorFechas = errorFechas);
    if (!camposOk || errorFechas != null) return;
    FocusScope.of(context).unfocus();
    context.read<PrecioProductoBloc>().add(PromocionGuardada(PromocionDatos(
          precioPromocional:
              PrecioValidators.leerPesos(_promoController.text)!,
          inicio: _inicio!,
          fin: _fin!,
        )));
  }

  void _quitarPromocion() {
    _promoController.clear();
    setState(() {
      _inicio = null;
      _fin = null;
      _errorFechas = null;
    });
    context.read<PrecioProductoBloc>().add(PromocionQuitada());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrecioProductoBloc, PrecioProductoState>(
      listener: (context, state) {
        if (state.status == PrecioProductoStatus.ready) {
          _llenarCampos(state.ficha.promocion);
        }
        final mensaje = state.status == PrecioProductoStatus.ready
            ? state.errorMessage ?? state.aviso
            : null;
        if (mensaje != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(mensaje)));
        }
      },
      builder: (context, state) {
        if (state.status != PrecioProductoStatus.ready) {
          return const SizedBox.shrink();
        }
        final precio = state.ficha.precio;
        final promocion = state.ficha.promocion;
        final ocupado = state.ocupado;
        final ahora = widget.ahora();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EtiquetaCampo('PROMOCIÓN'),
            const SizedBox(height: 8),
            if (promocion != null) ...[
              _PromocionActual(promocion: promocion, ahora: ahora),
              const SizedBox(height: 12),
            ],
            Form(
              key: _promoKey,
              child: CampoFormulario(
                key: const Key('campo-promocion'),
                controller: _promoController,
                etiqueta: 'Precio promocional (COP)',
                hint: 'Menor que el precio normal',
                icono: Icons.local_offer_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (texto) =>
                    PrecioValidators.precioPromocional(texto, precio?.precio),
                enabled: !ocupado,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('boton-fechas'),
              onPressed: ocupado ? null : _elegirFechas,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _inicio == null || _fin == null
                    ? 'Elegir fechas de inicio y fin'
                    : '${fechaCorta(_inicio!)} – ${fechaCorta(_fin!)}',
              ),
            ),
            if (_errorFechas != null) ...[
              const SizedBox(height: 8),
              ErrorMessage(message: _errorFechas!),
            ],
            const SizedBox(height: 12),
            BotonSuave(
              texto: 'Guardar promoción',
              icono: Icons.local_offer_outlined,
              onTap: ocupado ? null : _guardarPromocion,
            ),
            if (promocion != null)
              TextButton.icon(
                onPressed: ocupado ? null : _quitarPromocion,
                icon: const Icon(Icons.delete_outline,
                    color: ColoresEstado.rojo),
                label: const Text(
                  'Quitar promoción',
                  style: TextStyle(color: ColoresEstado.rojo),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PromocionActual extends StatelessWidget {
  final Promocion promocion;
  final DateTime ahora;

  const _PromocionActual({required this.promocion, required this.ahora});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final etiqueta = switch (promocion.estadoEn(ahora)) {
      EstadoPromocion.vigente => const EtiquetaEstado.exito('Vigente'),
      EstadoPromocion.programada => const EtiquetaEstado.info('Programada'),
      EstadoPromocion.vencida => const EtiquetaEstado.pendiente('Vencida'),
    };
    return TarjetaSuave(
      radio: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatoCop(promocion.precioPromocional),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Del ${fechaCorta(promocion.inicio)} al '
                  '${fechaCorta(promocion.fin)}',
                  style: TextStyle(fontSize: 12.5, color: t.textoGris),
                ),
              ],
            ),
          ),
          etiqueta,
        ],
      ),
    );
  }
}
