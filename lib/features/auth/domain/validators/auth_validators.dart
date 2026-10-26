/// Reglas de los formularios de autenticación. Cada método devuelve el
/// mensaje de error o `null` si el valor es válido, que es justo lo que espera
/// el `validator` de un `TextFormField`. Los casos de uso las vuelven a
/// aplicar para que el dominio no dependa de que la pantalla las haya
/// ejecutado.
abstract final class AuthValidators {
  /// El diseño del registro indica "Mínimo 8 caracteres".
  static const minPasswordLength = 8;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phoneSeparators = RegExp(r'[\s\-()]');
  static final _phonePattern = RegExp(r'^\+?\d{7,15}$');

  static String? fullName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Escribe tu nombre completo';
    return null;
  }

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe tu correo electrónico';
    if (!_emailPattern.hasMatch(text)) return 'Escribe un correo válido';
    return null;
  }

  /// La columna `usuario.telefono` admite nulos, así que el teléfono es
  /// opcional; si se escribe, tiene que parecer un número.
  static String? phone(String? value) {
    final text = (value ?? '').replaceAll(_phoneSeparators, '');
    if (text.isEmpty) return null;
    if (!_phonePattern.hasMatch(text)) {
      return 'Escribe un teléfono válido, por ejemplo +57 300 000 0000';
    }
    return null;
  }

  /// Contraseña nueva (registro).
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe una contraseña';
    if (text.length < minPasswordLength) {
      return 'Usa mínimo $minPasswordLength caracteres';
    }
    return null;
  }

  /// Contraseña existente (inicio de sesión): solo se exige que no esté vacía
  /// porque las reglas de longitud pudieron cambiar desde que se creó.
  static String? existingPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Escribe tu contraseña';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Repite tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }
}
