import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';

import '../support/fakes.dart';

const _arroz = Producto(
  id: 'p1',
  nombre: 'Arroz blanco 500 g',
  idCategoria: 'cat-super',
  categoria: 'Super',
);

/// Espera el primer estado que cumple [condicion].
Future<PrecioProductoState> _hasta(
  PrecioProductoBloc bloc,
  bool Function(PrecioProductoState s) condicion,
) =>
    bloc.stream.firstWhere(condicion);

/// Espera a que termine la acción en curso.
Future<PrecioProductoState> _alTerminar(PrecioProductoBloc bloc) =>
    _hasta(bloc, (s) => s.accion == AccionPrecio.ninguna);

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  });

  Future<PrecioProductoBloc> listo() async {
    final bloc = env.precioBloc(_arroz)..add(PrecioProductoStarted());
    await _hasta(bloc, (s) => s.status == PrecioProductoStatus.ready);
    return bloc;
  }

  test('al iniciar carga la ficha del producto', () async {
    env.precios.precargar('p1', 2500);

    final bloc = await listo();

    expect(bloc.state.ficha.precio?.precio, 2500);
    await bloc.close();
  });

  test('un comercio pendiente ve el aviso de espera', () async {
    env.iniciarSesionComoComercio(ApprovalStatus.pendiente);
    final bloc = env.precioBloc(_arroz)..add(PrecioProductoStarted());

    final state =
        await _hasta(bloc, (s) => s.status == PrecioProductoStatus.loadFailed);

    expect(state.errorMessage, contains('pendiente de aprobación'));
    await bloc.close();
  });

  test('escenario 1: guardar el precio recarga la ficha con el historial',
      () async {
    final bloc = await listo();

    bloc.add(PrecioGuardado(2800));
    expect(
      (await _hasta(bloc, (s) => s.ocupado)).accion,
      AccionPrecio.guardandoPrecio,
    );
    final state = await _alTerminar(bloc);

    expect(state.aviso, 'Precio actualizado');
    expect(state.ficha.precio?.precio, 2800);
    expect(state.ficha.historial, hasLength(1));
    await bloc.close();
  });

  test('guardar el precio conserva la disponibilidad actual', () async {
    env.precios.precargar('p1', 2500, disponible: false);
    final bloc = await listo();

    bloc.add(PrecioGuardado(2600));
    await _alTerminar(bloc);

    expect(env.precios.guardados.single.datos.disponible, isFalse);
    await bloc.close();
  });

  test('escenario 2: marcar agotado', () async {
    env.precios.precargar('p1', 2500);
    final bloc = await listo();

    bloc.add(DisponibilidadCambiada(false));
    final state = await _hasta(bloc, (s) => s.aviso != null);

    expect(state.aviso, 'Marcado como agotado');
    expect(state.ficha.precio?.disponible, isFalse);
    await bloc.close();
  });

  test('guardar y quitar una promoción', () async {
    env.precios.precargar('p1', 2500);
    final bloc = await listo();

    bloc.add(PromocionGuardada(PromocionDatos(
      precioPromocional: 2000,
      inicio: DateTime(2026, 11, 15),
      fin: DateTime(2026, 11, 30),
    )));
    var state = await _hasta(bloc, (s) => s.aviso != null);
    expect(state.aviso, 'Promoción guardada');
    expect(state.ficha.promocion?.precioPromocional, 2000);

    bloc.add(PromocionQuitada());
    state = await _hasta(bloc, (s) => s.aviso == 'Promoción eliminada');
    expect(state.ficha.promocion, isNull);
    await bloc.close();
  });

  test('un error al guardar se muestra y deja la ficha como estaba', () async {
    env.precios.precargar('p1', 2500);
    final bloc = await listo();
    env.precios.guardarError = const AuthFailure('Sin conexión');

    bloc.add(PrecioGuardado(2800));
    final state = await _hasta(bloc, (s) => s.errorMessage != null);

    expect(state.errorMessage, 'Sin conexión');
    expect(state.accion, AccionPrecio.ninguna);
    expect(state.ficha.precio?.precio, 2500);
    await bloc.close();
  });

  test('un segundo toque mientras guarda no reenvía', () async {
    final bloc = await listo();

    bloc
      ..add(PrecioGuardado(2800))
      ..add(PrecioGuardado(2900));
    await _alTerminar(bloc);
    await Future<void>.delayed(Duration.zero);

    expect(env.precios.guardados, hasLength(1));
    await bloc.close();
  });
}
