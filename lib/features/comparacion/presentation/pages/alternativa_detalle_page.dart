import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/presentation/comparacion_formato.dart';
import 'package:smartcart/features/confianza/presentation/widgets/confianza_del_precio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/presentation/widgets/mapa_establecimientos.dart';

/// Lo que recibe el detalle: la alternativa y desde dónde se calcularon las
/// distancias.
class AlternativaArgs {
  final Alternativa alternativa;
  final Ubicacion? cliente;

  const AlternativaArgs({required this.alternativa, this.cliente});
}

/// HU-18: el detalle de una alternativa. Los comercios en el mapa y, por
/// comercio, sus productos con el precio, su fuente, su fecha y su confianza
/// (HU-13), y la calificación del comercio (HU-25).
class AlternativaDetallePage extends StatelessWidget {
  final AlternativaArgs args;

  /// La fecha de "hoy" con la que se calcula la confianza; se inyecta en las
  /// pruebas.
  final DateTime Function() reloj;

  const AlternativaDetallePage({
    super.key,
    required this.args,
    this.reloj = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    final a = args.alternativa;
    final ahora = reloj();
    final conUbicacion = [
      for (final c in a.comercios)
        if (c.ubicacion != null) c,
    ];
    final centro = args.cliente ??
        (conUbicacion.isEmpty ? null : conUbicacion.first.ubicacion);
    return PantallaRol(
      tema: t,
      barraSuperior: const BarraTituloRol(
        titulo: 'Resumen de alternativa',
        mostrarAtras: true,
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Text(
            a.criterio.etiqueta,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: t.texto),
          ),
          Text(a.criterio.descripcion,
              style: TextStyle(fontSize: 13.5, color: t.textoGris)),
          const SizedBox(height: 14),
          if (centro != null) ...[
            MapaEstablecimientos(
              centro: centro,
              alto: 220,
              puntos: [
                for (final c in conUbicacion)
                  PuntoMapa(ubicacion: c.ubicacion!, titulo: c.nombre),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EtiquetaEstado.info(
                  '${a.establecimientos} ${a.establecimientos == 1 ? 'comercio' : 'comercios'}'),
              EtiquetaEstado.info('Total ${formatoCop(a.total)}'),
              if (a.ahorro > 0)
                EtiquetaEstado.exito('Ahorras ${formatoCop(a.ahorro)}'),
              EtiquetaEstado.info(
                  'Distancia: ${textoDistancia(a.distanciaTotalM)}'),
            ],
          ),
          const TituloSeccion(titulo: 'DESGLOSE POR COMERCIO'),
          for (final c in a.comercios) _Comercio(compra: c, ahora: ahora),
        ],
      ),
    );
  }
}

class _Comercio extends StatelessWidget {
  final CompraEnComercio compra;
  final DateTime ahora;

  const _Comercio({required this.compra, required this.ahora});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final lugar =
        [compra.direccion, compra.ciudad].where((s) => s.isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: t.suave, borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(Icons.storefront_outlined, color: t.primarioOscuro),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(compra.nombre,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: t.texto)),
                      if (lugar.isNotEmpty)
                        Text(lugar,
                            style:
                                TextStyle(fontSize: 12.5, color: t.textoGris)),
                      const SizedBox(height: 4),
                      Text(
                        '${textoCalificacion(compra.calificacion, compra.totalCalificaciones)}'
                        ' · ${textoDistancia(compra.distanciaM)}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: t.primarioOscuro),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final item in compra.items) ...[
              Divider(height: 24, color: t.borde),
              _Item(item: item, ahora: ahora),
            ],
            Divider(height: 24, color: t.borde),
            Row(
              children: [
                Expanded(
                  child: Text('Subtotal del comercio',
                      style: TextStyle(fontSize: 13.5, color: t.textoGris)),
                ),
                Text(formatoCop(compra.subtotal),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.texto)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final ItemAlternativa item;
  final DateTime ahora;

  const _Item({required this.item, required this.ahora});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final o = item.oferta;
    final marca = item.linea.marca;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.linea.nombre,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: t.texto)),
                  Text(
                    '${marca == null || marca.isEmpty ? '' : '$marca · '}'
                    'Cantidad: ${item.linea.cantidad}',
                    style: TextStyle(fontSize: 12.5, color: t.textoGris),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatoCop(o.precio),
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                if (o.enPromocion)
                  Text('Antes ${formatoCop(o.precioNormal)}',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: t.textoGris,
                          decoration: TextDecoration.lineThrough)),
                Text('Subt: ${formatoCop(item.subtotal)}',
                    style: TextStyle(fontSize: 11.5, color: t.textoGris)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConfianzaDelPrecio(
          fuente: o.fuente,
          actualizadoEn: o.actualizadoEn,
          ahora: ahora,
        ),
      ],
    );
  }
}
