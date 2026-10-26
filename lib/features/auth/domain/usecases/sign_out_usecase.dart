import 'package:smartcart/features/auth/data/repository/auth_repository_impl.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';

/// Cierra la sesión actual.
class SignOutUseCase {
  final AuthRepository _auth;

  SignOutUseCase({AuthRepository? auth}) : _auth = auth ?? AuthRepositoryImpl();

  Future<void> call() => _auth.signOut();
}
