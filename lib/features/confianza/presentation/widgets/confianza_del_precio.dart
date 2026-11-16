import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/confianza/domain/confianza_reglas.dart';
import 'package:smartcart/features/confianza/domain/entities/confianza_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';

/// HU-13: lo que acompaña a un precio para que el cliente sepa qué tan
/// confiable es: el nivel de confianza, si está desactualizado, su fuente
/// (Comercio o Comunidad), cuándo se actualizó y, si se pasa [onReportar], el
/// botón "Reportar precio incorrecto".
///
/// Es reutilizable: el detalle del producto lo usa hoy y las alternativas de
/// carrito (HU-18) lo pueden poner junto a cada precio. Calcula la confianza
/// con `ConfianzaReglas`; [ahora] es la fecha de "hoy" (se inyecta para
/// poder probarlo).
class ConfianzaDelPrecio extends StatelessWidget {
  final FuentePrecio fuente;
  final DateTime actualizadoEn;
  final DateTime ahora;

  /// Si es `null` no se muestra el botón de reporte.
  final VoidCallback? onReportar;

  /// El cliente ya reportó este precio: en vez del botón se muestra
  /// "Reporte enviado".
  final bool reportado;

  /// Se está enviando el reporte: el botón no acepta otro toque.
  final bool enviando;

  const ConfianzaDelPrecio({
    super.key,
    required this.fuente,
    required this.actualizadoEn,
    required this.ahora,
    this.onReportar,
    this.reportado = false,
    this.enviando = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final confianza = ConfianzaReglas.calcular(
      fuente: fuente,
      actualizadoEn: actualizadoEn,
      ahora: ahora,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _EtiquetaNivel(nivel: confianza.nivel),
            if (confianza.desactualizado) const _EtiquetaDesactualizado(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fuente: ${fuente.etiqueta}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.texto,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Actualizado ${fechaHora(actualizadoEn)} (${confianza.antiguedad})',
          style: TextStyle(fontSize: 12, color: t.textoGris),
        ),
        if (reportado) ...[
          const SizedBox(height: 8),
          const _ReporteEnviado(),
        ] else if (onReportar != null) ...[
          const SizedBox(height: 4),
          _BotonReportar(onTap: enviando ? null : onReportar),
        ],
      ],
    );
  }
}

/// "Confianza alta", "Confianza media" o "Confianza baja", en verde, ámbar o
/// rojo.
class _EtiquetaNivel extends StatelessWidget {
  final NivelConfianza nivel;

  const _EtiquetaNivel({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final texto = 'Confianza ${nivel.etiqueta.toLowerCase()}';
    return switch (nivel) {
      NivelConfianza.alto => EtiquetaEstado.exito(texto),
      NivelConfianza.medio => EtiquetaEstado.pendiente(texto),
      NivelConfianza.bajo => EtiquetaEstado.error(texto),
    };
  }
}

class _EtiquetaDesactualizado extends StatelessWidget {
  const _EtiquetaDesactualizado();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return EtiquetaEstado(
      texto: 'Desactualizado',
      color: t.textoGris,
      fondo: t.textoGris.withValues(alpha: 0.12),
      conBorde: true,
      icono: Icons.schedule,
    );
  }
}

/// El botón de texto de HU-13, escenario 3. El texto puede pasar a otra línea
/// en pantallas angostas en vez de salirse.
class _BotonReportar extends StatelessWidget {
  final VoidCallback? onTap;

  const _BotonReportar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final color = onTap == null ? t.textoGris : ColoresEstado.rojo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Reportar precio incorrecto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReporteEnviado extends StatelessWidget {
  const _ReporteEnviado();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 18, color: ColoresEstado.verde),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Reporte enviado',
            style: TextStyle(fontSize: 13, color: t.textoGris),
          ),
        ),
      ],
    );
  }
}
