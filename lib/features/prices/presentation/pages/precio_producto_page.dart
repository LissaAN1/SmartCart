import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';

/// HU-11: edición rápida del precio, la disponibilidad y la promoción de un
/// producto, con los últimos cambios del historial.
///
/// Necesita un `PrecioProductoBloc` arriba en el árbol (lo provee
/// `AppRouter`). Al volver, el catálogo recarga su lista.
class PrecioProductoPage extends StatefulWidget {
  /// Reloj de la pantalla; las pruebas lo fijan.
  final DateTime Function() ahora;

  const PrecioProductoPage({super.key, this.ahora = DateTime.now});

  @override
  State<PrecioProductoPage> createState() => _PrecioProductoPageState();
}

class _PrecioProductoPageState extends State<PrecioProductoPage> {
  final _precioKey = GlobalKey<FormState>();
  final _promoKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _promoController = TextEditingController();
  DateTime? _inicio;
  DateTime? _fin;
  String? _errorFechas;

  /// Los campos se llenan una sola vez, con lo que ya estaba guardado.
  bool _camposListos = false;

  @override
  void dispose() {
    _precioController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _llenarCampos(FichaPrecio ficha) {
    if (_camposListos) return;
    _camposListos = true;
    final precio = ficha.precio;
    if (precio != null) _precioController.text = formatoMiles(precio.precio);
    final promo = ficha.promocion;
    if (promo != null &&
        promo.estadoEn(widget.ahora()) != EstadoPromocion.vencida) {
      _promoController.text = formatoMiles(promo.precioPromocional);
      _inicio = promo.inicio;
      _fin = promo.fin;
    }
  }

  void _guardarPrecio() {
    if (!_precioKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context
        .read<PrecioProductoBloc>()
        .add(PrecioGuardado(PrecioValidators.leerPesos(_precioController.text)!));
  }

  Future<void> _elegirFechas() async {
    final hoy = soloFecha(widget.ahora());
    final inicio = _inicio;
    final fin = _fin;
    final rango = await showDateRangePicker(
      context: context,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      initialDateRange: inicio != null &&
              fin != null &&
              !inicio.isBefore(hoy)
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
    final t = TemaRol.comercio;
    return BlocConsumer<PrecioProductoBloc, PrecioProductoState>(
      listener: (context, state) {
        if (state.status == PrecioProductoStatus.ready) {
          _llenarCampos(state.ficha);
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
        return PantallaRol(
          tema: t,
          barraSuperior: const BarraTituloRol(
            titulo: 'Precio y disponibilidad',
            mostrarAtras: true,
          ),
          cuerpo: _cuerpo(context, state),
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, PrecioProductoState state) {
    switch (state.status) {
      case PrecioProductoStatus.initial:
      case PrecioProductoStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PrecioProductoStatus.loadFailed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorMessage(
                  message:
                      state.errorMessage ?? 'No pudimos cargar el precio.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context
                      .read<PrecioProductoBloc>()
                      .add(PrecioProductoStarted()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case PrecioProductoStatus.ready:
        break;
    }

    final bloc = context.read<PrecioProductoBloc>();
    final ficha = state.ficha;
    final precio = ficha.precio;
    final ocupado = state.ocupado;
    final ahora = widget.ahora();
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _Resumen(nombre: bloc.producto.nombre, ficha: ficha, ahora: ahora),
        const SizedBox(height: 20),
        Form(
          key: _precioKey,
          child: AuthTextField(
            key: const Key('campo-precio'),
            controller: _precioController,
            label: 'Precio normal (COP)',
            hint: 'Ej. 2.500',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: PrecioValidators.precio,
            enabled: !ocupado,
            onSubmitted: (_) => _guardarPrecio(),
          ),
        ),
        const SizedBox(height: 12),
        BotonPrimario(
          texto: 'Guardar precio',
          cargando: state.accion == AccionPrecio.guardandoPrecio,
          onTap: ocupado ? null : _guardarPrecio,
        ),
        const SizedBox(height: 20),
        TarjetaInterruptor(
          icono: Icons.inventory_outlined,
          titulo: precio == null || precio.disponible
              ? 'Disponible'
              : 'Agotado',
          subtitulo: precio == null
              ? 'Guarda el precio para marcar la disponibilidad'
              : precio.disponible
                  ? 'Los clientes lo ven disponible'
                  : 'Los clientes lo ven como no disponible',
          valor: precio?.disponible ?? true,
          onCambio: precio == null || ocupado
              ? null
              : (valor) => bloc.add(DisponibilidadCambiada(valor)),
        ),
        const SizedBox(height: 24),
        const TituloSeccion(titulo: 'Promoción', estilo: EstiloTitulo.grande),
        const SizedBox(height: 8),
        if (ficha.promocion != null) ...[
          _PromocionActual(promocion: ficha.promocion!, ahora: ahora),
          const SizedBox(height: 12),
        ],
        Form(
          key: _promoKey,
          child: AuthTextField(
            key: const Key('campo-promocion'),
            controller: _promoController,
            label: 'Precio promocional (COP)',
            hint: 'Menor que el precio normal',
            icon: Icons.local_offer_outlined,
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
        BotonPrimario(
          texto: 'Guardar promoción',
          cargando: state.accion == AccionPrecio.guardandoPromocion,
          onTap: ocupado ? null : _guardarPromocion,
        ),
        if (ficha.promocion != null)
          TextButton.icon(
            onPressed: ocupado ? null : _quitarPromocion,
            icon: const Icon(Icons.delete_outline, color: ColoresEstado.rojo),
            label: const Text(
              'Quitar promoción',
              style: TextStyle(color: ColoresEstado.rojo),
            ),
          ),
        const SizedBox(height: 24),
        const TituloSeccion(
          titulo: 'Últimos cambios',
          estilo: EstiloTitulo.grande,
        ),
        const SizedBox(height: 8),
        if (ficha.historial.isEmpty)
          Text(
            'Todavía no hay cambios de precio.',
            style: TextStyle(color: TemaRol.comercio.textoGris),
          )
        else
          for (final registro in ficha.historial)
            _FilaHistorial(registro: registro),
      ],
    );
  }
}

/// Precio que ve el cliente hoy, con la fecha y la fuente del último cambio.
class _Resumen extends StatelessWidget {
  final String nombre;
  final FichaPrecio ficha;
  final DateTime ahora;

  const _Resumen({
    required this.nombre,
    required this.ficha,
    required this.ahora,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final precio = ficha.precio;
    final mostrado = ficha.precioMostrado(ahora);
    final enPromocion = ficha.promocionVigente(ahora) != null;
    return TarjetaSuave(
      radio: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: t.texto,
            ),
          ),
          const SizedBox(height: 10),
          if (precio == null || mostrado == null)
            Text(
              'Aún no tiene precio. Escríbelo abajo y guárdalo.',
              style: TextStyle(color: t.textoGris),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formatoCop(mostrado),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: t.primarioOscuro,
                  ),
                ),
                if (enPromocion)
                  Text(
                    formatoCop(precio.precio),
                    style: TextStyle(
                      fontSize: 15,
                      color: t.textoGris,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (enPromocion) const EtiquetaEstado.exito('En promoción'),
                if (!precio.disponible) const EtiquetaEstado.error('Agotado'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Actualizado ${fechaHora(precio.actualizadoEn)} · '
              'Fuente: ${precio.fuente.etiqueta}',
              style: TextStyle(fontSize: 12.5, color: t.textoGris),
            ),
          ],
        ],
      ),
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

class _FilaHistorial extends StatelessWidget {
  final RegistroPrecio registro;

  const _FilaHistorial({required this.registro});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: t.textoGris),
          const SizedBox(width: 10),
          // Dos líneas para que quepa en pantallas angostas.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatoCop(registro.precio)}'
                  '${registro.disponible ? '' : ' · Agotado'}',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: t.texto),
                ),
                Text(
                  '${fechaHora(registro.registradoEn)} · '
                  '${registro.fuente.etiqueta}',
                  style: TextStyle(fontSize: 12, color: t.textoGris),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
