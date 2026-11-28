import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/calificaciones/domain/calificacion_reglas.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_args.dart';

/// HU-25: el cliente califica al comercio o al repartidor de una orden
/// completada con 1 a 5 estrellas y un comentario opcional. Al enviarse se
/// cierra devolviendo `true`.
///
/// Necesita un `CalificarOrdenBloc` arriba en el árbol (lo da `AppRouter`).
class CalificarOrdenPage extends StatelessWidget {
  final CalificarOrdenArgs args;

  const CalificarOrdenPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return PantallaRol(
      tema: t,
      barraSuperior: BarraTituloRol(
        titulo: args.tipo.titulo,
        mostrarAtras: true,
      ),
      cuerpo: BlocConsumer<CalificarOrdenBloc, CalificarOrdenState>(
        listenWhen: (previous, current) =>
            previous.status != CalificarOrdenStatus.enviada &&
            current.status == CalificarOrdenStatus.enviada,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                const SnackBar(content: Text('¡Gracias por tu calificación!')));
          Navigator.of(context).pop(true);
        },
        builder: (context, state) {
          final bloc = context.read<CalificarOrdenBloc>();
          final enviando = state.status == CalificarOrdenStatus.enviando;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Text(
                'Orden #${args.numeroOrden} · ${args.comercio}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.textoGris,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                args.tipo == TipoCalificacion.comercio
                    ? '¿Cómo fue tu experiencia con el comercio?'
                    : '¿Cómo fue la entrega?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.texto,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= CalificacionReglas.estrellasMax; i++)
                    IconButton(
                      tooltip: i == 1 ? '1 estrella' : '$i estrellas',
                      iconSize: 40,
                      icon: Icon(
                        i <= state.estrellas
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: t.primario,
                      ),
                      onPressed: enviando
                          ? null
                          : () => bloc.add(EstrellasElegidas(i)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                enabled: !enviando,
                maxLines: 4,
                minLines: 3,
                maxLength: CalificacionReglas.comentarioMax,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (texto) => bloc.add(ComentarioCambiado(texto)),
                decoration: InputDecoration(
                  labelText: 'Comentario (opcional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: ColoresEstado.rojo,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              BotonPrimario(
                texto: 'Enviar calificación',
                cargando: enviando,
                onTap: state.puedeEnviar
                    ? () => bloc.add(CalificacionEnviada())
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
