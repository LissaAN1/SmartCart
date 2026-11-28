import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Un lugar que se marca en el mapa.
class PuntoMapa {
  final Ubicacion ubicacion;
  final String titulo;

  const PuntoMapa({required this.ubicacion, required this.titulo});
}

/// Mapa de OpenStreetMap con un punto de referencia (el cliente), su radio
/// y los establecimientos. Es el componente de mapa de la app: lo usan el
/// mapa del cliente (HU-19) y lo reutilizarán la comparación del carrito
/// (HU-18) y la ruta del repartidor (HU-22).
///
/// Usamos OpenStreetMap porque no necesita llave ni facturación; sus
/// condiciones piden mostrar el crédito, que va abajo a la derecha.
class MapaEstablecimientos extends StatelessWidget {
  /// Las pruebas lo apagan: en ellas no hay red para descargar el mapa.
  static bool cargarTeselas = true;

  final Ubicacion centro;

  /// Si se da, se dibuja el círculo y el mapa se encuadra para mostrarlo
  /// completo.
  final int? radioM;
  final List<PuntoMapa> puntos;
  final double alto;

  const MapaEstablecimientos({
    super.key,
    required this.centro,
    this.radioM,
    this.puntos = const [],
    this.alto = 280,
  });

  static LatLng _latLng(Ubicacion u) => LatLng(u.latitud, u.longitud);

  /// El cuadro que contiene el círculo del radio. Sin radio, el que contiene
  /// el centro y todos los puntos, con al menos un kilómetro alrededor del
  /// centro (HU-18: los comercios de una alternativa).
  LatLngBounds _encuadre() {
    final metros = (radioM ?? 1000).toDouble();
    final dLat = metros / 111320;
    final dLon =
        metros / (111320 * math.cos(centro.latitud * math.pi / 180)).abs();
    return LatLngBounds.fromPoints([
      LatLng(centro.latitud - dLat, centro.longitud - dLon),
      LatLng(centro.latitud + dLat, centro.longitud + dLon),
      if (radioM == null)
        for (final p in puntos) _latLng(p.ubicacion),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: alto,
        child: FlutterMap(
          // Al cambiar el centro o el radio se vuelve a encuadrar.
          key: ValueKey((centro, radioM, puntos.length)),
          options: MapOptions(
            initialCenter: _latLng(centro),
            initialCameraFit: CameraFit.bounds(
              bounds: _encuadre(),
              padding: const EdgeInsets.all(16),
            ),
            backgroundColor: t.suave,
          ),
          children: [
            if (cargarTeselas)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smartcart',
              ),
            if (radioM != null)
              CircleLayer(circles: [
                CircleMarker(
                  point: _latLng(centro),
                  radius: radioM!.toDouble(),
                  useRadiusInMeter: true,
                  color: t.primario.withValues(alpha: 0.12),
                  borderColor: t.primario,
                  borderStrokeWidth: 2,
                ),
              ]),
            MarkerLayer(markers: [
              for (final p in puntos)
                Marker(
                  point: _latLng(p.ubicacion),
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  child: Tooltip(
                    message: p.titulo,
                    child: Icon(Icons.location_on,
                        size: 36, color: t.primarioOscuro),
                  ),
                ),
              Marker(
                point: _latLng(centro),
                width: 22,
                height: 22,
                child: Semantics(
                  label: 'Tu ubicación',
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.primario,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
            ]),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '© OpenStreetMap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: t.textoGris),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
