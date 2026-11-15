import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';

/// Abre el selector de archivos del sistema y lee el CSV como texto. Es la
/// única clase que conoce el paquete `file_picker`.
class FilePickerSelectorCsv implements SelectorArchivoCsv {
  @override
  Future<ArchivoCsv?> elegir() async {
    try {
      final archivo = await FilePicker.pickFile(
        dialogTitle: 'Elige el archivo CSV',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (archivo == null) return null;
      final bytes = await archivo.readAsBytes();
      // Si el archivo no es UTF-8 limpio, los caracteres raros se reemplazan
      // en vez de abortar la carga.
      return ArchivoCsv(
        nombre: archivo.name,
        contenido: utf8.decode(bytes, allowMalformed: true),
      );
    } on Exception {
      throw const AuthFailure('No pudimos leer el archivo. Inténtalo de nuevo.');
    }
  }
}
