import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('fullName rechaza vacío y acepta texto', () {
      expect(AuthValidators.fullName('  '), isNotNull);
      expect(AuthValidators.fullName(null), isNotNull);
      expect(AuthValidators.fullName('Ana Gómez'), isNull);
    });

    test('email valida el formato', () {
      expect(AuthValidators.email(''), 'Escribe tu correo electrónico');
      expect(AuthValidators.email('ana@'), 'Escribe un correo válido');
      expect(AuthValidators.email('ana correo@x.com'), isNotNull);
      expect(AuthValidators.email('ana@correo.com'), isNull);
    });

    test('phone es opcional pero se valida si se escribe', () {
      expect(AuthValidators.phone(''), isNull);
      expect(AuthValidators.phone(null), isNull);
      expect(AuthValidators.phone('+57 300 000 0000'), isNull);
      expect(AuthValidators.phone('(601) 555-1234'), isNull);
      expect(AuthValidators.phone('abc'), isNotNull);
      expect(AuthValidators.phone('123'), isNotNull);
    });

    test('newPassword exige mínimo 8 caracteres', () {
      expect(AuthValidators.newPassword(''), isNotNull);
      expect(AuthValidators.newPassword('1234567'), isNotNull);
      expect(AuthValidators.newPassword('12345678'), isNull);
    });

    test('existingPassword solo exige que no esté vacía', () {
      expect(AuthValidators.existingPassword(''), isNotNull);
      expect(AuthValidators.existingPassword('abc'), isNull);
    });

    test('confirmPassword compara con la contraseña', () {
      expect(AuthValidators.confirmPassword('', 'x'), isNotNull);
      expect(
        AuthValidators.confirmPassword('otra', 'clave123'),
        'Las contraseñas no coinciden',
      );
      expect(AuthValidators.confirmPassword('clave123', 'clave123'), isNull);
    });
  });
}
