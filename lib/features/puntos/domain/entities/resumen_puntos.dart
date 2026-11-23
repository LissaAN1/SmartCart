import 'package:smartcart/features/puntos/domain/nivel_colaborador.dart';

/// Puntos, nivel y reputación del colaborador (HU-16).
class ResumenPuntos {
  /// Puntos que puede canjear (HU-26).
  final int saldo;

  /// Puntos ganados en total por reportes validados; de aquí sale el nivel.
  final int acumulados;
  final NivelColaborador nivel;

  /// De 0 a 100.
  final num reputacion;

  const ResumenPuntos({
    required this.saldo,
    required this.acumulados,
    required this.nivel,
    required this.reputacion,
  });

  /// Colaborador recién activado: sin puntos, nivel Nuevo y reputación 0.
  static const inicial = ResumenPuntos(
    saldo: 0,
    acumulados: 0,
    nivel: NivelColaborador.nuevo,
    reputacion: 0,
  );

  NivelColaborador? get siguienteNivel => nivel.siguiente;
  double get progreso => nivel.progreso(acumulados);
  int get puntosParaSiguiente => nivel.puntosParaSiguiente(acumulados);
}
