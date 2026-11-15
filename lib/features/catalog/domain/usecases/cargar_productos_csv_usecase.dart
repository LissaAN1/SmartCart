import 'package:smartcart/features/catalog/domain/csv/csv_productos_parser.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

/// HU-10: carga varios productos desde el texto de un CSV.
///
/// Las filas válidas se guardan y las inválidas no detienen la carga: se
/// devuelven con su número y su motivo. Una fila es inválida si incumple las
/// reglas del producto, si su categoría no existe, o si su código de barras
/// ya está en el archivo o ya lo tiene otro producto del comercio.
class CargarProductosCsvUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  CargarProductosCsvUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  Future<ResultadoCargaCsv> call(String contenido) async {
    final comercio = await _comercioAprobado();
    final filas = CsvProductosParser.leer(contenido);

    // El archivo trae el nombre de la categoría; comparamos sin mayúsculas.
    final categorias = {
      for (final c in await _catalogo.categorias())
        c.nombre.trim().toLowerCase(): c.id,
    };

    final errores = <ErrorFilaCsv>[];
    final candidatos = <({int fila, ProductoDatos datos})>[];
    final codigosVistos = <String>{};

    for (final fila in filas) {
      final idCategoria = categorias[fila.categoria.toLowerCase()];
      if (fila.categoria.isNotEmpty && idCategoria == null) {
        errores.add(ErrorFilaCsv(
          fila: fila.numero,
          motivo: 'La categoría "${fila.categoria}" no existe.',
        ));
        continue;
      }
      final datos = normalizarProducto(ProductoDatos(
        nombre: fila.nombre,
        marca: fila.marca,
        codigoBarras: fila.codigoBarras,
        idCategoria: idCategoria ?? '',
      ));
      final error = ProductoValidators.datos(datos);
      if (error != null) {
        errores.add(ErrorFilaCsv(fila: fila.numero, motivo: error));
        continue;
      }
      final codigo = datos.codigoBarras;
      if (codigo != null && !codigosVistos.add(codigo)) {
        errores.add(ErrorFilaCsv(
          fila: fila.numero,
          motivo: 'El código de barras $codigo está repetido en el archivo.',
        ));
        continue;
      }
      candidatos.add((fila: fila.numero, datos: datos));
    }

    final codigos = [
      for (final c in candidatos)
        if (c.datos.codigoBarras != null) c.datos.codigoBarras!,
    ];
    final existentes = codigos.isEmpty
        ? <String>{}
        : await _catalogo.codigosExistentes(comercio.id, codigos);

    final aCargar = <ProductoDatos>[];
    for (final c in candidatos) {
      if (existentes.contains(c.datos.codigoBarras)) {
        errores.add(ErrorFilaCsv(
          fila: c.fila,
          motivo: 'Ya tienes un producto con el código '
              '${c.datos.codigoBarras}.',
        ));
      } else {
        aCargar.add(c.datos);
      }
    }

    if (aCargar.isNotEmpty) {
      await _catalogo.crearVarios(comercio.id, aCargar);
    }
    errores.sort((a, b) => a.fila.compareTo(b.fila));
    return ResultadoCargaCsv(cargados: aCargar.length, errores: errores);
  }
}
