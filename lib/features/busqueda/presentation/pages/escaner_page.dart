import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

/// HU-12 · escenario 2: escanea el código de barras de un producto con la
/// cámara y se cierra devolviendo el código. La primera vez el sistema pide
/// permiso de cámara; si se niega, se puede escribir el código a mano.
///
/// Es la única pantalla que conoce `mobile_scanner`.
class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  final _controller = MobileScannerController(
    // Los códigos de productos: EAN-13, EAN-8, UPC-A y UPC-E.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Evita cerrar dos veces si la cámara lee el código varias veces.
  bool _listo = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_listo) return;
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue?.trim();
      if (valor != null && ProductoValidators.codigoBarras(valor) == null) {
        _listo = true;
        Navigator.of(context).pop(valor);
        return;
      }
    }
  }

  Future<void> _escribirCodigo() async {
    final controller = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escribe el código de barras'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '7701234567890'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || codigo == null || codigo.isEmpty) return;
    _listo = true;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return Scaffold(
      backgroundColor: t.texto,
      appBar: AppBar(
        backgroundColor: t.texto,
        foregroundColor: t.superficie,
        title: const Text('Escanear código'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _alDetectar,
            errorBuilder: (context, error) => _ErrorCamara(
              permisoNegado:
                  error.errorCode == MobileScannerErrorCode.permissionDenied,
              onEscribir: _escribirCodigo,
            ),
          ),
          // Marco de referencia y ayuda.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: t.primario, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              children: [
                Text(
                  'Apunta al código de barras del producto',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.superficie, fontSize: 15),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _escribirCodigo,
                  style: TextButton.styleFrom(foregroundColor: t.superficie),
                  child: const Text('Escribir el código'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCamara extends StatelessWidget {
  final bool permisoNegado;
  final VoidCallback onEscribir;

  const _ErrorCamara({required this.permisoNegado, required this.onEscribir});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return ColoredBox(
      color: t.texto,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 48, color: t.superficie),
              const SizedBox(height: 12),
              Text(
                permisoNegado
                    ? 'Necesitamos permiso para usar la cámara. Actívalo en '
                        'los ajustes del teléfono o escribe el código.'
                    : 'No pudimos abrir la cámara. Puedes escribir el código.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.superficie, fontSize: 15),
              ),
              const SizedBox(height: 16),
              // Esta pantalla no usa PantallaRol, así que el color se pasa
              // directo en vez de usar BotonPrimario.
              FilledButton(
                onPressed: onEscribir,
                style: FilledButton.styleFrom(backgroundColor: t.primario),
                child: const Text('Escribir el código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
