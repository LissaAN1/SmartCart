import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/geocodificador.dart';
import 'package:smartcart/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';

import 'fakes.dart';
import 'fakes_cliente.dart';

// ───────────────────────── Datos de ejemplo ─────────────────────────

/// Dónde está el cliente en las pruebas (Cali): el mismo punto del GPS de
/// mentira (`FakeServicioUbicacion`).
const ubicacionCliente = ubicacionColaborador;

/// Lo que devuelve el geocodificador de mentira para la dirección de ejemplo
/// (unos 1,1 km al norte del GPS).
const direccionEjemplo = 'Calle 5 # 38-20, Cali';
const ubicacionDireccion = Ubicacion(latitud: 3.4616, longitud: -76.5320);

/// Comercios aprobados con ubicación, a ~0,6 km, ~3,3 km y ~7,8 km del GPS.
const comercioCerca = (
  id: 'c1',
  nombre: 'Minimercado La Esquina',
  ubicacion: Ubicacion(latitud: 3.4566, longitud: -76.5320),
);
const comercioMedio = (
  id: 'c2',
  nombre: 'Tienda Doña Rosa',
  ubicacion: Ubicacion(latitud: 3.4816, longitud: -76.5320),
);
const comercioLejos = (
  id: 'c3',
  nombre: 'Fruver El Lejano',
  ubicacion: Ubicacion(latitud: 3.5216, longitud: -76.5320),
);

// ───────────────────────── Dobles ─────────────────────────

/// La ubicación del cliente en memoria. Filtra los comercios con la misma
/// fórmula de distancia que la base (`Ubicacion.distanciaA`).
class FakeUbicacionClienteRepository implements UbicacionClienteRepository {
  PreferenciaUbicacion? guardada;
  final comercios = <({String id, String nombre, Ubicacion ubicacion})>[];
  final guardadas = <PreferenciaUbicacion>[];

  Object? errorAlLeer;
  Object? errorAlGuardar;
  Object? errorAlConsultar;

  @override
  Future<PreferenciaUbicacion?> obtener() async {
    if (errorAlLeer != null) throw errorAlLeer!;
    return guardada;
  }

  @override
  Future<void> guardar(PreferenciaUbicacion preferencia) async {
    if (errorAlGuardar != null) throw errorAlGuardar!;
    guardada = preferencia;
    guardadas.add(preferencia);
  }

  @override
  Future<List<EstablecimientoCercano>> comerciosEnRadio(
    Ubicacion centro,
    int radioM,
  ) async {
    if (errorAlConsultar != null) throw errorAlConsultar!;
    final dentro = [
      for (final c in comercios)
        if (centro.distanciaA(c.ubicacion) <= radioM)
          EstablecimientoCercano(
            id: c.id,
            nombre: c.nombre,
            direccion: 'Calle ${c.id}',
            ciudad: 'Cali',
            ubicacion: c.ubicacion,
            distanciaM: centro.distanciaA(c.ubicacion),
          ),
    ]..sort((a, b) => a.distanciaM.compareTo(b.distanciaM));
    return dentro;
  }
}

/// Geocodificador de mentira: solo conoce las direcciones de [conocidas].
class FakeGeocodificador implements Geocodificador {
  final conocidas = <String, Ubicacion>{direccionEjemplo: ubicacionDireccion};
  final buscadas = <String>[];

  @override
  Future<Ubicacion> buscar(String direccion) async {
    buscadas.add(direccion);
    final ubicacion = conocidas[direccion];
    if (ubicacion == null) {
      throw const AuthFailure('No encontramos esa dirección.');
    }
    return ubicacion;
  }
}

class UbicacionFakes {
  final repositorio = FakeUbicacionClienteRepository();
  final geocodificador = FakeGeocodificador();
}

final _fakesDeUbicacion = Expando<UbicacionFakes>('fakesDeUbicacion');

/// Casos de uso y Bloc de la ubicación del cliente (HU-19) con los dobles
/// del entorno.
extension EntornoUbicacion on TestEnv {
  UbicacionFakes get ubicacion =>
      _fakesDeUbicacion[this] ??= UbicacionFakes();

  /// Sesión de cliente con los tres comercios de ejemplo y el GPS en
  /// [ubicacionCliente].
  void iniciarSesionComoClienteConComercios() {
    iniciarSesionComoCliente();
    servicioUbicacion.ubicacion = ubicacionCliente;
    ubicacion.repositorio.comercios
        .addAll([comercioCerca, comercioMedio, comercioLejos]);
  }

  GetMiUbicacionUseCase get getMiUbicacion => GetMiUbicacionUseCase(
      cliente: clienteActivo, repositorio: ubicacion.repositorio);
  GuardarMiUbicacionUseCase get guardarMiUbicacion =>
      GuardarMiUbicacionUseCase(
          cliente: clienteActivo, repositorio: ubicacion.repositorio);
  GetComerciosEnRadioUseCase get getComerciosEnRadio =>
      GetComerciosEnRadioUseCase(
          cliente: clienteActivo, repositorio: ubicacion.repositorio);
  BuscarDireccionUseCase get buscarDireccion =>
      BuscarDireccionUseCase(geocodificador: ubicacion.geocodificador);

  MapaComerciosBloc mapaBloc() => MapaComerciosBloc(
        miUbicacion: getMiUbicacion,
        guardar: guardarMiUbicacion,
        comercios: getComerciosEnRadio,
        gps: obtenerUbicacion,
        buscarDireccion: buscarDireccion,
      );
}
