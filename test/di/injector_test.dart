import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/di/injector.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

void main() {
  tearDown(() => sl.reset());

  test('registra los repositorios con el tipo del contrato del dominio', () {
    setupDependencies();

    expect(sl.isRegistered<AuthRepository>(), isTrue);
    expect(sl.isRegistered<ProfileRepository>(), isTrue);
    expect(sl.isRegistered<ComercioRepository>(), isTrue);
    expect(sl.isRegistered<SignInUseCase>(), isTrue);
  });

  test('los Bloc se registran como fábrica: cada pantalla recibe uno nuevo', () {
    setupDependencies();

    expect(sl.isRegistered<LoginBloc>(), isTrue);
    expect(sl.isRegistered<RegisterBloc>(), isTrue);
    expect(sl.isRegistered<SessionBloc>(), isTrue);
    expect(sl.isRegistered<ColaboradorOnboardingBloc>(), isTrue);
    expect(sl.isRegistered<ComercioBloc>(), isTrue);
  });

  test('llamar dos veces a setupDependencies no duplica los registros', () {
    setupDependencies();

    expect(setupDependencies, returnsNormally);
  });
}
