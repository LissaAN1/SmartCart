import 'package:flutter/material.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/estadisticas/presentation/bloc/estadisticas_bloc.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';

/// Texto cuando no hay cifras que mostrar (HU-28, escenario 3).
const _sinInformacion = 'No hay información disponible';

/// HU-28: las cifras del panel del administrador, con sus estados de carga,
/// error y sin información.
class PanelEstadisticas extends StatelessWidget {
  /// `null` si la pantalla no tiene de dónde consultarlas.
  final EstadisticasState? estado;
  final VoidCallback? onReintentar;

  const PanelEstadisticas({super.key, this.estado, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final estado = this.estado;
    if (estado == null) return const _SinInformacion();

    if (estado.status == EstadisticasStatus.fallida) {
      return TarjetaSuave(
        radio: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ErrorMessage(
                message: estado.errorMessage ??
                    'No pudimos cargar las estadísticas.'),
            TextButton(
                onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final datos = estado.datos;
    if (datos == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Al volver a consultar mantenemos las cifras y avisamos que carga.
        if (estado.status == EstadisticasStatus.cargando)
          const LinearProgressIndicator(minHeight: 3),
        _Cifras(datos: datos),
      ],
    );
  }
}

class _SinInformacion extends StatelessWidget {
  const _SinInformacion();

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      radio: 20,
      padding: const EdgeInsets.all(18),
      child: Text(
        _sinInformacion,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: t.textoGris),
      ),
    );
  }
}

class _Cifras extends StatelessWidget {
  final EstadisticasPlataforma datos;

  const _Cifras({required this.datos});

  @override
  Widget build(BuildContext context) {
    final ordenes = datos.ordenes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion(titulo: 'USUARIOS REGISTRADOS'),
        _Lista(filas: [
          for (final rol in UserRole.values)
            (rol.label, datos.usuariosDe(rol)),
        ]),
        const TituloSeccion(titulo: 'COMERCIOS'),
        _Fila(metricas: [
          ('Aprobados', datos.comerciosEn(ApprovalStatus.aprobado)),
          ('Pendientes', datos.comerciosEn(ApprovalStatus.pendiente)),
          ('Rechazados', datos.comerciosEn(ApprovalStatus.rechazado)),
        ]),
        const TituloSeccion(titulo: 'REPARTIDORES'),
        _Fila(metricas: [
          ('Aprobados', datos.repartidoresAprobados),
          ('En línea', datos.repartidoresEnLinea),
        ]),
        const TituloSeccion(titulo: 'PENDIENTES DE REVISIÓN'),
        _Lista(filas: [
          ('Solicitudes de comercios', datos.solicitudesComercio),
          ('Solicitudes de repartidores', datos.solicitudesRepartidor),
          ('Reportes de precio', datos.reportesPrecioPendientes),
        ]),
        const TituloSeccion(titulo: 'ÓRDENES'),
        if (ordenes == null)
          const _SinInformacion()
        else ...[
          _Fila(metricas: [('Pedidos hoy', ordenes.hoy)]),
          const SizedBox(height: 12),
          _Lista(filas: [
            for (final estado in EstadoOrden.values)
              if (ordenes.de(estado) > 0) (estado.label, ordenes.de(estado)),
          ]),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Cifras destacadas en una fila.
class _Fila extends StatelessWidget {
  final List<(String, int)> metricas;

  const _Fila({required this.metricas});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, m) in metricas.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: TarjetaMetrica(
                etiqueta: m.$1,
                valor: formatoMiles(m.$2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cifras en una lista de "nombre ... número".
class _Lista extends StatelessWidget {
  final List<(String, int)> filas;

  const _Lista({required this.filas});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      radio: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (nombre, cifra) in filas)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(nombre,
                          style: TextStyle(fontSize: 14.5, color: t.texto)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatoMiles(cifra),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: t.primarioOscuro),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
