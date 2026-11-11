import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/domain/repository/aprobacion_repository.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// HU-24: el administrador aprueba o rechaza una solicitud.
///
/// * Solo una cuenta con el rol administrador puede decidir. Se comprueba
///   aquí para dar un mensaje claro, pero la barrera real es la base de datos
///   (`decidir_solicitud` y las políticas RLS): aunque alguien saltara esta
///   comprobación, Supabase lo rechaza.
/// * Al rechazar el motivo es obligatorio.
/// * El solicitante recibe una notificación con la decisión (la crea la misma
///   función de la base de datos, en la misma transacción).
class DecidirSolicitudUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final AprobacionRepository _repository;

  DecidirSolicitudUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
    required AprobacionRepository repository,
  })  : _auth = auth,
        _profiles = profiles,
        _repository = repository;

  Future<void> aprobar(SolicitudAprobacion solicitud) async {
    await _exigirAdministrador();
    await _repository.aprobar(solicitud);
  }

  Future<void> rechazar(SolicitudAprobacion solicitud, String? motivo) async {
    final texto = (motivo ?? '').trim();
    if (texto.isEmpty) throw const AuthFailure('Escribe el motivo del rechazo');
    await _exigirAdministrador();
    await _repository.rechazar(solicitud, texto);
  }

  Future<void> _exigirAdministrador() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para gestionar solicitudes.');
    }
    final profile = await _profiles.getProfile(user.id);
    if (!profile.hasRole(UserRole.administrador)) {
      throw const AuthFailure(
        'Solo el administrador puede aprobar o rechazar solicitudes.',
      );
    }
  }
}
