const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "nov 2026": mes y año en que la persona se registró.
String mesYAnio(DateTime fecha) => '${_meses[fecha.month - 1]} ${fecha.year}';

/// HU-11: "2.500". El valor absoluto con punto de miles, como se escribe en
/// Colombia; sirve para llenar un campo de precio.
String formatoMiles(int valor) {
  final digitos = valor.abs().toString();
  final grupos = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) grupos.write('.');
    grupos.write(digitos[i]);
  }
  return grupos.toString();
}

/// HU-11: "$ 2.500". Pesos colombianos enteros. Los negativos llevan el
/// signo antes del símbolo.
String formatoCop(int pesos) =>
    '${pesos < 0 ? '-' : ''}\$ ${formatoMiles(pesos)}';

/// HU-11: "Jul", "Ago": el mes abreviado con mayúscula, para los ejes de las
/// gráficas.
String mesCorto(int mes) {
  final m = _meses[(mes - 1) % 12];
  return '${m[0].toUpperCase()}${m.substring(1)}';
}

/// HU-11: montos cortos para espacios pequeños: "$900", "$4.5k", "$420k",
/// "$1.2M".
String formatoCopCorto(int pesos) {
  String decimal(double v) {
    final texto = v.toStringAsFixed(1);
    return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
  }

  final signo = pesos < 0 ? '-' : '';
  final valor = pesos.abs();
  if (valor >= 1000000) return '$signo\$${decimal(valor / 1000000)}M';
  if (valor >= 1000) return '$signo\$${decimal(valor / 1000)}k';
  return '$signo\$$valor';
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
