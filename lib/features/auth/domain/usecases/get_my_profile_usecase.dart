import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// Lee la sesión que Supabase guarda en el dispositivo y trae su perfil.
/// Devuelve `null` cuando no hay sesión iniciada.
class GetMyProfileUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  GetMyProfileUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _auth = auth,
        _profiles = profiles;

  Future<Profile?> call() async {
    final user = _auth.currentUser();
    if (user == null) return null;
    return _profiles.getProfile(user.id);
  }
}