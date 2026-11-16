/// Helpers para parsear filas de Supabase de forma tolerante.
///
/// El DER usa CHAR(1) para banderas (leida, disponible, activa). Según cómo
/// se hayan creado en Postgres pueden llegar como bool o como 'Y'/'N'/'S'/'1'.
bool parseBool(dynamic v) {
  if (v is bool) return v;
  if (v == null) return false;
  final s = v.toString().trim().toLowerCase();
  return s == 'y' || s == 's' || s == '1' || s == 'true' || s == 't';
}

DateTime? parseDate(dynamic v) =>
    v == null ? null : DateTime.parse(v.toString());

double? parseDouble(dynamic v) {
  if (v == null) return null;
  return v is num ? v.toDouble() : double.parse(v.toString());
}

int? parseInt(dynamic v) {
  if (v == null) return null;
  return v is num ? v.toInt() : int.parse(v.toString());
}

/// HU-11: una fecha sin hora como la guarda Postgres en una columna `date`
/// ("2026-11-15").
String toSqlDate(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year.toString().padLeft(4, '0')}-${dos(fecha.month)}-'
      '${dos(fecha.day)}';
}

/// HU-11: lee una columna `date` ("2026-11-15") como medianoche local, sin
/// que la zona horaria la mueva al día anterior.
DateTime? parseSqlDate(dynamic v) {
  if (v == null) return null;
  final fecha = DateTime.parse(v.toString());
  return DateTime(fecha.year, fecha.month, fecha.day);
}
