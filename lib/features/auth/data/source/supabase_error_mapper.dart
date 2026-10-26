import 'dart:developer' as developer;

import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce los errores del SDK de Supabase a [AuthFailure] con mensajes en
/// español. Lo usan los data sources para que de aquí hacia arriba nadie vea
/// una clase de Supabase ni un mensaje técnico en inglés.
const _connectionMessage =
    'No pudimos conectarnos. Revisa tu conexión a internet e inténtalo de nuevo.';
const _unknownMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.';

AuthFailure connectionFailure() => const AuthFailure(_connectionMessage);

AuthFailure mapAuthException(AuthException e) {
  final message = e.message.toLowerCase();
  developer.log('AuthException: ${e.message}', name: 'smartcart.auth');

  if (message.contains('invalid login credentials')) {
    return const AuthFailure('El correo o la contraseña no son correctos.');
  }
  if (message.contains('email not confirmed')) {
    return const AuthFailure('Confirma tu correo antes de iniciar sesión.');
  }
  if (message.contains('already registered') ||
      message.contains('already been registered')) {
    return const AuthFailure('Ya existe una cuenta con este correo.');
  }
  if (message.contains('password')) {
    return const AuthFailure(
      'La contraseña no cumple los requisitos de seguridad. Prueba con otra.',
    );
  }
  if (e.statusCode == '429' || message.contains('rate limit')) {
    return const AuthFailure(
      'Hiciste demasiados intentos. Espera un momento e inténtalo de nuevo.',
    );
  }
  if (message.contains('socket') ||
      message.contains('host lookup') ||
      message.contains('clientexception') ||
      message.contains('network')) {
    return connectionFailure();
  }
  return const AuthFailure(_unknownMessage);
}

AuthFailure mapPostgrestException(PostgrestException e) {
  // El detalle técnico queda en el log de depuración; no se muestra.
  developer.log(
    'PostgrestException(${e.code}): ${e.message}',
    name: 'smartcart.auth',
  );
  switch (e.code) {
    case '42501':
      return const AuthFailure('No tienes permiso para realizar esta acción.');
    case '23505':
      return const AuthFailure('Ya existe un registro con estos datos.');
    default:
      return const AuthFailure(
        'No pudimos guardar o leer tus datos. Inténtalo de nuevo.',
      );
  }
}
