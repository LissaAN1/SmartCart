import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/orders/domain/compras_reglas.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/domain/usecases/compras_usecases.dart';

abstract class ConfirmarCompraEvent {}

/// Armar el plan de compra con el carrito (al abrir la pantalla y al
/// reintentar).
class ConfirmarCompraStarted extends ConfirmarCompraEvent {}

/// El cliente eligió recogida o entrega para un comercio.
class EntregaElegida extends ConfirmarCompraEvent {
  final String idComercio;
  final TipoEntrega tipo;

  EntregaElegida(this.idComercio, this.tipo);
}

/// El cliente escribió o cambió la dirección de entrega de un comercio.
class DireccionCambiada extends ConfirmarCompraEvent {
  final String idComercio;
  final String direccion;

  DireccionCambiada(this.idComercio, this.direccion);
}

/// El cliente presionó "Confirmar compra".
class CompraConfirmada extends ConfirmarCompraEvent {}

enum ConfirmarCompraStatus { cargando, listo, falloCarga, confirmando, exito }

class ConfirmarCompraState {
  final ConfirmarCompraStatus status;
  final PlanCompra? plan;

  /// Lo elegido por comercio (por id). Todos arrancan en recogida.
  final Map<String, EleccionEntrega> elecciones;

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
    this.errorMessage,
    this.aviso,
    this.comprobante,
  });

  /// Lo que falta para poder confirmar; `null` si ya se puede.
  String? get motivoBloqueo {
    final plan = this.plan;
    if (plan == null) return ComprasReglas.mensajeCarritoVacio;
    return ComprasReglas.validar(plan, elecciones);
  }

  bool get puedeConfirmar =>
      status == ConfirmarCompraStatus.listo && motivoBloqueo == null;

  ConfirmarCompraState copyWith({
    ConfirmarCompraStatus? status,
    PlanCompra? plan,
    Map<String, EleccionEntrega>? elecciones,
    String? errorMessage,
    AvisoUi? aviso,
    ComprobanteCompra? comprobante,
  }) {
    return ConfirmarCompraState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      elecciones: elecciones ?? this.elecciones,
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

  int _avisos = 0;

  ConfirmarCompraBloc({
    required GetPlanCompraUseCase obtenerPlan,
    required ConfirmarCompraUseCase confirmar,
  })  : _obtenerPlan = obtenerPlan,
        _confirmar = confirmar,
        super(const ConfirmarCompraState()) {
    on<ConfirmarCompraStarted>(_onStarted);
    on<EntregaElegida>(_onEntregaElegida);
    on<DireccionCambiada>(_onDireccionCambiada);
    on<CompraConfirmada>(_onConfirmada);
  }

  String _mensaje(Object e) => e is AuthFailure
      ? e.message
      : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  Future<void> _onStarted(
    ConfirmarCompraStarted event,
    Emitter<ConfirmarCompraState> emit,
  ) async {
    emit(const ConfirmarCompraState());
    try {
      final plan = await _obtenerPlan();
      emit(ConfirmarCompraState(
        status: ConfirmarCompraStatus.listo,
        plan: plan,
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
    final anterior = state.elecciones[event.idComercio];
    emit(state.copyWith(
      elecciones: {
        ...state.elecciones,
        event.idComercio: EleccionEntrega(
          tipo: event.tipo,
          // Al volver a elegir entrega se conserva lo que ya se había escrito.
          direccion: anterior?.direccion,
        ),
      },
    ));
  }

  void _onDireccionCambiada(
    DireccionCambiada event,
    Emitter<ConfirmarCompraState> emit,
  ) {
    if (state.status != ConfirmarCompraStatus.listo) return;
    final anterior =
        state.elecciones[event.idComercio] ?? EleccionEntrega.recogida;
    emit(state.copyWith(
      elecciones: {
        ...state.elecciones,
        event.idComercio: anterior.conDireccion(event.direccion),
      },
    ));
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
      final comprobante = await _confirmar(plan, state.elecciones);
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
