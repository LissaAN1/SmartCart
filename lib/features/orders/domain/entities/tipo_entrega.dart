/// Cómo recibe el cliente su compra de un comercio.
enum TipoEntrega {
  recogida('recogida', 'Recogida en tienda'),
  entrega('entrega', 'Entrega a domicilio');

  const TipoEntrega(this.dbName, this.label);

  /// Valor guardado en `orden.tipo_entrega`.
  final String dbName;
  final String label;

  static TipoEntrega fromDbName(String? value) {
    for (final tipo in TipoEntrega.values) {
      if (tipo.dbName == value) return tipo;
    }
    return TipoEntrega.recogida;
  }
}

/// Lo que el cliente eligió para un comercio: recogerla o que se la lleven y,
/// en ese caso, adónde.
class EleccionEntrega {
  final TipoEntrega tipo;

  /// Solo se usa (y es obligatoria) con [TipoEntrega.entrega].
  final String? direccion;

  const EleccionEntrega({required this.tipo, this.direccion});

  static const recogida = EleccionEntrega(tipo: TipoEntrega.recogida);

  EleccionEntrega conDireccion(String? nueva) =>
      EleccionEntrega(tipo: tipo, direccion: nueva);
}
