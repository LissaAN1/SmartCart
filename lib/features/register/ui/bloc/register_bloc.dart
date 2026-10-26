import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/register/ui/bloc/register_event.dart';
import 'package:smartcart/features/register/ui/bloc/register_state.dart';

/// Convierte el formulario de registro en una llamada a SignUpUseCase.
/// El Bloc no sabe que registrar son varios pasos: espera un Profile.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SignUpUseCase _signUp;

  RegisterBloc({SignUpUseCase? signUp})
      : _signUp = signUp ?? SignUpUseCase(),
        super(const RegisterState()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // Un segundo toque mientras se procesa el primero no debe reenviar.
    if (state.status == RegisterStatus.loading) return;
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      final profile = await _signUp(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
      );
      emit(state.copyWith(status: RegisterStatus.success, profile: profile));
    } on AuthFailure catch (e) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
