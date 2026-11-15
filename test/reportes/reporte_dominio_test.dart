import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/reporte_reglas.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

import '../support/fakes.dart';

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

ReporteDatos _reporte({
  EstablecimientoCercano? establecimiento,
  int precio = 4900,
  int? promo,
  bool agotado = false,
}) =>
    ReporteDatos(
      establecimiento: establecimiento ?? establecimientoDePrueba(),
      producto: productoDePrueba,
      precio: precio,
      precioPromocional: promo,
      agotado: agotado,
    );

final _foto = FotoReporte(bytes: FakeSelectorFoto().foto!.bytes);

void main() {
  group('Ubicacion.distanciaA', () {
    test('un punto está a cero metros de sí mismo', () {
      expect(ubicacionColaborador.distanciaA(ubicacionColaborador), 0);
    });

    test('0,0003° de latitud son unos 33 metros', () {
      final metros = ubicacionColaborador.distanciaA(ubicacionEstablecimiento);

      expect(metros, closeTo(33.4, 0.5));
    });

    test('1° de latitud son unos 111 km, igual que en la base', () {
      const a = Ubicacion(latitud: 0, longitud: 0);
      const b = Ubicacion(latitud: 1, longitud: 0);

      expect(a.distanciaA(b), closeTo(111195, 50));
    });

    test('la distancia es la misma en los dos sentidos', () {
      expect(
        ubicacionColaborador.distanciaA(ubicacionLejana),
        closeTo(ubicacionLejana.distanciaA(ubicacionColaborador), 0.001),
      );
    });

    test('la longitud también cuenta (en el ecuador, 1° son unos 111 km)', () {
      const a = Ubicacion(latitud: 0, longitud: 0);
      const b = Ubicacion(latitud: 0, longitud: 1);

      expect(a.distanciaA(b), closeTo(111195, 50));
    });
  });

  group('ReporteReglas', () {
    test('el radio permitido es de 150 metros', () {
      expect(ReporteReglas.radioMaximoM, 150);
      expect(ReporteReglas.estaDentro(150), isTrue);
      expect(ReporteReglas.estaDentro(150.5), isFalse);
    });

    test('el mensaje de estar lejos dice cuánto', () {
      expect(
        ReporteReglas.mensajeFuera(1111.4),
        'Debes estar en el establecimiento para reportar el precio. '
        'Estás a 1111 m.',
      );
    });
  });

  group('ReporteValidators', () {
    test('parsePrecio entiende separadores y el signo de pesos', () {
      expect(ReporteValidators.parsePrecio('4900'), 4900);
      expect(ReporteValidators.parsePrecio('4.900'), 4900);
      expect(ReporteValidators.parsePrecio(r'$ 12,300'), 12300);
      expect(ReporteValidators.parsePrecio('abc'), isNull);
      expect(ReporteValidators.parsePrecio('12a'), isNull);
      expect(ReporteValidators.parsePrecio(''), isNull);
      expect(ReporteValidators.parsePrecio(null), isNull);
    });

    test('el precio es obligatorio, numérico, positivo y con tope', () {
      expect(ReporteValidators.precio(''), isNotNull);
      expect(ReporteValidators.precio('abc'), isNotNull);
      expect(ReporteValidators.precio('0'), isNotNull);
      expect(ReporteValidators.precio('4900'), isNull);
      expect(ReporteValidators.precio('100000000'), isNull);
      expect(ReporteValidators.precio('100000001'), isNotNull);
    });

    test('la promoción es opcional y debe ser menor que el precio', () {
      expect(ReporteValidators.precioPromocional('', '4900'), isNull);
      expect(ReporteValidators.precioPromocional(null, '4900'), isNull);
      expect(ReporteValidators.precioPromocional('4500', '4900'), isNull);
      expect(ReporteValidators.precioPromocional('4900', '4900'), isNotNull);
      expect(ReporteValidators.precioPromocional('5000', '4900'), isNotNull);
      expect(ReporteValidators.precioPromocional('abc', '4900'), isNotNull);
      expect(ReporteValidators.precioPromocional('0', '4900'), isNotNull);
    });

    test('la promoción no se compara si el precio normal aún no es válido', () {
      expect(ReporteValidators.precioPromocional('4500', ''), isNull);
    });

    test('la foto es obligatoria', () {
      expect(ReporteValidators.foto(null), isNotNull);
      expect(ReporteValidators.foto(_foto), isNull);
    });

    test('la sugerencia pide nombre, dirección y ciudad', () {
      const valida = SugerenciaDatos(
        nombre: 'Tienda Doña Rosa',
        direccion: 'Calle 10 # 5-20',
        ciudad: 'Cali',
      );
      expect(ReporteValidators.sugerencia(valida), isNull);
      expect(
        ReporteValidators.sugerencia(const SugerenciaDatos(
            nombre: '', direccion: 'Calle 10', ciudad: 'Cali')),
        isNotNull,
      );
      expect(
        ReporteValidators.sugerencia(const SugerenciaDatos(
            nombre: 'Tienda', direccion: 'ab', ciudad: 'Cali')),
        isNotNull,
      );
      expect(
        ReporteValidators.sugerencia(const SugerenciaDatos(
            nombre: 'Tienda', direccion: 'Calle 10', ciudad: '')),
        isNotNull,
      );
    });
  });

  group('GetColaboradorActivoUseCase', () {
    late TestEnv env;
    setUp(() => env = TestEnv());

    test('devuelve el id de quien tiene el modo Colaborador activo', () async {
      env.iniciarSesionComoColaborador();

      expect(await env.colaboradorActivo(), 'u1');
    });

    test('sin sesión pide iniciarla', () async {
      await expectLater(env.colaboradorActivo(), _falla('Inicia sesión'));
    });

    test('un cliente sin el modo Colaborador no puede reportar', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(env.colaboradorActivo(), _falla('modo Colaborador'));
    });
  });

  group('EnviarReportePrecioUseCase · escenario 1: reporte exitoso', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('dentro del establecimiento guarda el reporte con su foto', () async {
      final id = await env.enviarReporte(
        _reporte(promo: 4500, agotado: true),
        _foto,
      );

      expect(id, 'r1');
      final guardado = env.reportes.reportes.single;
      expect(guardado.userId, 'u1');
      expect(guardado.datos.precio, 4900);
      expect(guardado.datos.precioPromocional, 4500);
      expect(guardado.datos.agotado, isTrue);
      expect(guardado.datos.producto.id, 'p1');
      expect(guardado.datos.establecimiento.id, 'c1');
      expect(guardado.foto.bytes, _foto.bytes);
    });

    test('envía la ubicación actual del colaborador, no la anterior', () async {
      const otraCercana = Ubicacion(latitud: 3.4517, longitud: -76.5320);
      env.servicioUbicacion.ubicacion = otraCercana;

      await env.enviarReporte(_reporte(), _foto);

      expect(env.reportes.reportes.single.ubicacion, otraCercana);
    });

    test('la promoción y la disponibilidad son opcionales', () async {
      await env.enviarReporte(_reporte(), _foto);

      final datos = env.reportes.reportes.single.datos;
      expect(datos.precioPromocional, isNull);
      expect(datos.agotado, isFalse);
    });
  });

  group('EnviarReportePrecioUseCase · escenario 2: fuera del establecimiento',
      () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('lejos del establecimiento lo rechaza y explica cuánto', () async {
      final lejos = establecimientoDePrueba(ubicacion: ubicacionLejana);

      await expectLater(
        env.enviarReporte(_reporte(establecimiento: lejos), _foto),
        _falla('Debes estar en el establecimiento'),
      );

      expect(env.reportes.reportes, isEmpty);
    });

    test('el mensaje incluye la distancia real', () async {
      final lejos = establecimientoDePrueba(ubicacion: ubicacionLejana);

      await expectLater(
        env.enviarReporte(_reporte(establecimiento: lejos), _foto),
        _falla('Estás a 1112 m'),
      );
    });

    test('justo dentro del radio sí se acepta y justo fuera no', () async {
      // 0,00134° de latitud ≈ 149 m; 0,00137° ≈ 152 m.
      const dentro = Ubicacion(latitud: 3.4516 + 0.00134, longitud: -76.5320);
      const fuera = Ubicacion(latitud: 3.4516 + 0.00137, longitud: -76.5320);

      await env.enviarReporte(
        _reporte(establecimiento: establecimientoDePrueba(ubicacion: dentro)),
        _foto,
      );
      expect(env.reportes.reportes.length, 1);

      await expectLater(
        env.enviarReporte(
          _reporte(establecimiento: establecimientoDePrueba(ubicacion: fuera)),
          _foto,
        ),
        _falla('Debes estar'),
      );
      expect(env.reportes.reportes.length, 1);
    });
  });

  group('EnviarReportePrecioUseCase · escenario 3: sin foto', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('sin foto muestra que es obligatoria y no pide el GPS', () async {
      await expectLater(
        env.enviarReporte(_reporte(), null),
        _falla('La foto de la etiqueta es obligatoria'),
      );

      expect(env.servicioUbicacion.llamadas, 0);
      expect(env.reportes.reportes, isEmpty);
    });

    test('una foto vacía tampoco vale', () async {
      await expectLater(
        env.enviarReporte(_reporte(), FotoReporte(bytes: Uint8List(0))),
        _falla('foto'),
      );
    });
  });

  group('EnviarReportePrecioUseCase · otras reglas', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('el precio debe ser mayor que cero', () async {
      await expectLater(
        env.enviarReporte(_reporte(precio: 0), _foto),
        _falla('mayor que cero'),
      );
      expect(env.reportes.reportes, isEmpty);
    });

    test('la promoción debe ser menor que el precio normal', () async {
      await expectLater(
        env.enviarReporte(_reporte(precio: 4900, promo: 4900), _foto),
        _falla('menor que el precio normal'),
      );
    });

    test('quien no tiene el modo Colaborador no puede enviar', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(
        env.enviarReporte(_reporte(), _foto),
        _falla('modo Colaborador'),
      );
      expect(env.reportes.reportes, isEmpty);
    });

    test('si el GPS falla, el error llega y no se guarda nada', () async {
      env.servicioUbicacion.error =
          const AuthFailure('La ubicación del dispositivo está apagada.');

      await expectLater(
        env.enviarReporte(_reporte(), _foto),
        _falla('apagada'),
      );
      expect(env.reportes.reportes, isEmpty);
    });

    test('si la base rechaza el reporte, su mensaje llega a quien llamó',
        () async {
      env.reportes.enviarError =
          const AuthFailure('Ese establecimiento no está disponible.');

      await expectLater(
        env.enviarReporte(_reporte(), _foto),
        _falla('no está disponible'),
      );
    });
  });

  group('GetEstablecimientosCercanosUseCase', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('entrega los establecimientos cercanos por páginas', () async {
      for (var i = 2; i <= 5; i++) {
        env.reportes.establecimientos
            .add(establecimientoDePrueba(id: 'c$i', nombre: 'Tienda $i'));
      }

      final primera = await env.getEstablecimientos(
        ubicacionColaborador,
        const PageRequest(pageSize: 2),
      );
      expect(primera.items.length, 2);
      expect(primera.hasMore, isTrue);

      final ultima = await env.getEstablecimientos(
        ubicacionColaborador,
        const PageRequest(page: 2, pageSize: 2),
      );
      expect(ultima.items.length, 1);
      expect(ultima.hasMore, isFalse);
    });

    test('exige el modo Colaborador', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(
        env.getEstablecimientos(ubicacionColaborador, const PageRequest()),
        _falla('modo Colaborador'),
      );
    });
  });

  group('BuscarProductosUseCase', () {
    late TestEnv env;
    setUp(() {
      env = TestEnv()..iniciarSesionComoColaborador();
      env.reportes.productosPorComercio['c1'] = [
        productoDePrueba,
        const Producto(
          id: 'p2',
          nombre: 'Leche entera 1 L',
          marca: 'Alpina',
          codigoBarras: '7709990001112',
          idCategoria: 'cat-lacteos',
          categoria: 'Lácteos',
        ),
      ];
    });

    Future<List<String>> buscar(ConsultaProducto consulta) async {
      final pagina =
          await env.buscarProductos('c1', consulta, const PageRequest());
      return [for (final p in pagina.items) p.id];
    }

    test('por nombre o por marca', () async {
      expect(await buscar(const ConsultaProducto(texto: 'arroz')), ['p1']);
      expect(await buscar(const ConsultaProducto(texto: 'ALPINA')), ['p2']);
    });

    test('con el código de barras escaneado, la coincidencia es exacta',
        () async {
      expect(await buscar(const ConsultaProducto.codigo('7709990001112')), ['p2']);
      expect(await buscar(const ConsultaProducto.codigo('7709990')), isEmpty);
    });

    test('sin texto devuelve todos los productos del establecimiento', () async {
      expect(await buscar(const ConsultaProducto()), ['p1', 'p2']);
    });

    test('ignora los espacios de los bordes', () async {
      expect(await buscar(const ConsultaProducto(texto: '  leche  ')), ['p2']);
    });

    test('un código sin producto no devuelve nada', () async {
      expect(await buscar(const ConsultaProducto.codigo('1234567890123')), isEmpty);
    });

    test('exige el modo Colaborador', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(
        env.buscarProductos('c1', const ConsultaProducto(), const PageRequest()),
        _falla('modo Colaborador'),
      );
    });
  });

  group('SugerirEstablecimientoUseCase', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

    test('guarda la sugerencia con la ubicación del colaborador', () async {
      await env.sugerirEstablecimiento(const SugerenciaDatos(
        nombre: '  Tienda Doña Rosa ',
        direccion: 'Calle 10 # 5-20',
        ciudad: 'Cali',
      ));

      final s = env.reportes.sugerencias.single;
      expect(s.userId, 'u1');
      expect(s.datos.nombre, 'Tienda Doña Rosa');
      expect(s.ubicacion, ubicacionColaborador);
    });

    test('no guarda una sugerencia inválida ni pide el GPS', () async {
      await expectLater(
        env.sugerirEstablecimiento(const SugerenciaDatos(
            nombre: '', direccion: 'Calle 10', ciudad: 'Cali')),
        _falla('nombre'),
      );

      expect(env.reportes.sugerencias, isEmpty);
      expect(env.servicioUbicacion.llamadas, 0);
    });

    test('exige el modo Colaborador', () async {
      env.iniciarSesionCon({UserRole.cliente});

      await expectLater(
        env.sugerirEstablecimiento(const SugerenciaDatos(
            nombre: 'Tienda Rosa', direccion: 'Calle 10', ciudad: 'Cali')),
        _falla('modo Colaborador'),
      );
    });
  });

  group('TomarFotoUseCase', () {
    test('entrega la foto o null si se cancela', () async {
      final env = TestEnv();

      expect(await env.tomarFoto(), isNotNull);

      env.selectorFoto.foto = null;
      expect(await env.tomarFoto(), isNull);
    });
  });
}
