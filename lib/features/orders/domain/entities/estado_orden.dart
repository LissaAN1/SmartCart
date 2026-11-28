/// En qué punto de su camino está una orden. Las nuevas nacen en
/// [generada]; la HU-21 define quién puede pasarla de un estado al siguiente.
///
/// Los mismos valores están en el `check` de `orden.estado`
/// (docs/sql/sprint3_hu20_hu25.sql).
enum EstadoOrden {
  generada('generada', 'Orden generada'),
  aceptada('aceptada', 'Aceptada'),
  enPreparacion('en_preparacion', 'En preparación'),
  listaParaRecoger('lista_para_recoger', 'Lista para recoger'),
  enCamino('en_camino', 'En camino'),
  recogida('recogida', 'Recogida'),
  entregada('entregada', 'Entregada'),
  rechazada('rechazada', 'Rechazada');

  const EstadoOrden(this.dbName, this.label);

  /// Valor guardado en la columna `estado`.
  final String dbName;

  /// Texto para mostrar al cliente.
  final String label;

  /// La compra ya se cumplió (se recogió o se entregó): desde aquí el cliente
  /// puede calificar (HU-25).
  bool get completada => this == recogida || this == entregada;

  /// Un valor desconocido se trata como "generada": nunca se muestra como
  /// completada algo que no lo es.
  static EstadoOrden fromDbName(String? value) {
    for (final estado in EstadoOrden.values) {
      if (estado.dbName == value) return estado;
    }
    return EstadoOrden.generada;
  }
}
