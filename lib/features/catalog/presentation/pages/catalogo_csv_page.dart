import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';

/// HU-10: carga de varios productos desde un archivo CSV. Explica el formato,
/// deja elegir el archivo y muestra cuántos productos se cargaron y qué filas
/// fallaron con su motivo.
///
/// Necesita un `CargaCsvBloc` arriba en el árbol (lo provee `AppRouter`).
class CatalogoCsvPage extends StatelessWidget {
  const CatalogoCsvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Cargar por archivo',
        mostrarAtras: true,
      ),
      cuerpo: BlocBuilder<CargaCsvBloc, CargaCsvState>(
        builder: (context, state) {
          final cargando = state.status == CargaCsvStatus.cargando;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              const _FormatoEsperado(),
              const SizedBox(height: 20),
              BotonPrimario(
                texto: 'Elegir archivo CSV',
                cargando: cargando,
                onTap: () =>
                    context.read<CargaCsvBloc>().add(CargaCsvArchivoSolicitado()),
              ),
              const SizedBox(height: 20),
              if (state.status == CargaCsvStatus.failed)
                ErrorMessage(
                  message: state.errorMessage ?? 'No pudimos cargar el archivo.',
                ),
              if (state.status == CargaCsvStatus.listo)
                _Resultado(
                  archivo: state.archivo ?? '',
                  resultado: state.resultado!,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FormatoEsperado extends StatelessWidget {
  const _FormatoEsperado();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cómo debe ser el archivo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.texto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un CSV con una fila de encabezado y un producto por fila. '
            'Las columnas "nombre" y "categoria" son obligatorias; "marca" y '
            '"codigo_barras" son opcionales. Puede separarse con coma o con '
            'punto y coma. Categorías: Super, Frutas, Lácteos, Aseo, Café y '
            'Panadería.',
            style: TextStyle(fontSize: 13.5, height: 1.35, color: t.textoGris),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.suave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'nombre,marca,codigo_barras,categoria\n'
              'Arroz blanco 500 g,Diana,7701234567890,Super',
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'monospace',
                color: t.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  final String archivo;
  final ResultadoCargaCsv resultado;

  const _Resultado({required this.archivo, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final fallidas = resultado.errores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          archivo,
          style: TextStyle(fontSize: 12.5, color: t.textoGris),
        ),
        const SizedBox(height: 6),
        Text(
          resultado.cargados == 1
              ? 'Se cargó 1 producto.'
              : 'Se cargaron ${resultado.cargados} productos.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: t.texto,
          ),
        ),
        if (fallidas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            fallidas.length == 1
                ? '1 fila no se pudo cargar:'
                : '${fallidas.length} filas no se pudieron cargar:',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: ColoresEstado.rojo,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in fallidas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColoresEstado.rojoSuave,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Fila ${e.fila}: ${e.motivo}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: ColoresEstado.rojo,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
