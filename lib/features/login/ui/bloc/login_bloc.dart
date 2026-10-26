import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/login/ui/bloc/login_event.dart';
import 'package:smartcart/features/login/ui/bloc/login_state.dart';

/// Convierte el formulario de inicio de sesión en una llamada a SignInUseCase.
/// Es el mismo Bloc para los cinco perfiles: el perfil viaja en el evento.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInUseCase _signIn;

  LoginBloc({SignInUseCase? signIn})
      : _signIn = signIn ?? SignInUseCase(),
        super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Un segundo toque mientras se procesa el primero no debe reenviar.
    if (state.status == LoginStatus.loading) return;
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final profile = await _signIn(
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(state.copyWith(status: LoginStatus.success, profile: profile));
    } on AuthFailure catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
