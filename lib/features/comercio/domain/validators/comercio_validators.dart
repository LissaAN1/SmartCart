import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Reglas del formulario de registro del comercio. Igual que
/// `AuthValidators`: cada método devuelve el mensaje de error o `null`, y el
/// caso de uso las vuelve a aplicar.
abstract final class ComercioValidators {
  static final _horaPattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static String? nombre(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe el nombre del establecimiento';
    if (text.length < 3) return 'Usa mínimo 3 caracteres';
    return null;
  }

  /// A diferencia del registro de cuenta, aquí el teléfono es obligatorio:
  /// es el contacto del establecimiento.
  static String? telefono(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Escribe el teléfono del comercio';
    return AuthValidators.phone(value);
  }

  static String? direccion(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Escribe la dirección';
    return null;
  }

  static String? ciudad(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Escribe la ciudad o el barrio';
    return null;
  }

  static String? hora(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Elige una hora';
    if (!_horaPattern.hasMatch(text)) return 'Usa el formato HH:mm';
    return null;
  }

  /// El cierre tiene que ser posterior a la apertura (el horario no cruza la
  /// medianoche).
  static String? cierre(String? cierre, String? apertura) {
    final error = hora(cierre);
    if (error != null) return error;
    if (hora(apertura) != null) return null; // ya se avisa en su propio campo
    if (_minutos(cierre!.trim()) <= _minutos(apertura!.trim())) {
      return 'El cierre debe ser después de la apertura';
    }
    return null;
  }

  static String? servicio(ServicioComercio? value) {
    return value == null ? 'Elige el tipo de servicio' : null;
  }

  static int _minutos(String hhmm) {
    final partes = hhmm.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }
}
