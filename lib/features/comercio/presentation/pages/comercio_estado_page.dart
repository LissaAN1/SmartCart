import 'package:flutter/material.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// HU-07: lo que ve el dueño mientras su comercio no está aprobado. Con el
/// registro pendiente avisa que está en revisión; si fue rechazado muestra el
/// motivo. Desde aquí puede volver a consultar el estado o cerrar sesión.
class ComercioEstadoPage extends StatelessWidget {
  final Comercio comercio;
  final bool actualizando;
  final VoidCallback? onActualizar;
  final VoidCallback? onCerrarSesion;

  const ComercioEstadoPage({
    super.key,
    required this.comercio,
    this.actualizando = false,
    this.onActualizar,
    this.onCerrarSesion,
  });

  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _maxContentWidth = 480;

  bool get _rechazado => comercio.estado == ApprovalStatus.rechazado;

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
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
            'Mi comercio',
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
                  const SizedBox(height: 24),
                  _buildDatos(t),
                  const SizedBox(height: 24),
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
        ? 'Tu registro fue rechazado'
        : 'Tu registro está en revisión';
    final mensaje = _rechazado
        ? (comercio.motivoRechazo?.trim().isNotEmpty ?? false)
            ? 'Motivo: ${comercio.motivoRechazo}'
            : 'El administrador no aprobó tu comercio. Contacta al equipo de '
                'SmartCart para más información.'
        : 'Un administrador revisará los datos de tu comercio. Cuando lo '
            'apruebe podrás publicar tu catálogo y tus precios.';
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
            ? EtiquetaEstado.error(comercio.estado.label)
            : EtiquetaEstado.pendiente(comercio.estado.label),
      ],
    );
  }

  Widget _buildDatos(TemaRol t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borde),
      ),
      child: Column(
        children: [
          _Dato(Icons.storefront_outlined, 'Establecimiento', comercio.nombre),
          _Dato(Icons.place_outlined, 'Ubicación',
              '${comercio.direccion}, ${comercio.ciudad}'),
          _Dato(Icons.schedule, 'Horario', comercio.horario),
          _Dato(Icons.local_shipping_outlined, 'Servicio',
              comercio.servicio.label),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Dato(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: t.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: TextStyle(fontSize: 12, color: t.textoGris)),
                Text(valor,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.texto)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
