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
  ConsultaProductoReporte consulta,
);

/// HU-14, paso 2: el colaborador identifica el producto, escaneando su código
/// de barras o buscándolo por nombre o marca. Sin texto lista todos los
/// productos del establecimiento.
///
/// Donde hay cámara (Android, iOS y web) abre el escáner apenas se entra, que
/// es lo más rápido para quien está frente al estante. Si el producto del
/// código existe, pasa directo al formulario; si cancela el escáner o el
/// código no está, se queda aquí para buscar por nombre.
class ReporteProductoPage extends StatefulWidget {
  final EstablecimientoCercano establecimiento;
  final CrearListaProductos crearLista;

  /// Abrir el escáner al entrar. Es `true` salvo que no haya cámara.
  final bool escanearAlEntrar;

  const ReporteProductoPage({
    super.key,
    required this.establecimiento,
    required this.crearLista,
    this.escanearAlEntrar = true,
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
  ConsultaProductoReporte _consulta = const ConsultaProductoReporte();

  /// Se activa al leer un código: si la búsqueda trae exactamente un producto,
  /// se abre su formulario sin que la persona tenga que tocarlo. Se apaga al
  /// abrirlo, para que volver atrás no lo abra otra vez.
  bool _abrirAlEncontrar = false;

  /// El escáner usa la cámara con `mobile_scanner`, que solo existe en
  /// Android, iOS y web. En escritorio queda la búsqueda por nombre.
  bool get _puedeEscanear =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (widget.escanearAlEntrar && _puedeEscanear) {
      // Esperamos al primer cuadro: abrir una ruta durante `initState` no es
      // posible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _escanear();
      });
    }
  }

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
      setState(() => _consulta = ConsultaProductoReporte(texto: valor));
    });
  }

  Future<void> _escanear() async {
    final codigo =
        await Navigator.of(context).pushNamed<String>(AppRoutes.reporteEscaner);
    if (codigo == null || !mounted) return;
    _temporizador?.cancel();
    _texto.text = codigo;
    setState(() {
      _abrirAlEncontrar = true;
      _consulta = ConsultaProductoReporte.codigo(codigo);
    });
  }

  void _limpiar() {
    _temporizador?.cancel();
    _texto.clear();
    setState(() {
      _abrirAlEncontrar = false;
      _consulta = const ConsultaProductoReporte();
    });
  }

  /// Con un código escaneado y un único producto, abre su formulario.
  void _alCargarLista(PaginatedState<Producto> estado) {
    if (!_abrirAlEncontrar || !_consulta.esCodigo) return;
    if (estado.status != PaginatedStatus.success) return;
    _abrirAlEncontrar = false;
    if (estado.items.length == 1) _elegir(estado.items.first);
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
              child: BlocListener<PaginatedBloc<Producto>,
                  PaginatedState<Producto>>(
                listener: (context, estado) => _alCargarLista(estado),
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
          ),
        ],
      ),
    );
  }
}
