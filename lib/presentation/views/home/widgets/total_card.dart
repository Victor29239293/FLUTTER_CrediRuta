import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../infrastructure/data_class.dart';

/// Tarjeta que muestra el total de cobros con desglose por método de pago
class TotalCard extends StatelessWidget {
  final CobrosData cobrosData;

  const TotalCard({super.key, required this.cobrosData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMetodosPago(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  cobrosData.total.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ],
        ),
        _CantidadCobrosChip(cantidad: cobrosData.cantidadCobros),
      ],
    );
  }

  Widget _buildMetodosPago() {
    return Row(
      children: [
        Expanded(
          child: _MetodoPagoItem(
            label: 'Efectivo',
            monto: cobrosData.totalEfectivo,
            color: AppTheme.efectivo,
          ),
        ),
        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
        Expanded(
          child: _MetodoPagoItem(
            label: 'Transferencia',
            monto: cobrosData.totalTransferencia,
            color: AppTheme.transferencia,
          ),
        ),
      ],
    );
  }
}

/// Chip que muestra la cantidad de cobros
class _CantidadCobrosChip extends StatelessWidget {
  final int cantidad;

  const _CantidadCobrosChip({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$cantidad cobros',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Item individual para mostrar el monto por método de pago
class _MetodoPagoItem extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;

  const _MetodoPagoItem({
    required this.label,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
