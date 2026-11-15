import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/widgets/producto_card.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_args.dart';

/// Crea el Bloc de la lista paginada de productos de un establecimiento que
/// coinciden con una consulta. Lo entrega el `AppRouter` (con GetIt).
typedef CrearListaProductos = PaginatedBloc<Producto> Function(
  String idComercio,
  ConsultaProducto consulta,
);

/// HU-14, paso 2: el colaborador identifica el producto, escaneando su código
/// de barras o buscándolo por nombre o marca. Sin texto lista todos los
/// productos del establecimiento.
class ReporteProductoPage extends StatefulWidget {
  final EstablecimientoCercano establecimiento;
  final CrearListaProductos crearLista;

  const ReporteProductoPage({
    super.key,
    required this.establecimiento,
    required this.crearLista,
  });

  @override
  State<ReporteProductoPage> createState() => _ReporteProductoPageState();
}

class _ReporteProductoPageState extends State<ReporteProductoPage> {
  /// Tiempo que esperamos después de la última tecla para buscar, así no
  /// pedimos una página por cada letra.
  static const _pausa = Duration(milliseconds: 400);

  final _texto = TextEditingController();
  Timer? _temporizador;
  ConsultaProducto _consulta = const ConsultaProducto();

  /// El escáner usa la cámara con `mobile_scanner`, que solo existe en
  /// Android, iOS y web. En escritorio queda la búsqueda por nombre.
  bool get _puedeEscanear =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _temporizador?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _alEscribir(String valor) {
    _temporizador?.cancel();
    _temporizador = Timer(_pausa, () {
      if (!mounted) return;
      setState(() => _consulta = ConsultaProducto(texto: valor));
    });
  }

  Future<void> _escanear() async {
    final codigo = await Navigator.of(context)
        .pushNamed<String>(AppRoutes.reporteEscaner);
    if (codigo == null || !mounted) return;
    _temporizador?.cancel();
    _texto.text = codigo;
    setState(() => _consulta = ConsultaProducto.codigo(codigo));
  }

  void _limpiar() {
    _temporizador?.cancel();
    _texto.clear();
    setState(() => _consulta = const ConsultaProducto());
  }

  Future<void> _elegir(Producto producto) async {
    final navigator = Navigator.of(context);
    final enviado = await navigator.pushNamed<Object?>(
      AppRoutes.reporteFormulario,
      arguments: ReporteFormArgs(
        establecimiento: widget.establecimiento,
        producto: producto,
      ),
    );
    if (enviado == true && navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    final consulta = _consulta;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Elige el producto',
        mostrarAtras: true,
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.establecimiento.nombre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textoGris,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _texto,
              onChanged: _alEscribir,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busca por nombre o marca',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_texto.text.isNotEmpty || consulta.esCodigo)
                      IconButton(
                        tooltip: 'Quitar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: _limpiar,
                      ),
                    if (_puedeEscanear)
                      IconButton(
                        tooltip: 'Escanear código de barras',
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _escanear,
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.borde),
                ),
              ),
            ),
          ),
          if (consulta.esCodigo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Código escaneado: ${consulta.texto}',
                  style: TextStyle(fontSize: 12.5, color: t.textoGris),
                ),
              ),
            ),
          Expanded(
            child: BlocProvider<PaginatedBloc<Producto>>(
              // Otra consulta, otra lista.
              key: ValueKey('${consulta.esCodigo}:${consulta.texto}'),
              create: (_) => widget.crearLista(
                widget.establecimiento.id,
                consulta,
              )..add(PaginatedStarted()),
              child: PaginatedListView<Producto>(
                emptyMessage: consulta.esCodigo
                    ? 'No encontramos un producto con ese código en este '
                        'establecimiento.'
                    : consulta.texto.isEmpty
                        ? 'Este establecimiento todavía no tiene productos.'
                        : 'No encontramos productos con "${consulta.texto}".',
                itemBuilder: (context, producto) => ProductoCard(
                  producto: producto,
                  icono: Icons.chevron_right,
                  onTap: () => _elegir(producto),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
