import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';
import 'package:smartcart/features/session/ui/bloc/session_state.dart';

/// Recupera la sesión que Supabase guarda en el dispositivo y la cierra.
/// La selección de perfil lo usa para saltarse el login si ya hay sesión, y
/// el Home para cerrar sesión.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final GetMyProfileUseCase _getMyProfile;
  final SignOutUseCase _signOut;

  SessionBloc({GetMyProfileUseCase? getMyProfile, SignOutUseCase? signOut})
      : _getMyProfile = getMyProfile ?? GetMyProfileUseCase(),
        _signOut = signOut ?? SignOutUseCase(),
        super(const SessionState()) {
    on<SessionStarted>(_onStarted);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.loading));
    try {
      final profile = await _getMyProfile();
      if (profile == null) {
        emit(state.copyWith(status: SessionStatus.unauthenticated));
      } else {
        emit(
          state.copyWith(
            status: SessionStatus.authenticated,
            profile: profile,
          ),
        );
      }
    } catch (_) {
      // Sin red o sin perfil no podemos confiar en la sesión guardada: la
      // pantalla sigue en la selección de perfil y la persona entra por login.
      emit(state.copyWith(status: SessionStatus.unauthenticated));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await _signOut();
      emit(const SessionState(status: SessionStatus.unauthenticated));
    } catch (_) {
      emit(
        state.copyWith(
          status: SessionStatus.failure,
          errorMessage: 'No pudimos cerrar la sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
