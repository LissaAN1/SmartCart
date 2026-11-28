import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_args.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/domain/seguimiento_reglas.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/ordenes_cliente_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/widgets/orden_widgets.dart';

/// "Mis órdenes" del cliente, como en el diseño (HU-23): pestañas "En curso"
/// e "Historial", el aviso de la orden lista para recoger y cada orden con su
/// estado y su progreso, por páginas. Al tocar una se abre su detalle. En el
/// historial se califica al comercio y al repartidor (HU-25).
///
/// Necesita un `PaginatedBloc<Orden>` arriba en el árbol (lo da `AppRouter`).
/// Si es un `OrdenesClienteBloc` muestra las pestañas, y si además hay un
/// `ConteoOrdenesBloc`, el número de órdenes en curso.
class MisOrdenesPage extends StatelessWidget {
  /// Reloj de la pantalla; las pruebas lo fijan.
  final DateTime Function() ahora;

  const MisOrdenesPage({super.key, this.ahora = DateTime.now});

  static ConteoOrdenesBloc? _conteo(BuildContext context) {
    try {
      return BlocProvider.of<ConteoOrdenesBloc>(context);
    } on FlutterError {
      return null;
    }
  }

  void _recargar(BuildContext context) {
    context.read<PaginatedBloc<Orden>>().add(PaginatedStarted());
    _conteo(context)?.add(ConteoOrdenesPedido());
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    final bloc = context.read<PaginatedBloc<Orden>>();
    final pestanas = bloc is OrdenesClienteBloc ? bloc : null;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Mis órdenes',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh, color: t.texto),
            onPressed: () => _recargar(context),
          ),
        ],
      ),
      cuerpo: BlocBuilder<PaginatedBloc<Orden>, PaginatedState<Orden>>(
        builder: (context, state) {
          final enCurso = pestanas?.enCurso ?? true;
          final lista = enCurso
              ? state.items.where(SeguimientoReglas.listaParaRecoger).toList()
              : const <Orden>[];
          return PaginatedListView<Orden>(
            emptyMessage: enCurso
                ? SeguimientoReglas.mensajeSinOrdenes
                : 'Aún no tienes órdenes terminadas.',
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            encabezado: _Encabezado(
              pestanas: pestanas,
              conteo: _conteo(context),
              ordenLista: lista.isEmpty ? null : lista.first,
              onAbrir: (orden) => _abrirDetalle(context, orden),
            ),
            itemBuilder: (context, orden) => TarjetaOrden(
              orden: orden,
              ahora: ahora(),
              onAbrir: () => _abrirDetalle(context, orden),
              acciones: _accionesCalificar(context, orden),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirDetalle(BuildContext context, Orden orden) async {
    final cambio = await Navigator.of(context)
        .pushNamed<bool>(AppRoutes.detalleOrden, arguments: orden.id);
    // Confirmada en el detalle: la orden pasa al historial.
    if (cambio == true && context.mounted) _recargar(context);
  }

  Future<void> _calificar(
    BuildContext context,
    Orden orden,
    TipoCalificacion tipo,
  ) async {
    final bloc = context.read<PaginatedBloc<Orden>>();
    final enviada = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.calificarOrden,
      arguments: CalificarOrdenArgs(
        idOrden: orden.id,
        numeroOrden: orden.numero,
        comercio: orden.comercio,
        tipo: tipo,
      ),
    );
    // Calificada: la lista se relee para que ya no ofrezca calificar otra vez.
    if (enviada == true) bloc.add(PaginatedStarted());
  }

  /// HU-25: una orden completada se califica (al comercio y, si hubo, al
  /// repartidor) una sola vez.
  List<Widget> _accionesCalificar(BuildContext context, Orden orden) {
    if (!orden.estado.completada) return const [];
    return [
      if (orden.puedeCalificarComercio)
        BotonSuave(
          texto: 'Calificar al comercio',
          icono: Icons.star_outline_rounded,
          onTap: () => _calificar(context, orden, TipoCalificacion.comercio),
        )
      else
        const _YaCalificada(texto: 'Ya calificaste al comercio'),
      if (orden.tieneRepartidor) ...[
        const SizedBox(height: 8),
        if (orden.puedeCalificarRepartidor)
          BotonSuave(
            texto: 'Calificar al repartidor',
            icono: Icons.star_outline_rounded,
            onTap: () =>
                _calificar(context, orden, TipoCalificacion.repartidor),
          )
        else
          const _YaCalificada(texto: 'Ya calificaste al repartidor'),
      ],
    ];
  }
}

/// Título, pestañas, aviso de la orden lista y el subtítulo de la sección.
class _Encabezado extends StatelessWidget {
  final OrdenesClienteBloc? pestanas;
  final ConteoOrdenesBloc? conteo;
  final Orden? ordenLista;
  final ValueChanged<Orden> onAbrir;

  const _Encabezado({
    required this.pestanas,
    required this.conteo,
    required this.ordenLista,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final bloc = pestanas;
    final enCurso = bloc?.enCurso ?? true;
    final lista = ordenLista;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gestiona tus compras y recogidas',
          style: TextStyle(fontSize: 14, color: t.textoGris),
        ),
        const SizedBox(height: 16),
        if (bloc != null) ...[
          _Pestanas(
            enCurso: enCurso,
            conteo: conteo,
            onCambio: (valor) =>
                bloc.add(PestanaOrdenesCambiada(enCurso: valor)),
          ),
          const SizedBox(height: 16),
        ],
        if (lista != null) ...[
          AvisoOrdenLista(orden: lista, onTap: () => onAbrir(lista)),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Icon(enCurso ? Icons.schedule : Icons.history,
                size: 18, color: t.primario),
            const SizedBox(width: 8),
            Text(
              enCurso ? 'ÓRDENES ACTIVAS' : 'HISTORIAL',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: t.textoGris,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Pestanas extends StatelessWidget {
  final bool enCurso;
  final ConteoOrdenesBloc? conteo;
  final ValueChanged<bool> onCambio;

  const _Pestanas({
    required this.enCurso,
    required this.conteo,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final contador = conteo;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.borde.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pestana(
              texto: 'En curso',
              elegida: enCurso,
              onTap: () => onCambio(true),
              insignia: contador == null
                  ? null
                  : BlocBuilder<ConteoOrdenesBloc, int?>(
                      bloc: contador,
                      builder: (context, n) => n == null || n == 0
                          ? const SizedBox.shrink()
                          : Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(
                                color: t.suave,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: t.primario,
                                ),
                              ),
                            ),
                    ),
            ),
          ),
          Expanded(
            child: _Pestana(
              texto: 'Historial',
              elegida: !enCurso,
              onTap: () => onCambio(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  final String texto;
  final bool elegida;
  final VoidCallback onTap;
  final Widget? insignia;

  const _Pestana({
    required this.texto,
    required this.elegida,
    required this.onTap,
    this.insignia,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Material(
      color: elegida ? t.superficie : t.superficie.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: elegida ? t.primario : t.textoGris,
                  ),
                ),
              ),
              if (insignia != null) insignia!,
            ],
          ),
        ),
      ),
    );
  }
}

class _YaCalificada extends StatelessWidget {
  final String texto;

  const _YaCalificada({required this.texto});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            size: 18, color: ColoresEstado.verde),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto,
              style: TextStyle(fontSize: 13, color: t.textoGris)),
        ),
      ],
    );
  }
}
