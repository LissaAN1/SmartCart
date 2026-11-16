import 'package:smartcart/features/confianza/domain/entities/confianza_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';

/// Las reglas con que calculamos la confianza de un precio (HU-13).
///
/// El backlog pide que dependa "de la fuente y de qué tan reciente es" y que
/// el límite de días lo defina el equipo. Esto es lo que decidimos:
///
/// * **Punto de partida por fuente.** El comercio es quien conoce su precio:
///   empieza en *alta*. Un precio de la comunidad lo reporta cualquier
///   colaborador con una foto y aún no lo revisa nadie: empieza en *media* y
///   nunca llega a *alta* (la validación de reportes es la HU-15).
/// * **Cuánto baja con los días.**
///   hasta [diasReciente] días: no baja;
///   más de [diasReciente] y hasta [diasLimite]: baja un nivel;
///   más de [diasLimite]: el precio se marca como **desactualizado** y baja
///   dos niveles.
///
/// | Fuente | ≤ 3 días | 4 a 7 días | > 7 días (desactualizado) |
/// |---|---|---|---|
/// | Comercio | alta | media | baja |
/// | Comunidad | media | baja | baja |
///
/// Es una función pura: recibe la fecha de "hoy" para poder probarla.
abstract final class ConfianzaReglas {
  /// Hasta cuántos días un precio se considera reciente.
  static const diasReciente = 3;

  /// Más días que esto y el precio se marca como desactualizado.
  static const diasLimite = 7;

  static ConfianzaPrecio calcular({
    required FuentePrecio fuente,
    required DateTime actualizadoEn,
    required DateTime ahora,
  }) {
    final dias = diasDeAntiguedad(actualizadoEn, ahora);
    final desactualizado = dias > diasLimite;

    final inicio = switch (fuente) {
      FuentePrecio.comercio => NivelConfianza.alto,
      FuentePrecio.colaborador => NivelConfianza.medio,
    };
    final baja = dias <= diasReciente ? 0 : (desactualizado ? 2 : 1);
    final indice = (inicio.index - baja).clamp(0, NivelConfianza.alto.index);

    return ConfianzaPrecio(
      nivel: NivelConfianza.values[indice],
      desactualizado: desactualizado,
      dias: dias,
    );
  }

  /// Días de calendario (en la hora local) entre [actualizadoEn] y [ahora].
  /// Una fecha de "mañana" (reloj mal puesto) cuenta como hoy.
  static int diasDeAntiguedad(DateTime actualizadoEn, DateTime ahora) {
    final antes = actualizadoEn.toLocal();
    final hoy = ahora.toLocal();
    // En UTC para que el cambio de hora no altere el conteo de días.
    final dias = DateTime.utc(hoy.year, hoy.month, hoy.day)
        .difference(DateTime.utc(antes.year, antes.month, antes.day))
        .inDays;
    return dias < 0 ? 0 : dias;
  }
}
