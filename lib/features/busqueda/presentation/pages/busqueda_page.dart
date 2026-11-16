import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/usecases/buscar_productos_usecase.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/busqueda_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/widgets/resultado_card.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';

/// Abre el escáner y devuelve el código leído, o `null` si se canceló.
typedef Escanear = Future<String?> Function(BuildContext context);

Future<String?> _abrirEscaner(BuildContext context) =>
    Navigator.of(context).pushNamed<String>(AppRoutes.escaner);

/// HU-12: búsqueda de productos del cliente. Busca por nombre o marca
/// (escenarios 1 y 3) o escaneando el código de barras (escenario 2). Cada
/// resultado muestra el rango de precios y en cuántos establecimientos está;
/// al tocarlo se abre el producto con sus precios.
///
/// Necesita arriba en el árbol un `PaginatedBloc<ResultadoBusqueda>` (un
/// `BusquedaBloc`, lo provee `AppRouter`).
class BusquedaPage extends StatefulWidget {
  /// Texto con el que llega desde el Home (puede venir vacío).
  final String textoInicial;

  /// Las pruebas lo reemplazan; en la app abre la cámara.
  final Escanear escanear;

  const BusquedaPage({
    super.key,
    this.textoInicial = '',
    this.escanear = _abrirEscaner,
  });

  @override
  State<BusquedaPage> createState() => _BusquedaPageState();
}

class _BusquedaPageState extends State<BusquedaPage> {
  /// Espera tras la última tecla antes de buscar.
  static const _pausa = Duration(milliseconds: 400);

  late final _buscador = TextEditingController(text: widget.textoInicial);
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  void _buscar() {
    _espera?.cancel();
    if (!mounted) return;
    // Redibuja para que el mensaje de lista vacía corresponda al texto.
    setState(() {});
    context
        .read<PaginatedBloc<ResultadoBusqueda>>()
        .add(BusquedaCambiada(_buscador.text));
  }

  void _alEscribir(String _) {
    _espera?.cancel();
    _espera = Timer(_pausa, _buscar);
  }

  void _abrir(ConsultaProducto consulta) {
    // HU-13: si esta pantalla tiene el carrito y los favoritos del cliente,
    // el detalle los recibe para poder agregar y guardar desde él.
    final cliente = clienteBlocsOrNull(context);
    Navigator.of(context).pushNamed(
      AppRoutes.busquedaDetalle,
      arguments: cliente == null ? consulta : ConBlocsDelCliente(consulta, cliente),
    );
  }

  Future<void> _escanear() async {
    final codigo = await widget.escanear(context);
    if (!mounted || codigo == null || codigo.trim().isEmpty) return;
    _abrir(ConsultaPorCodigo(codigo.trim()));
  }

  String get _mensajeVacio =>
      _buscador.text.trim().length < BuscarProductosUseCase.minimoLetras
          ? 'Escribe el nombre o la marca del producto, o escanea su código '
              'de barras.'
          : 'No encontramos productos';

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Buscar productos',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Escanear código de barras',
            icon: Icon(Icons.qr_code_scanner, color: t.texto),
            onPressed: _escanear,
          ),
        ],
      ),
      cuerpo: PaginatedListView<ResultadoBusqueda>(
        emptyMessage: _mensajeVacio,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        encabezado: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('buscador-productos'),
                controller: _buscador,
                autofocus: widget.textoInicial.isEmpty,
                onChanged: _alEscribir,
                onSubmitted: (_) => _buscar(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Ej. arroz, leche, Diana',
                  prefixIcon: Icon(Icons.search, color: t.textoGris),
                  filled: true,
                  fillColor: t.superficie,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: t.borde),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: t.borde),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BotonSuave(
                texto: 'Escanear código de barras',
                icono: Icons.qr_code_scanner,
                onTap: _escanear,
              ),
            ],
          ),
        ),
        itemBuilder: (context, resultado) => ResultadoCard(
          resultado: resultado,
          onTap: () => _abrir(ConsultaPorClave(resultado.clave)),
        ),
      ),
    );
  }
}
