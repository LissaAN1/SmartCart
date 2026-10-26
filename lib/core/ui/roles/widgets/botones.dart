// lib/src/core/ui/roles/widgets/botones.dart
import 'package:flutter/material.dart';
import '../tema_rol.dart';

/// Botón lleno con el color del rol. Ej: "Aceptar Pedido →".
class BotonPrimario extends StatelessWidget {
  final String texto;
  final IconData? iconoFinal;
  final VoidCallback? onTap;
  final bool expandido;

  const BotonPrimario({
    super.key,
    required this.texto,
    this.iconoFinal,
    this.onTap,
    this.expandido = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final boton = FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: t.primario,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto),
          if (iconoFinal != null) ...[
            const SizedBox(width: 8),
            Icon(iconoFinal, size: 18),
          ],
        ],
      ),
    );
    return expandido ? SizedBox(width: double.infinity, child: boton) : boton;
  }
}

/// Botón suave (fondo del rol atenuado). Ej: "Ir al Catálogo".
class BotonSuave extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onTap;

  const BotonSuave({super.key, required this.texto, this.icono, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: t.superficie.withValues(alpha: 0.7),
          foregroundColor: t.primarioOscuro,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 18),
              const SizedBox(width: 8),
            ],
            Text(texto),
          ],
        ),
      ),
    );
  }
}

/// "Cerrar Sesión" con borde. Pide confirmación antes de llamar [onConfirmar].
class BotonCerrarSesion extends StatelessWidget {
  final VoidCallback? onConfirmar;
  final bool pedirConfirmacion;

  const BotonCerrarSesion({
    super.key,
    this.onConfirmar,
    this.pedirConfirmacion = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => pedirConfirmacion
            ? confirmarCierreSesion(context, onConfirmar)
            : onConfirmar?.call(),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textoGris,
          backgroundColor: t.superficie.withValues(alpha: 0.5),
          side: BorderSide(color: t.borde, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación reutilizable (también lo usan los ItemMenu
/// de "Cerrar sesión").
Future<void> confirmarCierreSesion(
    BuildContext context, VoidCallback? onConfirmar) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: const Text('Tendrás que volver a ingresar tus datos.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirmar?.call();
          },
          child: const Text('Salir',
              style: TextStyle(color: ColoresEstado.rojo)),
        ),
      ],
    ),
  );
}
