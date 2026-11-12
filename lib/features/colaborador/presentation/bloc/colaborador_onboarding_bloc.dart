import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_event.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_state.dart';

/// Convierte las acciones del onboarding en una llamada a
/// ActivarModoColaboradorUseCase. La regla "sin aceptar las condiciones no se
/// activa" vive en el caso de uso; el Bloc solo muestra su mensaje.
class ColaboradorOnboardingBloc
    extends Bloc<ColaboradorOnboardingEvent, ColaboradorOnboardingState> {
  final ActivarModoColaboradorUseCase _activar;

  ColaboradorOnboardingBloc({required ActivarModoColaboradorUseCase activar})
      : _activar = activar,
        super(const ColaboradorOnboardingState()) {
    on<TermsToggled>(_onTermsToggled);
    on<ActivationSubmitted>(_onSubmitted);
  }

  void _onTermsToggled(
    TermsToggled event,
    Emitter<ColaboradorOnboardingState> emit,
  ) {
    if (state.status == ColaboradorOnboardingStatus.loading) return;
    emit(
      state.copyWith(
        status: ColaboradorOnboardingStatus.initial,
        termsAccepted: event.accepted,
      ),
    );
  }

  Future<void> _onSubmitted(
    ActivationSubmitted event,
    Emitter<ColaboradorOnboardingState> emit,
  ) async {
    // Un segundo toque mientras se procesa el primero no debe reenviar.
    if (state.status == ColaboradorOnboardingStatus.loading) return;
    emit(state.copyWith(status: ColaboradorOnboardingStatus.loading));
    try {
      final profile = await _activar(acceptedTerms: state.termsAccepted);
      emit(
        state.copyWith(
          status: ColaboradorOnboardingStatus.success,
          profile: profile,
        ),
      );
    } on AuthFailure catch (e) {
      emit(
        state.copyWith(
          status: ColaboradorOnboardingStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ColaboradorOnboardingStatus.failure,
          errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
