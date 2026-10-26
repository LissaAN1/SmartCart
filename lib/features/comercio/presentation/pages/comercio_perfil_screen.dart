// lib/src/features/comercio/ui/screens/comercio_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/comercio_widgets.dart';

class ComercioPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  const ComercioPerfilScreen({super.key, this.onTab, this.onCerrarSesion});

  static const _quejas = [
    (titulo: 'Error en precio de café', fecha: '12 Oct 2026', desc: 'El cliente reportó una discrepancia de precio en caja.', estado: EstadoQueja.resuelto),
    (titulo: 'Producto no disponible', fecha: '08 Oct 2026', desc: 'Reporte de falta de stock en bananos.', estado: EstadoQueja.pendiente),
  ];

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      navItems: navComercio,
      tabActiva: 4,
      onTab: onTab,
      barraSuperior: BarraTituloRol(
        titulo: 'Mi Perfil',
        acciones: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: t.texto),
            onPressed: () {},
          ),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: 'Mercado Local Centro',
            insignia: Icons.storefront_outlined,
            ubicacion: 'Bogotá, D.C. - Centro Histórico',
            etiquetas: [
              EtiquetaEstado.marca('Víveres y Abarrotes'),
              const Calificacion(valor: 4.8, detalle: '(120+ reseñas)'),
            ],
          ),
          const SizedBox(height: 20),

          // ══ MÉTRICAS ══
          const Row(
            children: [
              Expanded(child: TarjetaMetrica(valor: '156', etiqueta: 'Ventas mes')),
              SizedBox(width: 12),
              Expanded(child: TarjetaMetrica(valor: '98%', etiqueta: 'Cumplimiento')),
            ],
          ),

          // ══ QUEJAS ══
          TituloSeccion(
            titulo: 'Quejas y Reclamos',
            estilo: EstiloTitulo.grande,
            accion: 'Ver histórico',
            onAccion: () {},
          ),
          for (final q in _quejas) ...[
            QuejaCard(
              titulo: q.titulo,
              fecha: q.fecha,
              descripcion: q.desc,
              estado: q.estado,
              onTap: () {},
            ),
            const SizedBox(height: 14),
          ],

          // ══ CONFIGURACIÓN ══
          const TituloSeccion(
            titulo: 'Configuración',
            estilo: EstiloTitulo.grande,
            padding: EdgeInsets.only(top: 12, bottom: 12),
          ),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.store_mall_directory_outlined,
                  titulo: 'Ajustes del Negocio',
                  subtitulo: 'Nombre, logo, categoría y dirección',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.schedule,
                  titulo: 'Horarios de atención',
                  subtitulo: 'Lun - Sáb • 7:00 a.m. - 8:00 p.m.',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.account_balance_wallet_outlined,
                  titulo: 'Métodos de Pago',
                  subtitulo: 'Cuenta para recibir tus ventas',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          BotonCerrarSesion(onConfirmar: onCerrarSesion),
        ],
      ),
    );
  }
}
