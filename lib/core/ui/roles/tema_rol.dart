// lib/src/core/ui/roles/tema_rol.dart
// Paleta de cada rol. Cada pantalla se envuelve en un TemaRolScope
// (lo hace PantallaRol) y los componentes leen los colores con
// TemaRol.of(context), así un mismo widget sirve para los 5 roles.
import 'package:flutter/material.dart';
import 'package:smartcart/core/constants/app_assets.dart';

enum RolTema { cliente, colaborador, repartidor, comercio, admin }

@immutable
class TemaRol {
  final Color primario;
  final Color primarioOscuro; // títulos de marca / texto sobre suave
  final Color suave; // fondo de íconos, chips y botones secundarios
  final Color fondo; // fondo del Scaffold
  final Color superficie; // tarjetas
  final Color borde;
  final Color texto;
  final Color textoGris;
  final String avatarAsset; // persona de muestra cuando no hay foto real

  const TemaRol({
    required this.primario,
    required this.primarioOscuro,
    required this.suave,
    required this.fondo,
    this.superficie = Colors.white,
    required this.borde,
    this.texto = const Color(0xFF1B1D21),
    this.textoGris = const Color(0xFF6B7078),
    required this.avatarAsset,
  });

  // ── Cliente: verde ──
  static const cliente = TemaRol(
    primario: Color(0xFF1F9D6B),
    primarioOscuro: Color(0xFF0F5C3F),
    suave: Color(0xFFE2F4EB),
    fondo: Color(0xFFF3F6F5),
    borde: Color(0xFFE3E8E6),
    avatarAsset: AppAssets.avatarCliente,
  );

  // ── Colaborador: naranja ──
  static const colaborador = TemaRol(
    primario: Color(0xFFF07A2B),
    primarioOscuro: Color(0xFF4A2511),
    suave: Color(0xFFFDEBDD),
    fondo: Color(0xFFFBF8F5),
    borde: Color(0xFFF1E8E1),
    texto: Color(0xFF3A1F12),
    avatarAsset: AppAssets.avatarColaborador,
  );

  // ── Repartidor: morado ──
  static const repartidor = TemaRol(
    primario: Color(0xFF6C47DB),
    primarioOscuro: Color(0xFF2B1A63),
    suave: Color(0xFFECE7FB),
    fondo: Color(0xFFF6F5FD),
    borde: Color(0xFFE4DFF7),
    avatarAsset: AppAssets.avatarRepartidor,
  );

  // ── Comercio: rosa ──
  static const comercio = TemaRol(
    primario: Color(0xFFD6337A),
    primarioOscuro: Color(0xFF5E1235),
    suave: Color(0xFFFBE3EE),
    fondo: Color(0xFFFCF1F5),
    borde: Color(0xFFF5D9E5),
    avatarAsset: AppAssets.avatarComercio,
  );

  // ── Administrador: verde azulado ──
  static const admin = TemaRol(
    primario: Color(0xFF14877B),
    primarioOscuro: Color(0xFF06302C),
    suave: Color(0xFFDDF1EE),
    fondo: Color(0xFFE3F7F5),
    borde: Color(0xFFCDEAE6),
    texto: Color(0xFF0D1F1D),
    avatarAsset: AppAssets.avatarAdmin,
  );

  static TemaRol de(RolTema rol) => switch (rol) {
        RolTema.cliente => cliente,
        RolTema.colaborador => colaborador,
        RolTema.repartidor => repartidor,
        RolTema.comercio => comercio,
        RolTema.admin => admin,
      };

  /// Tema activo del subárbol. Si no hay scope, usa el de cliente.
  static TemaRol of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TemaRolScope>()?.tema ??
      cliente;
}

class TemaRolScope extends InheritedWidget {
  final TemaRol tema;
  const TemaRolScope({super.key, required this.tema, required super.child});

  @override
  bool updateShouldNotify(TemaRolScope oldWidget) => tema != oldWidget.tema;
}

/// Colores de estado iguales en todos los roles.
abstract final class ColoresEstado {
  static const verde = Color(0xFF1E9E5A);
  static const verdeSuave = Color(0xFFE1F6EA);
  static const ambar = Color(0xFFC98A06);
  static const ambarSuave = Color(0xFFFFF4D6);
  static const azul = Color(0xFF2F6FDB);
  static const azulSuave = Color(0xFFE3EDFC);
  static const rojo = Color(0xFFD14343);
  static const rojoSuave = Color(0xFFFBE6E6);
  static const enLinea = Color(0xFF22C55E);
}
