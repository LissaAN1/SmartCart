import 'dart:async';

import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

/// Repositorio de autenticación en memoria para las pruebas.
class FakeAuthRepository implements AuthRepository {
  AppUser? current;
  Object? signInError;
  Object? signUpError;

  /// Si se asigna, signIn/signUp esperan a que se complete (simula la red).
  Completer<void>? gate;

  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    signUpCalls++;
    await gate?.future;
    if (signUpError != null) throw signUpError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    signInCalls++;
    await gate?.future;
    if (signInError != null) throw signInError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    current = null;
  }

  @override
  AppUser? currentUser() => current;
}

/// Repositorio de perfiles en memoria para las pruebas.
class FakeProfileRepository implements ProfileRepository {
  Profile? stored;
  Object? createError;
  Object? getError;
  final created = <Profile>[];
  final collaboratorIds = <String>[];

  @override
  Future<void> createProfile(Profile profile) async {
    if (createError != null) throw createError!;
    created.add(profile);
    stored = profile;
  }

  @override
  Future<void> createCollaboratorProfile(String userId) async {
    collaboratorIds.add(userId);
  }

  @override
  Future<Profile> getProfile(String id) async {
    if (getError != null) throw getError!;
    return stored ??
        (throw const AuthFailure(
          'Tu cuenta no tiene un perfil registrado en SmartCart.',
        ));
  }
}

Profile profileWith(Set<UserRole> roles) => Profile(
      id: 'u1',
      fullName: 'Ana María Gómez',
      email: 'ana@correo.com',
      phone: '+57 300 000 0000',
      roles: roles,
    );

/// Agrupa los dobles y construye los Blocs con ellos.
class TestEnv {
  final auth = FakeAuthRepository();
  final profiles = FakeProfileRepository();

  SignInUseCase get signIn => SignInUseCase(auth: auth, profiles: profiles);
  SignUpUseCase get signUp => SignUpUseCase(auth: auth, profiles: profiles);

  LoginBloc loginBloc() => LoginBloc(signIn: signIn);
  RegisterBloc registerBloc() => RegisterBloc(signUp: signUp);
  SessionBloc sessionBloc() => SessionBloc(
        getMyProfile: GetMyProfileUseCase(auth: auth, profiles: profiles),
        signOut: SignOutUseCase(auth: auth),
      );
}
