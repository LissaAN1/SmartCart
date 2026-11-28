/// "85 m" o "1,2 km", para mostrar qué tan lejos queda un establecimiento.
String formatoDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// "5 km": un radio de búsqueda, que siempre es un número entero de km.
String formatoRadio(int metros) => '${metros ~/ 1000} km';
