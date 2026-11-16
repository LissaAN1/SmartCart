import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/busqueda_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/widgets/resultado_card.dart';

import '../support/fakes.dart';
import 'busqueda_datos.dart';

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

void main() {
  late TestEnv env;

  setUp(() => env = entornoBusqueda());

  group('ResultadoBusqueda', () {
    test('agotado en todos cuando no hay rango', () {
      expect(lentejaResultado.agotado, isTrue);
      expect(arrozResultado.agotado, isFalse);
    });

    test('precio único cuando el mínimo y el máximo coinciden', () {
      expect(lecheResultado.precioUnico, isTrue);
      expect(arrozResultado.precioUnico, isFalse);
    });

    test('textos del rango y los establecimientos', () {
      expect(textoRango(4200, 5000), r'$ 4.200 – $ 5.000');
      expect(textoRango(3800, 3800), r'$ 3.800');
      expect(textoEstablecimientos(1), 'En 1 establecimiento');
      expect(textoEstablecimientos(3), 'En 3 establecimientos');
    });
  });

  group('DetalleProducto', () {
    test('el rango cuenta solo los disponibles', () {
      expect(arrozDetalle.disponibles, hasLength(2));
      expect(arrozDetalle.precioMin, 4200);
      expect(arrozDetalle.precioMax, 5000);
    });
  });

  group('BuscarProductosUseCase', () {
    test('escenario 1: busca por nombre y trae el rango de precios', () async {
      final pagina = await env.buscarProductos('arroz', const PageRequest());

      expect(pagina.items.single.nombre, 'Arroz Diana 500 g');
      expect(pagina.items.single.precioMin, 4200);
      expect(pagina.items.single.establecimientos, 2);
    });

    test('también busca por marca', () async {
      final pagina = await env.buscarProductos('ALQUERÍA', const PageRequest());

      expect(pagina.items.single.nombre, 'Leche entera 1L');
    });

    test('quita espacios de más antes de buscar', () async {
      await env.buscarProductos('  arroz   diana ', const PageRequest());

      expect(env.busqueda.textosBuscados.single, 'arroz diana');
    });

    test('escenario 3: sin coincidencias devuelve una página vacía', () async {
      final pagina = await env.buscarProductos('zzz', const PageRequest());

      expect(pagina.items, isEmpty);
      expect(pagina.hasMore, isFalse);
    });

    test('con menos de 2 letras no consulta la base', () async {
      final pagina = await env.buscarProductos(' a ', const PageRequest());

      expect(pagina.items, isEmpty);
      expect(env.busqueda.textosBuscados, isEmpty);
    });

    test('sin sesión pide iniciarla', () async {
      env.auth.current = null;

      await expectLater(
        env.buscarProductos('arroz', const PageRequest()),
        _falla('Inicia sesión'),
      );
    });

    test('pagina los resultados', () async {
      env.busqueda.resultados
        ..clear()
        ..addAll([
          for (var i = 1; i <= 25; i++)
            ResultadoBusqueda(
                clave: 'k$i', nombre: 'Arroz $i', categoria: 'Super'),
        ]);

      final primera = await env.buscarProductos('arroz', const PageRequest());
      final segunda = await env.buscarProductos(
          'arroz', const PageRequest(page: 1));

      expect(primera.items, hasLength(20));
      expect(primera.hasMore, isTrue);
      expect(segunda.items, hasLength(5));
      expect(segunda.hasMore, isFalse);
    });
  });

  group('GetDetalleProductoUseCase', () {
    test('abre un resultado por su clave', () async {
      final detalle =
          await env.getDetalleProducto(ConsultaPorClave(arrozResultado.clave));

      expect(detalle.ofertas, hasLength(3));
    });

    test('escenario 2: un código escaneado abre ese producto', () async {
      final detalle = await env
          .getDetalleProducto(const ConsultaPorCodigo(' 7701234567890 '));

      expect(detalle.nombre, 'Arroz Diana 500 g');
      expect(env.busqueda.clavesPedidas.single, 'cb:7701234567890');
    });

    test('un código que nadie vende lo dice', () async {
      await expectLater(
        env.getDetalleProducto(const ConsultaPorCodigo('7709999999999')),
        _falla('No encontramos productos con el código 7709999999999'),
      );
    });

    test('un código con letras o muy corto no se consulta', () async {
      await expectLater(
        env.getDetalleProducto(const ConsultaPorCodigo('ABC123')),
        _falla('8 y 14 dígitos'),
      );
      expect(env.busqueda.clavesPedidas, isEmpty);
    });

    test('sin sesión pide iniciarla', () async {
      env.auth.current = null;

      await expectLater(
        env.getDetalleProducto(ConsultaPorClave(arrozResultado.clave)),
        _falla('Inicia sesión'),
      );
    });
  });

  group('BusquedaBloc', () {
    Future<PaginatedState<ResultadoBusqueda>> listo(BusquedaBloc bloc) =>
        bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);

    test('arranca con el texto del Home', () async {
      final bloc = env.busquedaBloc(texto: 'leche')..add(PaginatedStarted());

      final state = await listo(bloc);

      expect(state.items.single.nombre, 'Leche entera 1L');
      await bloc.close();
    });

    test('cambiar el texto vuelve a buscar', () async {
      final bloc = env.busquedaBloc()..add(PaginatedStarted());
      expect((await listo(bloc)).items, isEmpty);

      bloc.add(BusquedaCambiada('arroz'));
      final state = await bloc.stream.firstWhere(
          (s) => s.status == PaginatedStatus.success && s.items.isNotEmpty);

      expect(state.items.single.nombre, 'Arroz Diana 500 g');
      expect(bloc.texto, 'arroz');
      await bloc.close();
    });

    test('un texto que llega mientras busca se aplica al terminar', () async {
      final pausa = Completer<void>();
      env.busqueda.pausa = pausa;
      final bloc = env.busquedaBloc(texto: 'arroz')
        ..add(PaginatedStarted())
        ..add(BusquedaCambiada('leche'));
      await Future<void>.delayed(Duration.zero);
      env.busqueda.pausa = null;
      pausa.complete();

      final state = await bloc.stream.firstWhere((s) =>
          s.status == PaginatedStatus.success &&
          s.items.isNotEmpty &&
          s.items.single.nombre == 'Leche entera 1L');

      expect(state.items, hasLength(1));
      await bloc.close();
    });

    test('un error de la base se muestra con su mensaje', () async {
      env.busqueda.buscarError = const AuthFailure('Sin conexión.');
      final bloc = env.busquedaBloc(texto: 'arroz')..add(PaginatedStarted());

      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.failure);

      expect(state.errorMessage, 'Sin conexión.');
      await bloc.close();
    });
  });

  group('DetalleProductoBloc', () {
    test('carga el producto con sus ofertas', () async {
      final bloc = env.detalleBloc(ConsultaPorClave(arrozResultado.clave))
        ..add(DetalleProductoStarted());

      final state = await bloc.stream
          .firstWhere((s) => s.status == DetalleProductoStatus.ready);

      expect(state.detalle?.ofertas, hasLength(3));
      await bloc.close();
    });

    test('si falla deja el mensaje para reintentar', () async {
      final bloc = env.detalleBloc(const ConsultaPorCodigo('7709999999999'))
        ..add(DetalleProductoStarted());

      final state = await bloc.stream
          .firstWhere((s) => s.status == DetalleProductoStatus.failed);

      expect(state.errorMessage, contains('No encontramos productos'));
      await bloc.close();
    });
  });
}
