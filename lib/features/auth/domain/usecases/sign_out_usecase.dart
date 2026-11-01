import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';

/// Cierra la sesión actual.
class SignOutUseCase {
  final AuthRepository _auth;

  SignOutUseCase({required AuthRepository auth}) : _auth = auth;

  Future<void> call() => _auth.signOut();
}