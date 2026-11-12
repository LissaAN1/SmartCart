import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../auth/domain/entities/profile.dart';
import '../widgets/repartidor_widgets.dart';

/// Perfil del repartidor (ya aprobado) con los datos reales de su cuenta.
/// Lo que todavía no tiene tabla (entregas, saldo, documentos, vehículo) no
/// se muestra con cifras inventadas.
class RepartidorPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final Profile profile;
  const RepartidorPerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.repartidor;
    final rating = profile.rating;
    final desde = profile.memberSince;
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
            nombre: profile.fullName,
            correo: profile.email,
            insignia: Icons.shield_outlined,
            etiquetas: [
              EtiquetaEstado.marca('Repartidor'),
              const EtiquetaEstado.exito('Aprobado'),
            ],
          ),
          if ((profile.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(profile.description!.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.textoGris)),
          ],
          const SizedBox(height: 22),

          // ══ ESTADÍSTICAS ══
          TarjetaEstadisticas(
            items: [
              Estadistica(
                Icons.star_border_rounded,
                rating == null ? '—' : rating.toStringAsFixed(1),
                'Calificación',
              ),
              Estadistica(Icons.reviews_outlined, '${profile.ratingCount}',
                  'Reseñas'),
              Estadistica(Icons.schedule,
                  desde == null ? '—' : mesYAnio(desde), 'Antigüedad'),
            ],
          ),

          // ══ CUENTA ══
          const TituloSeccion(titulo: 'INFORMACIÓN DE CONTACTO'),
          TarjetaSuave(
            radio: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                FilaContacto(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: profile.email),
                FilaContacto(
                    icono: Icons.phone_iphone,
                    etiqueta: 'Teléfono de contacto',
                    valor: profile.phone ?? 'No registrado'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const TituloSeccion(titulo: 'CUENTA'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () => mostrarProximamente(context)),
            ],
          ),
          const SizedBox(height: 24),
          BotonCerrarSesion(onConfirmar: onCerrarSesion),
        ],
      ),
    );
  }
}
