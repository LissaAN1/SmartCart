import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';

/// HU-10: formulario para crear un producto o editar (y eliminar) uno
/// existente. Al guardar o eliminar se cierra devolviendo `true` para que la
/// lista del catálogo se recargue.
///
/// Necesita un `ProductoFormBloc` arriba en el árbol (lo provee `AppRouter`).
class ProductoFormPage extends StatefulWidget {
  /// Producto que se edita; `null` al crear uno nuevo.
  final Producto? producto;

  const ProductoFormPage({super.key, this.producto});

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
  late String? _idCategoria = widget.producto?.idCategoria;

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ProductoFormBloc>().add(
          ProductoFormGuardado(
            ProductoDatos(
              nombre: _nombreController.text,
              marca: _marcaController.text,
              codigoBarras: _codigoController.text,
              idCategoria: _idCategoria ?? '',
            ),
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
          'Se quitará de tu catálogo y no se puede deshacer.',
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
    final editando = widget.producto != null;
    return BlocConsumer<ProductoFormBloc, ProductoFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProductoFormStatus.saved ||
            state.status == ProductoFormStatus.deleted) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return PantallaRol(
          tema: t,
          barraSuperior: BarraTituloRol(
            titulo: editando ? 'Editar producto' : 'Nuevo producto',
            mostrarAtras: true,
          ),
          cuerpo: _cuerpo(context, t, state, editando),
        );
      },
    );
  }

  Widget _cuerpo(
    BuildContext context,
    TemaRol t,
    ProductoFormState state,
    bool editando,
  ) {
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

    final ocupado = state.status == ProductoFormStatus.saving ||
        state.status == ProductoFormStatus.deleting;
    final error =
        state.status == ProductoFormStatus.saveFailed ? state.errorMessage : null;
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          AuthTextField(
            controller: _nombreController,
            label: 'Nombre del producto',
            hint: 'Ej. Arroz blanco 500 g',
            icon: Icons.inventory_2_outlined,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: ProductoValidators.nombre,
            enabled: !ocupado,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _marcaController,
            label: 'Marca (opcional)',
            hint: 'Ej. Diana',
            icon: Icons.sell_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: ProductoValidators.marca,
            enabled: !ocupado,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _codigoController,
            label: 'Código de barras (opcional)',
            hint: '7701234567890',
            icon: Icons.qr_code_2,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: ProductoValidators.codigoBarras,
            enabled: !ocupado,
          ),
          const SizedBox(height: 16),
          _SelectorCategoria(
            categorias: state.categorias,
            seleccionada: _idCategoria,
            enabled: !ocupado,
            onChanged: (id) => setState(() => _idCategoria = id),
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            ErrorMessage(message: error),
            const SizedBox(height: 16),
          ],
          BotonPrimario(
            texto: 'Guardar',
            cargando: state.status == ProductoFormStatus.saving,
            onTap: ocupado ? null : _guardar,
          ),
          if (editando) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: ocupado ? null : _eliminar,
              icon: const Icon(Icons.delete_outline, color: ColoresEstado.rojo),
              label: const Text(
                'Eliminar producto',
                style: TextStyle(color: ColoresEstado.rojo),
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: t.texto,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          hint: const Text('Selecciona'),
          validator: ProductoValidators.categoria,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category_outlined, color: t.textoGris),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.borde),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.borde),
            ),
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
