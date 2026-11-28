/// Reglas de la ubicación del cliente (HU-19). Los mismos valores están en
/// `guardar_ubicacion_cliente` y `comercios_en_radio`
/// (docs/sql/sprint3_hu19.sql).
abstract final class RadioReglas {
  /// El backlog pide un radio configurable sin fijar límites. Menos de 1 km
  /// casi nunca muestra comercios y más de 20 km ya no es "a la mano".
  static const minimoM = 1000;
  static const maximoM = 20000;

  /// Radio con el que empieza quien todavía no eligió uno.
  static const porDefectoM = 5000;

  /// Las opciones que ofrece la pantalla.
  static const opcionesM = [1000, 2000, 5000, 10000, 20000];

  /// Una dirección más corta que esto no alcanza para ubicarla.
  static const direccionMin = 5;
  static const direccionMax = 200;

  static bool radioValido(int metros) =>
      metros >= minimoM && metros <= maximoM;
}
