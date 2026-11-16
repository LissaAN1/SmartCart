import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';

/// Un punto de la gráfica: el precio que regía en una fecha.
class PuntoPrecio {
  final DateTime fecha;
  final int precio;

  const PuntoPrecio(this.fecha, this.precio);
}

/// Puntos de la gráfica de los últimos [meses] meses, en orden de fecha. Arranca
/// con el precio que regía al empezar la ventana y termina con el actual en
/// [ahora]. Vacío si el producto no tiene precio.
List<PuntoPrecio> puntosDeHistorial(
  FichaPrecio ficha,
  DateTime ahora, {
  int meses = 4,
}) {
  final actual = ficha.precio;
  if (actual == null) return const [];
  final inicio = DateTime(ahora.year, ahora.month - (meses - 1));
  final cronologico = ficha.historial.reversed.toList();

  // Precio vigente al empezar la ventana: el último cambio anterior, o el
  // primero que haya si no hay nada antes.
  final anteriores =
      cronologico.where((r) => r.registradoEn.isBefore(inicio)).toList();
  final dentro =
      cronologico.where((r) => !r.registradoEn.isBefore(inicio)).toList();
  final inicial = anteriores.isNotEmpty
      ? anteriores.last.precio
      : dentro.isNotEmpty
          ? dentro.first.precio
          : actual.precio;

  return [
    PuntoPrecio(inicio, inicial),
    for (final r in dentro) PuntoPrecio(r.registradoEn, r.precio),
    PuntoPrecio(ahora, actual.precio),
  ];
}

/// HU-11: tarjeta "Historial de Precios" de Editar producto: gráfica de área
/// de los últimos 4 meses y cuánto cambió el precio en el mes.
class HistorialPreciosCard extends StatelessWidget {
  final FichaPrecio ficha;
  final DateTime ahora;

  const HistorialPreciosCard({
    super.key,
    required this.ficha,
    required this.ahora,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final puntos = puntosDeHistorial(ficha, ahora);
    return TarjetaSuave(
      radio: 22,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: t.primario, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historial de Precios',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.texto,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.borde),
                ),
                child: Text(
                  'Últimos 4 meses',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.primario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (puntos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Guarda el precio para empezar el historial.',
                style: TextStyle(color: t.textoGris),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: CustomPaint(
                size: Size.infinite,
                painter: _GraficoPainter(
                  puntos: puntos,
                  linea: t.primario,
                  guia: t.borde,
                  texto: t.textoGris,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _PieVariacion(variacion: ficha.variacionDelMes(ahora)),
        ],
      ),
    );
  }
}

class _PieVariacion extends StatelessWidget {
  final double? variacion;

  const _PieVariacion({required this.variacion});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final (icono, texto) = switch (variacion) {
      final double d when d < 0 =>
        (Icons.trending_down, 'Bajó un ${_porcentaje(d)} este mes'),
      final double d when d > 0 =>
        (Icons.trending_up, 'Subió un ${_porcentaje(d)} este mes'),
      _ => (Icons.trending_flat, 'Sin cambios este mes'),
    };
    return Row(
      children: [
        Icon(icono, size: 18, color: t.texto),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 12.5, color: t.textoGris),
          ),
        ),
        Text(
          'VARIACIÓN REAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: t.textoGris,
          ),
        ),
      ],
    );
  }
}

/// "5.8%": un decimal, sin signo.
String _porcentaje(double v) => '${v.abs().toStringAsFixed(1)}%';

/// Gráfica de área escalonada: el precio se mantiene hasta el siguiente
/// cambio. El eje Y empieza en 0 y el X muestra los meses.
class _GraficoPainter extends CustomPainter {
  final List<PuntoPrecio> puntos;
  final Color linea;
  final Color guia;
  final Color texto;

  _GraficoPainter({
    required this.puntos,
    required this.linea,
    required this.guia,
    required this.texto,
  });

  static const _ejeY = 44.0;
  static const _ejeX = 22.0;
  static const _divisiones = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width - _ejeY;
    final alto = size.height - _ejeX;
    if (ancho <= 0 || alto <= 0) return;

    final maximo = _tope(puntos.map((p) => p.precio).reduce(math.max));
    final inicio = puntos.first.fecha.millisecondsSinceEpoch.toDouble();
    final fin = puntos.last.fecha.millisecondsSinceEpoch.toDouble();
    final rango = math.max(fin - inicio, 1.0);

    double x(DateTime f) =>
        _ejeY + (f.millisecondsSinceEpoch - inicio) / rango * ancho;
    double y(int precio) => alto - precio / maximo * alto;

    // Líneas guía y etiquetas del eje Y.
    final pincelGuia = Paint()
      ..color = guia
      ..strokeWidth = 1;
    for (var i = 0; i <= _divisiones; i++) {
      final valor = (maximo / _divisiones * i).round();
      final yy = y(valor);
      canvas.drawLine(Offset(_ejeY, yy), Offset(size.width, yy), pincelGuia);
      _texto(canvas, formatoCopCorto(valor), Offset(0, yy - 7), 10.5);
    }

    // Etiquetas de los meses.
    var mes = DateTime(puntos.first.fecha.year, puntos.first.fecha.month);
    while (!mes.isAfter(puntos.last.fecha)) {
      final xx = mes.isBefore(puntos.first.fecha) ? _ejeY : x(mes);
      _texto(canvas, mesCorto(mes.month), Offset(xx, alto + 6), 10.5);
      mes = DateTime(mes.year, mes.month + 1);
    }

    // Línea escalonada y área bajo ella.
    final trazo = Path()..moveTo(x(puntos.first.fecha), y(puntos.first.precio));
    for (var i = 1; i < puntos.length; i++) {
      trazo
        ..lineTo(x(puntos[i].fecha), y(puntos[i - 1].precio))
        ..lineTo(x(puntos[i].fecha), y(puntos[i].precio));
    }
    final area = Path.from(trazo)
      ..lineTo(x(puntos.last.fecha), alto)
      ..lineTo(x(puntos.first.fecha), alto)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [linea.withValues(alpha: 0.35), linea.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, alto)),
    );
    canvas.drawPath(
      trazo,
      Paint()
        ..color = linea
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Un tope "redondo" sobre el máximo, para que la línea no toque el borde.
  static int _tope(int maximo) {
    final objetivo = math.max(maximo * 1.2, 1000);
    final paso = math.pow(10, (math.log(objetivo) / math.ln10).floor()) / 2;
    return ((objetivo / paso).ceil() * paso).round();
  }

  void _texto(Canvas canvas, String valor, Offset posicion, double tamano) {
    final pintor = TextPainter(
      text: TextSpan(
        text: valor,
        style: TextStyle(fontSize: tamano, color: texto),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(canvas, posicion);
  }

  @override
  bool shouldRepaint(_GraficoPainter oldDelegate) =>
      oldDelegate.puntos != puntos ||
      oldDelegate.linea != linea ||
      oldDelegate.guia != guia;
}
