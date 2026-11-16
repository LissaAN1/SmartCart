import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/bloc/reporte_form_bloc.dart';
import 'package:smartcart/features/reportes/presentation/bloc/sugerencia_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';

import '../support/fakes.dart';

ReporteDatos _datos([EstablecimientoCercano? e]) => ReporteDatos(
      establecimiento: e ?? establecimientoDePrueba(),
      producto: productoDePrueba,
      precio: 4900,
    );

Future<ReporteFormState> _hasta(ReporteFormBloc bloc, ReporteFormStatus s) =>
    bloc.stream.firstWhere((e) => e.status == s);

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv()..iniciarSesionComoColaborador());

  group('UbicacionBloc', () {
    test('al pedirla queda lista con las coordenadas', () async {
      final bloc = env.ubicacionBloc();

      bloc.add(UbicacionSolicitada());
      final state =
          await bloc.stream.firstWhere((s) => s.status == UbicacionStatus.lista);

      expect(state.ubicacion, ubicacionColaborador);
      await bloc.close();
    });

    test('si el GPS falla deja el mensaje y se puede reintentar', () async {
      env.servicioUbicacion.error =
          const AuthFailure('La ubicación del dispositivo está apagada.');
      final bloc = env.ubicacionBloc();

      bloc.add(UbicacionSolicitada());
      final fallo = await bloc.stream
          .firstWhere((s) => s.status == UbicacionStatus.fallida);
      expect(fallo.errorMessage, contains('apagada'));

      env.servicioUbicacion.error = null;
      bloc.add(UbicacionSolicitada());
      final lista =
          await bloc.stream.firstWhere((s) => s.status == UbicacionStatus.lista);
      expect(lista.errorMessage, isNull);
      await bloc.close();
    });

    test('un error que no es esperado muestra un mensaje genérico', () async {
      env.servicioUbicacion.error = StateError('boom');
      final bloc = env.ubicacionBloc();

      bloc.add(UbicacionSolicitada());
      final state = await bloc.stream
          .firstWhere((s) => s.status == UbicacionStatus.fallida);

      expect(state.errorMessage, contains('No pudimos conocer tu ubicación'));
      await bloc.close();
    });

    test('un segundo toque mientras el GPS responde no la pide otra vez',
        () async {
      env.servicioUbicacion.gate = Completer<void>();
      final bloc = env.ubicacionBloc();

      bloc
        ..add(UbicacionSolicitada())
        ..add(UbicacionSolicitada());
      await bloc.stream.firstWhere((s) => s.status == UbicacionStatus.cargando);
      env.servicioUbicacion.gate!.complete();
      await bloc.stream.firstWhere((s) => s.status == UbicacionStatus.lista);

      expect(env.servicioUbicacion.llamadas, 1);
      await bloc.close();
    });
  });

  group('ReporteFormBloc · foto', () {
    test('tomar la foto la deja en el estado', () async {
      final bloc = env.reporteFormBloc();

      bloc.add(ReporteFotoSolicitada());
      final state = await bloc.stream.firstWhere((s) => s.foto != null);

      expect(state.foto!.bytes, isNotEmpty);
      await bloc.close();
    });

    test('cancelar la cámara conserva la foto anterior y no es un error',
        () async {
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      env.selectorFoto.foto = null;
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream
          .firstWhere((s) => s.status == ReporteFormStatus.initial && s.foto != null);

      expect(bloc.state.foto, isNotNull);
      expect(bloc.state.errorMessage, isNull);
      await bloc.close();
    });

    test('si no se da el permiso de la cámara muestra el motivo', () async {
      env.selectorFoto.error =
          const AuthFailure('Necesitamos el permiso de la cámara.');
      final bloc = env.reporteFormBloc();

      bloc.add(ReporteFotoSolicitada());
      final state = await _hasta(bloc, ReporteFormStatus.fotoFallida);

      expect(state.errorMessage, contains('permiso de la cámara'));
      await bloc.close();
    });

    test('un error inesperado de la cámara muestra un mensaje genérico',
        () async {
      env.selectorFoto.error = StateError('boom');
      final bloc = env.reporteFormBloc();

      bloc.add(ReporteFotoSolicitada());
      final state = await _hasta(bloc, ReporteFormStatus.fotoFallida);

      expect(state.errorMessage, contains('No pudimos tomar la foto'));
      await bloc.close();
    });

    test('quitar la foto la borra', () async {
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      bloc.add(ReporteFotoQuitada());
      await bloc.stream.firstWhere((s) => s.foto == null);

      expect(bloc.state.foto, isNull);
      await bloc.close();
    });
  });

  group('ReporteFormBloc · envío', () {
    test('con foto y dentro del establecimiento queda enviado', () async {
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      bloc.add(ReporteEnviado(_datos()));
      await _hasta(bloc, ReporteFormStatus.enviado);

      expect(env.reportes.reportes.length, 1);
      await bloc.close();
    });

    test('sin foto deja el error de que es obligatoria', () async {
      final bloc = env.reporteFormBloc();

      bloc.add(ReporteEnviado(_datos()));
      final state = await _hasta(bloc, ReporteFormStatus.envioFallido);

      expect(state.errorMessage, contains('La foto de la etiqueta es obligatoria'));
      expect(env.reportes.reportes, isEmpty);
      await bloc.close();
    });

    test('lejos del establecimiento deja el mensaje y conserva la foto',
        () async {
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      bloc.add(ReporteEnviado(
          _datos(establecimientoDePrueba(ubicacion: ubicacionLejana))));
      final state = await _hasta(bloc, ReporteFormStatus.envioFallido);

      expect(state.errorMessage, contains('Debes estar en el establecimiento'));
      expect(state.foto, isNotNull);
      await bloc.close();
    });

    test('un segundo toque mientras envía no repite el reporte', () async {
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      bloc
        ..add(ReporteEnviado(_datos()))
        ..add(ReporteEnviado(_datos()));
      await _hasta(bloc, ReporteFormStatus.enviado);

      expect(env.reportes.reportes.length, 1);
      await bloc.close();
    });

    test('un error inesperado se muestra con un mensaje genérico', () async {
      env.reportes.enviarError = StateError('boom');
      final bloc = env.reporteFormBloc();
      bloc.add(ReporteFotoSolicitada());
      await bloc.stream.firstWhere((s) => s.foto != null);

      bloc.add(ReporteEnviado(_datos()));
      final state = await _hasta(bloc, ReporteFormStatus.envioFallido);

      expect(state.errorMessage, contains('error inesperado'));
      await bloc.close();
    });
  });

  group('SugerenciaBloc', () {
    const datos = SugerenciaDatos(
      nombre: 'Tienda Doña Rosa',
      direccion: 'Calle 10 # 5-20',
      ciudad: 'Cali',
    );

    test('enviar la sugerencia la guarda', () async {
      final bloc = env.sugerenciaBloc();

      bloc.add(SugerenciaEnviada(datos));
      await bloc.stream.firstWhere((s) => s.status == SugerenciaStatus.enviada);

      expect(env.reportes.sugerencias.length, 1);
      await bloc.close();
    });

    test('un dato inválido deja el error', () async {
      final bloc = env.sugerenciaBloc();

      bloc.add(SugerenciaEnviada(const SugerenciaDatos(
          nombre: '', direccion: 'Calle 10', ciudad: 'Cali')));
      final state = await bloc.stream
          .firstWhere((s) => s.status == SugerenciaStatus.fallida);

      expect(state.errorMessage, isNotNull);
      expect(env.reportes.sugerencias, isEmpty);
      await bloc.close();
    });

    test('un segundo toque mientras envía no la repite', () async {
      env.servicioUbicacion.gate = Completer<void>();
      final bloc = env.sugerenciaBloc();

      bloc
        ..add(SugerenciaEnviada(datos))
        ..add(SugerenciaEnviada(datos));
      await bloc.stream.firstWhere((s) => s.status == SugerenciaStatus.enviando);
      env.servicioUbicacion.gate!.complete();
      await bloc.stream.firstWhere((s) => s.status == SugerenciaStatus.enviada);

      expect(env.reportes.sugerencias.length, 1);
      await bloc.close();
    });

    test('un error inesperado se muestra con un mensaje genérico', () async {
      env.reportes.sugerirError = StateError('boom');
      final bloc = env.sugerenciaBloc();

      bloc.add(SugerenciaEnviada(datos));
      final state = await bloc.stream
          .firstWhere((s) => s.status == SugerenciaStatus.fallida);

      expect(state.errorMessage, contains('error inesperado'));
      await bloc.close();
    });
  });
}
