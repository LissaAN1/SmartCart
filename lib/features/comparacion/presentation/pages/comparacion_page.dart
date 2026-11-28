import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/comparacion/domain/comparador_carrito.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/comparacion_formato.dart';
import 'package:smartcart/features/comparacion/presentation/pages/alternativa_detalle_page.dart';
import 'package:smartcart/features/ubicacion/presentation/formato_distancia.dart';

/// HU-18: "Tu carrito optimizado". El cliente elige qué priorizar y,
/// opcionalmente, una distancia máxima, y ve una alternativa por criterio
/// para el carrito completo. Necesita un `ComparacionBloc` arriba en el
/// árbol, y el carrito y los favoritos para "Explorar productos" (los da
/// `AppRouter`).
class ComparacionPage extends StatelessWidget {
  const ComparacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.cliente,
      barraSuperior: const BarraTituloRol(
        titulo: 'Tu carrito optimizado',
        mostrarAtras: true,
      ),
      cuerpo: BlocBuilder<ComparacionBloc, ComparacionState>(
        builder: (context, state) => switch (state.status) {
          ComparacionStatus.initial ||
          ComparacionStatus.cargando =>
            const Center(child: CircularProgressIndicator()),
          ComparacionStatus.falloCarga => _FalloCarga(mensaje: state.errorMessage),
          ComparacionStatus.vacia => const _CarritoVacio(),
          ComparacionStatus.lista => _Comparacion(state: state),
        },
      ),
    );
  }
}

class _FalloCarga extends StatelessWidget {
  final String? mensaje;

  const _FalloCarga({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorMessage(message: mensaje ?? 'No pudimos comparar tu carrito.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<ComparacionBloc>().add(ComparacionIniciada()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escenario 6: sin productos no hay alternativas.
class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: t.textoGris),
            const SizedBox(height: 14),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: t.texto),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega productos para comparar tu compra entre comercios.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textoGris),
            ),
            const SizedBox(height: 20),
            BotonPrimario(
              texto: 'Explorar productos',
              expandido: false,
              onTap: () => context.abrirExplorar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Comparacion extends StatelessWidget {
  final ComparacionState state;

  const _Comparacion({required this.state});

  Future<void> _configurarUbicacion(BuildContext context) async {
    final bloc = context.read<ComparacionBloc>();
    await Navigator.of(context).pushNamed(AppRoutes.mapaComercios);
    bloc.add(ComparacionUbicacionRecargada());
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final bloc = context.read<ComparacionBloc>();
    final resultado = state.resultado!;
    final productos = state.lineas.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        Text(
          'Comparamos ${productos == 1 ? 'tu producto' : 'tus $productos productos'} '
          'en los comercios aprobados con el precio de hoy.',
          style: TextStyle(fontSize: 14, color: t.textoGris),
        ),
        const TituloSeccion(titulo: 'QUÉ QUIERES PRIORIZAR'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in CriterioCompra.values)
              ChoiceChip(
                avatar: Icon(iconoCriterio(c), size: 18),
                label: Text(c.etiqueta),
                selected: c == state.criterio,
                selectedColor: t.suave,
                onSelected: (_) => bloc.add(ComparacionCriterioElegido(c)),
              ),
          ],
        ),
        const TituloSeccion(titulo: 'DISTANCIA MÁXIMA'),
        if (state.ubicacion == null)
          _SinUbicacion(onConfigurar: () => _configurarUbicacion(context))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sin límite'),
                selected: state.distanciaMaxM == null,
                selectedColor: t.suave,
                onSelected: (_) => bloc.add(ComparacionDistanciaElegida(null)),
              ),
              for (final m in ComparacionReglas.distanciasMaximasM)
                ChoiceChip(
                  label: Text(formatoRadio(m)),
                  selected: state.distanciaMaxM == m,
                  selectedColor: t.suave,
                  onSelected: (_) => bloc.add(ComparacionDistanciaElegida(m)),
                ),
            ],
          ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 10),
          ErrorMessage(message: state.errorMessage!),
        ],
        if (resultado.faltantes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _AvisoFaltantes(
            nombres: [for (final l in resultado.faltantes) l.nombre],
            todos: resultado.sinAlternativas,
          ),
        ],
        if (!resultado.sinAlternativas) ...[
          const TituloSeccion(titulo: 'ALTERNATIVAS'),
          for (final a in state.alternativas)
            _AlternativaCard(
              alternativa: a,
              destacada: a.criterio == state.criterio,
              onVerDetalle: () => Navigator.of(context).pushNamed(
                AppRoutes.comparacionDetalle,
                arguments: AlternativaArgs(
                  alternativa: a,
                  cliente: state.ubicacion?.ubicacion,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SinUbicacion extends StatelessWidget {
  final VoidCallback onConfigurar;

  const _SinUbicacion({required this.onConfigurar});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      radio: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configura tu ubicación para ver la distancia de cada alternativa '
            'y comparar solo los comercios cercanos.',
            style: TextStyle(fontSize: 13.5, color: t.textoGris),
          ),
          TextButton.icon(
            onPressed: onConfigurar,
            icon: const Icon(Icons.place_outlined, size: 18),
            label: const Text('Configurar ubicación'),
          ),
        ],
      ),
    );
  }
}

/// Escenario 5: qué productos no están en ningún comercio que cumpla.
class _AvisoFaltantes extends StatelessWidget {
  final List<String> nombres;

  /// Ningún producto se encontró: no hay alternativas.
  final bool todos;

  const _AvisoFaltantes({required this.nombres, required this.todos});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final lista = nombres.join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresEstado.ambar.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresEstado.ambar.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: ColoresEstado.ambar),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              todos
                  ? 'No encontramos tus productos disponibles en los comercios '
                      'que cumplen tu búsqueda: $lista. Prueba sin límite de '
                      'distancia.'
                  : 'No encontramos disponible: $lista. Las alternativas se '
                      'calcularon con los demás productos.',
              style: TextStyle(fontSize: 13.5, color: t.texto),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativaCard extends StatelessWidget {
  final Alternativa alternativa;
  final bool destacada;
  final VoidCallback onVerDetalle;

  const _AlternativaCard({
    required this.alternativa,
    required this.destacada,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final a = alternativa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: destacada ? t.suave.withValues(alpha: 0.45) : t.fondo,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: destacada ? t.primario : t.borde,
            width: destacada ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: destacada ? t.primario : t.suave,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconoCriterio(a.criterio),
                    color: destacada ? Colors.white : t.primarioOscuro,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.criterio.etiqueta,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: t.texto),
                  ),
                ),
              ],
            ),
            if (destacada || a.ahorro > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (destacada) const EtiquetaEstado.info('Tu criterio'),
                  if (a.ahorro > 0)
                    EtiquetaEstado.exito('Ahorras ${formatoCop(a.ahorro)}'),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(a.criterio.descripcion,
                style: TextStyle(fontSize: 13.5, color: t.textoGris)),
            Divider(height: 22, color: t.borde),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _Dato(
                  titulo: 'TOTAL ESTIMADO',
                  valor: formatoCop(a.total),
                  grande: true,
                ),
                _Dato(
                  titulo: 'COMERCIOS',
                  valor: '${a.establecimientos}',
                ),
                _Dato(
                  titulo: 'DISTANCIA',
                  valor: textoDistancia(a.distanciaTotalM),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onVerDetalle,
                child: const Text('Ver detalle ›'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool grande;

  const _Dato({required this.titulo, required this.valor, this.grande = false});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: t.textoGris)),
        const SizedBox(height: 2),
        Text(valor,
            style: TextStyle(
                fontSize: grande ? 22 : 16,
                fontWeight: FontWeight.w800,
                color: grande ? t.primarioOscuro : t.texto)),
      ],
    );
  }
}
