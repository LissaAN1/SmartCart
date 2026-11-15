import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_args.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';

/// Crea el Bloc de la lista paginada de establecimientos cercanos a una
/// ubicación. Lo entrega el `AppRouter` (con GetIt); la página no conoce de
/// dónde vienen los datos.
typedef CrearListaEstablecimientos = PaginatedBloc<EstablecimientoCercano>
    Function(Ubicacion ubicacion);

/// HU-14, paso 1: el colaborador elige dónde está. Toma su ubicación, lista
/// los establecimientos cercanos (del más cerca al más lejos) y ofrece
/// sugerir uno que no esté.
///
/// Necesita un `UbicacionBloc` arriba en el árbol (lo provee `AppRouter`).
class ReporteEstablecimientoPage extends StatelessWidget {
  final CrearListaEstablecimientos crearLista;

  const ReporteEstablecimientoPage({super.key, required this.crearLista});

  /// Abre un paso del flujo; si el reporte se envió, cierra este también
  /// para volver al inicio.
  Future<void> _abrir(
    BuildContext context,
    String ruta,
    Object? argumentos,
  ) async {
    final navigator = Navigator.of(context);
    final enviado =
        await navigator.pushNamed<Object?>(ruta, arguments: argumentos);
    if (enviado == true && navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Reportar precio',
        mostrarAtras: true,
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '¿En qué establecimiento estás?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.texto,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Debes estar en el lugar para reportar un precio.',
                style: TextStyle(fontSize: 13.5, color: t.textoGris),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<UbicacionBloc, UbicacionState>(
              builder: (context, state) {
                switch (state.status) {
                  case UbicacionStatus.initial:
                  case UbicacionStatus.cargando:
                    return const _BuscandoUbicacion();
                  case UbicacionStatus.fallida:
                    return _UbicacionFallida(
                      mensaje: state.errorMessage,
                      onReintentar: () => context
                          .read<UbicacionBloc>()
                          .add(UbicacionSolicitada()),
                    );
                  case UbicacionStatus.lista:
                    final ubicacion = state.ubicacion!;
                    return BlocProvider<PaginatedBloc<EstablecimientoCercano>>(
                      // Otra ubicación, otra lista.
                      key: ValueKey(ubicacion),
                      create: (_) =>
                          crearLista(ubicacion)..add(PaginatedStarted()),
                      child: PaginatedListView<EstablecimientoCercano>(
                        emptyMessage:
                            'No hay establecimientos con ubicación cerca de ti. '
                            'Puedes sugerir uno nuevo.',
                        itemBuilder: (context, e) => _TarjetaEstablecimiento(
                          establecimiento: e,
                          onTap: () =>
                              _abrir(context, AppRoutes.reporteProducto, e),
                        ),
                      ),
                    );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: BotonSuave(
              texto: 'Sugerir establecimiento',
              icono: Icons.add_business_outlined,
              onTap: () => _abrir(context, AppRoutes.reporteSugerir, null),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuscandoUbicacion extends StatelessWidget {
  const _BuscandoUbicacion();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text('Buscando tu ubicación...',
              style: TextStyle(color: t.textoGris)),
        ],
      ),
    );
  }
}

class _UbicacionFallida extends StatelessWidget {
  final String? mensaje;
  final VoidCallback onReintentar;

  const _UbicacionFallida({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorMessage(
              message: mensaje ?? 'No pudimos conocer tu ubicación.',
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _TarjetaEstablecimiento extends StatelessWidget {
  final EstablecimientoCercano establecimiento;
  final VoidCallback onTap;

  const _TarjetaEstablecimiento({
    required this.establecimiento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final e = establecimiento;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined, color: t.primarioOscuro),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.direccion} · ${e.ciudad}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textoGris),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatoDistancia(e.distanciaM),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.primarioOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
