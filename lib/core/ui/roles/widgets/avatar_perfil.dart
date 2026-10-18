// lib/src/core/ui/roles/widgets/avatar_perfil.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Avatar circular. Si no hay foto muestra las iniciales.
/// - [insignia]: ícono en un círculo de color primario abajo a la derecha
///   (escudo del repartidor, tienda del comercio...).
/// - [enLinea]: punto verde abajo a la derecha.
class AvatarPerfil extends StatelessWidget {
  final double radio;
  final String? fotoUrl;
  final String nombre;
  final IconData? insignia;
  final bool enLinea;

  const AvatarPerfil({
    super.key,
    this.radio = 46,
    this.fotoUrl,
    this.nombre = '',
    this.insignia,
    this.enLinea = false,
  });

  String get _iniciales {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final tieneFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    final tamInsignia = radio * 0.62;

    return SizedBox(
      width: radio * 2,
      height: radio * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
              radius: radio,
              backgroundColor: t.suave,
              backgroundImage: tieneFoto ? NetworkImage(fotoUrl!) : null,
              child: tieneFoto
                  ? null
                  : (_iniciales.isEmpty
                      ? Icon(Icons.person, size: radio, color: t.primario)
                      : Text(_iniciales,
                          style: TextStyle(
                              fontSize: radio * 0.6,
                              fontWeight: FontWeight.w700,
                              color: t.primario))),
          ),
          if (insignia != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: tamInsignia,
                height: tamInsignia,
                decoration: BoxDecoration(
                  color: t.primario,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.fondo, width: 2.5),
                ),
                child: Icon(insignia,
                    color: Colors.white, size: tamInsignia * 0.52),
              ),
            )
          else if (enLinea)
            Positioned(
              right: radio * 0.04,
              bottom: radio * 0.04,
              child: Container(
                width: radio * 0.38,
                height: radio * 0.38,
                decoration: BoxDecoration(
                  color: ColoresEstado.enLinea,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.fondo, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
