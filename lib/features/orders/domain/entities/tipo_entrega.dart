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

/// Lo que el cliente eligió para un comercio: recogerla o que se la lleven.
/// El destino de una entrega es la ubicación que tiene guardada (HU-19).
class EleccionEntrega {
  final TipoEntrega tipo;

  const EleccionEntrega({required this.tipo});

  static const recogida = EleccionEntrega(tipo: TipoEntrega.recogida);
  static const entrega = EleccionEntrega(tipo: TipoEntrega.entrega);
}
