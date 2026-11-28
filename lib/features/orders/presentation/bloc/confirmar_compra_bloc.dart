import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/orders/domain/compras_reglas.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/domain/usecases/compras_usecases.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';

abstract class ConfirmarCompraEvent {}

/// Armar el plan de compra (al abrir la pantalla y al reintentar), con el
/// carrito o con la alternativa elegida en la comparación (HU-18).
class ConfirmarCompraStarted extends ConfirmarCompraEvent {
  final SeleccionCompra? seleccion;

  ConfirmarCompraStarted([this.seleccion]);
}

/// El cliente eligió recogida o entrega para un comercio.
class EntregaElegida extends ConfirmarCompraEvent {
  final String idComercio;
  final TipoEntrega tipo;

  EntregaElegida(this.idComercio, this.tipo);
}

/// Volver a leer la ubicación guardada (al volver del mapa de la HU-19).
class UbicacionRecargada extends ConfirmarCompraEvent {}

/// El cliente presionó "Confirmar compra".
class CompraConfirmada extends ConfirmarCompraEvent {}

enum ConfirmarCompraStatus { cargando, listo, falloCarga, confirmando, exito }

class ConfirmarCompraState {
  final ConfirmarCompraStatus status;
  final PlanCompra? plan;

  /// Lo elegido por comercio (por id). Todos arrancan en recogida.
  final Map<String, EleccionEntrega> elecciones;

  /// La ubicación guardada del cliente: el destino de las entregas.
  final PreferenciaUbicacion? ubicacion;

  /// Error de la carga ([ConfirmarCompraStatus.falloCarga]).
  final String? errorMessage;

  /// Error al confirmar u otro mensaje para mostrar en un `SnackBar`.
  final AvisoUi? aviso;

  /// Las órdenes generadas y las listas de compra ([ConfirmarCompraStatus.exito]).
  final ComprobanteCompra? comprobante;

  const ConfirmarCompraState({
    this.status = ConfirmarCompraStatus.cargando,
    this.plan,
    this.elecciones = const {},
    this.ubicacion,
    this.errorMessage,
    this.aviso,
    this.comprobante,
  });

  /// Lo que falta para poder confirmar; `null` si ya se puede.
  String? get motivoBloqueo {
    final plan = this.plan;
    if (plan == null) return ComprasReglas.mensajeCarritoVacio;
    return ComprasReglas.validar(
      plan,
      elecciones,
      tieneUbicacion: ubicacion != null,
    );
  }

  bool get puedeConfirmar =>
      status == ConfirmarCompraStatus.listo && motivoBloqueo == null;

  ConfirmarCompraState copyWith({
    ConfirmarCompraStatus? status,
    PlanCompra? plan,
    Map<String, EleccionEntrega>? elecciones,
    PreferenciaUbicacion? ubicacion,
    String? errorMessage,
    AvisoUi? aviso,
    ComprobanteCompra? comprobante,
  }) {
    return ConfirmarCompraState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      elecciones: elecciones ?? this.elecciones,
      ubicacion: ubicacion ?? this.ubicacion,
      errorMessage: errorMessage,
      aviso: aviso,
      comprobante: comprobante ?? this.comprobante,
    );
  }
}

/// HU-20: la pantalla donde el cliente elige recogida o entrega por comercio
/// y confirma la compra.
class ConfirmarCompraBloc
    extends Bloc<ConfirmarCompraEvent, ConfirmarCompraState> {
  final GetPlanCompraUseCase _obtenerPlan;
  final ConfirmarCompraUseCase _confirmar;
  final GetMiUbicacionUseCase _ubicacion;

  /// La alternativa elegida; `null` si se confirma el carrito.
  SeleccionCompra? _seleccion;

  int _avisos = 0;

  ConfirmarCompraBloc({
    required GetPlanCompraUseCase obtenerPlan,
    required ConfirmarCompraUseCase confirmar,
    required GetMiUbicacionUseCase ubicacion,
  })  : _obtenerPlan = obtenerPlan,
        _confirmar = confirmar,
        _ubicacion = ubicacion,
        super(const ConfirmarCompraState()) {
    on<ConfirmarCompraStarted>(_onStarted);
    on<EntregaElegida>(_onEntregaElegida);
    on<UbicacionRecargada>(_onUbicacionRecargada);
    on<CompraConfirmada>(_onConfirmada);
  }

  /// Si no se puede leer, seguimos sin ella: la recogida no la necesita y la
  /// entrega pide configurarla.
  Future<PreferenciaUbicacion?> _leerUbicacion() async {
    try {
      return await _ubicacion();
    } catch (_) {
      return null;
    }
  }

  String _mensaje(Object e) => e is AuthFailure
      ? e.message
      : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  Future<void> _onStarted(
    ConfirmarCompraStarted event,
    Emitter<ConfirmarCompraState> emit,
  ) async {
    _seleccion = event.seleccion ?? _seleccion;
    emit(const ConfirmarCompraState());
    try {
      final plan = await _obtenerPlan(_seleccion);
      emit(ConfirmarCompraState(
        status: ConfirmarCompraStatus.listo,
        plan: plan,
        ubicacion: await _leerUbicacion(),
        elecciones: {
          for (final g in plan.registrados)
            g.idComercio!: EleccionEntrega.recogida,
        },
      ));
    } catch (e) {
      emit(ConfirmarCompraState(
        status: ConfirmarCompraStatus.falloCarga,
        errorMessage: _mensaje(e),
      ));
    }
  }

  void _onEntregaElegida(
    EntregaElegida event,
    Emitter<ConfirmarCompraState> emit,
  ) {
    if (state.status != ConfirmarCompraStatus.listo) return;
    emit(state.copyWith(
      elecciones: {
        ...state.elecciones,
        event.idComercio: EleccionEntrega(tipo: event.tipo),
      },
    ));
  }

  Future<void> _onUbicacionRecargada(
    UbicacionRecargada event,
    Emitter<ConfirmarCompraState> emit,
  ) async {
    final ubicacion = await _leerUbicacion();
    if (ubicacion != null) emit(state.copyWith(ubicacion: ubicacion));
  }

  Future<void> _onConfirmada(
    CompraConfirmada event,
    Emitter<ConfirmarCompraState> emit,
  ) async {
    final plan = state.plan;
    // Un segundo toque mientras se confirma no genera otra compra.
    if (plan == null || state.status != ConfirmarCompraStatus.listo) return;
    emit(state.copyWith(status: ConfirmarCompraStatus.confirmando));
    try {
      final comprobante = await _confirmar(
        plan,
        state.elecciones,
        quitarDelCarrito: _seleccion?.productosDelCarrito,
      );
      emit(state.copyWith(
        status: ConfirmarCompraStatus.exito,
        comprobante: comprobante,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ConfirmarCompraStatus.listo,
        aviso: AvisoUi(id: ++_avisos, texto: _mensaje(e), esError: true),
      ));
    }
  }
}
