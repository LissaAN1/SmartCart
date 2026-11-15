import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';

abstract class ProductoFormEvent {}

/// Al abrir el formulario: carga las categorías.
class ProductoFormStarted extends ProductoFormEvent {}

/// La persona presionó "Guardar".
class ProductoFormGuardado extends ProductoFormEvent {
  final ProductoDatos datos;

  ProductoFormGuardado(this.datos);
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
  final String? errorMessage;

  const ProductoFormState({
    this.status = ProductoFormStatus.initial,
    this.categorias = const [],
    this.errorMessage,
  });

  /// Las categorías se conservan entre estados; el error no se arrastra.
  ProductoFormState copyWith({
    ProductoFormStatus? status,
    List<Categoria>? categorias,
    String? errorMessage,
  }) {
    return ProductoFormState(
      status: status ?? this.status,
      categorias: categorias ?? this.categorias,
      errorMessage: errorMessage,
    );
  }
}

/// Formulario de un producto: sirve para crear (`editando == null`) y para
/// editar o eliminar uno existente. Al terminar deja el estado en `saved` o
/// `deleted` y la pantalla se cierra avisando que la lista debe recargarse.
class ProductoFormBloc extends Bloc<ProductoFormEvent, ProductoFormState> {
  final Producto? editando;
  final GetCategoriasUseCase _categorias;
  final CrearProductoUseCase _crear;
  final EditarProductoUseCase _editar;
  final EliminarProductoUseCase _eliminar;

  ProductoFormBloc({
    required this.editando,
    required GetCategoriasUseCase categorias,
    required CrearProductoUseCase crear,
    required EditarProductoUseCase editar,
    required EliminarProductoUseCase eliminar,
  })  : _categorias = categorias,
        _crear = crear,
        _editar = editar,
        _eliminar = eliminar,
        super(const ProductoFormState()) {
    on<ProductoFormStarted>(_onStarted);
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
      final categorias = await _categorias();
      emit(state.copyWith(
          status: ProductoFormStatus.ready, categorias: categorias));
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

  Future<void> _onGuardado(
    ProductoFormGuardado event,
    Emitter<ProductoFormState> emit,
  ) async {
    // Un segundo toque mientras se guarda el primero no debe reenviar.
    if (_ocupado) return;
    emit(state.copyWith(status: ProductoFormStatus.saving));
    try {
      final actual = editando;
      if (actual == null) {
        await _crear(event.datos);
      } else {
        await _editar(actual.id, event.datos);
      }
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
