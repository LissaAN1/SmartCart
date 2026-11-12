/// Aviso para una cuenta. Por ahora solo los crea la decisión del
/// administrador sobre un comercio o un repartidor (HU-24).
class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime? creadoEn;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.creadoEn,
  });

  @override
  String toString() => 'Notificacion($id, $titulo)';
}
