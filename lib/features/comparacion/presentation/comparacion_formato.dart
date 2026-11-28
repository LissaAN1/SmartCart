import 'package:flutter/material.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/ubicacion/presentation/formato_distancia.dart';

/// "4,5" para una calificación promedio.
String formatoCalificacion(double calificacion) =>
    calificacion.toStringAsFixed(1).replaceAll('.', ',');

/// "★ 4,5 (12)" o "Sin calificaciones" (HU-25).
String textoCalificacion(double? calificacion, int total) =>
    calificacion == null || total == 0
        ? 'Sin calificaciones'
        : '★ ${formatoCalificacion(calificacion)} ($total)';

/// "3,4 km" o "No disponible" cuando falta la ubicación del cliente o de un
/// comercio.
String textoDistancia(double? metros) =>
    metros == null ? 'No disponible' : formatoDistancia(metros);

IconData iconoCriterio(CriterioCompra criterio) => switch (criterio) {
      CriterioCompra.ahorro => Icons.savings_outlined,
      CriterioCompra.calidadPrecio => Icons.workspace_premium_outlined,
      CriterioCompra.comodidad => Icons.storefront_outlined,
    };
