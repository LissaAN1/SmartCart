import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/validators/aprobacion_validators.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// HU-24: el administrador aprueba o rechaza una solicitud de comercio o de
/// repartidor, y el solicitante recibe una notificación con la decisión.
///
/// Al rechazar exige un motivo. Además comprueba que quien decide sea
/// administrador para dar un mensaje claro, pero la garantía real está en la
/// base: las políticas RLS y `decidir_solicitud` rechazan a cualquier otra
/// cuenta aunque se salte la app.
class DecidirSolicitudUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final SolicitudesRepository _solicitudes;

  DecidirSolicitudUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
    required SolicitudesRepository solicitudes,
  })  : _auth = auth,
        _profiles = profiles,
        _solicitudes = solicitudes;

  Future<void> aprobar(Solicitud solicitud) async {
    await _comprobarAdministrador();
    await _solicitudes.decidir(solicitud, aprobar: true);
  }

  Future<void> rechazar(Solicitud solicitud, {required String motivo}) async {
    final error = AprobacionValidators.motivoRechazo(motivo);
    if (error != null) throw AuthFailure(error);
    await _comprobarAdministrador();
    await _solicitudes.decidir(
      solicitud,
      aprobar: false,
      motivo: motivo.trim(),
    );
  }

  Future<void> _comprobarAdministrador() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para revisar solicitudes.');
    }
    final profile = await _profiles.getProfile(user.id);
    if (!profile.hasRole(UserRole.administrador)) {
      throw const AuthFailure(
        'Solo el administrador puede aprobar o rechazar solicitudes.',
      );
    }
  }
}
