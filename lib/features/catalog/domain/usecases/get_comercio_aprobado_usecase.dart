import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';

/// Devuelve el comercio de la cuenta con sesión iniciada solo si ya fue
/// aprobado. Todos los casos de uso del catálogo parten de aquí: un comercio
/// pendiente o rechazado no puede gestionar productos.
///
/// Este chequeo da un mensaje claro; la garantía real está en la base, donde
/// las políticas RLS de `producto` exigen un comercio aprobado.
class GetComercioAprobadoUseCase {
  final AuthRepository _auth;
  final ComercioRepository _comercios;

  GetComercioAprobadoUseCase({
    required AuthRepository auth,
    required ComercioRepository comercios,
  })  : _auth = auth,
        _comercios = comercios;

  Future<Comercio> call() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para gestionar tu catálogo.');
    }
    final comercio = await _comercios.getMine(user.id);
    if (comercio == null) {
      throw const AuthFailure(
        'Registra tu comercio para poder gestionar tu catálogo.',
      );
    }
    return switch (comercio.estado) {
      ApprovalStatus.aprobado => comercio,
      ApprovalStatus.pendiente => throw const AuthFailure(
          'Tu comercio está pendiente de aprobación. Podrás cargar '
          'productos cuando el administrador lo apruebe.',
        ),
      ApprovalStatus.rechazado => throw const AuthFailure(
          'El registro de tu comercio fue rechazado, así que no puedes '
          'gestionar productos.',
        ),
    };
  }
}
