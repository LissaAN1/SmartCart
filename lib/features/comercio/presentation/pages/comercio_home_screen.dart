// lib/src/features/comercio/ui/screens/comercio_home_screen.dart
// Home del COMERCIO ("Panel del comercio"). El nombre del comercio es real; el
// resto (ventas, órdenes, tip) son datos de ejemplo hasta que existan las
// tablas correspondientes.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/comercio_widgets.dart';

class ComercioHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;

  /// Nombre del establecimiento registrado (dato real).
  final String nombreComercio;

  /// HU-10: abre el catálogo ("Ir al Catálogo"). Sin él avisa "próximamente".
  final VoidCallback? onAbrirCatalogo;

  /// HU-10: abre el formulario de un producto nuevo (botón "+").
  final VoidCallback? onNuevoProducto;

  /// HU-14: el comercio aún no guardó su ubicación; se avisa y se ofrece
  /// guardarla con [onFijarUbicacion].
  final bool sinUbicacion;
  final bool ubicando;
  final String? errorUbicacion;
  final VoidCallback? onFijarUbicacion;

  const ComercioHomeScreen({
    super.key,
    this.onTab,
    required this.nombreComercio,
    this.onAbrirCatalogo,
    this.onNuevoProducto,
    this.sinUbicacion = false,
    this.ubicando = false,
    this.errorUbicacion,
    this.onFijarUbicacion,
  });

  static const _ordenes = [
    (codigo: '#108-A', estado: EstadoOrdenComercio.pendiente, hace: 'Hace 5 min', cliente: 'Carlos Rodriguez', productos: 4, total: r'$ 45.200'),
    (codigo: '#109-C', estado: EstadoOrdenComercio.enProceso, hace: 'Hace 15 min', cliente: 'Maria Elena Gomez', productos: 2, total: r'$ 12.900'),
    (codigo: '#110-B', estado: EstadoOrdenComercio.entregado, hace: 'Hace 1 hora', cliente: 'Supermercado Central', productos: 12, total: r'$ 156.000'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      navItems: navComercio,
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: BarraTituloRol(
        titulo: 'Panel del comercio',
        acciones: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: t.texto),
            onPressed: () => mostrarProximamente(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AvatarPerfil(radio: 20, nombre: nombreComercio),
          ),
        ],
      ),
      fab: FloatingActionButton(
        backgroundColor: t.primario,
        shape: const CircleBorder(),
        onPressed: onNuevoProducto ?? () => mostrarProximamente(context),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ══ UBICACIÓN (HU-14) ══
          if (sinUbicacion) ...[
            _AvisoUbicacion(
              ubicando: ubicando,
              error: errorUbicacion,
              onTap: onFijarUbicacion,
            ),
            const SizedBox(height: 16),
          ],

          // ══ MÉTRICAS ══
          const Row(
            children: [
              Expanded(
                child: TarjetaMetrica(
                  valor: r'$ 840.000',
                  etiqueta: 'Ventas hoy',
                  nota: '+12% vs ayer',
                  centrada: false,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  valor: '14',
                  etiqueta: 'Pedidos activos',
                  nota: '3 por despachar',
                  centrada: false,
                ),
              ),
            ],
          ),

          // ══ ÓRDENES ══
          TituloSeccion(
            titulo: 'Órdenes Recientes',
            estilo: EstiloTitulo.grande,
            accion: 'Ver todas',
            onAccion: () => mostrarProximamente(context),
          ),
          for (final o in _ordenes) ...[
            OrdenComercioCard(
              codigo: o.codigo,
              estado: o.estado,
              hace: o.hace,
              cliente: o.cliente,
              productos: o.productos,
              total: o.total,
              onVerDetalle: () => mostrarProximamente(context),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),

          // ══ TIP ══
          TarjetaTip(
            titulo: 'Tip de Crecimiento',
            textoAntes: 'Los comercios que actualizan su catálogo '
                'semanalmente venden un ',
            resaltado: '20% más',
            textoDespues: '.',
            textoBoton: 'Ir al Catálogo',
            onBoton: onAbrirCatalogo ?? () => mostrarProximamente(context),
          ),
        ],
      ),
    );
  }
}

/// HU-14: sin la ubicación del comercio, los colaboradores no pueden
/// reportar precios en él (la app comprueba que estén en el lugar).
class _AvisoUbicacion extends StatelessWidget {
  final bool ubicando;
  final String? error;
  final VoidCallback? onTap;

  const _AvisoUbicacion({
    required this.ubicando,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_off_outlined, color: t.primarioOscuro),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Falta la ubicación de tu comercio',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estando en tu local, guárdala para que los colaboradores puedan '
            'reportar los precios de tus productos.',
            style: TextStyle(fontSize: 13, height: 1.3, color: t.textoGris),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(fontSize: 12.5, color: ColoresEstado.rojo),
            ),
          ],
          const SizedBox(height: 12),
          BotonPrimario(
            texto: 'Guardar ubicación',
            cargando: ubicando,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
