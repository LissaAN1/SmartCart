import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';

/// Parte de arriba del catálogo, como en el diseño: buscador, chips de
/// categorías, resumen (total, valor del stock, stock bajo) y el título
/// "Inventario Activo".
class EncabezadoInventario extends StatelessWidget {
  final TextEditingController buscador;
  final ValueChanged<String> onBuscar;
  final List<Categoria> categorias;

  /// Chip elegido; `null` es "Todos".
  final String? idCategoria;
  final ValueChanged<String?> onCategoria;

  /// `null` mientras carga o si no se pudo leer.
  final ResumenCatalogo? resumen;

  const EncabezadoInventario({
    super.key,
    required this.buscador,
    required this.onBuscar,
    required this.categorias,
    required this.idCategoria,
    required this.onCategoria,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final resumen = this.resumen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('buscador-catalogo'),
          controller: buscador,
          onChanged: onBuscar,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar productos...',
            prefixIcon: Icon(Icons.search, color: t.textoGris),
            filled: true,
            fillColor: t.superficie,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.borde),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.borde),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                texto: 'Todos',
                elegido: idCategoria == null,
                onTap: () => onCategoria(null),
              ),
              for (final c in categorias)
                _Chip(
                  texto: c.nombre,
                  elegido: idCategoria == c.id,
                  onTap: () => onCategoria(c.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: t.suave.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.borde),
          ),
          child: Row(
            children: [
              _Metrica(
                etiqueta: 'TOTAL ITEMS',
                valor: resumen == null ? '—' : '${resumen.totalProductos}',
              ),
              _Separador(color: t.borde),
              _Metrica(
                etiqueta: 'VALOR STOCK',
                valor: resumen == null
                    ? '—'
                    : formatoCopCorto(resumen.valorStock),
              ),
              _Separador(color: t.borde),
              _Metrica(
                etiqueta: 'BAJO STOCK',
                valor: resumen == null ? '—' : '${resumen.bajoStock}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: t.primario, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inventario Activo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.texto,
                ),
              ),
            ),
            if (resumen != null)
              Text(
                resumen.totalProductos == 1
                    ? '1 producto'
                    : '${resumen.totalProductos} productos',
                style: TextStyle(fontSize: 13, color: t.textoGris),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback onTap;

  const _Chip({
    required this.texto,
    required this.elegido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: elegido ? t.primario : t.superficie,
        shape: StadiumBorder(
          side: BorderSide(color: elegido ? t.primario : t.borde),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
                color: elegido ? t.superficie : t.texto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Metrica({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: t.texto,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: t.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  final Color color;

  const _Separador({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: color);
}
