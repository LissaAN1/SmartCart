// lib/src/features/repartidor/ui/screens/repartidor_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/repartidor_widgets.dart';

class RepartidorPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  const RepartidorPerfilScreen({super.key, this.onTab, this.onCerrarSesion});

  static const _documentos = [
    ('Licencia de Conducir', EstadoDocumento.verificado),
    ('Seguro Obligatorio (SOAT)', EstadoDocumento.verificado),
    ('Documento de Identidad', EstadoDocumento.verificado),
    ('Tarjeta de Propiedad', EstadoDocumento.enRevision),
  ];

  static const _entregas = [
    (comercio: 'Mercado Local Centro', destino: 'Las Aguas', fecha: 'Hoy, 11:20', valor: r'$ 4.500'),
    (comercio: 'Panadería La Estancia', destino: 'Chapinero', fecha: 'Hoy, 09:45', valor: r'$ 6.200'),
    (comercio: 'Fruver El Campo', destino: 'Teusaquillo', fecha: 'Ayer, 18:10', valor: r'$ 5.100'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.repartidor;
    return PantallaRol(
      tema: t,
      navItems: navRepartidor,
      tabActiva: 2,
      onTab: onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Perfil del repartidor'),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: 'Carlos Ramírez',
            insignia: Icons.shield_outlined,
            ubicacion: 'Bogotá, Colombia',
            etiquetas: [EtiquetaEstado.marca('Repartidor aprobado')],
          ),
          const SizedBox(height: 22),

          // ══ ESTADÍSTICAS + SALDO ══
          TarjetaEstadisticas(
            items: const [
              Estadistica(Icons.star_border_rounded, '4.9', 'Calificación'),
              Estadistica(Icons.check_circle_outline, '1.240', 'Entregas'),
              Estadistica(Icons.schedule, 'Ene 2023', 'Antigüedad'),
            ],
            pie: Row(
              children: [
                Icon(Icons.credit_card, size: 20, color: t.texto),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Saldo Disponible',
                      style: TextStyle(fontSize: 14, color: t.texto)),
                ),
                Text(r'$ 12.900',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: t.primario)),
              ],
            ),
          ),

          // ══ DOCUMENTACIÓN ══
          TituloSeccion(
            titulo: 'Documentación',
            icono: Icons.description_outlined,
            estilo: EstiloTitulo.grande,
            accion: 'ACTUALIZAR',
            onAccion: () {},
          ),
          GrupoMenu(
            items: [
              for (final d in _documentos)
                DocumentoItem(nombre: d.$1, estado: d.$2, onTap: () {}),
            ],
          ),

          // ══ HISTORIAL ══
          TituloSeccion(
            titulo: 'Historial de Entregas',
            icono: Icons.history,
            estilo: EstiloTitulo.grande,
            accion: 'VER TODO',
            onAccion: () {},
          ),
          GrupoMenu(
            items: [
              for (final e in _entregas)
                EntregaItem(
                  comercio: e.comercio,
                  destino: e.destino,
                  fecha: e.fecha,
                  valor: e.valor,
                  onTap: () {},
                ),
            ],
          ),

          // ══ CUENTA ══
          const TituloSeccion(titulo: 'CUENTA'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.two_wheeler,
                  titulo: 'Mi vehículo',
                  subtitulo: 'Moto • ABC-12D',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.account_balance_outlined,
                  titulo: 'Cuenta para pagos',
                  subtitulo: 'Retirar saldo disponible',
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
