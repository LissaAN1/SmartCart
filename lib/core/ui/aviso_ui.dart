import 'package:flutter/material.dart';

/// Un mensaje corto para mostrar en un `SnackBar` ("Agregado al carrito", "No
/// pudimos guardar..."). Los Blocs lo ponen en su estado; la pantalla lo
/// muestra una vez con [mostrarAviso].
///
/// Lleva un [id] que cambia con cada aviso: así el mismo texto dos veces
/// seguidas (dos errores iguales) se muestra las dos veces, porque la
/// pantalla reacciona al cambio de id y no al del texto.
class AvisoUi {
  final int id;
  final String texto;
  final bool esError;

  const AvisoUi({required this.id, required this.texto, this.esError = false});
}

/// ¿Es esta la pantalla que ve la persona? Varias pantallas apiladas pueden
/// escuchar al mismo Bloc; solo la de arriba debe mostrar el aviso.
bool esPantallaActual(BuildContext context) =>
    ModalRoute.of(context)?.isCurrent ?? true;

/// Muestra [aviso] en un `SnackBar`, reemplazando el que hubiera.
void mostrarAviso(BuildContext context, AvisoUi aviso) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(aviso.texto)));
}
