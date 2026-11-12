const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "nov 2026": mes y año en que la persona se registró.
String mesYAnio(DateTime fecha) => '${_meses[fecha.month - 1]} ${fecha.year}';
