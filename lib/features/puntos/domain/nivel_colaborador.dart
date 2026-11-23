/// Los niveles del colaborador (HU-16). Se alcanzan según los puntos
/// acumulados por reportes validados; canjear puntos (HU-26) no baja el nivel.
///
/// Los mismos mínimos están en `nivel_para_puntos()`
/// (docs/sql/sprint3_hu15_hu16.sql): si cambias uno, cambia el otro.
enum NivelColaborador {
  nuevo(numero: 1, nombre: 'Nuevo', puntosMinimos: 0),
  frecuente(numero: 2, nombre: 'Frecuente', puntosMinimos: 100),
  experto(numero: 3, nombre: 'Experto', puntosMinimos: 500);

  const NivelColaborador({
    required this.numero,
    required this.nombre,
    required this.puntosMinimos,
  });

  /// Valor guardado en `perfil_colaborador.nivel`.
  final int numero;
  final String nombre;

  /// Puntos acumulados desde los que se tiene este nivel.
  final int puntosMinimos;

  /// El nivel que corresponde a [acumulados] puntos. Un valor negativo cuenta
  /// como cero.
  static NivelColaborador desdePuntos(int acumulados) {
    var nivel = NivelColaborador.nuevo;
    for (final candidato in NivelColaborador.values) {
      if (acumulados >= candidato.puntosMinimos) nivel = candidato;
    }
    return nivel;
  }

  /// El nivel guardado en la base; un número desconocido cuenta como Nuevo.
  static NivelColaborador desdeNumero(int numero) {
    for (final nivel in NivelColaborador.values) {
      if (nivel.numero == numero) return nivel;
    }
    return NivelColaborador.nuevo;
  }

  /// El nivel que sigue, o `null` si ya es el último.
  NivelColaborador? get siguiente {
    final indice = NivelColaborador.values.indexOf(this);
    return indice + 1 < NivelColaborador.values.length
        ? NivelColaborador.values[indice + 1]
        : null;
  }

  /// Cuántos puntos faltan para el siguiente nivel (0 si ya es el último).
  int puntosParaSiguiente(int acumulados) {
    final proximo = siguiente;
    if (proximo == null) return 0;
    final faltan = proximo.puntosMinimos - acumulados;
    return faltan < 0 ? 0 : faltan;
  }

  /// Avance dentro del nivel actual hacia el siguiente, de 0 a 1. En el
  /// último nivel es 1.
  double progreso(int acumulados) {
    final proximo = siguiente;
    if (proximo == null) return 1;
    final tramo = proximo.puntosMinimos - puntosMinimos;
    final avance = acumulados - puntosMinimos;
    return (avance / tramo).clamp(0.0, 1.0).toDouble();
  }
}
