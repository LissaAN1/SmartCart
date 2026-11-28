import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/formato_distancia.dart';
import 'package:smartcart/features/ubicacion/presentation/widgets/mapa_establecimientos.dart';

/// HU-19: la ubicación y el radio de búsqueda del cliente, con los comercios
/// aprobados que quedan dentro en un mapa y en una lista. Necesita un
/// `MapaComerciosBloc` arriba en el árbol (lo da `AppRouter`).
class MapaComerciosPage extends StatelessWidget {
  const MapaComerciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.cliente,
      barraSuperior: const BarraTituloRol(
        titulo: 'Comercios cercanos',
        mostrarAtras: true,
      ),
      cuerpo: BlocConsumer<MapaComerciosBloc, MapaComerciosState>(
        listenWhen: (previous, current) =>
            current.aviso != null && current.aviso!.id != previous.aviso?.id,
        listener: (context, state) {
          if (esPantallaActual(context)) mostrarAviso(context, state.aviso!);
        },
        builder: (context, state) => switch (state.status) {
          MapaStatus.initial ||
          MapaStatus.cargando =>
            const Center(child: CircularProgressIndicator()),
          MapaStatus.falloCarga => _FalloCarga(mensaje: state.errorMessage),
          MapaStatus.sinUbicacion => _SinUbicacion(state: state),
          MapaStatus.listo => _Mapa(state: state),
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
            ErrorMessage(
                message: mensaje ?? 'No pudimos cargar tu ubicación.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<MapaComerciosBloc>().add(MapaIniciado()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escenario 2: no hay ubicación guardada y el GPS no la dio.
class _SinUbicacion extends StatelessWidget {
  final MapaComerciosState state;

  const _SinUbicacion({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final bloc = context.read<MapaComerciosBloc>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Icon(Icons.location_off_outlined, size: 52, color: t.textoGris),
        const SizedBox(height: 12),
        Text(
          'Escribe tu dirección',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: t.texto),
        ),
        const SizedBox(height: 6),
        Text(
          'Sin tu ubicación no podemos mostrarte los comercios cercanos. '
          'Con tu dirección también funciona.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: t.textoGris),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorMessage(message: state.errorMessage!),
        ],
        const SizedBox(height: 20),
        FormularioDireccion(
          ocupado: state.ocupado,
          onBuscar: (texto) => bloc.add(MapaDireccionBuscada(texto)),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: state.ocupado
              ? null
              : () => bloc.add(MapaUbicacionActualSolicitada()),
          icon: const Icon(Icons.my_location),
          label: const Text('Intentar con mi ubicación'),
        ),
      ],
    );
  }
}

class _Mapa extends StatelessWidget {
  final MapaComerciosState state;

  const _Mapa({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final preferencia = state.preferencia!;
    final comercios = state.comercios;
    final radio = formatoRadio(preferencia.radioM);
    return Column(
      children: [
        if (state.ocupado) const LinearProgressIndicator(minHeight: 3),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              MapaEstablecimientos(
                centro: preferencia.ubicacion,
                radioM: preferencia.radioM,
                puntos: [
                  for (final c in comercios)
                    PuntoMapa(ubicacion: c.ubicacion, titulo: c.nombre),
                ],
              ),
              const SizedBox(height: 14),
              _UbicacionActual(
                preferencia: preferencia,
                ocupado: state.ocupado,
              ),
              const TituloSeccion(titulo: 'RADIO DE BÚSQUEDA'),
              _SelectorRadio(
                radioM: preferencia.radioM,
                ocupado: state.ocupado,
              ),
              TituloSeccion(
                titulo: comercios.isEmpty
                    ? 'COMERCIOS A MENOS DE ${radio.toUpperCase()}'
                    : '${comercios.length} ${comercios.length == 1 ? 'COMERCIO' : 'COMERCIOS'} A MENOS DE ${radio.toUpperCase()}',
              ),
              if (comercios.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay comercios aprobados a menos de $radio. '
                    'Amplía el radio para ver más.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: t.textoGris),
                  ),
                )
              else
                for (final c in comercios) _ComercioItem(comercio: c),
            ],
          ),
        ),
      ],
    );
  }
}

/// De dónde sale la ubicación (GPS o dirección) y cómo cambiarla.
class _UbicacionActual extends StatelessWidget {
  final PreferenciaUbicacion preferencia;
  final bool ocupado;

  const _UbicacionActual({required this.preferencia, required this.ocupado});

  Future<void> _escribirDireccion(BuildContext context) async {
    final bloc = context.read<MapaComerciosBloc>();
    final texto = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escribe tu dirección',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            FormularioDireccion(
              inicial: preferencia.direccion,
              onBuscar: (texto) => Navigator.pop(ctx, texto),
            ),
          ],
        ),
      ),
    );
    if (texto != null) bloc.add(MapaDireccionBuscada(texto));
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final bloc = context.read<MapaComerciosBloc>();
    return TarjetaSuave(
      radio: 20,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                preferencia.desdeGps ? Icons.my_location : Icons.place_outlined,
                color: t.primarioOscuro,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  preferencia.direccion ?? 'Tu ubicación actual (GPS)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.texto),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: ocupado
                    ? null
                    : () => bloc.add(MapaUbicacionActualSolicitada()),
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Usar mi ubicación'),
              ),
              TextButton.icon(
                onPressed: ocupado ? null : () => _escribirDireccion(context),
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Escribir dirección'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorRadio extends StatelessWidget {
  final int radioM;
  final bool ocupado;

  const _SelectorRadio({required this.radioM, required this.ocupado});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final bloc = context.read<MapaComerciosBloc>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opcion in RadioReglas.opcionesM)
          ChoiceChip(
            label: Text(formatoRadio(opcion)),
            selected: opcion == radioM,
            selectedColor: t.suave,
            onSelected: ocupado || opcion == radioM
                ? null
                : (_) => bloc.add(MapaRadioCambiado(opcion)),
          ),
      ],
    );
  }
}

class _ComercioItem extends StatelessWidget {
  final EstablecimientoCercano comercio;

  const _ComercioItem({required this.comercio});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final lugar = [comercio.direccion, comercio.ciudad]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TarjetaSuave(
        radio: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: t.suave, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.storefront_outlined, color: t.primarioOscuro),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comercio.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.texto)),
                  if (lugar.isNotEmpty)
                    Text(lugar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: t.textoGris)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatoDistancia(comercio.distanciaM),
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.primarioOscuro),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo para escribir la dirección y buscarla. La validación la hace el
/// caso de uso; aquí solo se envía el texto.
class FormularioDireccion extends StatefulWidget {
  final String? inicial;
  final bool ocupado;
  final ValueChanged<String> onBuscar;

  const FormularioDireccion({
    super.key,
    this.inicial,
    this.ocupado = false,
    required this.onBuscar,
  });

  @override
  State<FormularioDireccion> createState() => _FormularioDireccionState();
}

class _FormularioDireccionState extends State<FormularioDireccion> {
  late final _texto = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar() => widget.onBuscar(_texto.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _texto,
          maxLength: RadioReglas.direccionMax,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _enviar(),
          decoration: const InputDecoration(
            labelText: 'Dirección',
            hintText: 'Calle 5 # 38-20, Cali',
            prefixIcon: Icon(Icons.place_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        BotonPrimario(
          texto: 'Buscar dirección',
          cargando: widget.ocupado,
          onTap: _enviar,
        ),
      ],
    );
  }
}
