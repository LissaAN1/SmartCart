const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "$ 4.900": pesos colombianos con punto como separador de miles.
String formatoPesos(int pesos) {
  final digitos = pesos.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '${pesos < 0 ? '-' : ''}\$ $buffer';
}

/// "Hoy, 15:05", "Ayer, 09:30" o "12 nov, 15:05" (con el año si no es el
/// actual). [ahora] solo existe para poder probarlo.
String formatoFechaHora(DateTime fecha, {DateTime? ahora}) {
  final ref = ahora ?? DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  final hora = '${dos(fecha.hour)}:${dos(fecha.minute)}';

  final hoy = DateTime(ref.year, ref.month, ref.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final diferencia = hoy.difference(dia).inDays;
  if (diferencia == 0) return 'Hoy, $hora';
  if (diferencia == 1) return 'Ayer, $hora';

  final mes = _meses[fecha.month - 1];
  final anio = fecha.year == ref.year ? '' : ' ${fecha.year}';
  return '${fecha.day} $mes$anio, $hora';
}
