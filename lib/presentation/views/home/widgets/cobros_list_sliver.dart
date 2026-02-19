import 'package:flutter/material.dart';
import '../../../../domain/cobro_model.dart';
import 'cobro_card.dart';

/// Sliver que muestra una lista de cobros
class CobrosListSliver extends StatelessWidget {
  final List<Cobro> cobros;

  const CobrosListSliver({super.key, required this.cobros});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cobro = cobros[index];
        return CobroCard(cobro: cobro);
      }, childCount: cobros.length),
    );
  }
}
