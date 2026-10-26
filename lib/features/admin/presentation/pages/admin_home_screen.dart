// lib/src/features/admin/ui/screens/admin_home_screen.dart
// Home del ADMINISTRADOR ("Panel"). Solo UI con datos de ejemplo.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/admin_widgets.dart';

class AdminHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final String nombre;
  const AdminHomeScreen({super.key, this.onTab, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return PantallaRol(
      tema: t,
      navItems: navAdmin(pendientes: 12),
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: BarraMarca(
        iconoLogo: Icons.shopping_basket_outlined,
        trailing: AvatarPerfil(radio: 22, nombre: nombre, enLinea: true),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        children: [
          // ══ SALUDO ══
          Text('Panel de control',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: t.texto)),
          const SizedBox(height: 4),
          Text('Resumen de la plataforma hoy',
              style: TextStyle(fontSize: 14, color: t.textoGris)),
          const SizedBox(height: 18),

          // ══ KPIs ══
          const Row(
            children: [
              Expanded(
                child: TarjetaMetrica(
                  icono: Icons.people_outline,
                  valor: '12.480',
                  etiqueta: 'Usuarios activos',
                  nota: '+4% esta semana',
                  centrada: false,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  icono: Icons.receipt_long_outlined,
                  valor: '1.326',
                  etiqueta: 'Pedidos hoy',
                  nota: '+9% vs ayer',
                  centrada: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: TarjetaMetrica(
                  icono: Icons.storefront_outlined,
                  valor: '342',
                  etiqueta: 'Comercios',
                  centrada: false,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  icono: Icons.two_wheeler,
                  valor: '87',
                  etiqueta: 'Repartidores en línea',
                  centrada: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ══ ESTADO DEL SISTEMA ══
          TarjetaEstadoSistema(
            servicios: const [
              ServicioSistema('API principal', '48 ms latencia', EstadoServicio.operativo,
                  icono: Icons.cloud_outlined),
              ServicioSistema('Pasarela de pagos', '120 ms latencia',
                  EstadoServicio.operativo,
                  icono: Icons.credit_card),
              ServicioSistema('Notificaciones push', '310 ms latencia',
                  EstadoServicio.degradado,
                  icono: Icons.notifications_none),
            ],
            onVerHistorial: () {},
          ),

          // ══ ACCESOS RÁPIDOS ══
          const TituloSeccion(
            titulo: 'Accesos Rápidos',
            estilo: EstiloTitulo.grande,
          ),
          AccesoRapidoCard(
            icono: Icons.check_circle_outline,
            titulo: 'Aprobaciones',
            subtitulo: 'Comercios y repartidores pendientes',
            contador: 12,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.shield_outlined,
            titulo: 'Moderación',
            subtitulo: 'Revisión de productos reportados',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.error_outline,
            titulo: 'Quejas',
            subtitulo: 'Gestión de reclamos activos',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.card_giftcard,
            titulo: 'Incentivos',
            subtitulo: 'Configuración de puntos y niveles',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // ══ ACCIÓN REQUERIDA ══
          AvisoDestacado(
            icono: Icons.assignment_late_outlined,
            titulo: 'Acción Requerida',
            descripcion: 'Hay 12 solicitudes de aprobación de comercios que '
                "expiran en menos de 24 horas. Prioriza la revisión de "
                "'Mercados Express'.",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
