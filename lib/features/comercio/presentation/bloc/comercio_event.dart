import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Algo que se le pide al ComercioBloc.
abstract class ComercioEvent {}

/// Leer el comercio de la cuenta (al abrir el Home y al "Actualizar estado").
class ComercioStarted extends ComercioEvent {
  @override
  String toString() => 'ComercioStarted()';
}

/// El dueño envió el formulario de registro.
class ComercioSubmitted extends ComercioEvent {
  final ComercioDatos datos;

  ComercioSubmitted(this.datos);

  @override
  String toString() => 'ComercioSubmitted(${datos.nombre})';
}
