import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que habla con Supabase Auth.
class SupabaseAuthDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      // Con la confirmación de correo activada Supabase crea la cuenta sin
      // sesión, y sin sesión las políticas no dejan guardar el perfil.
      if (response.user != null && response.session == null) {
        throw const AuthFailure(
          'Este proyecto exige confirmar el correo y el registro no se puede '
          'completar. Desactiva la confirmación de correo en Supabase.',
        );
      }
      return _toAppUser(response.user);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _toAppUser(response.user);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  AppUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  AppUser _toAppUser(User? user) {
    if (user == null) {
      throw const AuthFailure('Supabase no devolvió los datos de la cuenta.');
    }
    return AppUser(id: user.id, email: user.email ?? '');
  }
}
