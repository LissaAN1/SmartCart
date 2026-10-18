// lib/src/features/colaborador/ui/screens/colaborador_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/colaborador_widgets.dart';

class ColaboradorPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  const ColaboradorPerfilScreen({super.key, this.onTab, this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return PantallaRol(
      tema: t,
      navItems: navColaborador(misionesNuevas: 3),
      tabActiva: 3,
      onTab: onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Mi Perfil', mostrarAtras: true),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: 'Camila Rodríguez',
            insignia: Icons.verified_outlined,
            ubicacion: 'Bogotá, Colombia',
            etiquetas: [
              EtiquetaEstado.marca('Colaborador Nivel Plata'),
            ],
          ),
          const SizedBox(height: 22),

          // ══ ESTADÍSTICAS ══
          TarjetaEstadisticas(
            items: const [
              Estadistica(Icons.receipt_long_outlined, '86', 'Reportes'),
              Estadistica(Icons.stars_outlined, '2.450', 'Puntos'),
              Estadistica(Icons.verified_outlined, '97%', 'Precisión'),
            ],
            pie: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 20, color: t.texto),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ganancias disponibles',
                      style: TextStyle(fontSize: 14, color: t.texto)),
                ),
                Text(r'$ 18.500',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: t.primario)),
              ],
            ),
          ),

          // ══ ACTIVIDAD ══
          const TituloSeccion(titulo: 'ACTIVIDAD'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.chat_bubble_outline,
                  titulo: 'Historial de reportes',
                  subtitulo: 'Ver precios y ofertas enviadas',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.credit_card,
                  titulo: 'Métodos de pago',
                  subtitulo: 'Retirar mis ganancias',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.share_outlined,
                  titulo: 'Referir a un amigo',
                  subtitulo: r'Gana $5.000 por invitado',
                  onTap: () {}),
            ],
          ),

          // ══ CONFIGURACIÓN ══
          const TituloSeccion(titulo: 'CONFIGURACIÓN'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes de cuenta',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () {}),
              ItemMenu(
                icono: Icons.logout,
                titulo: 'Cerrar sesión',
                peligro: true,
                onTap: () => confirmarCierreSesion(context, onCerrarSesion),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const PieVersion(),
        ],
      ),
    );
  }
}
