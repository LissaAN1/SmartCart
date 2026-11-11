import 'package:flutter/material.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// HU-08: lo único que ve el repartidor mientras el administrador no lo
/// apruebe. Con el registro pendiente avisa que será revisado; si fue
/// rechazado lo dice. Desde aquí solo puede volver a consultar su estado o
/// cerrar sesión: no hay Home, Perfil ni disponibilidad hasta que lo aprueben.
class RepartidorEstadoPage extends StatelessWidget {
  final ApprovalStatus estado;
  final bool actualizando;
  final VoidCallback? onActualizar;
  final VoidCallback? onCerrarSesion;

  const RepartidorEstadoPage({
    super.key,
    required this.estado,
    this.actualizando = false,
    this.onActualizar,
    this.onCerrarSesion,
  });

  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _maxContentWidth = 480;

  bool get _rechazado => estado == ApprovalStatus.rechazado;

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.repartidor;
    return TemaRolScope(
      tema: t,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Mi registro',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.texto,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: Icon(Icons.logout, color: t.texto),
              onPressed: () => confirmarCierreSesion(context, onCerrarSesion),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _buildEncabezado(t),
                  const SizedBox(height: 28),
                  if (!_rechazado)
                    BotonPrimario(
                      texto: 'Actualizar estado',
                      iconoFinal: Icons.refresh,
                      cargando: actualizando,
                      onTap: onActualizar,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezado(TemaRol t) {
    final icono =
        _rechazado ? Icons.highlight_off : Icons.hourglass_top_rounded;
    final color = _rechazado ? ColoresEstado.rojo : ColoresEstado.ambar;
    final fondo =
        _rechazado ? ColoresEstado.rojoSuave : ColoresEstado.ambarSuave;
    final titulo = _rechazado
        ? 'Tu registro no fue aprobado'
        : '¡Bienvenido a SmartCart!';
    final mensaje = _rechazado
        ? 'El administrador no aprobó tu registro. Contacta al equipo de '
            'SmartCart para más información.'
        : 'Tu registro será revisado por el administrador. Cuando te aprueben '
            'podrás activar tu disponibilidad y recibir solicitudes de entrega.';
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
          child: Icon(icono, size: 42, color: color),
        ),
        const SizedBox(height: 18),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: t.texto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.35, color: t.textoGris),
        ),
        const SizedBox(height: 14),
        _rechazado
            ? EtiquetaEstado.error(estado.label)
            : EtiquetaEstado.pendiente(estado.label),
      ],
    );
  }
}
