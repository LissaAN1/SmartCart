import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_foto_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_formulario_producto_usecase.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_producto_usecase.dart';

abstract class ProductoFormEvent {}

/// Al abrir el formulario: carga las categorías y el comercio.
class ProductoFormStarted extends ProductoFormEvent {}

/// HU-11: el botón de cámara. La foto se sube al guardar.
class ProductoFormFotoPedida extends ProductoFormEvent {}

/// La persona presionó "Guardar cambios". [precio] es `null` si dejó el
/// campo vacío; [disponible] es el interruptor Disponible/Agotado (HU-11).
class ProductoFormGuardado extends ProductoFormEvent {
  final ProductoDatos datos;
  final int? precio;
  final bool disponible;

  ProductoFormGuardado(this.datos, {this.precio, this.disponible = true});
}

/// La persona confirmó que quiere eliminar el producto que está editando.
class ProductoFormEliminado extends ProductoFormEvent {}

enum ProductoFormStatus {
  initial,
  loadingCategorias,
  categoriasFailed,
  ready,
  saving,
  saved,
  saveFailed,
  deleting,
  deleted,
}

class ProductoFormState {
  final ProductoFormStatus status;
  final List<Categoria> categorias;

  /// El comercio de la cuenta: su nombre se muestra como la tienda.
  final Comercio? comercio;

  /// Foto elegida que todavía no se ha subido.
  final ImagenProducto? foto;

  final String? errorMessage;

  const ProductoFormState({
    this.status = ProductoFormStatus.initial,
    this.categorias = const [],
    this.comercio,
    this.foto,
    this.errorMessage,
  });

  /// Las categorías, el comercio y la foto se conservan entre estados; el
  /// error no se arrastra.
  ProductoFormState copyWith({
    ProductoFormStatus? status,
    List<Categoria>? categorias,
    Comercio? comercio,
    ImagenProducto? foto,
    String? errorMessage,
  }) {
    return ProductoFormState(
      status: status ?? this.status,
      categorias: categorias ?? this.categorias,
      comercio: comercio ?? this.comercio,
      foto: foto ?? this.foto,
      errorMessage: errorMessage,
    );
  }
}

/// Formulario "Editar producto": sirve para crear (`editando == null`) y para
/// editar o eliminar uno existente. Desde la HU-11 también guarda la foto,
/// el stock y el precio en el mismo paso. Al terminar deja el estado en
/// `saved` o `deleted` y la pantalla se cierra avisando que la lista debe
/// recargarse.
class ProductoFormBloc extends Bloc<ProductoFormEvent, ProductoFormState> {
  final Producto? editando;
  final GetFormularioProductoUseCase _formulario;
  final GuardarProductoUseCase _guardar;
  final EliminarProductoUseCase _eliminar;
  final ElegirFotoProductoUseCase _elegirFoto;

  ProductoFormBloc({
    required this.editando,
    required GetFormularioProductoUseCase formulario,
    required GuardarProductoUseCase guardar,
    required EliminarProductoUseCase eliminar,
    required ElegirFotoProductoUseCase elegirFoto,
  })  : _formulario = formulario,
        _guardar = guardar,
        _eliminar = eliminar,
        _elegirFoto = elegirFoto,
        super(const ProductoFormState()) {
    on<ProductoFormStarted>(_onStarted);
    on<ProductoFormFotoPedida>(_onFoto);
    on<ProductoFormGuardado>(_onGuardado);
    on<ProductoFormEliminado>(_onEliminado);
  }

  bool get _ocupado =>
      state.status == ProductoFormStatus.saving ||
      state.status == ProductoFormStatus.deleting;

  Future<void> _onStarted(
    ProductoFormStarted event,
    Emitter<ProductoFormState> emit,
  ) async {
    emit(state.copyWith(status: ProductoFormStatus.loadingCategorias));
    try {
      final formulario = await _formulario();
      emit(state.copyWith(
        status: ProductoFormStatus.ready,
        categorias: formulario.categorias,
        comercio: formulario.comercio,
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ProductoFormStatus.categoriasFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ProductoFormStatus.categoriasFailed,
        errorMessage: _inesperado,
      ));
    }
  }

  /// Un error al elegir la foto no cambia el estado: solo deja el mensaje.
  Future<void> _onFoto(
    ProductoFormFotoPedida event,
    Emitter<ProductoFormState> emit,
  ) async {
    if (_ocupado) return;
    try {
      final foto = await _elegirFoto();
      if (foto != null) emit(state.copyWith(foto: foto));
    } on AuthFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: _inesperado));
    }
  }

  Future<void> _onGuardado(
    ProductoFormGuardado event,
    Emitter<ProductoFormState> emit,
  ) async {
    // Un segundo toque mientras se guarda el primero no debe reenviar.
    if (_ocupado) return;
    emit(state.copyWith(status: ProductoFormStatus.saving));
    try {
      await _guardar(
        editando: editando,
        datos: event.datos,
        precio: event.precio,
        disponible: event.disponible,
        foto: state.foto,
      );
      emit(state.copyWith(status: ProductoFormStatus.saved));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ProductoFormStatus.saveFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
          status: ProductoFormStatus.saveFailed, errorMessage: _inesperado));
    }
  }

  Future<void> _onEliminado(
    ProductoFormEliminado event,
    Emitter<ProductoFormState> emit,
  ) async {
    final actual = editando;
    if (actual == null || _ocupado) return;
    emit(state.copyWith(status: ProductoFormStatus.deleting));
    try {
      await _eliminar(actual.id);
      emit(state.copyWith(status: ProductoFormStatus.deleted));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ProductoFormStatus.saveFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
          status: ProductoFormStatus.saveFailed, errorMessage: _inesperado));
    }
  }

  static const _inesperado = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
