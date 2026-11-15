import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';

/// Toma la foto con `image_picker`. Es la única clase que conoce ese paquete
/// y `permission_handler`.
///
/// En Android e iOS abre la cámara, después de pedir su permiso (la app lo
/// declara por el escáner de códigos, y con el permiso declarado la cámara
/// del sistema falla si no se concedió). En escritorio y web no hay cámara
/// que abrir: deja elegir un archivo de imagen.
class ImagePickerSelectorFoto implements SelectorFoto {
  final ImagePicker _picker;

  ImagePickerSelectorFoto({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  static bool get _esMovil =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<FotoReporte?> tomar() async {
    try {
      if (_esMovil) await _pedirPermisoCamara();
      final archivo = await _picker.pickImage(
        source: _esMovil ? ImageSource.camera : ImageSource.gallery,
        // Una etiqueta se lee bien a este tamaño y la foto pesa mucho menos.
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (archivo == null) return null;
      return FotoReporte(
        bytes: await archivo.readAsBytes(),
        extension: _extension(archivo.name),
      );
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('No pudimos tomar la foto. Inténtalo de nuevo.');
    }
  }

  Future<void> _pedirPermisoCamara() async {
    final estado = await Permission.camera.request();
    if (estado.isGranted || estado.isLimited) return;
    throw AuthFailure(
      estado.isPermanentlyDenied
          ? 'El permiso de la cámara está bloqueado. Actívalo en los ajustes de la app.'
          : 'Necesitamos el permiso de la cámara para fotografiar la etiqueta.',
    );
  }

  String _extension(String nombre) {
    final punto = nombre.lastIndexOf('.');
    final ext = punto < 0 ? '' : nombre.substring(punto + 1).toLowerCase();
    return switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
  }
}
