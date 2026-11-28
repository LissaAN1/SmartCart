import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/ui/pagination/paginated_list_view.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/colaborador/presentation/widgets/colaborador_widgets.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/puntos/presentation/widgets/movimiento_puntos_item.dart';

/// HU-16: puntos, nivel, reputación e historial de puntos del colaborador. El
/// historial se carga por páginas.
///
/// Necesita un `ResumenPuntosBloc` y un `PaginatedBloc<MovimientoPuntos>`
/// arriba en el árbol (los provee `AppRouter`).
class MisPuntosPage extends StatelessWidget {
  const MisPuntosPage({super.key});

  void _recargar(BuildContext context) {
    context.read<ResumenPuntosBloc>().add(ResumenPuntosStarted());
    context.read<PaginatedBloc<MovimientoPuntos>>().add(PaginatedStarted());
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: 'Mis puntos',
        mostrarAtras: true,
        acciones: [
          IconButton(
            tooltip: 'Actualizar',
            icon: Icon(Icons.refresh, color: t.texto),
            onPressed: () => _recargar(context),
          ),
        ],
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: BlocBuilder<ResumenPuntosBloc, ResumenPuntosState>(
              builder: (context, state) => _Resumen(state: state),
            ),
          ),
          const TituloSeccion(
            titulo: 'HISTORIAL DE PUNTOS',
            padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
          ),
          Expanded(
            child: PaginatedListView<MovimientoPuntos>(
              emptyMessage: 'Aún no tienes puntos. Los ganas cuando uno de '
                  'tus reportes de precio es validado.',
              itemBuilder: (context, movimiento) =>
                  MovimientoPuntosItem(movimiento: movimiento),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final ResumenPuntosState state;

  const _Resumen({required this.state});

  @override
  Widget build(BuildContext context) {
    final resumen = state.resumen;
    if (resumen == null) {
      if (state.status == ResumenPuntosStatus.failure) {
        return ErrorMessage(
            message: state.errorMessage ?? 'No pudimos cargar tus puntos.');
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        TarjetaPuntos(
          puntos: resumen.saldo,
          nivel: 'Nivel ${resumen.nivel.nombre}',
          siguienteNivel:
              resumen.siguienteNivel?.nombre ?? 'el nivel máximo',
          progreso: resumen.progreso,
          onCanjear: () => mostrarProximamente(context),
        ),
        const SizedBox(height: 12),
        _FilaDato(
          icono: Icons.trending_up,
          etiqueta: 'Siguiente nivel',
          valor: resumen.siguienteNivel == null
              ? 'Ya eres Experto'
              : '${resumen.siguienteNivel!.nombre}: te faltan '
                  '${resumen.puntosParaSiguiente} pts',
        ),
        _FilaDato(
          icono: Icons.verified_outlined,
          etiqueta: 'Reputación',
          valor: '${_formato(resumen.reputacion)} / 100',
        ),
        if (state.status == ResumenPuntosStatus.failure &&
            state.errorMessage != null) ...[
          const SizedBox(height: 8),
          ErrorMessage(message: state.errorMessage!),
        ],
      ],
    );
  }

  String _formato(num valor) => valor == valor.roundToDouble()
      ? valor.toInt().toString()
      : valor.toStringAsFixed(1);
}

class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 20, color: t.primario),
          const SizedBox(width: 10),
          Text(etiqueta, style: TextStyle(fontSize: 14, color: t.textoGris)),
          const SizedBox(width: 12),
          // El valor puede ser largo ("Experto: te faltan 380 pts"): ocupa lo
          // que sobra, alineado a la derecha, y baja de línea si hace falta.
          Expanded(
            child: Text(valor,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: t.texto)),
          ),
        ],
      ),
    );
  }
}
