import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Reglas de la comparación del carrito (HU-18) que el backlog deja al
/// equipo. Están en un solo lugar.
abstract final class ComparacionReglas {
  /// Calidad/precio: cuánto encarece una mala calificación. Un comercio de
  /// 5 estrellas pesa su precio; uno de 1 estrella pesa un 20 % más. Así un
  /// comercio bien calificado gana cuando la diferencia de precio es pequeña,
  /// pero no cuando es grande.
  static const pesoCalificacion = 0.20;
  static const calificacionMaxima = 5.0;
  static const calificacionMinima = 1.0;

  /// Un comercio sin calificaciones cuenta como uno de 3 estrellas: ni lo
  /// premiamos ni lo castigamos por ser nuevo.
  static const calificacionNeutra = 3.0;

  /// Distancias máximas que ofrece la pantalla (las mismas del radio de la
  /// HU-19).
  static const distanciasMaximasM = [1000, 2000, 5000, 10000, 20000];

  /// Comodidad: más combinaciones que esto y usamos el método rápido
  /// (ver [ComparadorCarrito]).
  static const maxCombinaciones = 20000;

  /// Factor por el que se multiplica el precio en Calidad/precio: 1 para 5
  /// estrellas y 1,2 para 1 estrella.
  static double factorCalidad(double? calificacion) {
    final c = (calificacion ?? calificacionNeutra)
        .clamp(calificacionMinima, calificacionMaxima);
    return 1 +
        pesoCalificacion *
            (calificacionMaxima - c) /
            (calificacionMaxima - calificacionMinima);
  }
}

/// Calcula las alternativas de compra del carrito completo (HU-18). Es una
/// función pura: recibe las ofertas ya leídas de la base, la ubicación del
/// cliente y la distancia máxima, y no toca la red.
abstract final class ComparadorCarrito {
  static ResultadoComparacion comparar({
    required List<LineaComparable> lineas,
    Ubicacion? cliente,
    int? distanciaMaxM,
  }) {
    final candidatos = <LineaComparable, List<OfertaComparable>>{};
    final faltantes = <LineaComparable>[];
    for (final linea in lineas) {
      final ofertas = _candidatas(linea, cliente, distanciaMaxM);
      if (ofertas.isEmpty) {
        faltantes.add(linea);
      } else {
        candidatos[linea] = ofertas;
      }
    }
    if (candidatos.isEmpty) {
      return ResultadoComparacion(alternativas: const {}, faltantes: faltantes);
    }

    double? distancia(OfertaComparable o) =>
        cliente == null || o.ubicacionComercio == null
            ? null
            : cliente.distanciaA(o.ubicacionComercio!);

    final ahorro = _elegirPorLinea(candidatos, (o) => o.precio.toDouble(),
        distancia);
    final calidad = _elegirPorLinea(
      candidatos,
      (o) => o.precio *
          ComparacionReglas.factorCalidad(
              o.tieneCalificaciones ? o.calificacion : null),
      distancia,
    );
    final comodidad = _menosComercios(candidatos, distancia);

    Alternativa armar(
      CriterioCompra criterio,
      Map<LineaComparable, OfertaComparable> eleccion,
    ) =>
        _armar(criterio, eleccion, cliente, distancia);

    return ResultadoComparacion(
      alternativas: {
        CriterioCompra.ahorro: armar(CriterioCompra.ahorro, ahorro),
        CriterioCompra.calidadPrecio:
            armar(CriterioCompra.calidadPrecio, calidad),
        CriterioCompra.comodidad: armar(CriterioCompra.comodidad, comodidad),
      },
      faltantes: faltantes,
    );
  }

  /// Las ofertas que entran en la comparación: disponibles y, si hay
  /// distancia máxima, de comercios con ubicación dentro de ella (escenario
  /// 4). Si un comercio tiene el mismo producto dos veces, queda la más
  /// barata.
  static List<OfertaComparable> _candidatas(
    LineaComparable linea,
    Ubicacion? cliente,
    int? distanciaMaxM,
  ) {
    final porComercio = <String, OfertaComparable>{};
    for (final o in linea.ofertas) {
      if (!o.disponible) continue;
      if (distanciaMaxM != null) {
        final lugar = o.ubicacionComercio;
        if (cliente == null || lugar == null) continue;
        if (cliente.distanciaA(lugar) > distanciaMaxM) continue;
      }
      final previa = porComercio[o.idComercio];
      if (previa == null || o.precio < previa.precio) {
        porComercio[o.idComercio] = o;
      }
    }
    return porComercio.values.toList();
  }

  /// Ahorro y Calidad/precio: cada línea con la oferta de menor [puntaje].
  /// Un empate se resuelve por precio, luego por cercanía y por último por
  /// comercio, para que el resultado no dependa del orden de llegada.
  static Map<LineaComparable, OfertaComparable> _elegirPorLinea(
    Map<LineaComparable, List<OfertaComparable>> candidatos,
    double Function(OfertaComparable o) puntaje,
    double? Function(OfertaComparable o) distancia,
  ) {
    return {
      for (final entrada in candidatos.entries)
        entrada.key: _mejor(entrada.value, puntaje, distancia),
    };
  }

  static OfertaComparable _mejor(
    Iterable<OfertaComparable> ofertas,
    double Function(OfertaComparable o) puntaje,
    double? Function(OfertaComparable o) distancia,
  ) {
    int comparar(OfertaComparable a, OfertaComparable b) {
      final porPuntaje = puntaje(a).compareTo(puntaje(b));
      if (porPuntaje != 0) return porPuntaje;
      final porPrecio = a.precio.compareTo(b.precio);
      if (porPrecio != 0) return porPrecio;
      final porDistancia = (distancia(a) ?? double.infinity)
          .compareTo(distancia(b) ?? double.infinity);
      if (porDistancia != 0) return porDistancia;
      return a.idComercio.compareTo(b.idComercio);
    }

    return ofertas.reduce((a, b) => comparar(a, b) <= 0 ? a : b);
  }

  /// Comodidad: el menor número de comercios que cubre todas las líneas y,
  /// entre los grupos de ese tamaño, el de menor costo total.
  ///
  /// Probamos grupos de 1 comercio, luego de 2, y así, y paramos en el
  /// primer tamaño que cubre todo: es exacto. Si un tamaño tiene más de
  /// [ComparacionReglas.maxCombinaciones] grupos (muchos comercios y un
  /// carrito muy disperso), usamos el método rápido de ir tomando el comercio
  /// que cubre más productos pendientes; puede usar un comercio de más.
  static Map<LineaComparable, OfertaComparable> _menosComercios(
    Map<LineaComparable, List<OfertaComparable>> candidatos,
    double? Function(OfertaComparable o) distancia,
  ) {
    final comercios = {
      for (final ofertas in candidatos.values)
        for (final o in ofertas) o.idComercio,
    }.toList()
      ..sort();

    Map<LineaComparable, OfertaComparable>? cubrir(Set<String> grupo) {
      final eleccion = <LineaComparable, OfertaComparable>{};
      for (final entrada in candidatos.entries) {
        final dentro =
            entrada.value.where((o) => grupo.contains(o.idComercio));
        if (dentro.isEmpty) return null;
        eleccion[entrada.key] =
            _mejor(dentro, (o) => o.precio.toDouble(), distancia);
      }
      return eleccion;
    }

    int costo(Map<LineaComparable, OfertaComparable> e) =>
        e.entries.fold(0, (s, x) => s + x.value.precio * x.key.cantidad);

    for (var tamano = 1; tamano <= comercios.length; tamano++) {
      if (_combinaciones(comercios.length, tamano) >
          ComparacionReglas.maxCombinaciones) {
        return _voraz(candidatos, distancia);
      }
      Map<LineaComparable, OfertaComparable>? mejor;
      for (final grupo in _grupos(comercios, tamano)) {
        final eleccion = cubrir(grupo);
        if (eleccion != null &&
            (mejor == null || costo(eleccion) < costo(mejor))) {
          mejor = eleccion;
        }
      }
      if (mejor != null) return mejor;
    }
    // No se llega aquí: el grupo con todos los comercios siempre cubre.
    return _voraz(candidatos, distancia);
  }

  static Map<LineaComparable, OfertaComparable> _voraz(
    Map<LineaComparable, List<OfertaComparable>> candidatos,
    double? Function(OfertaComparable o) distancia,
  ) {
    final pendientes = candidatos.keys.toSet();
    final eleccion = <LineaComparable, OfertaComparable>{};
    while (pendientes.isNotEmpty) {
      final cubre = <String, int>{};
      for (final linea in pendientes) {
        for (final o in candidatos[linea]!) {
          cubre[o.idComercio] = (cubre[o.idComercio] ?? 0) + 1;
        }
      }
      final elegido = (cubre.entries.toList()
            ..sort((a, b) {
              final porCantidad = b.value.compareTo(a.value);
              return porCantidad != 0 ? porCantidad : a.key.compareTo(b.key);
            }))
          .first
          .key;
      for (final linea in pendientes.toList()) {
        final aqui =
            candidatos[linea]!.where((o) => o.idComercio == elegido);
        if (aqui.isNotEmpty) {
          eleccion[linea] = _mejor(aqui, (o) => o.precio.toDouble(), distancia);
          pendientes.remove(linea);
        }
      }
    }
    return eleccion;
  }

  static int _combinaciones(int n, int k) {
    var resultado = 1;
    for (var i = 1; i <= k; i++) {
      resultado = resultado * (n - k + i) ~/ i;
      if (resultado > ComparacionReglas.maxCombinaciones) return resultado;
    }
    return resultado;
  }

  /// Todos los grupos de [tamano] elementos de [elementos].
  static Iterable<Set<String>> _grupos(
    List<String> elementos,
    int tamano, [
    int desde = 0,
  ]) sync* {
    if (tamano == 0) {
      yield <String>{};
      return;
    }
    for (var i = desde; i <= elementos.length - tamano; i++) {
      for (final resto in _grupos(elementos, tamano - 1, i + 1)) {
        yield {elementos[i], ...resto};
      }
    }
  }

  static Alternativa _armar(
    CriterioCompra criterio,
    Map<LineaComparable, OfertaComparable> eleccion,
    Ubicacion? cliente,
    double? Function(OfertaComparable o) distancia,
  ) {
    final porComercio = <String, List<ItemAlternativa>>{};
    for (final entrada in eleccion.entries) {
      porComercio
          .putIfAbsent(entrada.value.idComercio, () => [])
          .add(ItemAlternativa(linea: entrada.key, oferta: entrada.value));
    }

    final comercios = [
      for (final items in porComercio.values)
        CompraEnComercio(
          idComercio: items.first.oferta.idComercio,
          nombre: items.first.oferta.comercio,
          direccion: items.first.oferta.direccion,
          ciudad: items.first.oferta.ciudad,
          ubicacion: items.first.oferta.ubicacionComercio,
          calificacion: items.first.oferta.calificacion,
          totalCalificaciones: items.first.oferta.totalCalificaciones,
          distanciaM: distancia(items.first.oferta),
          items: items,
        ),
    ]..sort((a, b) {
        final porItems = b.items.length.compareTo(a.items.length);
        return porItems != 0 ? porItems : a.nombre.compareTo(b.nombre);
      });

    final totalActual = eleccion.keys.fold(0, (suma, linea) {
      final precio = linea.precioActual;
      return precio == null ? suma : suma + precio * linea.cantidad;
    });

    final distancias = comercios.map((c) => c.distanciaM).toList();
    final distanciaTotal = cliente == null || distancias.contains(null)
        ? null
        : distancias.fold<double>(0, (s, d) => s + d!);

    return Alternativa(
      criterio: criterio,
      comercios: comercios,
      totalActual: totalActual,
      distanciaTotalM: distanciaTotal,
    );
  }
}
