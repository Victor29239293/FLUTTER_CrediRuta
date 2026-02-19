import 'package:flutter/material.dart';

import '../../../../domain/recinto_model.dart';
import 'header_section.dart';
import 'empty_state.dart';
import 'recinto_card.dart';

/// Contenido principal de la vista de recintos
///
/// Muestra el header con estadísticas y la lista de recintos
/// o un estado vacío si no hay recintos registrados.
class RecintosContent extends StatelessWidget {
  final List<Recinto> recintos;

  const RecintosContent({super.key, required this.recintos});

  int get _recintosActivos => recintos.where((r) => r.activo).length;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Header con estadísticas
        SliverToBoxAdapter(
          child: HeaderSection(
            total: recintos.length,
            activos: _recintosActivos,
          ),
        ),

        // Lista de recintos o estado vacío
        if (recintos.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyState())
        else
          _buildRecintosList(),

        // Espacio inferior para el FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildRecintosList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecintoCard(recinto: recintos[index]),
          ),
          childCount: recintos.length,
        ),
      ),
    );
  }
}
