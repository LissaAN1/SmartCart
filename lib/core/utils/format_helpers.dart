const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "nov 2026": mes y año en que la persona se registró.
String mesYAnio(DateTime fecha) => '${_meses[fecha.month - 1]} ${fecha.year}';

/// HU-11: "$ 2.500". Pesos colombianos enteros, con punto de miles como se
/// escriben en Colombia. Los negativos llevan el signo antes del símbolo.
String formatoCop(int pesos) {
  final digitos = pesos.abs().toString();
  final grupos = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) grupos.write('.');
    grupos.write(digitos[i]);
  }
  return '${pesos < 0 ? '-' : ''}\$ $grupos';
}

/// HU-11: "15 nov 2026".
String fechaCorta(DateTime fecha) =>
    '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';

/// HU-11: "15 nov 2026 · 14:05", en la hora local del teléfono.
String fechaHora(DateTime fecha) {
  final local = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fechaCorta(local)} · ${dos(local.hour)}:${dos(local.minute)}';
}

/// La fecha sin la hora (medianoche local). Sirve para comparar días, como
/// el inicio y el fin de una promoción.
DateTime soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);
