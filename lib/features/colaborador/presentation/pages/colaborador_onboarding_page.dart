import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_event.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_state.dart';

/// HU-06: onboarding del modo Colaborador. Dos pasos en una sola pantalla:
/// una guía corta de cómo reportar un precio y las condiciones de uso con el
/// botón "Activar". Al activarse devuelve el perfil actualizado a quien la
/// abrió (`Navigator.pop(context, profile)`).
class ColaboradorOnboardingPage extends StatefulWidget {
  const ColaboradorOnboardingPage({super.key});

  @override
  State<ColaboradorOnboardingPage> createState() =>
      _ColaboradorOnboardingPageState();
}

class _ColaboradorOnboardingPageState extends State<ColaboradorOnboardingPage> {
  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _maxContentWidth = 480;

  bool _enCondiciones = false;

  static const _pasos = [
    (
      Icons.search,
      'Encuentra el producto',
      'Ubícalo en la tienda donde estás y confirma el nombre y la marca.',
    ),
    (
      Icons.photo_camera_outlined,
      'Toma una foto del precio',
      'Fotografía la etiqueta para que otras personas puedan confiar en el dato.',
    ),
    (
      Icons.stars_outlined,
      'Envía el reporte y gana puntos',
      'Cada reporte verificado suma puntos, sube tu nivel y mejora tu reputación.',
    ),
  ];

  static const _condiciones = [
    'Reportaré solo precios reales que vea en el establecimiento.',
    'Las fotos que envíe corresponderán a la etiqueta del producto.',
    'No enviaré reportes falsos ni duplicados para ganar puntos.',
    'SmartCart puede revisar mis reportes y ajustar mis puntos y reputación.',
  ];

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    return TemaRolScope(
      tema: t,
      child: BlocListener<ColaboradorOnboardingBloc,
          ColaboradorOnboardingState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == ColaboradorOnboardingStatus.success) {
            Navigator.of(context).pop(state.profile);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: BotonAtras(
              onTap: _enCondiciones
                  ? () => setState(() => _enCondiciones = false)
                  : () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              'Modo Colaborador',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: t.texto,
              ),
            ),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _enCondiciones ? _buildCondiciones(t) : _buildGuia(t),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuia(TemaRol t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          'Así funciona reportar un precio',
          style: TextStyle(
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: t.texto,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Con la misma cuenta podrás ayudar a la comunidad y ganar '
          'incentivos. Sigues siendo cliente.',
          style: TextStyle(fontSize: 14, color: t.textoGris),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < _pasos.length; i++) ...[
          _PasoGuia(
            numero: i + 1,
            icono: _pasos[i].$1,
            titulo: _pasos[i].$2,
            descripcion: _pasos[i].$3,
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 12),
        BotonPrimario(
          texto: 'Continuar',
          iconoFinal: Icons.arrow_forward,
          onTap: () => setState(() => _enCondiciones = true),
        ),
      ],
    );
  }

  Widget _buildCondiciones(TemaRol t) {
    return BlocBuilder<ColaboradorOnboardingBloc, ColaboradorOnboardingState>(
      builder: (context, state) {
        final loading = state.status == ColaboradorOnboardingStatus.loading;
        final error = state.status == ColaboradorOnboardingStatus.failure
            ? state.errorMessage
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Condiciones de uso',
              style: TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Para activar el modo Colaborador debes aceptarlas.',
              style: TextStyle(fontSize: 14, color: t.textoGris),
            ),
            const SizedBox(height: 18),
            for (final condicion in _condiciones)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 20, color: t.primario),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        condicion,
                        style: TextStyle(
                            fontSize: 14, height: 1.3, color: t.texto),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: loading
                  ? null
                  : () => context
                      .read<ColaboradorOnboardingBloc>()
                      .add(TermsToggled(!state.termsAccepted)),
              child: Row(
                children: [
                  Checkbox(
                    value: state.termsAccepted,
                    activeColor: t.primario,
                    onChanged: loading
                        ? null
                        : (v) => context
                            .read<ColaboradorOnboardingBloc>()
                            .add(TermsToggled(v ?? false)),
                  ),
                  Expanded(
                    child: Text(
                      'Acepto las condiciones de uso del modo Colaborador',
                      style: TextStyle(fontSize: 13.5, color: t.texto),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              ErrorMessage(message: error),
              const SizedBox(height: 16),
            ],
            BotonPrimario(
              texto: 'Activar',
              cargando: loading,
              onTap: () => context
                  .read<ColaboradorOnboardingBloc>()
                  .add(ActivationSubmitted()),
            ),
          ],
        );
      },
    );
  }
}

class _PasoGuia extends StatelessWidget {
  final int numero;
  final IconData icono;
  final String titulo;
  final String descripcion;

  const _PasoGuia({
    required this.numero,
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
            child: Icon(icono, color: t.primario),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero. $titulo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.3, color: t.textoGris),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
