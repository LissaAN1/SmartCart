import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// HU-14: lee el código de barras de un producto con la cámara y lo devuelve
/// al cerrarse (`Navigator.pop(codigo)`). Solo se abre en Android, iOS y web;
/// `mobile_scanner` pide el permiso de la cámara por su cuenta.
class EscanerCodigoPage extends StatefulWidget {
  const EscanerCodigoPage({super.key});

  @override
  State<EscanerCodigoPage> createState() => _EscanerCodigoPageState();
}

class _EscanerCodigoPageState extends State<EscanerCodigoPage> {
  /// Los códigos que llevan los productos: EAN-13/EAN-8 y UPC.
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  /// El lector detecta el mismo código muchas veces por segundo: solo
  /// devolvemos el primero.
  bool _leido = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_leido) return;
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue;
      if (valor != null && valor.isNotEmpty) {
        _leido = true;
        Navigator.of(context).pop(valor);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanea el código de barras'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _alDetectar,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No pudimos abrir la cámara. Revisa que le diste permiso a '
                  'la app e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Apunta la cámara al código del producto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
