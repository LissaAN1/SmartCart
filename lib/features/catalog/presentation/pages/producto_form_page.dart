import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/catalog/presentation/widgets/campo_formulario.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/prices/presentation/widgets/historial_precios_card.dart';
import 'package:smartcart/features/prices/presentation/widgets/seccion_precio_producto.dart';

/// HU-10 + HU-11: "Editar Producto", como en el diseño. Crea un producto o
/// edita (y elimina) uno existente; en la misma pantalla se cambian la foto,
/// el precio y el stock, y se ven el historial de precios, la disponibilidad
/// y la promoción. Al guardar o eliminar se cierra devolviendo `true` para
/// que la lista del catálogo se recargue.
///
/// Necesita arriba en el árbol un `ProductoFormBloc` y, al editar, un
/// `PrecioProductoBloc` (los provee `AppRouter`).
class ProductoFormPage extends StatefulWidget {
  /// Producto que se edita; `null` al crear uno nuevo.
  final Producto? producto;

  /// Reloj de la pantalla; las pruebas lo fijan.
  final DateTime Function() ahora;

  const ProductoFormPage({
    super.key,
    this.producto,
    this.ahora = DateTime.now,
  });

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController =
      TextEditingController(text: widget.producto?.nombre);
  late final _marcaController =
      TextEditingController(text: widget.producto?.marca);
  late final _codigoController =
      TextEditingController(text: widget.producto?.codigoBarras);
  late final _stockController =
      TextEditingController(text: '${widget.producto?.stock ?? 0}');
  late final _precioController = TextEditingController(
    text: widget.producto?.precio == null
        ? ''
        : formatoMiles(widget.producto!.precio!),
  );
  late String? _idCategoria = widget.producto?.idCategoria;

  bool get _editando => widget.producto != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _codigoController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final textoPrecio = _precioController.text.trim();
    context.read<ProductoFormBloc>().add(
          ProductoFormGuardado(
            ProductoDatos(
              nombre: _nombreController.text,
              marca: _marcaController.text,
              codigoBarras: _codigoController.text,
              idCategoria: _idCategoria ?? '',
              stock: int.tryParse(_stockController.text.trim()) ?? 0,
            ),
            precio: textoPrecio.isEmpty
                ? null
                : PrecioValidators.leerPesos(textoPrecio),
          ),
        );
  }

  Future<void> _eliminar() async {
    final bloc = context.read<ProductoFormBloc>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar ${widget.producto!.nombre}?'),
        content: const Text(
          'Se quitará de tu catálogo con su historial de precios y no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: ColoresEstado.rojo),
            ),
          ),
        ],
      ),
    );
    if (confirmado == true) bloc.add(ProductoFormEliminado());
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return BlocConsumer<ProductoFormBloc, ProductoFormState>(
      listener: (context, state) {
        if (state.status == ProductoFormStatus.saved ||
            state.status == ProductoFormStatus.deleted) {
          Navigator.of(context).pop(true);
          return;
        }
        // Un error al elegir la foto no cambia el estado: se avisa aparte.
        final error = state.errorMessage;
        if (error != null && state.status == ProductoFormStatus.ready) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, state) {
        return PantallaRol(
          tema: t,
          barraSuperior: BarraTituloRol(
            titulo: _editando ? 'Editar Producto' : 'Nuevo Producto',
            mostrarAtras: true,
          ),
          cuerpo: _cuerpo(context, state),
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, ProductoFormState state) {
    switch (state.status) {
      case ProductoFormStatus.initial:
      case ProductoFormStatus.loadingCategorias:
        return const Center(child: CircularProgressIndicator());
      case ProductoFormStatus.categoriasFailed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorMessage(
                  message:
                      state.errorMessage ?? 'No pudimos cargar las categorías.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.read<ProductoFormBloc>().add(ProductoFormStarted()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      default:
        break;
    }

    // Este contexto está por encima de PantallaRol, así que el tema se toma
    // directo (con TemaRol.of saldría el tema por defecto, verde).
    final t = TemaRol.comercio;
    final ocupado = state.status == ProductoFormStatus.saving ||
        state.status == ProductoFormStatus.deleting;
    final error =
        state.status == ProductoFormStatus.saveFailed ? state.errorMessage : null;
    final comercio = state.comercio;
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Cabecera(
            producto: widget.producto,
            state: state,
            nombre: _nombreController,
            onCamara: ocupado
                ? null
                : () => context
                    .read<ProductoFormBloc>()
                    .add(ProductoFormFotoPedida()),
          ),
          if (_editando) ...[
            const SizedBox(height: 20),
            BlocBuilder<PrecioProductoBloc, PrecioProductoState>(
              builder: (context, precios) => switch (precios.status) {
                PrecioProductoStatus.ready => HistorialPreciosCard(
                    ficha: precios.ficha,
                    ahora: widget.ahora(),
                  ),
                PrecioProductoStatus.loadFailed => Column(
                    children: [
                      ErrorMessage(
                        message: precios.errorMessage ??
                            'No pudimos cargar el historial de precios.',
                      ),
                      TextButton(
                        onPressed: () => context
                            .read<PrecioProductoBloc>()
                            .add(PrecioProductoStarted()),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                _ => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              },
            ),
          ],
          const SizedBox(height: 24),
          CampoFormulario(
            key: const Key('campo-nombre'),
            controller: _nombreController,
            etiqueta: 'Nombre del producto',
            hint: 'Ej. Arroz Diana Premium 5 kg',
            icono: Icons.inventory_2_outlined,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: ProductoValidators.nombre,
            enabled: !ocupado,
          ),
          const SizedBox(height: 18),
          CampoFormulario(
            key: const Key('campo-precio'),
            controller: _precioController,
            etiqueta: 'Precio actual (COP)',
            hint: 'Ej. 4.900',
            icono: Icons.attach_money,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            // Opcional: un producto puede guardarse sin precio todavía.
            validator: (texto) => (texto ?? '').trim().isEmpty
                ? null
                : PrecioValidators.precio(texto),
            enabled: !ocupado,
            estilo: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.primario,
            ),
            sufijo: _editando ? const _VariacionPrecio() : null,
          ),
          const SizedBox(height: 18),
          CampoFormulario(
            key: const Key('campo-marca'),
            controller: _marcaController,
            etiqueta: 'Marca (opcional)',
            hint: 'Ej. Diana',
            icono: Icons.sell_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: ProductoValidators.marca,
            enabled: !ocupado,
          ),
          const SizedBox(height: 18),
          CampoFormulario(
            key: const Key('campo-codigo'),
            controller: _codigoController,
            etiqueta: 'Código de barras (opcional)',
            hint: '7701234567890',
            icono: Icons.qr_code_2,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: ProductoValidators.codigoBarras,
            enabled: !ocupado,
          ),
          const SizedBox(height: 18),
          CampoFormulario(
            key: const Key('campo-stock'),
            controller: _stockController,
            etiqueta: 'Stock (unidades)',
            hint: '0',
            icono: Icons.warehouse_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: ProductoValidators.stock,
            enabled: !ocupado,
          ),
          const SizedBox(height: 18),
          _SelectorCategoria(
            categorias: state.categorias,
            seleccionada: _idCategoria,
            enabled: !ocupado,
            onChanged: (id) => setState(() => _idCategoria = id),
          ),
          const SizedBox(height: 18),
          const EtiquetaCampo('Tienda / Sucursal'),
          const SizedBox(height: 8),
          _CampoSoloLectura(
            icono: Icons.storefront_outlined,
            texto: comercio == null
                ? '—'
                : '${comercio.nombre} · ${comercio.ciudad}',
          ),
          const SizedBox(height: 18),
          const _AvisoPrecio(),
          const SizedBox(height: 24),
          if (_editando)
            SeccionPrecioProducto(ahora: widget.ahora)
          else
            Text(
              'Después de guardar el producto podrás marcarlo como agotado y '
              'crearle promociones.',
              style: TextStyle(fontSize: 13, color: t.textoGris),
            ),
          const SizedBox(height: 24),
          if (error != null) ...[
            ErrorMessage(message: error),
            const SizedBox(height: 16),
          ],
          if (_editando) ...[
            OutlinedButton.icon(
              onPressed: ocupado ? null : _eliminar,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.texto,
                side: BorderSide(color: t.borde),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'Eliminar producto',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ESTA ACCIÓN NO SE PUEDE DESHACER Y BORRARÁ EL HISTORIAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: t.textoGris,
              ),
            ),
            const SizedBox(height: 24),
          ],
          BotonPrimario(
            texto: 'Guardar Cambios',
            cargando: state.status == ProductoFormStatus.saving,
            onTap: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

/// Foto (con el botón de cámara), nombre, código y tienda.
class _Cabecera extends StatelessWidget {
  final Producto? producto;
  final ProductoFormState state;
  final TextEditingController nombre;
  final VoidCallback? onCamara;

  const _Cabecera({
    required this.producto,
    required this.state,
    required this.nombre,
    required this.onCamara,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final foto = state.foto;
    final codigo = producto?.codigoBarras;
    final comercio = state.comercio;
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.superficie,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: t.borde, width: 2),
                ),
                child: foto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(foto.bytes, fit: BoxFit.cover),
                      )
                    : ImagenPlaceholder(
                        url: producto?.fotoUrl,
                        radio: 20,
                        icono: iconoDeCategoria(producto?.categoria ?? ''),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: t.primario,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Cambiar foto',
                    onPressed: onCamara,
                    icon: Icon(Icons.photo_camera_outlined,
                        color: t.superficie),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // El nombre de arriba sigue lo que se escribe en el campo.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: nombre,
          builder: (context, valor, _) => Text(
            valor.text.trim().isEmpty ? 'Producto sin nombre' : valor.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.texto,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            if (codigo != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.suave,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SKU: $codigo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.primario,
                  ),
                ),
              ),
            if (comercio != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 16, color: t.textoGris),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      comercio.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.textoGris),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// "↘ -5%": cambio del precio actual frente al anterior del historial.
class _VariacionPrecio extends StatelessWidget {
  const _VariacionPrecio();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return BlocBuilder<PrecioProductoBloc, PrecioProductoState>(
      builder: (context, state) {
        final v = state.ficha.variacionUltimoCambio();
        if (v == null || v == 0) return const SizedBox.shrink();
        final baja = v < 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              baja ? Icons.trending_down : Icons.trending_up,
              size: 16,
              color: t.texto,
            ),
            const SizedBox(width: 4),
            Text(
              '${baja ? '-' : '+'}${v.abs().round()}%',
              style: TextStyle(fontSize: 12, color: t.texto),
            ),
          ],
        );
      },
    );
  }
}

class _CampoSoloLectura extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _CampoSoloLectura({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: t.suave.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borde),
      ),
      child: Row(
        children: [
          Icon(icono, color: t.primario, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 15.5, color: t.textoGris),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso del diseño, con el texto que corresponde a la HU-11: el precio del
/// comercio se publica directo, con fuente "Comercio".
class _AvisoPrecio extends StatelessWidget {
  const _AvisoPrecio();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.suave.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: t.primario, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'El nuevo precio se publica de inmediato con la fuente '
              'Comercio y queda guardado en el historial.',
              style: TextStyle(fontSize: 13, height: 1.4, color: t.textoGris),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista desplegable de categorías. Si el producto editado trae una
/// categoría que ya no está en la lista, no se preselecciona.
class _SelectorCategoria extends StatelessWidget {
  final List<Categoria> categorias;
  final String? seleccionada;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _SelectorCategoria({
    required this.categorias,
    required this.seleccionada,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final valor = categorias.any((c) => c.id == seleccionada) ? seleccionada : null;
    OutlineInputBorder borde(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaCampo('Categoría'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          hint: const Text('Selecciona'),
          validator: ProductoValidators.categoria,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: t.superficie,
            prefixIcon: Icon(Icons.category_outlined, color: t.primario),
            border: borde(t.borde),
            enabledBorder: borde(t.borde),
          ),
          items: [
            for (final c in categorias)
              DropdownMenuItem(value: c.id, child: Text(c.nombre)),
          ],
        ),
      ],
    );
  }
}
