import 'package:flutter/material.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Cuadrícula para elegir el perfil con el que se registra la persona.
/// Solo muestra los perfiles que permiten el registro público.
class RoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perfilesDisponibles =
            PerfilVisual.todos.where((perfil) => perfil.permiteRegistro);

        final width = (constraints.maxWidth - _spacing) / 2;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final perfil in perfilesDisponibles)
              SizedBox(
                width: width,
                child: _RoleCard(
                  perfil: perfil,
                  selected: perfil.rol == selected,
                  enabled: enabled,
                  onTap: () => onChanged(perfil.rol),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  final PerfilVisual perfil;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.perfil,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = perfil.paleta;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: perfil.nombre,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? t.suave : const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? t.primario : t.borde,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      height: 14,
                      child: selected
                          ? Icon(
                              Icons.check_circle,
                              size: 16,
                              color: t.primario,
                            )
                          : null,
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: selected ? t.primario : t.suave,
                    child: Icon(
                      perfil.icono,
                      size: 26,
                      color: selected ? Colors.white : t.primario,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    perfil.nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? t.primario : t.texto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}