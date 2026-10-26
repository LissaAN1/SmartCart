import 'package:flutter/material.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/ui/roles/tema_rol.dart';

/// Lo visual de cada perfil en un solo lugar: nombre, ícono, color y el lema
/// que acompaña al login. Centralizamos esto para que la selección de perfil,
/// el login y el registro lean la misma configuración en lugar de repetir
/// condicionales por perfil.
@immutable
class PerfilVisual {
  final UserRole rol;
  final RolTema tema;
  final IconData icono;

  /// Frase bajo "Bienvenido a SmartCart". Salen de la tabla de roles del
  /// README; la del colaborador es la del diseño.
  final String lema;

  const PerfilVisual._(this.rol, this.tema, this.icono, this.lema);

  String get nombre => rol.label;
  TemaRol get paleta => TemaRol.de(tema);

  /// Si en el login se ofrece crear una cuenta. El administrador no se
  /// registra desde la app.
  bool get permiteRegistro => rol.canSelfRegister;

  /// Orden de la pantalla de selección (el mismo del diseño).
  static const todos = [
    PerfilVisual._(
      UserRole.cliente,
      RolTema.cliente,
      Icons.shopping_bag_outlined,
      'Arma tu carrito y encuentra la compra que más te conviene.',
    ),
    PerfilVisual._(
      UserRole.colaborador,
      RolTema.colaborador,
      Icons.price_check_outlined,
      'Reporta precios y gana recompensas increíbles.',
    ),
    PerfilVisual._(
      UserRole.comercio,
      RolTema.comercio,
      Icons.storefront_outlined,
      'Gestiona tus productos, precios y promociones.',
    ),
    PerfilVisual._(
      UserRole.repartidor,
      RolTema.repartidor,
      Icons.delivery_dining_outlined,
      'Acepta entregas y lleva cada pedido a su destino.',
    ),
    PerfilVisual._(
      UserRole.administrador,
      RolTema.admin,
      Icons.admin_panel_settings_outlined,
      'Supervisa la plataforma y aprueba comercios.',
    ),
  ];

  static PerfilVisual de(UserRole rol) =>
      todos.firstWhere((p) => p.rol == rol);
}
