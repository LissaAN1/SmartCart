import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_movimientos_puntos_usecase.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_resumen_puntos_usecase.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/repository/validacion_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/validacion_usecases.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

import 'fakes.dart';

/// Un reporte dudoso: 8.000 reportado contra 4.900 registrado (63 % más).
ReportePorConfirmar reportePorConfirmar(
  int n, {
  int precio = 8000,
  int? precioActual = 4900,
}) =>
    ReportePorConfirmar(
      id: 'rp$n',
      producto: 'Producto $n',
      establecimiento: 'Minimercado La Esquina',
      precio: precio,
      precioActual: precioActual,
      creadoEn: DateTime(2026, 11, 20, 10, n),
      motivo: 'El precio es muy distinto al registrado.',
    );

/// Repositorio de confirmaciones en memoria. Confirmar o corregir un reporte
/// lo saca de la lista, como hace la base.
class FakeValidacionRepository implements ValidacionRepository {
  final porConfirmarLista = <ReportePorConfirmar>[];
  final deMiComercioLista = <ReportePorConfirmar>[];
  final confirmadosColaborador = <(String, Ubicacion)>[];
  final confirmadosComercio = <String>[];
  final corregidos = <(String, int)>[];
  Object? listError;
  Object? accionError;

  PagedResult<ReportePorConfirmar> _pagina(
    List<ReportePorConfirmar> todos,
    PageRequest request,
  ) {
    final filas = todos.skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<PagedResult<ReportePorConfirmar>> porConfirmar(
      PageRequest request) async {
    if (listError != null) throw listError!;
    return _pagina(porConfirmarLista, request);
  }

  @override
  Future<PagedResult<ReportePorConfirmar>> deMiComercio(
      PageRequest request) async {
    if (listError != null) throw listError!;
    return _pagina(deMiComercioLista, request);
  }

  @override
  Future<void> confirmarComoColaborador(
    String idReporte,
    Ubicacion ubicacion,
  ) async {
    if (accionError != null) throw accionError!;
    confirmadosColaborador.add((idReporte, ubicacion));
    porConfirmarLista.removeWhere((r) => r.id == idReporte);
  }

  @override
  Future<void> confirmarComoComercio(String idReporte) async {
    if (accionError != null) throw accionError!;
    confirmadosComercio.add(idReporte);
    deMiComercioLista.removeWhere((r) => r.id == idReporte);
  }

  @override
  Future<void> corregirComoComercio(String idReporte, int precio) async {
    if (accionError != null) throw accionError!;
    corregidos.add((idReporte, precio));
    deMiComercioLista.removeWhere((r) => r.id == idReporte);
  }
}

/// Repositorio de puntos en memoria.
class FakePuntosRepository implements PuntosRepository {
  ResumenPuntos resumenActual = ResumenPuntos.inicial;
  final movimientosLista = <MovimientoPuntos>[];
  Object? resumenError;
  Object? movimientosError;
  int llamadasResumen = 0;

  @override
  Future<ResumenPuntos> resumen() async {
    llamadasResumen++;
    if (resumenError != null) throw resumenError!;
    return resumenActual;
  }

  @override
  Future<PagedResult<MovimientoPuntos>> movimientos(PageRequest request) async {
    if (movimientosError != null) throw movimientosError!;
    final filas = movimientosLista
        .skip(request.from)
        .take(request.pageSize + 1)
        .toList();
    return PagedResult.fromRows(filas, request);
  }
}

MovimientoPuntos movimiento(
  int n, {
  int puntos = 10,
  TipoMovimientoPuntos tipo = TipoMovimientoPuntos.reporteValidado,
}) =>
    MovimientoPuntos(
      id: 'm$n',
      puntos: puntos,
      tipo: tipo,
      motivo: 'Reporte validado: Producto $n',
      creadoEn: DateTime(2026, 11, 20, 9, n),
    );

/// TestEnv con lo de las HU-15 y HU-16.
class ValidacionEnv extends TestEnv {
  final validacion = FakeValidacionRepository();
  final puntos = FakePuntosRepository();

  GetReportesPorConfirmarUseCase get getPorConfirmar =>
      GetReportesPorConfirmarUseCase(
          colaborador: colaboradorActivo, validacion: validacion);
  ConfirmarReporteColaboradorUseCase get confirmarColaborador =>
      ConfirmarReporteColaboradorUseCase(
          colaborador: colaboradorActivo,
          ubicacion: obtenerUbicacion,
          validacion: validacion);
  GetReportesDeMiComercioUseCase get getDeMiComercio =>
      GetReportesDeMiComercioUseCase(
          comercio: comercioAprobado, validacion: validacion);
  ConfirmarReporteComercioUseCase get confirmarComercio =>
      ConfirmarReporteComercioUseCase(
          comercio: comercioAprobado, validacion: validacion);
  CorregirReporteComercioUseCase get corregirComercio =>
      CorregirReporteComercioUseCase(
          comercio: comercioAprobado, validacion: validacion);
  AccionReporteBloc accionReporteBloc() => AccionReporteBloc(
        confirmarColaborador: confirmarColaborador,
        confirmarComercio: confirmarComercio,
        corregirComercio: corregirComercio,
      );

  GetResumenPuntosUseCase get getResumenPuntos =>
      GetResumenPuntosUseCase(colaborador: colaboradorActivo, puntos: puntos);
  GetMovimientosPuntosUseCase get getMovimientosPuntos =>
      GetMovimientosPuntosUseCase(
          colaborador: colaboradorActivo, puntos: puntos);
  ResumenPuntosBloc resumenPuntosBloc() =>
      ResumenPuntosBloc(getResumen: getResumenPuntos);
}
