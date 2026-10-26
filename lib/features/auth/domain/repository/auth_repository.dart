import 'package:smartcart/features/auth/domain/entities/app_user.dart';

/// Contrato para crear cuentas, abrir o cerrar la sesión y consultarla.
abstract class AuthRepository {
  Future<AppUser> signUp({required String email, required String password});
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  AppUser? currentUser();
}
